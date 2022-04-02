local conf = ... or {}
local moon = require("moon")
local socket = require("moon.socket")
local json = require("json")
local memorydata = require("memorydata")

local commands = wm_get_commands("commands")
local fdlist = memorydata.getobj("fdlist")

socket.on("connect", function(fd, msg)
    print("connect", fd, moon.decode(msg, "Z"))
    socket.set_enable_chunked(fd, "wr")

    local param_data = {
        name = conf.name
    }

    local tomsg = string.pack(">H", 1) .. string.pack("s1", "regist_login") .. string.pack("s1", json.encode(param_data))
    socket.write(fd, tomsg)
end)

-- function

-- local transfer_ids = {
--     [1] = , --客户端转来的消息
--     [2] = , --服务器转来的消息
-- }

local transfer_func = {}

---本地协议
transfer_func[1] = function (from_srv_fd, src_msg)
    local nextpos = 0
    local from_gate_service, nextpos = string.unpack(">I4", src_msg, nextpos)
    local cli_fd, nextpos = string.unpack(">I4", src_msg, nextpos)
    local cmd, nextpos = string.unpack("s1", src_msg, nextpos)

    if not commands[cmd] then
        socket.close(from_srv_fd)
        print("close ", from_srv_fd, "commands not exist!", cmd)
        return
    end

    local str_data = string.unpack("s1", src_msg, nextpos)
    local json_data = json.decode(str_data)

    commands[cmd](from_srv_fd, from_gate_service, cli_fd, json_data)
end

socket.on("message", function(fd, msg)
    --echo message to client
    -- socket.write(fd, moon.decode(msg, "Z"))

    local src_msg = moon.decode(msg, "Z")
    local index, nextpos = string.unpack(">H", src_msg)

    if not transfer_func[index] then
        socket.close(fd)
        print("close ", fd, "transfer_func not exist!", index)
        return
    end

    local ok, err = xpcall(transfer_func[index], debug.traceback, fd, string.sub(src_msg, nextpos))

    if not ok then
        print("error", err)
    end
end)

socket.on("close", function(fd, msg)
    print("close ", fd, moon.decode(msg, "Z"))
end)

socket.on("error", function(fd, msg)
    print("error ", fd, moon.decode(msg, "Z"))
end)

local all_conf = require("server_config")

local function do_connect(host, port, index)
    local fd, err = socket.connect(host, port, moon.PTYPE_SOCKET)

    if fd then
        fdlist[index] = fd
    else
        print("*** todo reconnect ingate", index, host, port)
    end
end

moon.async(function()
    local ingate_conf = all_conf["ingate"]
    local host = ingate_conf.host
    local baseport = ingate_conf.base_port
    local num = ingate_conf.num
    local fdlist = {}

    for i = 1, num do
        local port = baseport + i - 1
        do_connect(host, port, i)
    end
end)

--
moon.shutdown(function()
    moon.quit()
end)

------消息处理
---登录
function commands.login(from_srv_fd, from_gate_service, cli_fd, msg)
    print(table.tostring(msg))

    local ret_msg = string.pack(">H", 2) .. string.pack(">I4>I4", from_gate_service, cli_fd) ..
    string.pack("s1s1", "login_result", json.encode({ret = 1, content = "登录成功", d = 123456}))

    socket.write(from_srv_fd, ret_msg)
end

------消息处理 end
