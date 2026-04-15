local M = {}
function M.add_plugin(folder_path, plugin)
    local folder_path = vim.fn.expand(folder_path)
    local file = io.open(folder_path .."/".. plugin.name .. ".lua","w")
    if not file then
        vim.notify("Erro ao criar arquivo para o plugin: " .. plugin.url, vim.log.levels.ERROR)
        return
    end

    -- write in the file
    file:write('return {\n')
    file:write('"' .. plugin.url .. '",\n')
    file:write('}\n')
    file:close()
    
end
function M.remove_plugin(dir_path, plugin_name)
    local plugin_path = dir_path .. "/" .. plugin_name
    vim.fn.delete(plugin_path, "rf")
end

return M