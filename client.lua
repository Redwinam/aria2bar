local log = hs.logger.new('aria2client', 'info')

local M = {
    rpcUrl = "http://localhost:16800/jsonrpc"
}

-- RPC 请求函数
function M.request(method, params, callback)
    local json = require("hs.json")
    local requestBody = json.encode({
        jsonrpc = "2.0",
        id = "qwer",
        method = method,
        params = params or {""}
    })

    -- 仅在调试时打印请求信息
    -- log.d('发送请求到: ' .. M.rpcUrl)
    -- log.d('请求内容: ' .. requestBody)

    hs.http.asyncPost(M.rpcUrl, requestBody, {["Content-Type"] = "application/json"}, function(status, body, headers)
        -- 仅在调试时打印响应信息
        -- log.d('收到响应状态码: ' .. status)
        -- if body then
        --     log.d('响应内容: ' .. body)
        -- end
        
        if status == 200 and callback then
            local success, response = pcall(json.decode, body)
            if success then
                callback(response)
            else
                log.e('解析响应失败: ' .. body)
                callback(nil)
            end
        else
            callback(nil)
        end
    end)
end

-- 获取全局状态
function M.getGlobalStat(callback)
    M.request("aria2.getGlobalStat", {}, callback)
end

-- 定义需要获取的任务信息
local TASK_KEYS = {
    "gid",
    "status",
    "files",
    "totalLength",
    "completedLength",
    "downloadSpeed",
    "uploadSpeed",
    "connections",
    "numSeeders",
    "seeder",
    "uploadLength",
    "bitfield",
    "errorCode",
    "errorMessage",
    "followedBy",
    "following",
    "belongsTo",
    "dir",
    "completedTime",
    "addedTime"
}

-- 获取所有活动任务
function M.tellActive(callback)
    M.request("aria2.tellActive", {TASK_KEYS}, callback)
end

-- 获取等待中的任务
function M.tellWaiting(callback)
    M.request("aria2.tellWaiting", {0, 1000, TASK_KEYS}, callback)
end

-- 获取已停止的任务
function M.tellStopped(callback)
    -- 使用完整的参数列表
    local keys = {
        "gid", "status", "totalLength", "completedLength", "uploadLength",
        "bitfield", "downloadSpeed", "uploadSpeed", "infoHash",
        "numSeeders", "seeder", "pieceLength", "numPieces", "connections",
        "errorCode", "errorMessage", "followedBy", "following", "belongsTo",
        "dir", "files", "bittorrent", "verifiedLength", "verifyIntegrityPending",
        "completedTime"
    }
    M.request("aria2.tellStopped", {0, 1000, keys}, callback)
end

-- 暂停所有任务
function M.pauseAll(callback)
    M.request("aria2.pauseAll", {}, callback)
end

-- 恢复所有任务
function M.unpauseAll(callback)
    M.request("aria2.unpauseAll", {}, callback)
end

-- 暂停指定任务
function M.pause(gid, callback)
    M.request("aria2.pause", {gid}, callback)
end

-- 恢复指定任务
function M.unpause(gid, callback)
    M.request("aria2.unpause", {gid}, callback)
end

-- 删除任务
function M.remove(gid, callback)
    M.request("aria2.remove", {gid}, callback)
end

-- 删除下载记录
function M.removeDownloadResult(gid, callback)
    M.request("aria2.removeDownloadResult", {gid}, callback)
end

return M
