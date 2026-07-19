local VERSION = "0.1"

-- Configurações

-- Adiciona o diretório /lib ao caminho de pesquisa de módulos
package.path = package.path .. ";/lib/?.lua;/lib/?/init.lua"
if not fs.exists("/lib") then
    fs.makeDir("/lib")
end

-- Adiciona o diretório /bin ao caminho de pesquisa de comandos
shell.setPath(shell.path() .. ":/bin")
if not fs.exists("/bin") then
    fs.makeDir("/bin")
end

-- Desativa motd por padrão
settings.set("motd.enable", false)


-- Salva as configurações
settings.save()

-- Inicia
term.setTextColor(colors.orange)
print("SevenCC " .. VERSION)
term.setTextColor(colors.white)

