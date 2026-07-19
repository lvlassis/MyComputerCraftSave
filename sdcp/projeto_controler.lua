-- Host 
MODEM = "top"
PROTOCOL = "miner"

-- Abre a rednet
if not rednet.isOpen(MODEM) then
  rednet.open(MODEM)
end

-- Encontra as turtles miners
local miners = {rednet.lookup("miner")}
if not miners then error("Nenhum miner encontrado") end
table.sort(miners)

-- Converte para string
local miners_str = {}
for _, miner in pairs(miners) do table.insert(miners_str, tostring(miner)) end

-- Escolhe uma para mandar mensagem
local miner = nil
if type(miners) == "table" then
  write("Miners: ")
  for _, miner in pairs(miners_str) do
    write(miner.." ")
  end
  print()
  write("Escolha um miner: ")
  miner = read(nil, miners_str, function(text) return textutils.complete(text, miners_str) end, tostring(miners[1]))
else
  miner = miners
end
miner = tonumber(miner)

-- Mostra o miner escolhido
write("Miner escolhido: ")
print(miner)

-- Lê a mensagem para enviar ao miner
write("Mensagem: ")
msg = textutils.serialise({
  command = read()
})

-- Envia a mensagem
if miner and msg then
  rednet.send(miner, msg, PROTOCOL)
end
