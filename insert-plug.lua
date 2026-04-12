function insert_plugin(folder_path, plug)
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

local repo = require("repository")
insert_plugin("plugins", repo[3])
