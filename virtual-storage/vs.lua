local vs = require "virtual_storage"

local function show_help()
  print([[
Uso: vs <cmd> [arguments]

cmd: 
- scan 
- ls
  ]])
end

local actions = {
  ["scan"] = function()
    vs:scan()
  end,

  ["inv"] = function ()
    vs:list_inventarios()
  end,

  ["list"] = function ()
    vs:list_itens()
  end,

  ["ls"] = function ()
    vs:list_itens()
  end,

  ["pull"] = function (item_name, count)
    print("item_name:", item_name)
    print("count:", count)
    vs:pull(item_name, tonumber(count))
  end,

  ["empty"] = function ()
    vs:empty()
  end,

  ["contents"] = function()
    print(textutils.serialise(vs:get_contents_table()))
  end,

  ["push"] = function (input_slot)
    vs:push(tonumber(input_slot))
  end

}


local function main()
  -- Recebe o comando
  local cmd = arg[1]

  -- Valida
  if not cmd then
    show_help();
    return
  elseif not actions[cmd] then
    print(('Comando "%s" nao existe!'):format(cmd))
    print()
    show_help()
    return
  end

  -- Obtém os argumentos
  table.remove(arg, 1)

  -- Executa
  vs:open()
  actions[cmd](table.unpack(arg))
  vs:close()
end
main()
