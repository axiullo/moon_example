---获取一个命令集合，如果没有，创建一个命令集合
---防重名的作用
local all_commands = {}
function wm_get_commands(name)
    local commands = all_commands[name]
    if commands then
        return commands
    end

    commands = {}
    all_commands[name] = commands

    local commands_ = {}
    commands.interface = commands_

    setmetatable(
        commands,
        {
            __index = commands_,
            __newindex = function(_, k, v)
                assert(not commands_[k], "interface defined: " .. k)
                rawset(commands_, k, v)
            end
        }
    )

    return commands
end

---尝试执行
function wm_justrun(f, ...)
    if not f then return end
    return f(...)
end


