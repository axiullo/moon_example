local moon = require("moon")
require("common")
local msend = require("middle.msend")

local commands = wm_get_commands("commands")
local memorydata = require("middle.memorydata")

local server_list = memorydata.getobj("server_list")
local _wg = moon.exports
local transfer_type = _wg.transfer_type

local this = {}

---注册登录服
function commands.regist_server(fd, msg_data)
    local base_name = msg_data.base_name
    local name = msg_data.name
    local type_list = server_list[base_name]

    if not type_list then
        server_list[base_name] = setmetatable({}, {__mode = "kv"})
        type_list = server_list[base_name]
    end

    type_list[fd] = name
    print("sys", "regist_server", fd, base_name, name)
end

---玩家登录成功
function commands.s2s_login_after(src_fd, msg_data)
    local account_id = msg_data.account_id
    local playerinfo = msg_data.playerinfo
    local base_name = playerinfo.base_name
    local findname = base_name .. (playerinfo.n + 1)
    local type_list = server_list[base_name]

    if not type_list then
        print("error", "s2s_login_after type_list empty", base_name)
        return
    end

    local fd = table.findKeyByValue(type_list, findname)

    if not fd then
        print("error", "s2s_login_after not find playerserver", findname)
        return
    end

    local data = {
        account_id = account_id,
    }

    msend.sendbyttype(fd, transfer_type.s2s, "s2s_login_after", data)

    print("~~~~~~~  s2s_login_after", fd)
    -- --广播
    -- moon.raw_send(moon.PTYPE_SRV2SRV, 0, tostring(moon.addr()), msg)
end

return this
