local Menu = require("nui.menu")
local Input = require("nui.input")
local Layout = require("nui.layout")
local Popup = require("nui.popup")
local event = require("nui.utils.autocmd").event

local function open_add_plugin_menu()
    local all_items = transform_the_repository_in_menu_itens()
    local filtered_items = vim.deepcopy(all_items)

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
        on_change = function(value)
            -- será usado para re-renderizar o menu abaixo
        end,
    })

    local function make_menu(items)
        return Menu({
            border = {
                style = "rounded",
                text = { top = " Plugins " },
            },
            win_options = {
                winhighlight = "Normal:Normal",
            },
        }, {
            lines = items,
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
    end

    local plugin_menu = make_menu(filtered_items)

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

    -- Filtrar conforme o usuário digita
    search_input:on(event.TextChangedI, function()
        local query = vim.api.nvim_get_current_line():gsub("^>%s*", ""):lower()

        local new_items = {}
        for _, item in ipairs(all_items) do
            if item.text:lower():find(query, 1, true) then
                table.insert(new_items, item)
            end
        end

        -- Limpa e reescreve o buffer do menu com os itens filtrados
        vim.api.nvim_set_option_value("modifiable", true, { buf = plugin_menu.bufnr })
        vim.api.nvim_buf_set_lines(plugin_menu.bufnr, 0, -1, false, {})

        for i, menu_item in ipairs(new_items) do
            vim.api.nvim_buf_set_lines(plugin_menu.bufnr, i - 1, i, false, { "  " .. menu_item.text })
        end
    end)

    -- Tab para mover foco do input para o menu
    search_input:map("i", "<Tab>", function()
        vim.api.nvim_set_current_win(plugin_menu.winid)
        vim.cmd("stopinsert")
    end, { noremap = true })

    -- Entra em insert mode direto no search
    vim.api.nvim_set_current_win(search_input.winid)
    vim.cmd("startinsert")
end
