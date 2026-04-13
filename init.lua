local Menu = require("nui.menu")

local function open_add_plugin_menu()
    local Popup = require("nui.popup")
    local Layout = require("nui.layout")

    local right_window = Popup({
        border = {
            style = "rounded",
            text = { top = " Plugin Information " },
        },
    })

    local left_menu = Menu({
        border = {
            style = "rounded",
            text = { top = " Plugins " },
        },
        win_options = {
            winhighlight = "Normal:Normal",
        },
    }, {
        lines = transform_the_repository_in_menu_itens(),
        on_change = function(item)
            vim.api.nvim_set_option_value("modifiable", true, { buf = right_window.bufnr })
            vim.api.nvim_buf_set_lines(right_window.bufnr, 0, -1, false, {
                "",
                "  " .. item.data.description,
            })
        end,
        on_submit = function(item)
            local plugin_manager = require("lazy-shop.plugin-manager")
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
            Layout.Box(left_menu, { size = "40%" }),
            Layout.Box(right_window, { size = "60%" }),
        }, { dir = "row" })
    )

    layout:mount()
end

local function open_home_menu()
    local Popup = require("nui.popup")
    local Layout = require("nui.layout")

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

function transform_the_repository_in_menu_itens()
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
