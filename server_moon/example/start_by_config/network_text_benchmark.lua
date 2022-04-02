local moon = require("moon")
local socket = require("moon.socket")
local conf = ... or {}

local function run_slave()
    local command = {}

    command.START =  function(fd)
        moon.async(function()
            while true do
                local n = socket.read(fd,"\r\n")
                if not n then
                    --print(fd,"closed")
                    return
                end
                local v =1
                for _=1, 1000 do
                    v = v + 1
                end
                if n == "PING" then
                    socket.write(fd, "+PONG\r\n")
                end
            end
        end)
    end

    moon.dispatch('lua',function(sender, session, cmd, ...)
        local f = command[cmd]
        if f then
            moon.response('lua',sender,session,f(...))
        else
            error(string.format("Unknown command %s", tostring(cmd)))
        end
    end)
end


local function run_master(conf)
    local listenfd  = socket.listen(conf.host,conf.port,moon.PTYPE_TEXT)

    print(string.format([[

        network text benchmark run at %s %d with %d slaves.
        run benchmark use: redis-benchmark -t ping -p %d -c 1000 -n 100000
    ]], conf.host, conf.port, conf.count, conf.port))

    local slave = {}

    moon.async(function()
        for _=1,conf.count do
            local sid = moon.new_service("lua",{name="slave",file="start_by_config/network_text_benchmark.lua"})
            table.insert(slave,sid)
        end

        local balance = 1
        while true do
            if balance>#slave then
                balance = 1
            end
            local fd = socket.accept(listenfd,slave[balance])
            moon.co_call("lua",slave[balance],"START", fd)
            balance = balance + 1
        end
    end)

    moon.shutdown(function()
        socket.close(listenfd)
    end)
end

if conf.master then
    run_master(conf)
else
    run_slave()
end