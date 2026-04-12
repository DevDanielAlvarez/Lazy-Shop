function delete_plug(folder_path, plug)
    -- mount full name path to delete the correct file
    local file_path = folder_path .. "/" .. plug.name .. ".lua"

    local ok, err = os.remove(file_path)
    if not ok then
        print("Error: " .. err)
        return
    end
    print(file)
end

delete_plug("plugins", require("repository")[1])
