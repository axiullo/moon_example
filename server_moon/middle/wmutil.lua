local all_conf = require("server_config")

local this = {}

---根据id获得网关的分配
function this.get_gate_by_id(id)
    local all_server = all_conf["gate"]

    if not all_server then
        return
    end

    local n = id % all_server.num
    local port = all_server.base_port + n

    return {host = all_server.host, port = port, n = n, base_name = all_server.base_name}
end

---根据id获得玩家的分配
function this.get_player_by_id(id)
    local all_server = all_conf["player"]

    if not all_server then
        return
    end

    local n = id % all_server.num
    local port = all_server.base_port + n

    return {host = all_server.host, port = port, n = n, base_name = all_server.base_name}
end

return this
