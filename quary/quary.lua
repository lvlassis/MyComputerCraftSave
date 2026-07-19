local rpc = require 'rpc'
local tp = require 'tuplus'

-- Funções

local function forEach(self, f)
  local tasks = {}
  for _, o in ipairs(self) do
    table.insert(tasks, function ()
      f(o)
    end)
  end
  parallel.waitForAll(table.unpack(tasks))
end

local function obter_miners()
  local miners_ids = {rednet.lookup("miner")}
  local miners = {}
  for _, id in pairs(miners_ids) do
    local novo_miner = rpc.Proxy(id, "miner")
    print(novo_miner)
    table.insert(miners, novo_miner)
  end

  miners.forEach = forEach

  return miners
end


---@param miners table
---@param posicao table
local function ordenar_proximidade(miners, posicao)
  table.sort(miners,
    function(m, n)
      return m.distanceTo(posicao) < n.distanceTo(posicao)
    end
  )
end


local function mais_proximo(miners, posicao)
  local miners_cp = miners
  ordenar_proximidade(miners_cp, posicao)
  return miners_cp[1]
end


local function formacaoInicial(miners, posA, dx, dy, dz)
  local wx = math.floor(dx / #miners)
  local formacao = {}
  local facing = tp.vectorToFacing(vector.new(0, 0, dz):normalize())
  for i = 0, #miners-1 do
    table.insert(formacao,
      {
        pos = vector.new(posA.x + i*wx, posA.y, posA.z),
        facing = facing
      }
    )
  end
  return formacao
end


local function posicionarFormacao(miners, formacao)
  local tasks = {}
  for k, miner in ipairs(miners) do
    table.insert(tasks, function ()
local posicao = formacao[k]
      print("Movendo: "..miner.id)
      miner.walkTo(posicao.pos)
    end)
  end
  parallel.waitForAll(table.unpack(tasks))

  sleep(1)

  tasks = {}
  for k, miner in ipairs(miners) do
    table.insert(tasks, function ()
      local posicao = formacao[k]
      print("Girando: "..miner.id)
      miner.turnTo(posicao.facing)
    end)
  end
  parallel.waitForAll(table.unpack(tasks))
end


local function digDown(miners)
  local tasks = {}
  for _, miner in ipairs(miners) do
    table.insert(tasks, function ()
      miner.tryDigDown()
      miner.down()
    end)
  end
  parallel.waitForAll(table.unpack(tasks))
end



-- Main

peripheral.find('modem', rednet.open)

local posA = vector.new(-52, 64, -25)
local dx, dy, dz = -9, -6, -9

local miners = obter_miners()
print("Encontrados: "..#miners)

local formacao = formacaoInicial(miners, posA, dx, dy, dz)
posicionarFormacao(miners, formacao)

-- Maneiras de async:
-- digDown(miners)
-- miners:forEach(function (miner)
--   miner.tryDigDown()
--   sleep(0.5)
--   miner.down()
-- end)

miners:forEach(function (miner)
  miner.shell("cubeEf 4 2 3")
end)

