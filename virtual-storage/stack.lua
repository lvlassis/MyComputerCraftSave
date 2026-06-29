---@class Stack
---@field item_name string
---@field inventory_id string
---@field slot integer
---@field count integer
---@field maxCount integer
local Stack = {}
Stack.__index = Stack

function Stack:new(item_name, count, maxCount, inventory_id,  slot)
  local t = {}
  t.item_name = item_name
  t.count = count
  t.maxCount = maxCount
  t.inventory_id = inventory_id
  t.slot = slot
  t.__classname = "Stack"
  return setmetatable(t, self)
end

function Stack:instantiate_from_data(data)
  return Stack:new(
      data.item_name,
      data.count,
      data.maxCount,
      data.inventory_id,
      data.slot
    )
end

return Stack
