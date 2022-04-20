---__init__ --启动服务配置
if _G["__init__"] then
    local arg = ... --- command line args
    return {
        -- thread = 16,
        enable_console = true,
        logfile = string.format("log/moon-%s-%s.log", arg[1], os.date("%Y-%m-%d-%H-%M-%S")),
        loglevel = 'DEBUG',
    }
end

local moon = require("moon")
print("start server")

---设置lua模块环境变量
-- define lua module search dir
local path = table.concat({
    "./lualib/?.lua",
    "./wmlualib/?.lua",
    -- "./middle/?.lua",
}, ";")

local oldpackpath = package.path
package.path = path .. ";"
moon.set_env("PATH", string.format("package.path='%s'..package.path\n", package.path))
package.path = oldpackpath .. ";" .. package.path
---设置lua模块环境变量 end

local all_conf = require("server_config")

local function gate_startup()
    local conf = all_conf.gate

    for i = 1, conf.num do
        conf.port = conf.base_port + i - 1
        conf.name = conf.base_name .. i
        conf.threadid = i --指定在哪个work上运行, 这个work不再提供其他服务
        local r = moon.new_service("lua", conf)
    end

    local conf2 = all_conf.ingate

    for i = 1, conf2.num do
        conf2.port = conf2.base_port + i - 1
        conf2.name = conf2.base_name .. i
        local r = moon.new_service("lua", conf2)
    end
end

local function login_startup()
    local conf = all_conf.login

    for i = 1, conf.num do
        conf.port = conf.base_port + i - 1
        conf.name = conf.base_name .. i
        local r = moon.new_service("lua", conf)
    end
end

local function player_startup()
    local conf = all_conf.player

    for i = 1, conf.num do
        conf.name = conf.base_name .. i
        local r = moon.new_service("lua", conf)
    end
end

local startup_func = {
    gate = gate_startup,
    login = login_startup,
    player = player_startup,
}

local arg = load(moon.get_env("ARG"))()

moon.async(function()
    local func = startup_func[arg[1]]

    if not func then
        print("error", "startup type not found")
        moon.quit()
        return
    end

    func()
end)
