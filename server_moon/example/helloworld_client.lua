------------------------TCP CLIENT----------------------------
local moon = require("moon")
local socket = require("moon.socket")

local HOST = "127.0.0.1"
local PORT = 23850

local function send(fd, data)
    if not fd then
        return false
    end
    local len = #data
    return socket.write(fd, string.pack(">H", len)..data)
end

local function session_read(fd)
    if not fd then
        return false
    end
    local data, err = socket.read(fd, 2)
    if not data then
        print(fd, "fd read error", err)
        return false
    end

    local len = string.unpack(">H", data)

    data, err = socket.read(fd, len)
    if not data then
        print(fd, "fd read error", err)
        return false
    end
    return data
end

moon.async(function()
    local startts = moon.time()
    print("@@@@@@@ startts =  ", startts)

    local fd, err = socket.sync_connect(HOST, PORT, moon.PTYPE_TEXT)

    local endts = moon.time()
    print("@@@@@@@ ts =  ", endts, endts - startts)

    if not fd then
        print(err)
        return
    end

    print(fd, "Please input:")
    repeat
        local input = io.read()
        if input then
            send(fd, input)
            local rdata = session_read(fd)
            print("recv", rdata)
        end
    until(not input)
end)


