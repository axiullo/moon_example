local moon = require("moon")
local socket = require("moon.socket")
local json = require("json")

require("priority_load")

local _wg = moon.exports
local transfer_type = _wg.transfer_type

local this = {}

---转发给客户端
function this.toclient(req_info, cmd, msg_data)
    local ret_msg = string.pack(">H", transfer_type.client) ..
    string.pack(">I4>I4", req_info.from_service, req_info.cli_fd) ..
    string.pack("s1s1", cmd, json.encode(msg_data))

    socket.write(req_info.from_srv_fd, ret_msg)
end

---客户端给服务器消息转发
function this.message_tos(frm_fd, req_info, msg_data)
    local param_msg = string.pack(">H", transfer_type.native) ..
    string.pack(">I4", req_info.from_service) ..
    string.pack(">I4", req_info.cli_fd) ..
    msg_data

    socket.write(frm_fd, param_msg)
end

---打包发送
function this.send(fd, cmd, msg_data)
    local param_msg = string.pack("s1s1", cmd, json.encode(msg_data))

    socket.write(fd, param_msg)
end

---直接发送
function this.dic_send(fd, msg)
    socket.write(fd, msg)
end

---发送消息通过transfer_type
function this.sendbyttype(fd, mtype, cmd, msg_data)
    local tomsg = string.pack(">H", mtype) .. string.pack("s1s1", cmd, json.encode(msg_data))
    socket.write(fd, tomsg)
end

return this
