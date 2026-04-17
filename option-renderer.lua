local M = {}

--- Renderiza uma opção booleana (toggle)
---@param opt table: objeto de opção com type="boolean"
---@return string|boolean: novo valor ou nil se cancelado
function M.render_boolean(opt)
  local current_value = opt.default or false
  
  return vim.ui.select(
    { "true", "false" },
    { prompt = opt.label .. " (" .. opt.description .. "): " },
    function(choice)
      if choice == "true" then
        current_value = true
      elseif choice == "false" then
        current_value = false
      end
    end
  )
end

--- Renderiza uma opção select (múltipla escolha)
---@param opt table: objeto de opção com type="select"
---@return string|nil: valor selecionado ou nil se cancelado
function M.render_select(opt)
  local selected_value = nil
  
  vim.ui.select(
    opt.choices or {},
    { prompt = opt.label .. " (" .. opt.description .. "): " },
    function(choice)
      selected_value = choice
    end
  )
  
  return selected_value
end

--- Renderiza uma opção numérica com validação
---@param opt table: objeto de opção com type="number"
---@return number|nil: valor inserido ou nil se cancelado
function M.render_number(opt)
  local min_val = opt.min
  local max_val = opt.max
  local prompt = opt.label .. " (" .. opt.description .. ")"
  
  if min_val or max_val then
    prompt = prompt .. " [range: " .. (min_val or "-∞") .. " to " .. (max_val or "∞") .. "]"
  end
  
  local result = nil
  vim.ui.input(
    { prompt = prompt .. ": ", default = tostring(opt.default or "") },
    function(input)
      if not input then
        return
      end
      
      local num = tonumber(input)
      if not num then
        vim.notify("Valor inválido: esperado um número", vim.log.levels.WARN)
        return
      end
      
      if min_val and num < min_val then
        vim.notify("Valor mínimo: " .. min_val, vim.log.levels.WARN)
        return
      end
      
      if max_val and num > max_val then
        vim.notify("Valor máximo: " .. max_val, vim.log.levels.WARN)
        return
      end
      
      result = num
    end
  )
  
  return result
end

--- Renderiza uma opção string (texto livre)
---@param opt table: objeto de opção com type="string"
---@return string|nil: texto inserido ou nil se cancelado
function M.render_string(opt)
  local result = nil
  
  vim.ui.input(
    { prompt = opt.label .. " (" .. opt.description .. "): ", default = opt.default or "" },
    function(input)
      result = input
    end
  )
  
  return result
end

--- Renderiza opção genérica baseado no tipo
---@param opt table: objeto de opção
---@return any: valor retornado pela função apropriada
function M.render_option(opt)
  if opt.type == "boolean" then
    return M.render_boolean(opt)
  elseif opt.type == "select" then
    return M.render_select(opt)
  elseif opt.type == "number" then
    return M.render_number(opt)
  elseif opt.type == "string" then
    return M.render_string(opt)
  else
    vim.notify("Tipo de opção desconhecido: " .. (opt.type or "undefined"), vim.log.levels.WARN)
    return nil
  end
end

return M
