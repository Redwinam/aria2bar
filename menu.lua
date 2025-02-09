local utils = require("aria2.utils")
local client = require("aria2.client")
local log = hs.logger.new('aria2menu', 'info')

local M = {
    menuIcon = nil,
    updateTimer = nil,
    currentTasks = {}  -- 存储所有任务的状态
}





-- 处理任务数据
local function processTask(task)
    local name = task.files and task.files[1] and (task.files[1].path:match("([^/]+)$") or task.files[1].path) or "未知文件"
    local progress = utils.formatProgress(tonumber(task.completedLength), tonumber(task.totalLength))
    local speed = utils.formatSpeed(task.downloadSpeed)
    local size = utils.formatSize(task.totalLength)
    local remainingTime = task.downloadSpeed ~= "0" and 
        utils.formatTime(math.floor((tonumber(task.totalLength) - tonumber(task.completedLength)) / tonumber(task.downloadSpeed))) or 
        "未知"
    
    -- 获取文件路径
    local filePath = ""
    local fullPath = ""
    if task.files and task.files[1] then
        if task.dir and task.files[1].path then
            -- 如果有 dir 属性，使用它
            filePath = task.dir
            fullPath = task.dir .. "/" .. task.files[1].path:match("([^/]+)$")
        else
            -- 否则从完整路径中提取目录
            fullPath = task.files[1].path
            filePath = fullPath:match("(.+)/[^/]*$") or ""
        end
    end
    
    -- 获取完成时间
    local completedTime = os.time()
    if task.status == "complete" and task.files and task.files[1] and task.files[1].path then
        local attr = hs.fs.attributes(task.files[1].path)
        if attr then
            completedTime = attr.creation
        end
    end
    
    return {
        gid = task.gid,
        name = name,
        progress = progress,
        speed = speed,
        size = size,
        status = task.status,
        remainingTime = remainingTime,
        completedTime = completedTime,
        addedTime = tonumber(task.addedTime) or 0,
        filePath = filePath,
        fullPath = fullPath
    }
end

-- 按完成时间排序任务
local function sortTasksByTime(tasks)
    table.sort(tasks, function(a, b)
        return a.completedTime > b.completedTime
    end)
    return tasks
end

-- 更新菜单显示
local function updateMenu(globalStat, tasks)
    if not M.menuIcon then return end
    
    -- 设置菜单栏显示
    local numActive = tonumber(globalStat.numActive) or 0
    local downloadSpeed = tonumber(globalStat.downloadSpeed) or 0
    
    if numActive == 0 or downloadSpeed == 0 then
        if M.menuIcon:title() ~= "·" then
            M.menuIcon:setTitle("·")
        end
    else
        M.menuIcon:setTitle(utils.formatSpeed(globalStat.downloadSpeed))
    end
    
    -- 构建菜单项
    local menuItems = {
        {title = "--- 下载状态 ---", disabled = true},
        {title = string.format("下载速度: %s", utils.formatSpeed(globalStat.downloadSpeed))},
        {title = string.format("上传速度: %s", utils.formatSpeed(globalStat.uploadSpeed))},
        {title = string.format("活动任务: %s", globalStat.numActive)},
        {title = string.format("等待任务: %s", globalStat.numWaiting)},
        {title = string.format("已完成任务: %s", globalStat.numStopped)},
        {title = "-"}
    }
    
    -- 添加活动任务
    if #tasks.active > 0 then
        table.insert(menuItems, {title = "--- 正在下载 ---", disabled = true})
        for _, task in ipairs(tasks.active) do
            table.insert(menuItems, {
                title = string.format("%s (%s/%s - %s - 剩余%s)", 
                    task.name:sub(1, 30) .. (task.name:len() > 30 and "..." or ""),
                    task.progress,
                    task.size,
                    task.speed,
                    task.remainingTime
                ),
                menu = {
                    {title = "暂停", fn = function() client.pause(task.gid, function() M.updateStatus() end) end},
                    {title = "删除", fn = function() client.remove(task.gid, function() M.updateStatus() end) end}
                }
            })
        end
        table.insert(menuItems, {title = "-"})
    end
    
    -- 添加等待任务
    if #tasks.waiting > 0 then
        table.insert(menuItems, {title = "--- 等待下载 ---", disabled = true})
        for _, task in ipairs(tasks.waiting) do
            table.insert(menuItems, {
                title = string.format("%s (%s)", 
                    task.name:sub(1, 40) .. (task.name:len() > 40 and "..." or ""),
                    task.size
                ),
                menu = {
                    {title = "开始", fn = function() client.unpause(task.gid, function() M.updateStatus() end) end},
                    {title = "删除", fn = function() client.remove(task.gid, function() M.updateStatus() end) end}
                }
            })
        end
        table.insert(menuItems, {title = "-"})
    end
    
    -- 添加已完成任务（最近5个）
    if #tasks.stopped > 0 then
        -- 按完成时间排序
        tasks.stopped = sortTasksByTime(tasks.stopped)
        
        table.insert(menuItems, {title = "--- 最近完成 ---", disabled = true})
        for i = 1, math.min(10, #tasks.stopped) do
            local task = tasks.stopped[i]
            local timeStr = utils.formatTimestamp(task.completedTime)
            local title = string.format("%s", task.name:sub(1, 50) .. (task.name:len() > 50 and "..." or ""))
            local subtitle = string.format("%s - %s", task.size, timeStr)
            
            local submenuItems = {
                {title = subtitle, disabled = true},
                {title = "-"}
            }
            
            -- 只有当文件路径存在时才添加打开文件夹选项
            if task.filePath and task.filePath ~= "" then
                table.insert(submenuItems, {title = "打开文件夹", fn = function()
                    log.d('尝试打开文件夹: ' .. task.filePath)
                    hs.execute(string.format("open \"%s\"", task.filePath))
                end})
            end
            
            table.insert(submenuItems, {title = "删除记录", fn = function()
                client.removeDownloadResult(task.gid, function() M.updateStatus() end)
            end})
            
            table.insert(menuItems, {
                title = title,
                menu = submenuItems
            })
        end
        table.insert(menuItems, {title = "-"})
    end
    
    -- 添加控制按钮
    table.insert(menuItems, {title = "暂停所有", fn = function() client.pauseAll(function() M.updateStatus() end) end})
    table.insert(menuItems, {title = "继续所有", fn = function() client.unpauseAll(function() M.updateStatus() end) end})
    table.insert(menuItems, {title = "-"})
    table.insert(menuItems, {title = "刷新", fn = M.updateStatus})
    table.insert(menuItems, {title = "退出", fn = M.stop})
    
    M.menuIcon:setMenu(menuItems)
end

-- 更新状态
function M.updateStatus()
    -- 获取全局状态
    client.getGlobalStat(function(globalStatResponse)
        if not globalStatResponse or not globalStatResponse.result then
            M.menuIcon:setTitle("Aria2 ⚠️")
            return
        end
        
        local tasks = {active = {}, waiting = {}, stopped = {}}
        
        -- 获取活动任务
        client.tellActive(function(activeResponse)
            if activeResponse and activeResponse.result then
                for _, task in ipairs(activeResponse.result) do
                    if task and task.status then
                        local processedTask = processTask(task)
                        if processedTask then
                            table.insert(tasks.active, processedTask)
                        end
                    end
                end
            end
            
            -- 获取等待任务
            client.tellWaiting(function(waitingResponse)
                if waitingResponse and waitingResponse.result then
                    for _, task in ipairs(waitingResponse.result) do
                        if task and task.status then
                            local processedTask = processTask(task)
                            if processedTask then
                                table.insert(tasks.waiting, processedTask)
                            end
                        end
                    end
                end
                
                -- 获取已停止任务
                client.tellStopped(function(stoppedResponse)
                    if stoppedResponse and stoppedResponse.result then
                        for _, task in ipairs(stoppedResponse.result) do
                                    -- 只处理任务，不输出响应数据
                            if task and task.status then
                                local processedTask = processTask(task)
                                if processedTask then
                                    table.insert(tasks.stopped, processedTask)
                                end
                            end
                        end
                    end
                    
                    -- 更新菜单显示
                    updateMenu(globalStatResponse.result, tasks)
                end)
            end)
        end)
    end)
end

-- 启动监控
function M.start()
    if M.menuIcon then return end
    
    M.menuIcon = hs.menubar.new()
    if M.menuIcon then
        M.menuIcon:setTitle("0 B/s")
        
        -- 启动定时更新
        M.updateTimer = hs.timer.doEvery(1, function()
            -- 菜单处于打开状态时也更新速度
            client.getGlobalStat(function(response)
                if response and response.result then
                    local numActive = tonumber(response.result.numActive) or 0
                    local downloadSpeed = tonumber(response.result.downloadSpeed) or 0
                    
                    local title = (numActive == 0 or downloadSpeed == 0) and "·" or utils.formatSpeed(downloadSpeed)
                    if M.menuIcon:title() ~= title then
                        M.menuIcon:setTitle(title)
                    end
                end
            end)
        end)
        
        -- 启动菜单内容更新定时器
        M.menuUpdateTimer = hs.timer.doEvery(3, M.updateStatus)
        
        -- 立即更新一次状态
        M.updateStatus()
        
        hs.alert.show("Aria2 监控已启动")
    end
end

-- 停止监控
function M.stop()
    if M.updateTimer then
        M.updateTimer:stop()
        M.updateTimer = nil
    end
    
    if M.menuUpdateTimer then
        M.menuUpdateTimer:stop()
        M.menuUpdateTimer = nil
    end
    
    if M.menuIcon then
        M.menuIcon:delete()
        M.menuIcon = nil
    end
end

return M
