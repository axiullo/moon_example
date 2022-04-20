---内存数据

local this = {
    memorydata = {}
}

local memorydata = this.memorydata

function this.getobj(name, default_value)
    if not memorydata[name] then
        memorydata[name] = default_value or {}
    end

    return memorydata[name]
end

function this.deleteobj(name)
    memorydata[name] = nil
end

return this
