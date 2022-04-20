local conf = ... or {}
local moon = require("moon")
local socket = require("moon.socket")
local json = require("json")
local memorydata = require("middle.memorydata")
local msend = require("middle.msend")

local commands = wm_get_commands("commands")
local fdlist = memorydata.getobj("fdlist")

require("priority_load")
require("commands.player.player_commands")

---------------------------------- socket监听事件 ----------------------------
socket.on("connect", function(fd, msg)
    print("connect", fd, moon.decode(msg, "Z"))
end)

local _wg = moon.exports
local transfer_type = _wg.transfer_type
local transfer_func = {}

---本地协议
transfer_func[transfer_type.native] = function (from_srv_fd, src_msg)
    local nextpos = 0
    local from_gate_service, nextpos = string.unpack(">I4", src_msg, nextpos)
    local cli_fd, nextpos = string.unpack(">I4", src_msg, nextpos)
    local cmd, nextpos = string.unpack("s1", src_msg, nextpos)
    local func = commands[cmd]

    print("receive msg cmd = ", cmd, from_srv_fd, cli_fd)

    if not func then
        socket.close(from_srv_fd)
        print("close ", from_srv_fd, "commands not exist!", cmd)
        return
    end

    local str_data = string.unpack("s1", src_msg, nextpos)
    local json_data = json.decode(str_data)

    ---封装来源信息
    local req_info = {
        from_srv_fd = from_srv_fd, --来源的通信上下文
        from_service = from_gate_service, --来源的服务id
        cli_fd = cli_fd, --来源的客户端句柄
    }

    func(req_info, json_data)
end

---
transfer_func[transfer_type.s2s] = function(fd, src_msg)
    local cmd, nextpos = string.unpack("s1", src_msg)
    local func = commands[cmd]

    if not func then
        socket.close(fd)
        print("close ", fd, "commands not exist!", cmd)
        return
    end

    local str_data = string.unpack("s1", src_msg, nextpos)
    local json_data = json.decode(str_data)

    func(fd, json_data)
end

socket.on("message", function(fd, msg)
    local src_msg = moon.decode(msg, "Z")
    local index, nextpos = string.unpack(">H", src_msg)
    local func = transfer_func[index]

    if not func then
        socket.close(fd)
        print("close ", fd, "transfer_func not exist!", index)
        return
    end

    moon.async(function()
        local ok, err = xpcall(func, debug.traceback, fd, string.sub(src_msg, nextpos))

        if not ok then
            print("error", err)
        end
    end)
end)

socket.on("close", function(fd, msg)
    print("close ", fd, moon.decode(msg, "Z"))

    for tp, list in pairs(fdlist) do
        if table.hash_remove(list, fd) then
            break
        end
    end
end)

socket.on("error", function(fd, msg)
    print("error ", fd, moon.decode(msg, "Z"))
end)
---------------------------------- socket监听事件 end ----------------------------

local all_conf = require("server_config")

---启动标识,全部为true, 认为服务器正常启动
local startup_flags = {
    db = false,
    login = false,
}

local mysql = require("wmlualib.mysql")

moon.async(function()
    if mysql:connect() then
        startup_flags.db = true

        -- local a = mysql:execute_query("show databases")
        -- print_r(a)
        -- local b = mysql:execute_query(" select 1 + 2 as p")
        -- print_r(b)
        -- local res = mysql:execute_query("create table cats " .. "(id serial primary key, " .. "name varchar(5))")
        -- print_r(res)
        -- res = mysql:execute_query("select * from notexisttable")
        -- print_r(res)
    end
end)

local allloginnum = 0
local success_num = 0

---检查是否连上所有登录服务器
local function login_check()
    success_num = success_num + 1

    if success_num == allloginnum then
        startup_flags.login = true
        print("login_check success!")
    end
end

local function do_connect_login(host, port, index)
    local fd, err = socket.sync_connect(host, port, moon.PTYPE_SOCKET)

    if fd then
        local son_fdlist = table.get_or_create(fdlist, "login", {})
        son_fdlist[index] = fd
        socket.set_enable_chunked(fd, "wr")

        local param_data = {
            base_name = conf.base_name,
            name = conf.name
        }

        msend.sendbyttype(fd, transfer_type.s2s, "regist_server", param_data)
        login_check()
    else
        print("*** todo reconnect login", index, host, port)

        moon.timeout(10000, function (...)
            do_connect_login(host, port, index)
        end)
    end
end

moon.async(function()
    local login_conf = all_conf["login"]
    local host = login_conf.host
    local baseport = login_conf.base_port
    local num = login_conf.num
    allloginnum = num

    for i = 1, num do
        local port = baseport + i - 1
        do_connect_login(host, port, i)
    end
end)

local function do_connect_ingate(host, port, index)
    local fd, err = socket.connect(host, port, moon.PTYPE_SOCKET)

    if fd then
        local son_fdlist = table.get_or_create(fdlist, "ingate", {})
        son_fdlist[index] = fd
        socket.set_enable_chunked(fd, "wr")

        local param_data = {
            base_name = conf.base_name,
            name = conf.name
        }

        msend.sendbyttype(fd, transfer_type.s2s, "regist_server", param_data)
    else
        print("*** todo reconnect ingate", index, host, port)
    end

    return fd
end

---服务器启动
local function startup()
    moon.exports.starup_flag = true

    moon.async(function()
        local ingate_conf = all_conf["ingate"]
        local host = ingate_conf.host
        local baseport = ingate_conf.base_port
        local num = ingate_conf.num

        for i = 1, num do
            local port = baseport + i - 1
            do_connect_ingate(host, port, i)
        end
    end)
end

---启动检查
local function startup_check()
    print("startup_check")

    local alltrue = true

    for k, v in pairs(startup_flags) do
        if not v then
            alltrue = false
        end
    end

    if alltrue then
        startup()
    else
        moon.timeout(1500, startup_check)
    end
end

startup_check()

--- 关服
moon.shutdown(function()
    moon.quit()
end)
