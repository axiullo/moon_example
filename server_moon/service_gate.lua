local conf = ... or {}
local moon = require("moon")
local socket = require("moon.socket")
local seri = require("seri")

require("regist_protocol")

require("profiler")

local message = wm_get_commands("message")

local HOST = conf.host
local PORT = conf.port

local all_conf = require("server_config")
local fd_list = {}
local fd2player = {}

local this = {}
local servertype_list = {
    [101] = "login",
}

print(package.path)

-------------------2 bytes len (big endian) protocol------------------------
socket.on("accept", function(fd, msg)
    local receiver = moon.decode(msg, "R") --socket的类型
    local sessionid = moon.decode(msg, "E")
    print("accept ", fd, sender, moon.decode(msg, "Z"), receiver)
    -- 设置read超时，单位秒
    socket.settimeout(fd, 10)
    -- 该协议默认只支持最大长度32KB的数据收发
    -- 设置标记可以把超多32KB的数据拆分成多个包
    -- 可以单独设置独写的标记，r:表示读。w:表示写
    socket.set_enable_chunked(fd, "w")

    fd_list[fd] = 0
end)

-- 获得分配的内部网关的名称
function this.get_ingate_name(num)
    local ingate_conf = all_conf['ingate']
    local ret = num % ingate_conf.num + 1

    return ret
end

socket.on("message", function(fd, msg)
    local sender = moon.decode(msg, "S")
    local src_msg = moon.decode(msg, "Z")

    ---疑问: 消息序列号有啥用?  tcp保证了消息的序列性
    local msgSN, nextpos = string.unpack(">I4", src_msg)
    local cur_msgSN = fd_list[fd] + 1

    if cur_msgSN ~= msgSN then
        socket.close(fd)
        print("close ", fd, "msgSN not same!")
        return
    end

    local servertype = string.unpack(">H", src_msg, nextpos)

    if not servertype_list[servertype] then
        socket.close(fd)
        print("close ", fd, "servertype not exist!")
        return
    end

    --转到ingate, ingate解析消息 转到对应的服务器
    local newmsg = string.sub(src_msg, nextpos)
    moon.raw_send(moon.PTYPE_CLI2SRV, moon.queryservice("ingate"..this.get_ingate_name(fd)), tostring(fd), newmsg)

    -- local json_data = string.unpack("s1", src_msg, nextpos)
    -- print(json_data)

    fd_list[fd] = fd_list[fd] + 1
end)

socket.on("close", function(fd, msg)
    fd_list[fd] = nil
    print("close ", fd, moon.decode(msg, "Z"))
end)

socket.on("error", function(fd, msg)
    print("error ", fd, moon.decode(msg, "Z"))
end)

-- moon.PTYPE_SOCKET ：2字节(大端)表示长度的协议
local listenfd = socket.listen(HOST, PORT, moon.PTYPE_SOCKET)
socket.start(listenfd)--start accept
print("gate server start", conf.name, HOST, PORT)

--
moon.shutdown(function()
    moon.quit()
end)

function message.srv2cli_message(cli_fd, src_msg)
    socket.write(cli_fd, src_msg)
end

return this
