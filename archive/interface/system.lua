pretty = require "cc.pretty"
mouse = require("mouse")
escape = peripheral.find("monitor")
escape.write("hi")

names = peripheral.getNames()
inv_system = {}
input_chest = nil

for id, name in ipairs(names) do
    if peripheral.hasType(name, "minecraft:trapped_chest") then
        escape.write("Sugoy")
        input_chest = peripheral.wrap(name)
    elseif peripheral.hasType(name, "inventory") then
        chest = {id, name, peripheral.wrap(name)}
        table.insert(inv_system, chest)
    end
end

itens_list = {} --Todos os itens do Sistema
for n=1, #inv_system do
    for k, item in ipairs(inv_system[n][3].list()) do
        item.chest_id = n
        table.insert(itens_list, item)
    end
end

--Display
--[[
for k, item in ipairs(itens_list) do
    print(string.format("%02dx %s",item.count, item.name))
end]]

--GUI
scr_width, scr_height = term.getSize()
function drawGui()
    term.setBackgroundColor(colors.black)
    term.clear()
    paintutils.drawFilledBox(2, 2, scr_width-15, scr_height, colors.gray)
    paintutils.drawLine(5,1,scr_width-15,1, colors.blue)
    paintutils.drawFilledBox(scr_width-13,scr_height-1,scr_width-8,scr_height, colors.lime)
    paintutils.drawFilledBox(scr_width-6, scr_height-1, scr_width-1, scr_height, colors.orange)
    term.setCursorPos(6, 1)
    titulo = "Super Seven's Sorting System"
    if string.len(titulo) > scr_width-21 then
        titulo = "SSSS"
    end
    term.setBackgroundColor(colors.blue)
    term.setTextColor(colors.white)
    term.write(titulo)
    term.setBackgroundColor(colors.lime)
    term.setCursorPos(scr_width-12, scr_height-1)
    term.write("PULL")
    term.setBackgroundColor(colors.orange)
    term.setCursorPos(scr_width-5, scr_height-1)
    term.write("PUSH")
end

function drawItens(item_table, first_pos, sel_pos, size)
    term.setTextColor(colors.white)
    for k=first_pos, first_pos+size-1 do
        if k ~= sel_pos then
            term.setBackgroundColor(colors.gray)
        else
            term.setBackgroundColor(colors.lightGray)
        end
        term.setCursorPos(2,k-first_pos+2)
        term.write(string.format("%02dx %s",item_table[k].count,item_table[k].name))
    end
end


first_pos = 1
sel_pos = 1
size = 18
while true do
    drawGui()
    drawItens(itens_list, first_pos, sel_pos, size)
    event, a, b, c = os.pullEvent()
    
    if event == "key" then
        if keys.getName(a) == "up" then
            sel_pos = sel_pos - 1
        elseif keys.getName(a) == "down" then
            sel_pos = sel_pos + 1
        end
        
        if sel_pos < 1 then
            sel_pos = 1
        elseif sel_pos > #itens_list then
            sel_pos = #itens_list
        end
        
        
        if sel_pos < first_pos then
            first_pos = sel_pos
        elseif sel_pos+1 > first_pos+size then
            first_pos = sel_pos-size+1
        end
    elseif event == "mouse_click" and a == 1 then
        if mouse.isInside(b, c, scr_width-13, scr_height-1, scr_width-8, scr_height) then
            escape.clear()
            escape.setCursorPos(1, 1)
            escape.write(itens_list[sel_pos].chest_id)
            local id = itens_list[sel_pos].chest_id
            local target_chest = inv_system[id][3]
            input_chest.pullItems(peripheral.getName(target_chest), 1)
        end
    end
    
    
end
