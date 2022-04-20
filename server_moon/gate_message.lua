local moon = require("moon")
local msend = require("middle.msend")
local message = wm_get_commands("message")

function message.srv2cli_message(cli_fd, src_msg)
    msend.dic_send(cli_fd, src_msg)
end

function message.srv2srv_message(header, src_msg)

end
