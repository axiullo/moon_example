local moon = require("moon")
local memorydata = require("memorydata")
local socket = require("moon.socket")
local message = wm_get_commands("message")

local login_list = memorydata.getobj("login_list")
local this = {}

function this.clitologin(from_gate, cli_fd, msg)
    if not next(login_list) then
        print_warn("no login_server link")
        return
    end

    local loginkeys = table.keys(login_list)
    local loginfd = loginkeys[math.random(#loginkeys)]

    local param_msg = string.pack(">H", 1) .. string.pack(">I4", from_gate) .. string.pack(">I4", cli_fd) .. msg
    socket.write(loginfd, param_msg)
end

this.call_func = {
    login = this.clitologin,
}

--服务器类型
local servertype_list = {
    login = 101,
}

function this.getservertype(id)
    for k, v in pairs(servertype_list) do
        if id == v then
            return k
        end
    end
end

---客户端给服务器消息
function message.cli2srv_message(from_gate, cli_fd, servertypeid, msg)
    local func = this.call_func[this.getservertype(servertypeid)]
    func(from_gate, cli_fd, msg)
end

return this
