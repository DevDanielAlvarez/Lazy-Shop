local Menu = require("nui.menu")         -- left window (interactive list)
vim.api.nvim_create_user_command("LazyShop", function()
    local Popup = require("nui.popup")   -- right window (simple text)
    local Layout = require("nui.layout") -- organize windows in the screen

    --   configure right window(Popup)
    local right_window = Popup({
        border = {
            style = "rounded",                       -- rounded border
            text = { top = " Plugin Information " }, -- title of the top border
        },
    })

    local left_menu = Menu({
        border = {
            style = "rounded",
            text = { top = " Plugins " }, -- title of the top border
        },
        win_options = {
            winhighlight = "Normal:Normal", -- use normal theme colors
        },
    }, {
        lines = transform_the_repository_in_menu_itens(), -- function that transforms the repository items into menu items
        on_change = function(item)                        -- left item selected
            vim.api.nvim_set_option_value("modifiable", true, { buf = right_window.bufnr })
            vim.api.nvim_buf_set_lines(right_window.bufnr, 0, -1, false, {
                "",
                "  " .. item.data.description, -- pega o primeiro valor da tabela data
            })
        end,
        on_submit = function(item)
            Snacks.notify("the " .. item.data.name .. " plugin was added ✅, please restart your neovim >< 🐱", {
                level = vim.log.levels.INFO, -- snacks não tem "success", INFO é o mais próximo
                timeout = 7000,              -- duração em milissegundos (5 segundos)
                title = "LazyShop",
            })
        end
    })

    -- configure layout with explicit child sizes
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
    -- mount the layout and open it
    layout:mount()
end, {})

function transform_the_repository_in_menu_itens()
    local items_of_repository = require("lazy-shop.repository")
    local menu_items = {}
    for _, item in ipairs(items_of_repository) do
        table.insert(menu_items,
            Menu.item(item.name, { data = { description = item.description, url = item.url, name = item.name } }))
    end
    return menu_items
end
