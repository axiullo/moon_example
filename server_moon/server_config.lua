--全服务配置
return {
    gate = {
        base_name = "gate",
        file = "service_gate.lua",
        host = "0.0.0.0",
        base_port = 20520,
        num = 3,
        unique = true, -- 通过name做唯一区分,name不能相同
    },

    ingate = {
        base_name = "ingate",
        file = "service_ingate.lua",
        host = "127.0.0.1", --内网ip
        base_port = 20620,
        num = 2,
        unique = true, -- 通过name做唯一区分,name不能相同
    },

    login = {
        base_name = "login",
        file = "service_login.lua",
        num = 1,
        unique = true, -- 通过name做唯一区分,name不能相同
    }
}
