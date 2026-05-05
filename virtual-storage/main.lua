-- Computercraft

local virtual_storage = {
  -- Ajuda a encontrar os itens. Fazer list
  _itens = {},
  -- Formato { "minecraft:oak_planks" = { { inventory = "minecraft:chest_8", slot = 39, count = 30 }, { inventory = "minecraft:chest_7", slot = 29, count = 1 } } }

  _inventarios = {}
  -- Formato { "minecraft:chest_8" = peripheral.wrap("minecraft:chest_8") }
}


function virtual_storage:load()
  itens_file = fs.open("status.json", "r")
  if itens_file then
    self._itens = textutils.unserialize(itens_file.readAll())
    itens_file.close()
  end
end

function virtual_storage:save()
  file = fs.open("status.json", "w")
  file.write(textutils.serialize(self._itens))
end


function virtual_storage:scan_inventarios()
  -- Mapear os inventarios
  perifericos = peripheral.getNames()
  for i, p in ipairs(perifericos) do
    if peripheral.hasType(p, "inventory") then
      self._inventarios[p] = peripheral.wrap(p) 
    end
  end
end


function virtual_storage:scan() 
  self:scan_inventarios()

  -- Mapear os itens
  for name, inv in pairs(self._inventarios) do
    local inv_items = inv.list()
    for slot, item in pairs(inv_items) do
      -- print(name, slot, item.name, item.count)
      self._itens[item.name] = self._itens[item.name] or {}
      table.insert(self._itens[item.name], { inventory = name, slot = slot, count = item.count })
    end
  end

  virtual_storage:save()
end


function virtual_storage:list_inventarios()
  -- Listar os inventarios encontrados
  for name, p in pairs(self._inventarios) do
    print(name)
  end
end


function virtual_storage:list_itens()
  -- Listar os itens encontrados
  for name, inv in pairs(self._itens) do
    print(name)
    for i, item in ipairs(inv) do
      print("  ", item.inventory, item.slot, item.count)
    end
  end
end


function virtual_storage:pull(item_name)
  -- Encontra os itens
  stacks = self._itens[item_name] or nil
  if not stacks then
    print("Item n encontrado: " .. item_name)
    return false
  end
  stack = stacks[1] or nil
  if not stack then
    print("Item n encontrado: " .. item_name)
    return false
  end
  source = self._inventarios[stack.inventory]

  -- Puxa os itens para o turtle
  source.pushItems("turtle_1", stack.slot, stack.count)

  -- Atualiza o cache
  table.remove(stacks, 1)

end


function virtual_storage:push() 

end


function virtual_storage:list() 

end


-- virtual_storage:scan()
virtual_storage:load()
virtual_storage:scan_inventarios()
virtual_storage:pull("minecraft:yellow_wool")
virtual_storage:list_itens()
virtual_storage:save()
