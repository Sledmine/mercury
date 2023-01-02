local search = require "Mercury.actions.search"
local json = require "cjson"

local function listPackages(jsonPrint, tablePrint)
    local installedPackages = environment.packages()
    if installedPackages then
        --  TODO This requires a real list filtering implementation
        if jsonPrint then
            print(json.encode(installedPackages))
        elseif tablePrint then
            print(inspect(installedPackages))
        else
            print("Installed Packages:")
            for packageIndex, package in pairs(installedPackages) do
                print("- " .. package.label .. " v" .. package.version)
            end
        end
        return true
    end
    cprint("Warning There are not any installed packages using Mercury... yet.")
    return false
end

return listPackages
