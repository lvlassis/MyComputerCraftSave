---@class Inventory
---@field public network_id string
---@field public api ccTweaked.peripheral.wrappedPeripheral
---@field public list ccTweaked.peripheral.itemList
local Inventory = {}
Inventory.__index = Inventory

---Construtor de Inventory
---@param network_id string
---@param content table
---@return Inventory
function Inventory:new(network_id, content)
  local t = {}
  t.network_id = network_id
  t.api = peripheral.wrap(network_id)
  t.content = content or {}
  t.__classname = "Inventory"
  return setmetatable(t, self)
end

function Inventory:instantiate_from_data(data)
  return Inventory:new(
      data.network_id,
      data.content
    )
end

function Inventory:scan()
  self.content = self.api.list()
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

--- Transfere um item deste inventário para o inventário de destino
function Inventory:pullItems(toName, slot, limit, targetSlot)
  local quantity = self.api.pushItems(toName, slot, limit, targetSlot)
  self.content[slot].count = self.content[slot].count - quantity
  if self.content[slot].count <= 0 then
    self.content[slot] = nil
  end
  return quantity
end

return Inventory
