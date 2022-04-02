require("common")
local commands = wm_get_commands("commands")
local memorydata = require("memorydata")

local login_list = memorydata.getobj("login_list")

local this = {}
---注册登录服
function commands.regist_login(fd, msg_data)
    local name = msg_data.name
    login_list[fd] = name
    print("sys", "regist_login", fd, name)
end

return this
