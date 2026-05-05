local output_name = "minecraft:barrel_30"

function notOutput(name, wrapped)
    return name ~= output_name
end

function isOnInventory(item_name, inventory)
    for slot, inv_item in pairs(inventory) do
        if item_name == inv_item.name then
            return true, slot
        end
    end
    return false
end

function searchOnListaInv(item_name, listaInv)
    for i, inventory in pairs(listaInv) do
        if isOnInventory(item_name, inventory.list()) then
            return true, inventory
        end
    end
    return false
end

function searchFreeInventory(item_name, listaInv)
    for i, inventory in pairs(listaInv) do
        if isOnInventory(item_name, inventory.list()) and not isFull(inventory) then
            return true, inventory
        end
    end
    return false
end

function isFull(inventory)
    return #inventory.list() == inventory.size()
end

function getItemByName(item_name, inventory)
    for slot, item in pairs(inventory) do
        if item.name == item_name then
            return item
        end
    end
end

function addToInventory(item, inventory)
    local isPresent, slot = isOnInventory(item.name, inventory)
    if isPresent then
        inventory[slot].count = inventory[slot].count + item.count 
    else
        table.insert(inventory, item)
    end
end

function loadInventory(listaInv)
    local inventory = {}
    for index, inv in pairs(listaInv) do
        local string = textutils.serialize(inv.list())
        for slot, item in pairs(inv.list()) do
            addToInventory(item, inventory)
        end
    end
    return inventory
end

function printInv(inventory)
    for slot, item in pairs(inventory) do
        local name = item.name
        local i = string.find(name, ":")
        name = string.sub(name, i+1)
        print(("%dx %s"):format(item.count, name))
    end
end

function printInvOnMonitor(inventory, monitor)
    line = 1
    for slot, item in pairs(inventory) do
        local name = item.name
        local i = string.find(name, ":")
        name = string.sub(name, i+1)
        monitor.setCursorPos(1, line)
        monitor.write(("%dx %s"):format(item.count, name))
        line = line + 1
    end
end

function pegarItem(destination, itemName, listaInv, count)
    for index, inv in pairs(listaInv) do
        local isPresent, slot = isOnInventory(itemName, inv.list())
        if isPresent then
            destination.pullItems(peripheral.getName(inv), slot, count)
            print("Transfered ".. count .. "x " .. itemName)
            return
        end
    end
end

function guardarTudo(listaOutput, input)
    for slot, item in pairs(input.list()) do
        local exists, output = searchFreeInventory(item.name, listaOutput)
        if not exists then
            for i, inventory in pairs(listaOutput) do
                if not isFull(inventory) then
                    output = inventory
                end
            end
        end
        input.pushItems(peripheral.getName(output), slot)
        print("Put " .. item.count .. "x " .. item.name)
    end
end

function byName(a, b)
    local t = {a.name, b.name}
    table.sort(t)
    return a.name == t[1]
end

-- Status getters e setters
function getStatus()
    local file = io.open("inventory.txt")
    local content = file:read("*all")
    local inventory = textutils.unserialize(content)
    if inventory == nil then
        inventory
    end
    return inventory
end

function setStatus(newStatusTable)
    local file = io.open("status.config", "w")
    local content = textutils.serialize(newStatusTable)
    file:write(content)
    file:close()
end


local listaInv = {peripheral.find("inventory", notOutput)}
local outputInv = peripheral.wrap(output_name)
local monitor = peripheral.find("monitor")
local monitor_side = "left"

if arg[1] == "push" then
    guardarTudo(listaInv, outputInv)
elseif arg[1] == "get" then
    local nome = arg[2]
    local count = tonumber(arg[3])
    if count == nil then
        count = 64
    end
    pegarItem(outputInv, nome, listaInv, count)
else 
    local inventory = loadInventory(listaInv)
    table.sort(inventory, byName)
    if monitor then
        printInvOnMonitor(inventory, monitor)
    else
        printInv(inventory)
    end
end
