local moon = require("moon")
local commands = wm_get_commands("commands")
local msend = require("middle.msend")
local this = {}

---ping
function commands.ping(fd)
    msend.send(fd, "pong", {t = moon.time()})
end

return this
