---@class Inventory
---@field public network_id string
---@field public api ccTweaked.peripheral.wrappedPeripheral
---@field public list ccTweaked.peripheral.itemList
local Inventory = {}
Inventory.__index = Inventory

---Construtor de Inventory
---@param network_id string
---@return Inventory
function Inventory:new(network_id)
  local t = {}
  t.network_id = network_id
  t.api = peripheral.wrap(network_id)
  t.content = t.api.list()
  t.__classname = "Inventory"
  return setmetatable(t, self)
end

function Inventory:instantiate_from_data(data)
  return Inventory:new(
      data.network_id
    )
end


---Retorna o número de slots vazios do inventário
---@return number
function Inventory:free()
  return self.api.size() - #self.content
end

function Inventory:state()
  return {
    self.network_id,
    self.content
  }
end

return Inventory
