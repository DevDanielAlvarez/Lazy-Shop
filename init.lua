local Menu = require("nui.menu")
local Input = require("nui.input")
local Layout = require("nui.layout")
local Popup = require("nui.popup")
local event = require("nui.utils.autocmd").event
local repository = require("lazy-shop.repository")
local option_renderer = require("lazy-shop.option-renderer")

local function remove_plugin(dir_path, plugin_name)
  local plugin_path = dir_path .. "/" .. plugin_name
  vim.fn.delete(plugin_path, "rf")
end

local function detect_config_style(filepath)
  local lines = vim.fn.readfile(filepath)
  local content = table.concat(lines, "\n")
  if content:find("config%s*=") then
    return "config"
  elseif content:find("opts%s*=") then
    return "opts"
  end
  return nil
end

local function inject_opts(filepath)
  local lines = vim.fn.readfile(filepath)
  local new_lines = {}
  local injected = false
  for _, line in ipairs(lines) do
    table.insert(new_lines, line)
    if not injected and line:match("^%s*return%s*{") then
      table.insert(new_lines, "    opts = {")
      table.insert(new_lines, "        -- configure your options here")
      table.insert(new_lines, "    },")
      injected = true
    end
  end
  vim.fn.writefile(new_lines, filepath)
end

local function inject_config(filepath)
  local lines = vim.fn.readfile(filepath)
  local new_lines = {}
  local injected = false
  for _, line in ipairs(lines) do
    table.insert(new_lines, line)
    if not injected and line:match("^%s*return%s*{") then
      table.insert(new_lines, "    config = function()")
      table.insert(new_lines, "        -- configure your plugin here")
      table.insert(new_lines, "    end,")
      injected = true
    end
  end
  vim.fn.writefile(new_lines, filepath)
end

--- Encontra as opções de um plugin no repositório
---@param plugin_name string: nome do plugin
---@param repo_data table: dados do repositório
---@return table: opções do plugin ou {}
local function find_plugin_options(plugin_name, repo_data)
  if not repo_data then
    return {}
  end
  
  for _, plugin in ipairs(repo_data) do
    if plugin.name == plugin_name then
      return plugin.options or {}
    end
  end
  
  return {}
end

--- Formata um valor Lua para ser inserido no arquivo
---@param value any: valores a formatar
---@param indent number: nível de indentação
---@return string: valor formatado
local function format_lua_value(value, indent)
  indent = indent or 4
  local indent_str = string.rep(" ", indent)
  
  if type(value) == "boolean" then
    return value and "true" or "false"
  elseif type(value) == "number" then
    return tostring(value)
  elseif type(value) == "string" then
    return '"' .. value:gsub('"', '\\"') .. '"'
  elseif type(value) == "table" then
    local result = "{\n"
    for k, v in pairs(value) do
      result = result .. indent_str .. k .. " = " .. format_lua_value(v, indent + 4) .. ",\n"
    end
    result = result .. string.rep(" ", indent - 4) .. "}"
    return result
  else
    return "nil"
  end
end

--- Injeta opções configuradas no lado de opts = {...}
---@param filepath string: caminho do arquivo do plugin
---@param options table: opções configuradas {key=value, ...}
local function inject_configured_options(filepath, options)
  local lines = vim.fn.readfile(filepath)
  local new_lines = {}
  local found_opts = false
  
  for i, line in ipairs(lines) do
    if line:match("^%s*opts%s*=%s*{") then
      -- Encontrou a seção opts, agora insere as opções configuradas
      found_opts = true
      table.insert(new_lines, line)
      
      -- Pega o nível de indentação
      local indent = line:match("^(%s*)")
      local opt_indent = indent .. "    "
      
      -- Insere cada opção configurada
      for key, value in pairs(options) do
        local lua_value = format_lua_value(value, #opt_indent + 4)
        table.insert(new_lines, opt_indent .. key .. " = " .. lua_value .. ",")
      end
    else
      table.insert(new_lines, line)
    end
  end
  
  if found_opts then
    vim.fn.writefile(new_lines, filepath)
  end
end

--- Interface interativa para configurar um plugin
---@param plugin_name string: nome do plugin
---@param filepath string: caminho do arquivo
---@param options table: array de opções disponíveis
local function open_interactive_config(plugin_name, filepath, options)
  if #options == 0 then
    vim.notify('Plugin "' .. plugin_name .. '" não possui opções configuráveis.', vim.log.levels.INFO)
    vim.cmd("edit " .. filepath)
    return
  end
  
  local configured = {}
  local current_option_idx = 1
  
  local function show_option_config()
    if current_option_idx > #options then
      -- Todas as opções foram configuradas, salva arquivo
      -- Verifica se há seção opts no arquivo
      local content = table.concat(vim.fn.readfile(filepath), "\n")
      if content:find("opts%s*=") then
        inject_configured_options(filepath, configured)
      else
        -- Se não houver opts, injeta primeiro
        inject_opts(filepath)
        vim.schedule(function()
          inject_configured_options(filepath, configured)
        end)
      end
      
      -- Notificação de sucesso com timeout de 15s (15000ms)
      vim.notify(
        "✓ Opções configuradas com sucesso!\n\nRecomendação: reinicie o Neovim para aplicar as mudanças.",
        vim.log.levels.INFO,
        { timeout = 15000 }
      )
      return
    end
    
    local opt = options[current_option_idx]
    local prompt = opt.label .. " (" .. opt.type .. ")"
    
    if opt.description then
      prompt = prompt .. "\n  " .. opt.description
    end
    
    if opt.type == "boolean" then
      vim.ui.select(
        { "true", "false" },
        { prompt = prompt .. "\nEscolha: " },
        function(choice)
          if choice then
            configured[opt.key] = (choice == "true")
          end
          current_option_idx = current_option_idx + 1
          show_option_config()
        end
      )
    elseif opt.type == "select" then
      vim.ui.select(
        opt.choices or {},
        { prompt = prompt .. "\nEscolha: " },
        function(choice)
          if choice then
            configured[opt.key] = choice
          end
          current_option_idx = current_option_idx + 1
          show_option_config()
        end
      )
    elseif opt.type == "number" then
      local range_hint = ""
      if opt.min or opt.max then
        range_hint = " [" .. (opt.min or "-∞") .. ".." .. (opt.max or "∞") .. "]"
      end
      vim.ui.input(
        { prompt = prompt .. range_hint .. "\nDigite: ", default = tostring(opt.default or "") },
        function(input)
          if input then
            local num = tonumber(input)
            if num then
              if (not opt.min or num >= opt.min) and (not opt.max or num <= opt.max) then
                configured[opt.key] = num
              else
                vim.notify("Valor fora do intervalo permitido!", vim.log.levels.WARN)
              end
            else
              vim.notify("Valor inválido (esperado número)!", vim.log.levels.WARN)
            end
          end
          current_option_idx = current_option_idx + 1
          show_option_config()
        end
      )
    elseif opt.type == "string" then
      vim.ui.input(
        { prompt = prompt .. "\nDigite: ", default = opt.default or "" },
        function(input)
          if input then
            configured[opt.key] = input
          end
          current_option_idx = current_option_idx + 1
          show_option_config()
        end
      )
    else
      current_option_idx = current_option_idx + 1
      show_option_config()
    end
  end
  
  show_option_config()
end


local function build_menu_items(data)
  local items = {}
  for _, item in ipairs(data) do
    table.insert(
      items,
      Menu.item(item.name .. " ( " .. item.category .. " )", {
        data = {
          description = item.description,
          url = item.url,
          name = item.name,
          category = item.category,
        },
      })
    )
  end
  return items
end

local function open_add_plugin_menu()
  vim.notify("LazyShop: fetching repository...", vim.log.levels.INFO)

  repository.fetch(function(data)
    local all_items = build_menu_items(data)

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
          "",
          "  url: " .. (item.data.url or ""),
          "  category: " .. (item.data.category or ""),
        })
      end,
      on_submit = function(item)
        local ok, plugin_manager = pcall(require, "lazy-shop.plugin-manager")
        if not ok or type(plugin_manager) ~= "table" then
          vim.notify("Erro ao carregar plugin-manager: " .. tostring(plugin_manager), vim.log.levels.ERROR)
          return
        end
        plugin_manager.add_plugin("~/.config/nvim/lua/plugins", item.data)
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
  end)
end

local function open_remove_plugin_menu()
  local plugins_dir = vim.fn.stdpath("config") .. "/lua/plugins"

  local function get_installed_plugins()
    local items = {}
    local files = vim.fn.glob(plugins_dir .. "/*.lua", false, true)
    for _, filepath in ipairs(files) do
      local filename = vim.fn.fnamemodify(filepath, ":t")
      local plugin_name = vim.fn.fnamemodify(filepath, ":t:r")
      table.insert(
        items,
        Menu.item(plugin_name, {
          data = {
            name = plugin_name,
            filename = filename,
            filepath = filepath,
          },
        })
      )
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
        if choice ~= "Yes" then
          return
        end
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

local function open_config_plugin_menu()
  local plugins_dir = vim.fn.stdpath("config") .. "/lua/plugins"

  local function get_installed_plugins()
    local items = {}
    local files = vim.fn.glob(plugins_dir .. "/*.lua", false, true)
    for _, filepath in ipairs(files) do
      local filename = vim.fn.fnamemodify(filepath, ":t")
      local plugin_name = vim.fn.fnamemodify(filepath, ":t:r")
      table.insert(
        items,
        Menu.item(plugin_name, {
          data = {
            name = plugin_name,
            filename = filename,
            filepath = filepath,
          },
        })
      )
    end
    return items
  end

  local all_items = get_installed_plugins()

  if #all_items == 0 then
    vim.notify("No plugins found in " .. plugins_dir, vim.log.levels.WARN)
    return
  end

  -- Busca as opções do repositório
  repository.fetch(function(repo_data)
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
        text = { top = " Installed Plugins " },
      },
      win_options = {
        winhighlight = "Normal:Normal",
      },
    }, {
      lines = all_items,
      on_change = function(item)
        vim.api.nvim_set_option_value("modifiable", true, { buf = right_window.bufnr })
        
        local plugin_options = find_plugin_options(item.data.name, repo_data)
        local preview = {
          "",
          "  Plugin: " .. item.data.name,
          "  File: " .. item.data.filename,
        }
        
        if #plugin_options > 0 then
          table.insert(preview, "")
          table.insert(preview, "  [Opções Disponíveis]")
          for _, opt in ipairs(plugin_options) do
            table.insert(preview, "    • " .. opt.label .. " (" .. opt.type .. ")")
          end
          table.insert(preview, "")
          table.insert(preview, "  <Enter> para configurar as opções")
        else
          table.insert(preview, "")
          table.insert(preview, "  Este plugin não possui opções configuráveis.")
          table.insert(preview, "  <Enter> para editar arquivo manualmente")
        end
        
        vim.api.nvim_buf_set_lines(right_window.bufnr, 0, -1, false, preview)
      end,
      on_submit = function(item)
        local ok, err = pcall(function()
          local filepath = item.data.filepath
          
          if not repo_data then
            vim.notify("ERRO: repo_data é nil!", vim.log.levels.ERROR)
            return
          end
          
          local plugin_options = find_plugin_options(item.data.name, repo_data)
          
          -- Abre a interface no scheduler para evitar conflito com o layout do Nui
          vim.schedule(function()
            if #plugin_options > 0 then
              -- Abre a interface interativa de configuração
              open_interactive_config(item.data.name, filepath, plugin_options)
            else
              -- Se não houver opções, abre o editor normal
              local style = detect_config_style(filepath)

              if style then
                vim.cmd("edit " .. filepath)
                vim.notify('Opening "' .. item.data.name .. '" — style detected: ' .. style, vim.log.levels.INFO)
              else
                vim.ui.select({
                  "opts = {}  (declarativo, recomendado pelo lazy.nvim)",
                  "config = function() end  (imperativo, mais flexível)",
                }, { prompt = 'Choose config style for "' .. item.data.name .. '":' }, function(choice)
                  if not choice then
                    return
                  end
                  if choice:find("opts") then
                    inject_opts(filepath)
                  else
                    inject_config(filepath)
                  end
                  vim.cmd("edit " .. filepath)
                  vim.notify('Config injected into "' .. item.data.name .. '". File opened.', vim.log.levels.INFO)
                end)
              end
            end
          end)
        end)
        
        if not ok then
          vim.notify("Erro ao configurar plugin: " .. tostring(err), vim.log.levels.ERROR)
        end
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

    -- Adiciona keybind para sair com ESC
    vim.api.nvim_buf_set_keymap(search_input.bufnr, "i", "<Esc>", "", {
      noremap = true,
      callback = function()
        layout:unmount()
      end,
    })

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

    -- Adiciona keybind no menu para fechar com ESC
    vim.api.nvim_buf_set_keymap(plugin_menu.bufnr, "n", "<Esc>", "", {
      noremap = true,
      callback = function()
        layout:unmount()
      end,
    })

    vim.api.nvim_set_current_win(search_input.winid)
    vim.cmd("startinsert")
  end)
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
      if item.text == "Remove Plugin" then
        open_remove_plugin_menu()
        return
      end
      if item.text == "Config Plugin" then
        open_config_plugin_menu()
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
