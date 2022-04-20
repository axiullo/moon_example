local moon = require("moon")
require("common")
local commands = wm_get_commands("commands")

---玩家登录成功,玩家服记录
function commands.s2s_login_after(fd, msg_data)
    local account_id = msg_data.account_id

    print("s2s_login_after", account_id)
end
