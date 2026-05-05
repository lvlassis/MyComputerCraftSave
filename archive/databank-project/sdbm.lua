--[[
    O Seven's Data Base Manager é um sistema de CRIAÇÃO, LEITURA e ESCRITA 
    de um Banco de Dados criado por ele mesmo. A intenção é ter uma forma 
    de guadar os dados por trás de uma interface de metadados.

    Features que busco:
        - Eficiência na busca dos dados
        - Abstração dos Dados
]]

require "constants"


-- Este é o nome do módulo com as funcionalidades
local sdbm = {
    --[[
        new_table. Função que cria um novo arquivo
        com nome "name" que conterá os dados 
        seguindo os metadados. Retorna um objeto 
        de referência para o arquivo.

        function (name) -> table_obj
    ]]
    new_table = nil, 


    --[[
        table_obj. Um objeto de referência para
        um arquivo table. Possui métodos de Select,
        Insert, Delete.
    ]]
    table_obj = {
        metadata = nil,
        line = nil,   -- Retorna o elemento na linha n
        insert = nil,   -- Insere um elemento 
        delete = nil    -- Deleta um elemento 
    },

}




function new_table(name, columns_names, columns_types)
    -- Verificações de entrada
    assert(#columns_names == #columns_types, "rows_names count does not match rows_types count")

    -- Constantes locais
    local count = #columns_names

    -- Funções Locais
    -- Construtor de Columns
    local function column(name, type)
        return {
            name = name,
            type = type
        }
    end


    -- Método Save
    local function save(table_controller)
        local table_obj = table_controller.table_obj
        -- Cria o arquivo table.db
        file = io.open(table_obj.file_path, "w")

        -- Escreve os metadados na table.db
        file:write(textutils.serialize(table_obj))

        -- Salva e fecha a table.db
        file:flush()
        file:close()
    end


    -- Método getColumns
    local function getColumns(table_controller)
        return table_controller.table_obj.columns
    end


    -- Método addItem
    local function addItem (...)
        local argumento = {...}
        local table_controller = argumento[1]

        -- Gera um item de acordo com o nome das colunas
        local function makeItem(arg_list)
            print(#arg_list)
            print(#columns_names)
            assert(#arg_list == #columns_names + 1) -- +1 pelo self:method()

            local item = {}
            for i=1, #columns_names do
                item[columns_names[i]] = arg_list[i+1] -- O primeiro argumento é um self
            end
            return item
        end

        print("Numero de Arg: "..#argumento)
        local item = makeItem(argumento)

        for i=1, #columns_names do
            assert(item[columns_names[i]] ~= nil)
        end
        table.insert(table_controller.table_obj.data, item)
    end








    -- Tabela com os dados e metadados
    local table_obj = {
        name = name,    -- Nome da Table
        columns = {},      -- Colunas da Table
        columns_names = columns_names,
        columns_types = columns_types,
        data = {},
        file_path = name..".db"
    }

    -- Preenche table_obj.column com as Columns já com seus respectivos nomes e valores
    for i=1, count do
        new_column = column(columns_names[i], columns_types[i])
        table.insert(table_obj.columns, new_column)
    end


    -- Objeto a ser retornado
    local table_controller = {
        -- Dados e metadados
        table_obj = table_obj,

        -- Métodos
        save = save,
        getColumns = getColumns,
        addItem = addItem,
    }

    return table_controller
end


-- Teste
-- Cria uma tabela de plantas
plantas = new_table(
    "plantas",
    {"id", "nome", "especie", "data_plantio"},
    {NUMBER_TYPE, STRING_TYPE, STRING_TYPE, STRING_TYPE}
)

plantas:addItem(2, "Pequi", "Caryocar brasiliensis", "1954-03-13")
plantas:save()

-- Teste do getColumns 
columns = plantas:getColumns()
print(textutils.serialize(columns))
