local moon = require("moon")
local commands = wm_get_commands("commands")
local mysql = require("wmlualib.mysql")
local json = require("json")
local socket = require("moon.socket")
local msend = require("middle.msend")
local memorydata = require("middle.memorydata")
local wmutil = require("middle.wmutil")

local server_list = memorydata.getobj("server_list")
local _wg = moon.exports
local transfer_type = _wg.transfer_type

local this = {}

---登录
---@ from_srv_fd, from_gate_service, cli_fd,
function commands.login(req_info, msg)
    local data = mysql:find_one("account", {{account_name = msg.account_name}})

    if not data then
        msend.toclient(req_info, "login_result", {result = 0, content = "用户不存在, 请注册"})
        return
    end

    local gateinfo = wmutil.get_gate_by_id(data.id)
    msend.toclient(req_info, "login_result", {result = 1, content = "登录成功", d = 123456, gateinfo = gateinfo})

    this.login_after(data.id, req_info)

end

---插入的key
local insertkey = {
    account_name = true,
    createtime = true,
    params = true,
    password = true
}

---注册
function commands.regist(req_info, msg)
    local data = mysql:find_one("account", {{account_name = msg.account_name}})

    if data then
        msend.toclient(req_info, "regist_result", {result = 0, content = "用户已存在"})
        return
    end

    local insertdata = {}

    for k in pairs(insertkey) do
        insertdata[k] = msg[k]
    end

    insertdata.createtime = moon.time()
    insertdata.params = json.encode(insertdata.params or "{}")

    local res = mysql:insert_one("account", insertdata)
    --res值     print_r(res)
    --     <var> = {
    --     affected_rows   = 1,
    --     insert_id       = 5,
    --     server_status   = 2,
    --     warning_count   = 0,
    -- },

    local id = res.insert_id
    local gateinfo = wmutil.get_gate_by_id(id)
    msend.toclient(req_info, "regist_result", {result = 1, content = "注册成功", gateinfo = gateinfo})

    this.login_after(id, req_info)
end

function this.login_after(account_id, req_info)
    local playerinfo = wmutil.get_player_by_id(account_id)
    --分配网关和玩家服, 去通知玩家服,这个玩家验证成功.
    --客户端去验证是否是同一个网关.
    msend.sendbyttype(req_info.from_srv_fd, transfer_type.s2s, "s2s_login_after", {account_id = account_id, playerinfo = playerinfo})
end

----------------------------------------------------
---注册服务器
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

return this
