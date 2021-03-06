
local math_floor = math.floor
local strfmt     = string.format
local strlen        = string.len
local dbgtrace   = debug.traceback
local strrep        = string.rep
local strsplit      = string.split
local strtrim       = string.trim
local tsort         = table.sort
local tbconcat = table.concat
local tbinsert = table.insert

local pairs = pairs
local ipairs = ipairs
local tostring = tostring
local type = type

local function _dump_value(v)
    if type(v) == "string" then
        v = "\"" .. v .. "\""
    end
    return tostring(v)
end

local function _dump_key(v)
    if type(v) == "number" then
        v = "[" .. v .. "]"
    end
    return tostring(v)
end

_G["print_r"] = function (value, desciption, nesting, _print)
    if type(nesting) ~= "number" then nesting = 10 end
    _print = _print or print

    local lookup = {}
    local result = {}
    local traceback = strsplit(dbgtrace("", 2), "\n")
    tbinsert(result,"\ndump from: " .. strtrim(traceback[2]).."\n")

    local function _dump(_value, _desciption, _indent, nest, keylen)
        _desciption = _desciption or "<var>"
        local spc = ""
        if type(keylen) == "number" then
            spc = strrep(" ", keylen - strlen(_dump_key(_desciption)))
        end
        if type(_value) ~= "table" then
            result[#result + 1] = strfmt("%s%s%s = %s,", _indent, _dump_key(_desciption),
            spc, _dump_value(_value))
        elseif lookup[tostring(_value)] then
            result[#result + 1] = strfmt("%s%s%s = '*REF*',", _indent, _dump_key(_desciption), spc)
        else
            lookup[tostring(_value)] = true
            if nest > nesting then
                result[#result + 1] = strfmt("%s%s = '*MAX NESTING*',", _indent, _dump_key(_desciption))
            else
                result[#result + 1] = strfmt("%s%s = {", _indent, _dump_key(_desciption))
                local indent2 = _indent .. "    "
                local keys = {}
                keylen = 0
                local values = {}
                for k, v in pairs(_value) do
                    keys[#keys + 1] = k
                    local vk = _dump_value(k)
                    local vkl = strlen(vk)
                    if vkl > keylen then keylen = vkl end
                    values[k] = v
                end
                tsort(keys, function(a, b)
                    if type(a) == "number" and type(b) == "number" then
                        return a < b
                    else
                        return tostring(a) < tostring(b)
                    end
                end)
                for _, k in ipairs(keys) do
                    _dump(values[k], k, indent2, nest + 1, keylen)
                end
                result[#result + 1] = strfmt("%s},", _indent)
            end
        end
    end
    _dump(value, desciption, " ", 1)
    _print(tbconcat(result,"\n"))
end
