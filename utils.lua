local M = {}

-- 格式化速度显示
function M.formatSpeed(speedInBytes)
    local units = {"B/s", "KB/s", "MB/s", "GB/s"}
    local size = tonumber(speedInBytes)
    if size == 0 then return "0 B/s" end
    local unitIndex = 1
    
    while size > 1024 and unitIndex < #units do
        size = size / 1024
        unitIndex = unitIndex + 1
    end
    
    return string.format("%.1f %s", size, units[unitIndex])
end

-- 格式化文件大小
function M.formatSize(bytes)
    local units = {"B", "KB", "MB", "GB", "TB"}
    local size = tonumber(bytes)
    if size == 0 then return "0 B" end
    local unitIndex = 1
    
    while size > 1024 and unitIndex < #units do
        size = size / 1024
        unitIndex = unitIndex + 1
    end
    
    return string.format("%.1f %s", size, units[unitIndex])
end

-- 格式化进度
function M.formatProgress(completed, total)
    if total == 0 then return "0%" end
    return string.format("%.1f%%", (completed / total) * 100)
end

-- 格式化时间（秒转换为可读格式）
function M.formatTime(seconds)
    if not seconds or tonumber(seconds) == 0 then return "未知" end
    seconds = tonumber(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    
    if hours > 0 then
        return string.format("%d小时%d分", hours, minutes)
    elseif minutes > 0 then
        return string.format("%d分%d秒", minutes, secs)
    else
        return string.format("%d秒", secs)
    end
end

-- 格式化时间戳
function M.formatTimestamp(timestamp)
    if not timestamp or tonumber(timestamp) == 0 then return "未知" end
    
    local now = os.time()
    local diff = now - tonumber(timestamp)
    
    if diff < 60 then
        return "刚刚"
    elseif diff < 3600 then
        return string.format("%d分钟前", math.floor(diff / 60))
    elseif diff < 86400 then
        return string.format("%d小时前", math.floor(diff / 3600))
    else
        local date = os.date("*t", timestamp)
        return string.format("%d-%02d-%02d %02d:%02d", 
            date.year, date.month, date.day, date.hour, date.min)
    end
end

return M
