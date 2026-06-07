-- Computercraft

---@class stack
---@field inventory string
---@field slot integer
---@field count integer

-- Debug Library

local log = {
  DEBUG = 0,
  level = 0,
  step_by_step = false,
  debug = function (log, s, breakpoint)
    if log.level ~= log.DEBUG then return end
    print(("DEBUG: %s"):format(s))
    if breakpoint then log.step_by_step = true end
    if log.step_by_step then read() end
  end
}

-- Virtual Storage

local CACHE_FILE = "status.json"

local virtual_storage = {
  -- Nome da turtle que executa o programa
  computer_label = "turtle_1",

  -- Ajuda a encontrar os itens. Fazer list
  -- Formato { "minecraft:oak_planks" = { { inventory = "minecraft:chest_8", slot = 39, count = 30 }, { inventory = "minecraft:chest_7", slot = 29, count = 1 } } }
  _itens = {},

  -- Formato { "minecraft:chest_8" = peripheral.wrap("minecraft:chest_8") }
  _inventarios = {}
}

function virtual_storage:open()
  -- Carrega o cache
  self:load()

  -- Escaneia os inventários conectados
  self:scan_inventarios()
end

function virtual_storage:close()
  -- Salva o cache
  self:save()
end


-- Retorna a lista de stacks do item buscado
function virtual_storage:get_stacks(item_name)
  log:debug(("Get '%s'"):format(item_name))
  return self._itens[item_name] or nil
end


function virtual_storage:load()
  local itens_file = fs.open(CACHE_FILE, "r")
  if itens_file then
    local content = itens_file.readAll()
    if not content then return end
    self._itens = textutils.unserialize(content)
    itens_file.close()
  end
end

function virtual_storage:save()
  local file = fs.open(CACHE_FILE, "w")
  if not file then return end
  file.write(textutils.serialize(self._itens))
end


function virtual_storage:scan_inventarios()
  -- Mapear os inventarios
  log:debug("Escaneando inventarios...")

  local perifericos = peripheral.getNames()

  log:debug(("Encontrado: %d perifericos..."):format(#perifericos - 1))

  -- Salva o resultado
  for _, p in ipairs(perifericos) do
    if peripheral.hasType(p, "inventory") then
      self._inventarios[p] = peripheral.wrap(p)
    end
  end
end


function virtual_storage:scan()
  self:scan_inventarios()

  -- Mapear os itens
  log:debug("Mapeando itens...")
  self._itens = {}
  for name, inv in pairs(self._inventarios) do
    local inv_items = inv.list()
    for slot, item in pairs(inv_items) do
      -- print(name, slot, item.name, item.count)
      self._itens[item.name] = self._itens[item.name] or {}
      table.insert(self._itens[item.name], { inventory = name, slot = slot, count = item.count })
    end
  end

  log:debug(("Salvando %s..."):format(CACHE_FILE))
  self:save()
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


--- Informa quais as movimentações necessárias para se retirar "count" itens de uma lista de stacks
---@param stacks stack[]
---@param count integer
---@return stack[]
function virtual_storage:get_pull_moves(stacks, count)
  log:debug("Function: get_pull_moves")
  if count then
    log:debug(("Count: %d"):format(count))
  else
    log:debug("Count: all")
  end

  -- Se não informou quantidade, é pra tirar tudo
  if not count then
    log:debug("Exiting: get_pull_moves. count = all")
    return stacks
  end

  local moves = {}
  for _, stack in ipairs(stacks) do
    if stack.count >= count then
      -- Se a stack analizada já possui a quantidade, tire apenas o necessário e acabou
      local move = {
        inventory = stack.inventory,
        slot = stack.slot,
        count = count,
      }
      table.insert(moves, move)
      count = 0
      break
    else
      -- Se a stack ainda não possui o suficiente, pega tudo e passa para a próxima
      table.insert(moves, stack)
      count = count - stack.count
    end
  end

  -- Verifica se faltou itens
  if count > 0 then
    log:debug("Nao havia itens o bastante")
  end

  return moves
end


function virtual_storage:get_inventory(inventory_name)
  return self._inventarios[inventory_name] or error(("Inventario '%s' nao existe"):format(inventory_name))
end


function virtual_storage:pull_cached(inventory_name, slot, count)
  -- Encontra o inventário
  local source = self:get_inventory(inventory_name)

  -- Encontra qual o item_name
  local item_name = source.getItemDetail(slot).name

  -- Atualiza o cache
  -- Encontra no cache de qual stack é que estamos pegando
  log:debug(("Procurando: %s, slot %d"):format(inventory_name, slot))
  local encontrou = false
  local stacks = self:get_stacks(item_name)
  for i, stack in ipairs(stacks) do
    log:debug(("Stack %d: %s, slot %d"):format(i, stack.inventory, stack.slot))
    if stack.inventory == inventory_name and stack.slot == slot then
      log:debug("Encontrou")
      encontrou = true
      stack.count = stack.count - count -- Atualiza o cache
      if stack.count == 0 then
        log:debug(("Removendo stack %s"):format(i))
        table.remove(stacks, i)
      end
      break
    end
  end
  -- TODO: Otimizar essa busca. 
  -- Sugestão 1: alterar formato da stack para:
  --  "minecraft:item_name" = {
  --    "inventory_name" = {
  --      "slot_number" = count
  --    }
  --  }
  -- Contras:
  -- - Vai dificultar a implementação do algoritmo de get_pull_moves
  --
  -- Sugestão 2: adicionar um outro cache em um formato especializado
  -- Contras:
  -- - Vai possivelmente dobrar o tamanho do arquivo de cache.

  if not encontrou then
    error(("Nao encontrado: Stack {inventory: %s, slot: %d}, abortando pull"))
  end

  -- Realiza o pull
  source.pushItems(self.computer_label, slot, count)
end


function virtual_storage:pull(item_name, count)
  log:debug(("Running: pull %s"):format(item_name))

  -- Encontra as stacks com os itens
  local stacks = self:get_stacks(item_name)
  if not stacks then
    print("Item n encontrado: " .. item_name)
    return false
  end

  -- Encontra quais movimentações serão necessárias realizar
  local movimentacoes = virtual_storage:get_pull_moves(stacks, count)
  local movimentacoes_string = textutils.serialise(movimentacoes, {compact = true})
  log:debug(("Movimentacoes:\n%s"):format(movimentacoes_string))

  -- Realiza as movimentações
  for i = #movimentacoes, 1, -1 do
    local move = movimentacoes[i]
    self:pull_cached(move.inventory, move.slot, move.count)

    -- Atualiza o cache
    -- table.remove(stacks, 1)
  end
end


function virtual_storage:get_contents_table()
  --[[ Returns:
  {
    "item_name" = { count = ??? },
    "item2_name" = { count = ??? },
  }
  ]]
  local contents = {}

  for item_name, slots in pairs(self._itens) do
    log:debug(item_name)

    -- Conta quantos items há no total
    local count = 0
    for _, slot in ipairs(slots) do
      count = count + slot.count
    end

    -- Salva metadados do item
    contents[item_name] = { count = count }
  end

  return contents
end


function virtual_storage:push()

end


function virtual_storage:list()

end

return virtual_storage

