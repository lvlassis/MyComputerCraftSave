sm = require("storageManager2")

local barril_io_name = "minecraft:barrel_30"
local barril_IO = peripheral.wrap(barril_io_name)
local storage = getInventoryFromFile()

function getOutputInventory()
    return loadInventory({barril_IO})
end

function printSlot(slot)
    assert(slot.item)
    print(slot.item.count .. "x " .. slot.item.displayName)
end

function get(nome, count, modifier)
    local itensEncontrados = find(nome, modifier, false)
    local inventario_output = getOutputInventory()
    local espaco_livre_output = nil
    
    local movedCount = 0
    for i, item in pairs(itensEncontrados) do
        espaco_livre_output = searchEmptySlot(inventario_output)
        movedCount = moverItem(item, espaco_livre_output, count)
        count = count - movedCount
        if count <= 0 then break end
    end
end

function getAll(nome)
    local itensEncontrados = searchByName(storage, nome)
    local inventario_output = getOutputInventory()
    local espaco_livre_output = nil
    
    for i, item in pairs(itensEncontrados) do
        espaco_livre_output = searchEmptySlot(inventario_output)
        moverItem(item, espaco_livre_output, count)
    end
end

function pushAll()
    local inputStorage = getOutputInventory()
    for k, inputSlot in pairs(inputStorage) do
        if inputSlot.item then stackInto(inputSlot, storage) end
    end
    for k, inputSlot in pairs(inputStorage) do
        if inputSlot.item then stockInto(inputSlot, storage) end
    end
end

function refill()

end

function find(word, modifier, toPrint)
    local search = {
        ["name"] = searchByName,
        ["id"] = searchById,
        ["tag"] = searchByTag,
        ["group"] = searchByGroup
    }
    if modifier == nil then modifier = "name" end
    local foundItems = search[modifier](storage, word)
    if toPrint == nil then toPrint = true end
    if toPrint then
        for k, slot in pairs(foundItems) do
            printSlot(slot)
        end
    end
    return foundItems
end

function update()
    storage = loadStorageInventory()
end

function list()
    for k, slot in ipairs(storage) do
        if slot.item then printSlot(slot) end
    end
end


if #arg == 0 then return end
local selected_command = string.lower(arg[1])

if selected_command == "get" then
    local nome = arg[2]
    local count = arg[3]
    if count == nil then count = 1 end
    if count == "all" then 
        return getAll(nome)
    else 
        count = tonumber(count)
        get(nome, count) 
    end
elseif selected_command == "push" then
    pushAll()
elseif selected_command == "refill" then
    refill()
elseif selected_command == "find" then
    local word = arg[2]
    local modifier = arg[3]
    if modifier == nil then modifier = "name" end
    find(word, modifier)
elseif selected_command == "list" then
    list()
elseif selected_command == "update" then
    update()
end

updateInventoryFile(storage)
