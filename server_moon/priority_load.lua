---启动时优先加载
local moon = require("moon")
local _wg = moon.exports

local _common = require("global_common")

table.easy_copy(_common, _wg)
