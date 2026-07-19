local tp = require 'tuplus'

local args = {...}
local profundidade = tonumber(args[1]) or 64
local id = tonumber(args[2]) or 1
local offset = 0
if id == 1 then
    print('Minerador 1')
    offset = -3
elseif id == 2 then
    print('Minerador 2')
    offset = -4
else
    error('ID do minerador deve ser 1 ou 2.')
end

local function digNext()
    tp.tryDig()
    tp.tryDigDown()
    tp.tryDigUp()
    tp.forward()
end

local function explore(depth)
    if id == 1 then tp.turnLeft() else tp.turnRight() end

    for i = 1, depth do
        digNext()
    end
    for i = 1, depth do
        tp.back()
    end

    if id == 1 then tp.turnRight() else tp.turnLeft() end
end



-- Aguardando sinal
while not redstone.getInput("left") do
    sleep(0.1)
end

-- Main
tp.tryDigUp()
tp.up()
for i = 1, profundidade do
    while not tp.forward() do
        sleep(0.1)
    end
    if (i + offset) >= 0 and (i + offset) % 3 == 0 then
        explore(5)
    end
end

