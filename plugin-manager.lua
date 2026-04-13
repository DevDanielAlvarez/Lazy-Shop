local Methods = {}

function Methods.insert_plugin(folder_path, plug)
    folder_path = vim.fn.expand(folder_path)

    if not plug or not plug.name or not plug.url then
        print("invalid plugin data")
        return
    end

    -- mount full name file path
    local file_path = folder_path .. "/" .. plug.name .. ".lua"

    -- create and open the file
    local file = io.open(file_path, "w")

    if not file then
        print("the folder " .. folder_path .. " not exists")
        return
    end

    -- write in the file
    file:write('return {\n')
    file:write('"' .. plug.url .. '",\n')
    file:write('}\n')

    -- close the file
    file:close()

    print(file_path)
end

function Methods.delete_plug(folder_path, plug)
    -- mount full name path to delete the correct file
    local file_path = folder_path .. "/" .. plug.name .. ".lua"

    local ok, err = os.remove(file_path)
    if not ok then
        print("Error: " .. err)
        return
    end
    print("File deleted: " .. file_path)
end

return Methods
