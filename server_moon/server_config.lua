--全服务配置
return {
    gate = {
        base_name = "gate",
        file = "service_gate.lua",
        host = "10.6.60.234",
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
        host = "127.0.0.1", --内网ip
        base_port = 20701,
        num = 1,
        unique = true, -- 通过name做唯一区分,name不能相同
    },

    player = {
        base_name = "player",
        file = "service_player.lua",
        host = "127.0.0.1", --内网ip
        base_port = 21001,
        num = 3,
        unique = true, -- 通过name做唯一区分,name不能相同
    },

    room = {
        base_name = "room",
        file = "service_room.lua",
        host = "127.0.0.1", --内网ip
        base_port = 22001,
        num = 3,
        unique = true, -- 通过name做唯一区分,name不能相同
    },
}
