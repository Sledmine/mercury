local search = require "Mercury.actions.search"
local json = require "cjson"

local function listPackages()
    local installedPackages = environment.packages()
    if (installedPackages) then
        -- // TODO This requires a real list filtering implementation
        print(inspect(installedPackages))
        return true
    end
    cprint("Warning, There are not any installed packages using Mercury...yet.")
    return false
end

return listPackages
