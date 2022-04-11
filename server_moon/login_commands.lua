local moon = require("moon")
local commands = wm_get_commands("commands")
local mysql = require("wmlualib.mysql")
local json = require("json")
local socket = require("moon.socket")
local msend = require("msend")

---登录
---@ from_srv_fd, from_gate_service, cli_fd,
function commands.login(req_info, msg)
    local data = mysql:find_one("account", {{account_name = msg.account_name}})

    if not data then
        msend.toclient(req_info, "login_result", {result = 0, content = "用户不存在, 请注册"})
        return
    end

    msend.toclient(req_info, "login_result", {result = 1, content = "登录成功", d = 123456})
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
    msend.toclient(req_info, "regist_result", {result = 1, content = "注册成功"})
end
