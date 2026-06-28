local Inventory = require("inventory")
local Stack = require("stack")

local ct = {}


---Filtra as funções de um objeto recursivamente, deixando apenas os dados que podem ser serializados
---@param obj table
---@return table
function ct.extract_serializable_data(obj)
  local obj_data = { __classname = obj.__classname }

  for key, value in pairs(obj) do
    if type(value) == "table" then
      obj_data[key] = ct.extract_serializable_data(value)
    elseif type(value) ~= "function" then
      obj_data[key] = value
    end
  end

  return obj_data
end


function ct.serialize(obj, options)
  local data = ct.extract_serializable_data(obj)
  return textutils.serialize(data, options)
end


---Instancia um objeto recursivamente
---@param data table
---@return any
function ct.instantiate(data)
  -- Instancia folhas
  if type(data) ~= "table" then
    return data
  elseif data.__classname == "Inventory" then
    return Inventory:instantiate_from_data(data)
  elseif data.__classname == "Stack" then
    return Stack:instantiate_from_data(data)
  end

  -- Percorre o resto da árvore
  local instantiated_data = {}
  for k, v in pairs(data) do
    instantiated_data[k] = ct.instantiate(v)
  end
  return instantiated_data
end


---Desserializa um objeto instanciando suas classes filhas
---@param text string
---@return table|nil
function ct.unserialize(text)
  local data = textutils.unserialize(text)
  if not data then return end
  return ct.instantiate(data)
end

return ct
