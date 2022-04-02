-- >: 设为大端编码
-- H: 一个无符号 short （本地大小）

local en_str = string.pack(">H", 1)
print(type(en_str))
local en_str2 = string.pack(">I4", 2)


local msg = en_str .. en_str2
print("---->>>>>>>> ", msg)

local de_str1 = string.sub(msg, 1, 2)
print(de_str1)
local de_str2 = string.sub(msg, 3, 6)
print(de_str2)

de_str1 = string.unpack(">H", de_str1)
print("----<<<<<<< ", de_str1)

de_str2 = string.unpack(">I4", de_str2)
print("----<<<<<<< ", de_str2)


-- 不同格式一起组装打包
local enstr = string.pack(">H>Is1s1", 267, 6666666, "aaaa", "bbbbbbb")
-- enstr = enstr .. string.pack("s1", "bbbbbbb")
print(enstr)

local id, nextpos = string.unpack(">H", enstr);
local num, nextpos = string.unpack(">I", enstr, nextpos);
local destr, nextpos = string.unpack("s1", enstr, nextpos);
local destr2 = string.unpack("s1", enstr, nextpos)
print(id, num)
print(destr)
print(destr2)
-- 不同格式一起组装打包 end
