ts = require("turtleSettings")
tp = require("tuplus")


pref = ts.getPreferences()

if pref.orientateOnStartup == true then
    if tp.canGpsOrientate() then
        shell.run("orientate")
    else
        shell.run("orientate -m")
    end
end

shell.run "miner"
