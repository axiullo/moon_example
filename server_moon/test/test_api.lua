local moon = require("moon")
local seri = require("seri")
local crypt = require("crypt")

local p = seri.pack("1", 2, 3, {a = 1, b = 2}, nil)
print(p)
local strp = crypt.xor_str(p)
print(strp)

local cmd, sz, len = seri.unpack_one(p, true)
print(cmd)
print(seri.unpack(sz, len))


local p1 = seri.pack("1", 2, 3, {a = 1, b = 2}, nil)
local cmd1, sz1, len1 = seri.unpack_one(p1, false)
print(cmd1)
print(seri.unpack(sz1, len1))
