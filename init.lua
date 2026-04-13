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
                vim.notify("Erro ao carregar plugin-manager: " .. tostring(plugin_manager), vim.log.levels.ERROR)
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
            Menu.item("Add Plugin", { data = { description = "Browse plugins and add one to your config." } }),
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
