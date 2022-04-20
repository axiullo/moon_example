local moon = require("moon")
local socket = require("moon.socket")
local json = require("json")

--define lua module search dir
local path = table.concat({
    "./lualib/?.lua",
    "./wmlualib/?.lua",
}, ";")

local oldpackpath = package.path
package.path = path .. ";"
moon.set_env("PATH", string.format("package.path='%s'..package.path\n", package.path))
package.path = oldpackpath .. ";" .. package.path

require("priority_load")

local clientfd
local HOST = "10.6.60.234"
local PORT = 20521
local msgid = 0

local commands = wm_get_commands("commands")
local _wg = moon.exports

_wg.is_serverstop = false
local this = {}

local function is_serverstop()
    return _G.is_serverstop
end

--todo 消息的封装
local function get_msgid()
    msgid = msgid + 1
    return msgid
end

local function send(fd, data)
    if not fd then
        return false
    end

    socket.write(fd, data)

    -- local len = #data
    -- return socket.write(fd, string.pack(">H", len)..data)
end

--服务器类型
local servertype_list = _wg.servertype_list_type2id

local function send2login(fd, cmd, src_data)
    src_data = src_data or ""
    src_data = json.encode(src_data)
    local tmpmsgid = get_msgid()
    local msg = string.pack(">I4>Hs1s1", tmpmsgid, servertype_list.login, cmd, src_data)

    send(fd, msg)
end

local function send2gate(fd, cmd, src_data)
    src_data = src_data or ""
    src_data = json.encode(src_data)
    local tmpmsgid = get_msgid()
    local msg = string.pack(">I4>Hs1s1", tmpmsgid, servertype_list.gate, cmd, src_data)

    send(fd, msg)
end

-- 异步连接
local function do_connect_async(is_reconnect)
    if is_serverstop() then
        return
    end

    msgid = 0
    local fd, err = socket.connect(HOST, PORT, moon.PTYPE_SOCKET)

    if not fd then
        print_error("!!!!" .. err)

        local co = coroutine.create(function(timerid)
            do_connect_async(is_reconnect)
        end)

        moon.timeout(3000, co)
        return
    end
end

local profiler = require("profiler")
--同步连接
--疑问: connect 会耗时2s 为什么?
local function do_connect(is_reconnect)
    if is_serverstop() then
        return
    end

    profiler:execute_cost_start("socket connect")

    msgid = 0
    local fd, err = socket.sync_connect(HOST, PORT, moon.PTYPE_SOCKET)

    profiler:execute_cost_end()

    if not fd then
        print_error("!!!!" .. err)

        local co = coroutine.create(function(timerid)
            do_connect(is_reconnect)
        end)

        moon.timeout(3000, co)
        return
    end
end

-- moon.async(do_connect)
do_connect()

local function do_ping()
    if not clientfd then
        return
    end

    print("~~~~ do_ping")
    send2gate(clientfd, "ping")

    moon.timeout(8000, do_ping)
end

local lg_data = {
    account_name = "wm1",
    password = "123456",
    params = {
        a = 1,
        b = 2,
    },
    name = "哈哈"
}

socket.on("connect", function(fd, msg)
    print("connect ", fd, moon.decode(msg, "Z"))

    clientfd = fd

    send2login(clientfd, "login", lg_data)
    do_ping()
end)

socket.on("message", function(fd, msg)
    local src_msg = moon.decode(msg, "Z")
    local nextpos = 0
    local cmd, nextpos = string.unpack("s1", src_msg, nextpos)

    print_debug("receive msg cmd ", cmd)

    local func = commands[cmd]

    if not func then
        print("error", "undefine cmd ", cmd)
        return
    end

    local json_data = string.unpack("s1", src_msg, nextpos)
    func(json.decode(json_data))
    -- socket.write_message(fd, msg)
end)

socket.on("close", function(fd, msg)
    print("close ", fd, moon.decode(msg, "Z"))

    clientfd = nil
    do_connect(true)
end)

socket.on("error", function(fd, msg)
    print("error ", fd, moon.decode(msg, "Z"))
end)

---
function commands.login_result(data)
    if data.result == 0 then
        send2login(clientfd, "regist", lg_data)
    elseif data.result == 1 then
        this.login_after(data.gateinfo)
    end
end

---
function commands.regist_result(data)
    if data.result == 0 then
        print(data.content)

        this.login_after(data.gateinfo)
    elseif data.result == 1 then
        print(data.content)
    end
end

local gate_servertime = -1
function commands.pong(data)
    gate_servertime = data.t
    print("pong servertime = ", gate_servertime)
end

function this.login_after(gateinfo)
    if HOST ~= gateinfo.host or PORT ~= gateinfo.port then
        print("@@@@@@@@@@ login_after ")
        HOST = gateinfo.host
        PORT = gateinfo.port
        msgid = 0
        clientfd = nil

        do_connect()
    end
end
