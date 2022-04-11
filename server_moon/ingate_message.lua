local moon = require("moon")
local memorydata = require("memorydata")
local socket = require("moon.socket")
local message = wm_get_commands("message")
local msend = require("msend")

local login_list = memorydata.getobj("login_list")
local this = {}

function this.clitologin(req_info, msg)
    if not next(login_list) then
        print_warn("no login_server link")
        return
    end

    local loginkeys = table.keys(login_list)
    local loginfd = loginkeys[math.random(#loginkeys)]

    msend.message_tos(loginfd, req_info, msg)
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
function message.cli2srv_message(servertypeid, req_info, msg)
    local func = this.call_func[this.getservertype(servertypeid)]
    func(req_info, msg)
end

return this
