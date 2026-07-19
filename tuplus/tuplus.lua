--[[
    Sevening_
    Turtle Plus eh um modulo para melhores funcoes de controle sobre as turtles.
]]

local tuplus = {}
tuplus.__version__ = 2.1


-- Imports
local ioutils = require "ioutils"



-- Constantes
-- Enumeracao de Movimentos
local MOVIMENTO = {
    UP = 'u',
    DOWN = 'd',
    FORWARD = 'f',
    BACK = 'b',
    LEFT = 'l',
    RIGHT = 'r'
}


-- Adiciona um movimento a todos os caminhos ate entao registrados
tuplus.registrarMovimento = function(movimento)
    for _, caminho in pairs(Caminhos) do
        if caminho.gravando then
            table.insert(caminho.movimentos, movimento)
        end
    end
end




-----------------------
-- Directional Functions
-----------------------

EAST = 0
SOUTH = 1
WEST = 2
NORTH = 3


tuplus.facingToString = function(direction)
    if direction == EAST then return "East"
    elseif direction == SOUTH then return "South"
    elseif direction == WEST then return "West"
    elseif direction == NORTH then return "North"
    end
end


---------------------------
-- Status getters e setters
---------------------------

local fileName = "status.config"
tuplus.getStatus = function()
    if not fs.exists(fileName) then
        fs.open(fileName, "w")
    end
    local file = io.open(fileName)
    local content = file:read("*all")
    local status = textutils.unserialize(content)
    if status == nil then status = {} end
    if status.position == nil then status.position = vector.new(0,0,0) end
    if status.facing == nil then status.facing = EAST end
    return status
end


tuplus.setStatus = function(newStatusTable)
    local file = io.open(fileName, "w")
    local content = textutils.serialize(newStatusTable)
    file:write(content)
    file:close()
end


-------------------------
-- Facing getter e setter
-------------------------

FACING = nil
tuplus.getFacing = function()
    if FACING then
        return FACING
    end
    local status = tuplus.getStatus()
    FACING = status.facing
    return FACING
end


tuplus.setFacing = function(direction)
    FACING = direction
end


tuplus.saveFacing = function()
    local status = tuplus.getStatus()
    assert(status.facing)
    status.facing = FACING
    tuplus.setStatus(status)
end


---------------------------
-- Position getter e setter
---------------------------

POSITION = nil
tuplus.getPosition = function()
    if POSITION then
        return POSITION
    end
    local status = tuplus.getStatus()
    local posTable = status.position
    POSITION = vector.new(posTable.x, posTable.y, posTable.z)
    return POSITION
end


tuplus.setPosition = function(pos)
    POSITION = pos
end


tuplus.savePosition = function()
    local status = tuplus.getStatus()
    assert(status.position)
    status.position = POSITION
    tuplus.setStatus(status)
end

---------------------------------------------
-- Conversão Facing(String) to Facing(Number)
---------------------------------------------

tuplus.facingToNum = function(facing)
    local facing = string.lower(facing)
    if facing == "w" then return WEST
    elseif facing == "s" then return SOUTH
    elseif facing == "e" then return EAST
    elseif facing == "n" then return NORTH
    else return false
    end
end


tuplus.facingToVector = function(facing)
	if facing == EAST then
		return vector.new(1, 0, 0)
	elseif facing == WEST then
		return vector.new(-1, 0, 0)
	elseif facing == SOUTH then
		return vector.new(0, 0, 1)
	elseif facing == NORTH then
		return vector.new(0, 0, -1)
	end
end


tuplus.vectorToFacing = function(vetor)
    if vetor:equals(vector.new(1, 0, 0)) then return EAST
    elseif vetor:equals(vector.new(-1, 0, 0)) then return WEST
    elseif vetor:equals(vector.new(0, 0, 1)) then return SOUTH
    elseif vetor:equals(vector.new(0, 0, -1)) then return NORTH
    end
end


--------------
-- Orientation
--------------

--Facing orientation
tuplus.askForDirection = function()
    local facing = ioutils.askFor(tuplus.facingToNum, "Set the direction: [n, s, e, w]", "Not a valid direction...")
    return facing
end


tuplus.gpsFindDirection = function()
    local pos_a = tuplus.gpsFindPosition()
    local tries = 0
    while turtle.detect() do
        tuplus.turnLeft()
        tries = tries + 1
        if tries > 3 then
            tuplus.tryDig()
            break
        end
    end
    tuplus.forward()
    local pos_b = tuplus.gpsFindPosition()
    tuplus.back()
    local look_vector = pos_b - pos_a
    return tuplus.vectorToFacing(look_vector)
end


tuplus.orientateFacing = function(option)
    local modem = peripheral.find("modem")
    local facing_direction = 0
    if modem and gps.locate() and not (option == "manual") then
        facing_direction = tuplus.gpsFindDirection()
    else
        facing_direction = tuplus.askForDirection()
    end
    tuplus.setFacing(facing_direction)
    tuplus.saveFacing()
    return true
end


-----------------------
-- Position orientation
-----------------------

tuplus.askForPosition = function()
    local x = ioutils.askFor(tonumber, "Set X:", "Not a number...")
    local y = ioutils.askFor(tonumber, "Set Y:", "Not a number...")
    local z = ioutils.askFor(tonumber, "Set Z:", "Not a number...")
    local position = vector.new(x, y, z)
    return position
end


tuplus.gpsFindPosition = function()
    local x, y, z = gps.locate()
    return vector.new(x, y, z)
end


tuplus.orientatePosition = function(option)
    local modem = peripheral.find("modem")
    local position = vector.new(0, 0, 0)
    if modem and gps.locate() and not (option == "manual") then
        position = tuplus.gpsFindPosition()
    else
        position = tuplus.askForPosition()
    end
    tuplus.setPosition(position)
    tuplus.savePosition()
    return true
end


tuplus.canGpsOrientate = function()
    local modem = peripheral.find("modem")
    if modem and gps.locate() then
        return true
    end
    return false
end


--To orientate
tuplus.orientate = function(option)
    local success_facing = tuplus.orientateFacing(option)
    local success_position = tuplus.orientatePosition(option)
    return success_facing and success_position
end


--------------------------
-- Funções para rotacionar
--------------------------

tuplus.turnRight = function()
    turtle.turnRight()
    local facing = tuplus.getFacing()
    facing = facing + 1
    facing = facing%4     --Matemática circular :3
    tuplus.setFacing(facing)
    tuplus.registrarMovimento(MOVIMENTO.RIGHT)
end


tuplus.turnLeft = function()
    turtle.turnLeft()
    local facing = tuplus.getFacing()
    facing = facing - 1
    facing = facing%4     --Matemática de relógio XD
    tuplus.setFacing(facing)
    tuplus.registrarMovimento(MOVIMENTO.LEFT)
end


tuplus.turnTo = function(targetDirection)
    targetDirection = targetDirection % 4
    while tuplus.getFacing() ~= targetDirection do
        if tuplus.facingDistance(tuplus.getFacing(), targetDirection) > 1 then
            tuplus.turnLeft()
        else
            tuplus.turnRight()
        end
    end
end


tuplus.facingDistance = function(dirInicial, dirFinal)    --Matemática circular :)
    return (dirFinal - dirInicial) % 4
end


-------------------
--Digging Functions
-------------------

tuplus.tryDig = function()
    while turtle.detect() do
        turtle.dig()
        sleep(0.1)
    end
end


tuplus.tryDigUp = function()
    while turtle.detectUp() do
        turtle.digUp()
        sleep(0.1)
    end
end


tuplus.tryDigDown = function()
    while turtle.detectDown() do
        turtle.digDown()
        sleep(0.1)
    end
end


------------------
--Moving functions
------------------

--- Anda para frente n vezes. O movimento é registrado internamente.
--- @param n number|nil Número de passos (padrão: 1)
--- @return boolean Retorna true se a turtle conseguiu andar. Caso contrário, retorna false e o número de passos que ela conseguiu andar.
tuplus.forward = function(n)
  n = n or 1
  for i = 1, n do
    local moved = turtle.forward()
    if not moved then
      return false, i-1
    end
      local position = tuplus.getPosition()
      local facing = tuplus.getFacing()
      tuplus.setPosition(position + tuplus.facingToVector(facing))
      tuplus.registrarMovimento(MOVIMENTO.FORWARD)
  end
  return true
end


--- Anda para trás n vezes. O movimento é registrado internamente.
--- @param n number|nil Número de passos (padrão: 1)
--- @return boolean Retorna true se a turtle conseguiu andar. Caso contrário, retorna false e o número de passos que ela conseguiu andar.
tuplus.back = function(n)
  n = n or 1
  for i = 1, n do
    local moved = turtle.back()
    if not moved then
      return false, i-1
    end
    local position = tuplus.getPosition()
    local facing = tuplus.getFacing()
    tuplus.setPosition(position - tuplus.facingToVector(facing))
    tuplus.registrarMovimento(MOVIMENTO.BACK)
  end
  return true
end


--- Anda para cima n vezes. O movimento é registrado internamente.
--- @param n number|nil Número de passos (padrão: 1)
--- @return boolean Retorna true se a turtle conseguiu andar. Caso contrário, retorna false e o número de passos que ela conseguiu andar.
tuplus.up = function(n)
  n = n or 1
  for i = 1, n do
    local moved = turtle.up()
    if not moved then
      return false, i-1
    end
    local position = tuplus.getPosition()
    tuplus.setPosition(position + vector.new(0, 1, 0))
    tuplus.registrarMovimento(MOVIMENTO.UP)
  end
  return true
end


--- Anda para baixo n vezes. O movimento é registrado internamente.
--- @param n number|nil Número de passos (padrão: 1)
--- @return boolean Retorna true se a turtle conseguiu andar. Caso contrário, retorna false e o número de passos que ela conseguiu andar.
tuplus.down = function(n)
  n = n or 1
  for i = 1, n do
    local moved = turtle.down()
    if not moved then
      return false, i-1
    end
    local position = tuplus.getPosition()
    tuplus.setPosition(position + vector.new(0, -1, 0))
    tuplus.registrarMovimento(MOVIMENTO.DOWN)
  end
  return true
end


---Anda até uma coordenada 
---@param destination table|vector Coordenadas de destino, deve conter x, y, e z
tuplus.walkTo = function(destination)
    local x = destination.x
    local y = destination.y
    local z = destination.z

    if tuplus.getPosition().x > x then
        tuplus.turnTo(WEST)
    elseif tuplus.getPosition().x < x then
        tuplus.turnTo(EAST)
    end

    while tuplus.getPosition().x ~= x do
        tuplus.tryDig()
        tuplus.forward()
    end

    if tuplus.getPosition().z < z then
        tuplus.turnTo(SOUTH)
    elseif tuplus.getPosition().z > z then
        tuplus.turnTo(NORTH)
    end

    while tuplus.getPosition().z ~= z do
        tuplus.tryDig()
        tuplus.forward()
    end

    while tuplus.getPosition().y ~= y do
        if tuplus.getPosition().y < y then
            tuplus.tryDigUp()
            tuplus.up()
        elseif tuplus.getPosition().y > y then
            tuplus.tryDigDown()
            tuplus.down()
        end
    end
end


---Sobe até esbarrar em um obstáculo
tuplus.upUntil = function()
    while tuplus.up() do end
end


---Desce até esbarrar em um obstáculo
tuplus.downUntil = function()
    while tuplus.down() do end
end


---Vai para frente até esbarrar em um obstáculo
tuplus.forwardUntil = function()
    while tuplus.forward() do end
end


---Vai para trás até esbarrar em um obstáculo
tuplus.backUntil = function()
    while tuplus.back() do end
end


---Experimental. Anda até uma coordenada sem quebrar blocos. Não funciona completamente.
tuplus.smoothWalkTo = function(destination)
    while not tuplus.getPosition().equals(destination) do
        local deslocamento = destination - tuplus.getPosition()
        while deslocamento:dot(tuplus.facingToVector(tuplus.getFacing())) <= 0 do
            tuplus.turnLeft()
        end
        tuplus.forward()
    end
end


----------------------
-- Funcoes de caminhos
----------------------

Caminhos = {}


-- Dicionario movimento para funcao
local DICT_MOVIMENTO = {
    [MOVIMENTO.UP] = tuplus.up,
    [MOVIMENTO.DOWN] = tuplus.down,
    [MOVIMENTO.FORWARD] = tuplus.forward,
    [MOVIMENTO.BACK] = tuplus.back,
    [MOVIMENTO.LEFT] = tuplus.turnLeft,
    [MOVIMENTO.RIGHT] = tuplus.turnRight,
}


-- Dicionario movimento para funcao reverso
local DICT_MOVIMENTO_R = {
    [MOVIMENTO.UP] = tuplus.down,
    [MOVIMENTO.DOWN] = tuplus.up,
    [MOVIMENTO.FORWARD] = tuplus.back,
    [MOVIMENTO.BACK] = tuplus.forward,
    [MOVIMENTO.LEFT] = tuplus.turnRight,
    [MOVIMENTO.RIGHT] = tuplus.turnLeft,
}


---Retorna o caminho com o nome especificado
---@param nome_caminho string
---@return Caminho|nil
tuplus.getCaminho = function(nome_caminho)
    return Caminhos[nome_caminho]
end


---Retorna a lista de movimentos de um caminho
---@param nome_caminho string
---@return Table|nil
tuplus.getMovimentos = function(nome_caminho)
    local caminho = tuplus.getCaminho(nome_caminho)
    return caminho.movimentos
end


---Altera o valor de um caminho
---@param nome_caminho string
---@param caminho Caminho
tuplus.setCaminho = function(nome_caminho, caminho)
    Caminhos[nome_caminho] = caminho
end


---Cria um caminho novo na lista de caminhos
---Caminhos *não* são gravados por padrao
---@param nome string Nome do novo caminho
---@return Caminho Caminho criado
tuplus.novoCaminho = function(nome)
    local caminho = {
        -- Lista de movimentos do caminho
        movimentos = {},

        -- Variável que define se estamos 
        -- gravando os movimentos realizados 
        -- neste caminho
        gravando = false,
    }

    Caminhos[nome] = caminho
    return caminho
end

---Remove um caminho da lista de caminhos
---@param nome_caminho string Nome do caminho a ser removido
tuplus.deletarCaminho = function(nome_caminho)
    Caminhos[nome_caminho] = nil
end


---Verifica se um caminho existe
---@param nome_caminho string Nome do caminho a ser verificado
---@return boolean true se o caminho existe, false caso contrário
tuplus.existeCaminho = function(nome_caminho)
    return Caminhos[nome_caminho] ~= nil
end


---Inicia a gravação de um caminho para poder ser atualizado. Caso não exista, cria o caminho.
---@param nome_caminho string Nome do caminho a ser gravado
tuplus.gravarCaminho = function(nome_caminho)
    if not tuplus.existeCaminho(nome_caminho) then
        tuplus.novoCaminho(nome_caminho)
    end
    Caminhos[nome_caminho].gravando = true
end


---Encerra a gravação de um caminho, para que nao possa ser alterado.
---@param nome_caminho string Nome do caminho a ser parado
tuplus.pararGravacaoCaminho = function(nome_caminho)
    if not tuplus.existeCaminho(nome_caminho) then
        return
    end
    Caminhos[nome_caminho].gravando = false
end


---Percorre um caminho
---@param nome_caminho string Nome do caminho a ser percorrido
tuplus.percorrerCaminho = function(nome_caminho)
    local caminho = tuplus.getCaminho(nome_caminho)
    for k, movimento in pairs(caminho.movimentos) do
        DICT_MOVIMENTO[movimento]()
    end
end


---Percorre um caminho ao contrário. De trás para frente. Desfaz o caminho.
---@param nome_caminho string Nome do caminho a ser desfeito
tuplus.desfazerCaminho = function(nome_caminho)
    tuplus.pararGravacaoCaminho(nome_caminho)
    local caminho = tuplus.getCaminho(nome_caminho)
    local movimentos = caminho.movimentos
    for i = #movimentos, 1, -1 do
        local movimento = movimentos[i]
        DICT_MOVIMENTO_R[movimento]()
    end
end


---Limpa o registro de um caminho sem deleta-lo
---@param nome_caminho string Nome do caminho a ser limpo
tuplus.limparCaminho = function(nome_caminho)
    Caminhos[nome_caminho].movimentos = {}
end

---Calcula o tamanho de um caminho. Útil para saber quanto de combustível é necessário para percorrer o caminho.
---@param nome_caminho string Nome do caminho a ser calculado
---@return number Tamanho do caminho
tuplus.tamanhoCaminho = function(nome_caminho)
    local movimentos = tuplus.getMovimentos(nome_caminho)

    local dict_gastos = {
        [MOVIMENTO.UP] = 1,
        [MOVIMENTO.DOWN] = 1,
        [MOVIMENTO.FORWARD] = 1,
        [MOVIMENTO.BACK] = 1,
        [MOVIMENTO.LEFT] = 0,
        [MOVIMENTO.RIGHT] = 0
    }

    local tamanho = 0
    for _, m in pairs(movimentos) do
        tamanho = tamanho + dict_gastos[m]
    end
    return tamanho
end


---Salva os movimentos de um caminho em um arquivo
---para que possam ser carregados eventualmente
---@param nome_caminho string Nome do caminho a ser salvo
---@param nome_arquivo string Nome do arquivo onde o caminho será salvo
tuplus.salvarCaminho = function(nome_caminho, nome_arquivo)
    local caminho = tuplus.getCaminho(nome_caminho)
    local conteudo = textutils.serializeJSON(caminho)
    local file = io.open(nome_arquivo, "w")
    if file then
        file:write(conteudo)
        file:flush()
        file:close()
    else
        print("[Erro] Arquivo ".. nome_arquivo.. " não pode ser criado")
    end
end

---Carrega os movimentos de um caminho salvos em um arquivo. 
---Cria um caminho novo com os movimentos carregados.
---@param nome_caminho string Nome do caminho a ser salvo
---@param nome_arquivo string Nome do arquivo de onde o caminho será carregado
tuplus.carregarCaminho = function(nome_caminho, nome_arquivo)
    local file = io.open(nome_arquivo, "r")
    if not file then
        print("[Erro] Arquivo ".. nome_arquivo .."não existe")
        return
    end
    local content = file:read()
    file:close()
    local caminho_carregado = textutils.unserializeJSON(content)
    tuplus.setCaminho(nome_caminho, caminho_carregado)
end


------------------------
-- Funcoes de Inventario
------------------------

tuplus.search = function(itemName)
    for slot=1, 16 do
        local item = turtle.getItemDetail(slot)
        if item then
            if item.name == itemName then
                turtle.select(slot)
                return true
            end
        end
    end
    return false
end

-- Encontra o primeiro item que satisfáz o filtro
tuplus.searchBy = function(filter)
  for slot=1, 16 do
    local item = turtle.getItemDetail(slot)
    if item and filter(item) then
      turtle.select(slot)
      return true
    end
  end
  return false
end


tuplus.searchNotEmptySlot = function()
    for slot=1, 16 do
        if turtle.getItemCount(slot) > 0 then 
            turtle.select(slot)
            return true
        end
    end
    return false
end


-- Verifica se inventario esta cheio 
tuplus.inventarioCheio = function()
    local selected_slot = turtle.getSelectedSlot()
    for s=16, 1, -1 do
        turtle.select(s)
        if turtle.getItemCount() == 0 then
            turtle.select(selected_slot)
            return false
        end
    end
    turtle.select(selected_slot)
    return true
end


-- Esvazia o inventario dropando todos os itens
tuplus.esvaziarInventario = function()
    local selected_slot = turtle.getSelectedSlot()
    for s=1, 16 do
        turtle.select(s)
        turtle.drop()
    end
    turtle.select(selected_slot)
end


-- Dropa itens do inventário
tuplus.drop = function (options)
  local direction = options.direction or "forward"
  local item_name = options.item_name or nil
  local quantidade = options.count or nil
  local slot = options.slot or nil
  local esvaziar = options.esvaziar or false

  -- Esvaziar inventário
  if esvaziar == true then
    return tuplus.esvaziarInventario()
  end

  local turtle_drop = {["forward"] = turtle.drop, ["down"] = turtle.dropDown, ["up"] = turtle.dropUp}

  -- Dropa quantidade de itens de um slot específico em uma direção
  if slot then
    turtle.select(slot)
    return turtle_drop[direction](quantidade)
  end

  -- Dropa todos os items com certo nome em uma direção
  if item_name then
    local restantes = quantidade
    -- Encontra de qual slot dropar
    while tp.search(item_name) and restantes > 0 do
      -- Encontra quanto dropar
      local quantidade_slot = turtle.getItemCount()
      local quantidade_dropar = quantidade_slot -- Por padrão vai dropar tudo no slot
      if restantes < quantidade then -- Caso reste dropar menos do que o disponível
        quantidade_dropar = restantes
      end
      -- Dropa
      if turtle_drop[direction](quantidade_dropar) then
        restantes = restantes - quantidade_dropar
      end
    end
    -- Retorno
    if restantes <= 0 then
      return true
    end
  end

  return false
end

-- Retorna quantos itens com esse nome estão no inventário
tuplus.getQuantidade = function(itemName)
  local quantidade = 0
  for i = 1, 16 do
    local item = turtle.getItemDetail(i)
    if not item then goto continue end
    if item.name ~= itemName then goto continue end
    quantidade = quantidade + item.count
    ::continue::
  end
  return quantidade
end


-- Inspeciona para ver se o bloco da frente eh o desejado
tuplus.isBlock = function(block_name)
    local _, block = turtle.inspect()
    return block.name == block_name
end


-- Inspeciona para ver se o bloco de cima eh o desejado
tuplus.isBlockUp = function(block_name)
    local _, block = turtle.inspectUp()
    return block.name == block_name
end


-- Inspeciona para ver se o bloco de baixo eh o desejado
tuplus.isBlockDown = function(block_name)
    local _, block = turtle.inspectDown()
    return block.name == block_name
end


tuplus.distanceTo = function(final_pos)
    local vmt = getmetatable(vector.new(0, 0, 0))
    setmetatable(final_pos, vmt)
    local diff_vector = final_pos - tuplus.getPosition()
    return diff_vector:length()
end


tuplus.closestPos = function(pos_list)
    local menor_distancia = tuplus.distanceToMe(pos_list[1])
    local closest = pos_list[1]
    for _,posicao in ipairs(pos_list) do
        if tuplus.distanceToMe(posicao) < menor_distancia then
            menor_distancia = tuplus.distanceToMe(posicao)
            closest = posicao
        end
    end
    return closest
end



------------------------
-- Funcoes de construcao
------------------------

tuplus.place = function()
    canPlace, error = turtle.place()
    while not canPlace do
        if error == "Cannot place block here" then
            return turtle.place()
        end
        if not tuplus.searchNotEmptySlot() then
            return turtle.place()
        end
        canPlace, error = turtle.place()
    end
    return true
end


tuplus.placeDown = function()
    local canPlace, error = turtle.placeDown()
    while not canPlace do
        if error == "Cannot place block here" then
            return turtle.placeDown()
        end
        if not tuplus.searchNotEmptySlot() then
            return turtle.placeDown()
        end
        canPlace, error = turtle.placeDown()
    end
    return true
end


tuplus.placeUp = function()
    local canPlace, error = turtle.placeUp()
    while not canPlace do
        if error == "Cannot place block here" then
            return turtle.placeUp()
        end
        if not tuplus.searchNotEmptySlot() then
            return turtle.placeUp()
        end
        canPlace, error = turtle.placeUp()
    end
    return true
end


-------------------------
-- Funções de combustivel
-------------------------
tuplus.refuelAll = function()
    shell.run('refuel', 'all')
end


return tuplus
