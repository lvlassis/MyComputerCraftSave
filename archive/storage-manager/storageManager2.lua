local output_name = "minecraft:barrel_30"


function notOutput(name, wrapped)
    return name ~= output_name
end


function intersection(table1, table2)
    local intersection = {}
    for i, element1 in ipairs(table1) do
        for j, element2 in ipairs(table2) do
            if element1 == element2 then
                table.insert(intersection, element1)
                break
            end
        end
    end
    return intersection
end


function isOnInventory(item_name, inventory) -- Vai se tornar obsoleto
    for slot, inv_item in pairs(inventory) do
        if item_name == inv_item.name then
            return true, slot
        end
    end
    return false
end


function inventoryHasSlot(inventory, slot)
    for i, s in ipairs(inventory) do
        if s == slot then return true end
    end
    return false
end


function tableFind(table, element)
    for i, v in ipairs(table) do
        if v == element then
            return i
        end
    end
    return nil
end


function searchOnListaInv(item_name, listaInv) -- Vai se tornar obsoleto
    for i, inventory in pairs(listaInv) do
        if isOnInventory(item_name, inventory.list()) then
            return true, inventory
        end
    end
    return false
end


function searchFreeSlot(item_name, inventory)   --Procura um slot incompleto com o item escolhido
    for i, slot in pairs(inventory) do
        if isOnInventory(item_name, inventory.list()) and not isFull(inventory) then
            return true, inventory
        end
    end
    return false
end


function isFull(inventory)
    return #inventory.list() == inventory.size()
end


function isSlotFull(slot)
    if not slot.item then return false end
    return slot.item.count == slot.item.maxCount
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
    for i, barrel in pairs(listaInv) do
        local barrelName = peripheral.getName(barrel)
        local maxSlots = barrel.size()
        for nSlot=1, maxSlots do
            local item = barrel.getItemDetail(nSlot)
            local slot = {
                storageName = barrelName,
                slotNumber = nSlot,
                item = item
            }
            table.insert(inventory, slot)
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


function moverItem(slotInput, slotOutput, count)
    assert(slotInput.item)
    if not count then count = 64 end
    local itemName = slotInput.item.displayName

    local inputStorageName = slotInput.storageName
    local input = peripheral.wrap(inputStorageName)
    local inputSlotNumber = slotInput.slotNumber

    local outputStorageName = slotOutput.storageName
    local output = peripheral.wrap(outputStorageName)
    local outputSlotNumber = slotOutput.slotNumber

    local movedCount = input.pushItems(outputStorageName, inputSlotNumber, count, outputSlotNumber)
    print("Transfered ".. movedCount .. "x " .. itemName)
    
    if movedCount == slotInput.item.count then 
        slotOutput.item = slotInput.item
        slotInput.item = nil
    elseif movedCount > 0 then 
        slotOutput = updateSlot(slotOutput)
        slotInput.item.count = slotInput.item.count - movedCount 
    end
    return movedCount
end


function stackInto(slot, inventory_output)
    assert(slot.item)

    local slotId = slot.item.name
    local slotName = slot.item.displayName

    local sameIdSlots = searchById(inventory_output, slotId)
    local sameNameSlots = searchByName(inventory_output, slotName)

    local stackableSlots = intersection(sameIdSlots, sameNameSlots)
    for k, slot in ipairs(stackableSlots) do
        if isSlotFull(slot) then table.remove(stackableSlots, k) end
    end

    for i, stackableSlot in ipairs(stackableSlots) do
        moverItem(slot, stackableSlot)
        if not slot.item then
                return true
        end
    end
    return false, slot.item.count
end


function stockInto(slot, inventory_output)
    assert(slot.item)
    local emptySlot = searchEmptySlot(inventory_output)
    moverItem(slot, emptySlot)
end


function byName(a, b)
    local t = {a.name, b.name}
    table.sort(t)
    return a.name == t[1]
end

local invFileName = "inventory.txt"

-- Status getters e setters

function getInventoryFromFile()
    local file = io.open(invFileName)
    local content = file:read("*all")
    local inventory = textutils.unserialize(content)
    if inventory == nil then
        --inventory
    end
    file:close()
    return inventory
end


function updateInventoryFile(newInventory)
    local file = io.open(invFileName, "w")
    local content = textutils.serialize(newInventory)
    file:write(content)
    file:close()
end


--Search functions
function searchByName(inventory, name)
    name = string.lower(name)
    local output = {}
    for i, slot in ipairs(inventory) do
        if slot.item then
            local itemName = slot.item.displayName
            itemName = string.lower(itemName)
            if string.find(itemName, name) then
                table.insert(output, slot)
            end
        end
    end
    return output
end


function searchById(inventory, id)
    id = string.lower(id)
    local output = {}
    for i, slot in ipairs(inventory) do
        if slot.item then
            local itemId = slot.item.name
            itemId = string.lower(itemId)
            if string.find(itemId, id) then
                table.insert(output, slot)
            end
        end
    end
    return output
end


function searchByTag(inventory, tag)
    local output = {}
    for i, slot in ipairs(inventory) do
        if slot.item then
            local itemTags = slot.item.tags
            if itemTags[tag] then
                table.insert(output, slot)
            end
        end
    end
    return output
end


function searchByGroup(inventory, groupId)
    local output = {}
    for i, slot in ipairs(inventory) do
        if slot.item then
            if #slot.item.itemGroups > 0 then
                local itemGroupId = slot.item.itemGroups[1].id
                if itemGroupId == groupId then
                    table.insert(output, slot)
                end
            end
        end
    end
    return output
end


function searchEmptySlot(inventory)
    for i, slot in ipairs(inventory) do
        if not slot.item then
            return slot
        end
    end
    return nil
end


function loadStorageInventory()
    return loadInventory({peripheral.find("inventory", notOutput)})
end


function updateSlot(slot)
    local slot = slot
    local slotBarrelName = slot.storageName
    local slotNumber = slot.slotNumber
    local barrel = peripheral.wrap(slotBarrelName)
    slot.item = barrel.getItemDetail(slotNumber)
    return slot
end

function quickSearchInventory(inventory)
    local quickInventory = {
        get = function(self, storageName, slotNumber)
            return self[storageName][slotNumber]
        end
    }
    for _, slot in pairs(inventory) do
        local storageName = slot.storageName
        local slotNumber = slot.slotNumber
        local item = slot.item
        quickInventory[storageName][slotNumber] = item
    end
    return quickInventory
end
