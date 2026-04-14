local Menu = require("nui.menu")
local Input = require("nui.input")
local Layout = require("nui.layout")
local Popup = require("nui.popup")
local event = require("nui.utils.autocmd").event

local function transform_the_repository_in_menu_itens()
    local items_of_repository = require("lazy-shop.repository")
    local menu_items = {}
    for _, item in ipairs(items_of_repository) do
        table.insert(menu_items, Menu.item(item.name, {
            data = {
                description = item.description,
                url = item.url,
                name = item.name,
            },
        }))
    end
    return menu_items
end

local function remove_plugin(dir_path, plugin_name)
    local plugin_path = dir_path .. "/" .. plugin_name
    vim.fn.delete(plugin_path, "rf")
end

local function open_add_plugin_menu()
    local all_items = transform_the_repository_in_menu_itens()

    local right_window = Popup({
        border = {
            style = "rounded",
            text = { top = " Plugin Information " },
        },
    })

    local search_input = Input({
        border = {
            style = "rounded",
            text = { top = " Search " },
        },
        win_options = {
            winhighlight = "Normal:Normal",
        },
    }, {
        prompt = "> ",
        default_value = "",
        on_change = function(_) end,
    })

    local plugin_menu = Menu({
        border = {
            style = "rounded",
            text = { top = " Plugins " },
        },
        win_options = {
            winhighlight = "Normal:Normal",
        },
    }, {
        lines = all_items,
        on_change = function(item)
            vim.api.nvim_set_option_value("modifiable", true, { buf = right_window.bufnr })
            vim.api.nvim_buf_set_lines(right_window.bufnr, 0, -1, false, {
                "",
                "  " .. (item.data.description or ""),
            })
        end,
        on_submit = function(item)
            local ok, plugin_manager = pcall(require, "lazy-shop.plugin-manager")
            if not ok or type(plugin_manager) ~= "table" then
                vim.notify("Erro ao carregar plugin-manager: " .. tostring("in plug " .. plugin_manager),
                    vim.log.levels.ERROR)
                return
            end
            plugin_manager.insert_plugin(vim.fn.stdpath("config") .. "/lua/plugins", item.data)
        end,
    })

    local layout = Layout(
        {
            relative = "editor",
            position = "50%",
            size = {
                width = "80%",
                height = "60%",
            },
        },
        Layout.Box({
            Layout.Box({
                Layout.Box(search_input, { size = 3 }),
                Layout.Box(plugin_menu, { grow = 1 }),
            }, { dir = "col", size = "40%" }),
            Layout.Box(right_window, { size = "60%" }),
        }, { dir = "row" })
    )

    layout:mount()

    search_input:on(event.TextChangedI, function()
        local line = vim.api.nvim_get_current_line()
        local query = line:gsub("^>%s*", ""):lower()

        local new_items = {}
        for _, item in ipairs(all_items) do
            if item.text:lower():find(query, 1, true) then
                table.insert(new_items, item)
            end
        end

        vim.api.nvim_set_option_value("modifiable", true, { buf = plugin_menu.bufnr })
        vim.api.nvim_buf_set_lines(plugin_menu.bufnr, 0, -1, false, {})

        for i, menu_item in ipairs(new_items) do
            vim.api.nvim_buf_set_lines(plugin_menu.bufnr, i - 1, i, false, { "  " .. menu_item.text })
        end
    end)

    search_input:map("i", "<Tab>", function()
        vim.api.nvim_set_current_win(plugin_menu.winid)
        vim.cmd("stopinsert")
    end, { noremap = true })

    vim.api.nvim_set_current_win(search_input.winid)
    vim.cmd("startinsert")
end

local function open_remove_plugin_menu()
    local plugins_dir = vim.fn.stdpath("config") .. "/lua/plugins"

    local function get_installed_plugins()
        local items = {}
        local files = vim.fn.glob(plugins_dir .. "/*.lua", false, true)
        for _, filepath in ipairs(files) do
            local filename = vim.fn.fnamemodify(filepath, ":t")
            local plugin_name = vim.fn.fnamemodify(filepath, ":t:r")
            table.insert(items, Menu.item(plugin_name, {
                data = {
                    name = plugin_name,
                    filename = filename,
                    filepath = filepath,
                },
            }))
        end
        return items
    end

    local all_items = get_installed_plugins()

    if #all_items == 0 then
        vim.notify("No plugins found in " .. plugins_dir, vim.log.levels.WARN)
        return
    end

    local right_window = Popup({
        border = {
            style = "rounded",
            text = { top = " Plugin File Preview " },
        },
    })

    local search_input = Input({
        border = {
            style = "rounded",
            text = { top = " Search " },
        },
        win_options = {
            winhighlight = "Normal:Normal",
        },
    }, {
        prompt = "> ",
        default_value = "",
        on_change = function(_) end,
    })

    local plugin_menu = Menu({
        border = {
            style = "rounded",
            text = { top = " Installed Plugins " },
        },
        win_options = {
            winhighlight = "Normal:Normal",
        },
    }, {
        lines = all_items,
        on_change = function(item)
            vim.api.nvim_set_option_value("modifiable", true, { buf = right_window.bufnr })
            local lines = vim.fn.readfile(item.data.filepath)
            local preview = { "", "  File: " .. item.data.filename, "" }
            for _, line in ipairs(lines) do
                table.insert(preview, "  " .. line)
            end
            vim.api.nvim_buf_set_lines(right_window.bufnr, 0, -1, false, preview)
        end,
        on_submit = function(item)
            vim.ui.select({ "Yes", "No" }, {
                prompt = 'Remove "' .. item.data.name .. '"?',
            }, function(choice)
                if choice ~= "Yes" then return end

                local ok, err = pcall(remove_plugin, plugins_dir, item.data.filename)
                if ok then
                    vim.notify('Plugin "' .. item.data.name .. '" removed successfully.', vim.log.levels.INFO)
                else
                    vim.notify("Failed to remove plugin: " .. tostring(err), vim.log.levels.ERROR)
                end
            end)
        end,
    })

    local layout = Layout(
        {
            relative = "editor",
            position = "50%",
            size = {
                width = "80%",
                height = "60%",
            },
        },
        Layout.Box({
            Layout.Box({
                Layout.Box(search_input, { size = 3 }),
                Layout.Box(plugin_menu, { grow = 1 }),
            }, { dir = "col", size = "40%" }),
            Layout.Box(right_window, { size = "60%" }),
        }, { dir = "row" })
    )

    layout:mount()

    search_input:on(event.TextChangedI, function()
        local query = vim.api.nvim_get_current_line():gsub("^>%s*", ""):lower()
        local new_items = {}
        for _, item in ipairs(all_items) do
            if item.text:lower():find(query, 1, true) then
                table.insert(new_items, item)
            end
        end

        vim.api.nvim_set_option_value("modifiable", true, { buf = plugin_menu.bufnr })
        vim.api.nvim_buf_set_lines(plugin_menu.bufnr, 0, -1, false, {})
        for i, menu_item in ipairs(new_items) do
            vim.api.nvim_buf_set_lines(plugin_menu.bufnr, i - 1, i, false, { "  " .. menu_item.text })
        end
    end)

    search_input:map("i", "<Tab>", function()
        vim.api.nvim_set_current_win(plugin_menu.winid)
        vim.cmd("stopinsert")
    end, { noremap = true })

    vim.api.nvim_set_current_win(search_input.winid)
    vim.cmd("startinsert")
end

local function open_home_menu()
    local right_window = Popup({
        border = {
            style = "rounded",
            text = { top = " About LazyShop " },
        },
    })

    local home_menu = Menu({
        border = {
            style = "rounded",
            text = { top = " LazyShop " },
        },
        win_options = {
            winhighlight = "Normal:Normal",
        },
    }, {
        lines = {
            Menu.item("Add Plugin",    { data = { description = "Browse plugins and add one to your config." } }),
            Menu.item("Remove Plugin", { data = { description = "Remove a plugin from your config." } }),
            Menu.item("Config Plugin", { data = { description = "Open plugin configuration options." } }),
        },
        on_change = function(item)
            vim.api.nvim_set_option_value("modifiable", true, { buf = right_window.bufnr })
            vim.api.nvim_buf_set_lines(right_window.bufnr, 0, -1, false, {
                "",
                "  " .. item.data.description,
            })
        end,
        on_submit = function(item)
            if item.text == "Add Plugin" then
                open_add_plugin_menu()
                return
            end
            if item.text == "Remove Plugin" then
                open_remove_plugin_menu()
                return
            end
            vim.notify(item.text .. " is not implemented yet", vim.log.levels.INFO)
        end,
    })

    local layout = Layout(
        {
            relative = "editor",
            position = "50%",
            size = {
                width = "60%",
                height = "40%",
            },
        },
        Layout.Box({
            Layout.Box(home_menu, { size = "45%" }),
            Layout.Box(right_window, { size = "55%" }),
        }, { dir = "row" })
    )

    layout:mount()
end

vim.api.nvim_create_user_command("LazyShop", function()
    open_home_menu()
end, {})