local conf = ... or {}
local moon = require("moon")
local socket = require("moon.socket")
local json = require("json")

require("global_common")
require("regist_protocol")
require("ingate_commands")
require("ingate_message")

local _wg = moon.exports
local commands = wm_get_commands("commands")
local memorydata = require("memorydata")

local HOST = conf.host
local PORT = conf.port

local all_conf = require("server_config")
local fd_list = memorydata.getobj("fd_list")
local login_list = memorydata.getobj("login_list", setmetatable({}, {__mode = "kv"}))

local this = {}
local transfer_func = {}
local transfer_type = _wg.transfer_type

---本地协议
transfer_func[transfer_type.native] = function(fd, src_msg)
    local cmd, nextpos = string.unpack("s1", src_msg)

    if not commands[cmd] then
        socket.close(fd)
        print("close ", fd, "commands not exist!", cmd)
        return
    end

    local str_data = string.unpack("s1", src_msg, nextpos)
    local json_data = json.decode(str_data)

    commands[cmd](fd, json_data)
end

---转回客户端
transfer_func[transfer_type.client] = function(fd, src_msg)
    local nextpos = 0
    local service_id, nextpos = string.unpack(" > I4", src_msg, nextpos)
    local cli_id, nextpos = string.unpack(" > I4", src_msg, nextpos)

    moon.raw_send(moon.PTYPE_SRV2CLI, service_id, tostring(cli_id), string.sub(src_msg, nextpos))
end

-------------------2 bytes len (big endian) protocol------------------------
socket.on("accept", function(fd, msg)
    local receiver = moon.decode(msg, "R") --socket的类型
    local sessionid = moon.decode(msg, "E")
    print("accept ", fd, sender, moon.decode(msg, "Z"), receiver)
    -- 设置read超时，单位秒
    -- socket.settimeout(fd, 10)
    -- 该协议默认只支持最大长度32KB的数据收发
    -- 设置标记可以把超多32KB的数据拆分成多个包
    -- 可以单独设置独写的标记，r:表示读。w:表示写
    socket.set_enable_chunked(fd, "w")

    fd_list[fd] = 0
end)

socket.on("message", function(fd, msg)
    local src_msg = moon.decode(msg, "Z")
    local index, nextpos = string.unpack(" > H", src_msg)
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
    fd_list[fd] = nil
    print("close ", fd, moon.decode(msg, "Z"))

    local login_name = login_list[fd]

    if login_name then
        login_list[fd] = nil
        print("login fd closed ", login_name)
    end
end)

socket.on("error", function(fd, msg)
    print("error ", fd, moon.decode(msg, "Z"))
end)

-- moon.PTYPE_SOCKET ：2字节(大端)表示长度的协议
local listenfd = socket.listen(HOST, PORT, moon.PTYPE_SOCKET)
socket.start(listenfd)--start accept
print("ingate server start", conf.name, HOST, PORT)

moon.shutdown(function()
    moon.quit()
end)

return this
