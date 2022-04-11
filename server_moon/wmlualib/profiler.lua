---性能分析工具

local moon = require("moon")

local profiler = {}

-- 执行消耗开始
function profiler:execute_cost_start(info)
    info = info or "execute cost"
    self.start_ts = os.time()
    self.info = info
    print(string.format("%s cost start %d", info, self.start_ts))
end

-- 执行消耗结束
function profiler:execute_cost_end()
    -- body
    self.end_ts = os.time()
    print(string.format("%s cost end %d, cost = %d", self.info, self.end_ts, self.end_ts - self.start_ts))
end

return profiler
