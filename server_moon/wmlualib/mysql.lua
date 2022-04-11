local moon = require("moon")
local mysql = require("moon.db.mysql")

local _M = {}

--todo 连接断了,重连机制

function _M:connect(opts)
    if _M.db then
        return
    end

    --todo 使用配置文件
    local db, err = mysql.connect({
        host = "127.0.0.1",
        port = 3306,
        database = "wm",
        user = "root",
        password = "123456",
        timeout = 1000, --连接超时ms
        max_packet_size = 1024 * 1024, --数据包最大字节数
    })

    if db.code then
        print(db.err)
        return
    end

    _M.db = db

    return true
end

function _M:disconnect()
    local db = _M.db

    if not db then
        return
    end

    db.disconnect()
end

function _M:execute_query(sql)
    if not _M.db then return false end

    -- print("execute_query sql = ", sql)
    local res = _M.db:query(sql)

    if res.code then
        error(string.format("code = %s, err = %s", res.code, res.err))
    end

    return res
end

---查询一条记录
---@param conditions 条件数组,  {{字段名称=条件值}}  --todo 加个op操作字段 = > <...
---@param keys 显示的字段数组
---@return 数据, 没有找到返回nil
function _M:find_one(tbl_name, conditions, keys)
    if not _M.db then return false end

    keys = keys or "*"

    local sql_format = "select %s from %s"
    local str_keys

    if keys ~= "*" then
        str_keys = table.concat(keys, ",")
    else
        str_keys = keys
    end

    local str_where = ""

    if conditions then
        for _, v in ipairs(conditions) do
            for k, vv in pairs(v) do
                if type(vv) == "string" then
                    str_where = str_where .. k .. "='" .. vv .. "',"
                else
                    str_where = str_where .. k .. "=" .. vv .. ","
                end
            end
        end

        str_where = string.sub(str_where, 1, #str_where - 1)
    end

    if #str_where > 0 then
        sql_format = "select %s from %s where %s"
    end

    local str_sql = string.format(sql_format, keys, tbl_name, str_where)
    local res = self:execute_query(str_sql)
    return res and res[1]
end

---插入一条记录
function _M:insert_one(tbl_name, data)
    if not _M.db then return false end

    local sql_format = "INSERT INTO %s (%s) VALUES(%s)"
    local keys = {}
    local values = {}

    for k, v in pairs(data) do
        table.insert(keys, k)

        if type(v) == "string" then
            table.insert(values, '\''..v..'\'')
        else
            table.insert(values, v)
        end
    end

    local str_keys = table.concat(keys, ",")
    local str_values = table.concat(values, ",")

    local res = self:execute_query(string.format(sql_format, tbl_name, str_keys, str_values))
    return res
end

return _M
