local M = {}
local cache = nil

local RAW_URL = "https://raw.githubusercontent.com/DevDanielAlvarez/lazy-shop-repository/main/repository.json"

function M.fetch(callback)
    if cache then
        callback(cache)
        return
    end

    vim.system({ "curl", "-s", RAW_URL }, { text = true }, function(result)
        if result.code ~= 0 or not result.stdout or result.stdout == "" then
            vim.schedule(function()
                vim.notify("LazyShop: failed to fetch repository", vim.log.levels.ERROR)
            end)
            return
        end

        local ok, data = pcall(vim.json.decode, result.stdout)
        if not ok or type(data) ~= "table" then
            vim.schedule(function()
                vim.notify("LazyShop: invalid repository JSON", vim.log.levels.ERROR)
            end)
            return
        end

        cache = data
        vim.schedule(function()
            callback(data)
        end)
    end)
end

return M