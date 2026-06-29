-- Libraries

local ct = require("class_tools")
local Inventory = require("inventory")
local Stack = require("stack")
local log = require("debug")

-- Debug Library

local log = {
  DEBUG = 0,
  INFO = 1,
  WARNING = 2,
  ERROR = 3,
  level = 0,
  step_by_step = false,
  debug = function (log, s, breakpoint)
    if log.level ~= log.DEBUG then return end
    print(("DEBUG: %s"):format(s))
    if breakpoint then log.step_by_step = true end
    if log.step_by_step then read() end
  end,
  info = function (log, s)
    if log.level > log.INFO then return end
    print(("INFO: %s"):format(s))
  end
}

log.level = log.DEBUG

-- Virtual Storage --

local CACHE_FILE = "status.json"

local modem = peripheral.find("modem")

local virtual_storage = {
  -- Nome da turtle que executa o programa
  computer_label = modem.getNameLocal(),

  -- Ajuda a encontrar os itens. Fazer list
  -- Formato { "minecraft:oak_planks" = { { inventory = "minecraft:chest_8", slot = 39, count = 30 }, { inventory = "minecraft:chest_7", slot = 29, count = 1 } } }
  _itens = {},

  -- Formato { "minecraft:chest_8" = Inventory:new("minecraft:chest_8") }
  _inventarios = {}
}


function virtual_storage:open()
  -- Carrega o cache
  self:load()

  self.computer_label = modem.getNameLocal()
end


function virtual_storage:close()
  -- Salva o cache
  self:save()
end


--- Retorna a lista de stacks do item buscado
---@param item_name string
---@return Stack[]|nil
function virtual_storage:_get_stacks(item_name)
  log:debug(("Get '%s'"):format(item_name))
  return self._itens[item_name] or nil
end


function virtual_storage:load()
  local itens_file = fs.open(CACHE_FILE, "r")
  if itens_file then
    local content = itens_file.readAll()
    if not content then return end

    local vs_data = ct.unserialize(content)
    if not vs_data then return end

    for key, value in pairs(vs_data) do
      self[key] = value
    end

    itens_file.close()
  end
end


function virtual_storage:save()
  local file = fs.open(CACHE_FILE, "w")
  if not file then return end

  local data = ct.serialize(self)

  file.write(data)
  file.close()
end


function virtual_storage:_scan_inventories()
  -- Mapear os inventarios
  log:debug("Escaneando inventarios...")

  local perifericos = peripheral.getNames()

  log:debug(("Encontrado: %d perifericos..."):format(#perifericos - 1))

  -- Salva o resultado
  for _, network_id in ipairs(perifericos) do
    if peripheral.hasType(network_id, "inventory") then
      local inventory = Inventory:new(network_id)
      inventory:scan()
      self._inventarios[network_id] = inventory
    end
  end
end


function virtual_storage:_scan_stacks()
  -- Mapear os itens
  log:debug("Escaneando stacks de itens...")

  self._itens = {}
  for network_id, inv in pairs(self._inventarios) do

    for slot, item in pairs(inv.content) do
      local itemDetail = inv.api.getItemDetail(slot)

      -- Inicializa a lista de stacks do item caso não exista
      self._itens[item.name] = self._itens[item.name] or {}

      -- Insere a Stack na lista do item
      table.insert(self._itens[item.name],
        Stack:new(
          item.name,
          item.count,
          itemDetail.maxCount,
          network_id,
          slot
        )
      )
    end
  end
end


function virtual_storage:scan()
  self:_scan_inventories()
  self:_scan_stacks()

  log:debug(("Salvando %s..."):format(CACHE_FILE))
  self:save()
end


function virtual_storage:list_inventarios()
  -- Listar os inventarios encontrados
  for _, inventory in pairs(self._inventarios) do
    print(inventory.network_id)
  end
end


function virtual_storage:list_itens()
  -- Listar os itens encontrados
  for name, stack_list in pairs(self._itens) do
    print(name)
    for _, stack in ipairs(stack_list) do
      print("  ", stack.inventory_id, stack.slot, stack.count)
    end
  end
end


local function _limpa_inventario_turtle()
  for i = 1, 16 do
    if turtle.getItemCount(i) > 0 then
      turtle.select(i)
      log:debug("Executa drop da morte 2")
      turtle.drop()
    end
  end
  turtle.select(1)
end


--- Informa quais as movimentações necessárias para se retirar "count" itens de uma lista de stacks
---@param stacks Stack[]
---@param count integer
---@return Stack[]
function virtual_storage:_get_pull_moves(stacks, count)
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
        inventory_id = stack.inventory_id,
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


function virtual_storage:get_inventory(network_id)
  return self._inventarios[network_id] or error(("Inventario '%s' nao existe"):format(network_id))
end


function virtual_storage:_pull_cached(inventory_name, slot, count)
  -- Encontra o inventário
  local source = self:get_inventory(inventory_name)

  -- Encontra qual o item_name
  local item_name = source.api.getItemDetail(slot).name

  -- Atualiza o cache
  -- Encontra no cache de qual stack é que estamos pegando
  log:debug(("Procurando: %s, slot %d"):format(inventory_name, slot))
  local encontrou = false
  local stacks = self:_get_stacks(item_name)
  for i, stack in ipairs(stacks) do
    log:debug(("Stack %d: %s, slot %d"):format(i, stack.inventory_id, stack.slot))
    if stack.inventory_id == inventory_name and stack.slot == slot then
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
    error(("Nao encontrado: Stack {inventory: %s, slot: %d}, abortando pull"):format(inventory_name, slot))
  end

  -- Realiza o pull
  source:pullItems(self.computer_label, slot, count)
  turtle.drop()
end


function virtual_storage:empty()
  log:info("Running: empty")
  -- Executa pull para cada um dos itens
  for item_name, _ in pairs(self._itens) do
    self:pull(item_name)
  end
end


function virtual_storage:pull(item_name, count)
  log:info(("Running: pull %s"):format(item_name))

  -- Garante que não há itens no output
  _limpa_inventario_turtle()

  -- Encontra as stacks com os itens
  local stacks = self:_get_stacks(item_name)
  if not stacks then
    print("Item n encontrado: " .. item_name)
    return false
  end

  -- Encontra quais movimentações serão necessárias realizar
  local movimentacoes = virtual_storage:_get_pull_moves(stacks, count)
  local movimentacoes_string = textutils.serialise(movimentacoes, {compact = true})
  log:debug(("Movimentacoes:\n%s"):format(movimentacoes_string))

  -- Realiza as movimentações 
  for i = #movimentacoes, 1, -1 do -- Itera de trás para frente
    local move = movimentacoes[i]
    self:_pull_cached(move.inventory_id, move.slot, move.count)
  end
end


function virtual_storage:_get_contents_table()
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


--- Encontra quantos slots com certo item possuem espaços livres
--- @param item_name string
--- @return integer espaco_total Quantidade de itens livres
--- @return table|nil inventarios_disponiveis Quais inventários que possuem esses slots
function virtual_storage:_free_space_with(item_name)
  -- Encontrar as stacks do mesmo item
  local same_item_stacks = self:_get_stacks(item_name)
  if not same_item_stacks then return 0, nil end

  -- Encontrar espaços disponíveis nas stacks 
  local espaco_total = 0
  local inventarios_disponiveis = {}
  for _, stack in ipairs(same_item_stacks) do
    local espaco_livre = stack.maxCount - stack.count
    espaco_total = espaco_total + espaco_livre
    if espaco_livre > 0 then
      inventarios_disponiveis[stack.inventory] = true
    end
  end

  return espaco_total, inventarios_disponiveis
end


--- Encontra quantos slots estão vazios
--- @return integer empty_slots Quantidade de slots vazios
--- @return table|nil inventory_sources Quais inventários que possuem slots vazios
function virtual_storage:_empty_slots()
  local inventory_sources = {}
  local empty_slots = 0
  for name, inventory in pairs(self._inventarios) do
    local vazios = inventory.api.size() - #inventory.api.list()
    empty_slots = empty_slots + vazios
    if vazios > 0 then
      inventory_sources[name] = true
    end
  end
  return empty_slots, inventory_sources
end


--- Envia o item de "input_slot" para o sistema
---@param input_slot integer
function virtual_storage:push(input_slot)

  -- Encontrar o nome do item e quantidade -> Converter em stack
  local item_detail =  turtle.getItemDetail(input_slot)
  if not item_detail then
    error(("Slot %d está vazio"):format(input_slot))
  end
  local input_item_name = item_detail.name
  local input_count = item_detail.count
  local input_max_count = item_detail.count + turtle.getItemSpace()

  -- Verificar se há espaços disponiveis
  local espaco_total = 0
  local espaco_slots, inventarios_disponiveis = virtual_storage:_free_space_with(input_item_name)
  espaco_total = espaco_total + espaco_slots

  local empty_slots, inventory_sources = virtual_storage:_empty_slots()
  espaco_total = espaco_total + empty_slots * input_max_count



  log:info(("Espaco Total: %s"):format(espaco_total))

  -- Encontrar espaço disponível em geral 
  -- for inventory_id, inventory in pairs(self._inventarios) do
  --
  -- end

  -- Fazer a conta para ver se há espaço disponível para a transação
  -- Realizar as movimentações
  
end


return virtual_storage
