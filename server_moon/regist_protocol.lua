local moon = require("moon")
local message = wm_get_commands("message")

local reg_protocol = moon.register_protocol
local this = {}

reg_protocol {
    name = "CLI2SRV",
    PTYPE = moon.PTYPE_CLI2SRV,
    pack = function(...)
        return ...
    end,
    dispatch = function(msg)
        local from_gate = moon.decode(msg, "S")
        local cli_fd = moon.decode(msg, "H")
        local src_msg = moon.decode(msg, "Z")

        print("=================== CLITOSER dispatch", cli_fd, src_msg)

        local servertypeid, nextpos = string.unpack(">H", src_msg)
        message.cli2srv_message(from_gate, cli_fd, servertypeid, string.sub(src_msg, nextpos))
    end
}

reg_protocol {
    name = "SRV2CLI",
    PTYPE = moon.PTYPE_SRV2CLI,
    pack = function(...)
        return ...
    end,
    dispatch = function(msg)
        print("=================== SRV2CLI dispatch")

        local from_gate = moon.decode(msg, "S")
        local cli_fd = moon.decode(msg, "H")
        local src_msg = moon.decode(msg, "Z")
        print(cli_fd)
        print(src_msg)

        message.srv2cli_message(cli_fd, src_msg)
    end
}

return this


