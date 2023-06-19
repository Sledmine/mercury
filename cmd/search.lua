local json = require "cjson"

--- Attempts to found an installed package given packageLabel
---@return packageMercury? package
local function searchPackage(packageLabel)
    local installedPackages = config.packages()
    if (installedPackages and installedPackages[packageLabel]) then
        return installedPackages[packageLabel]
    end
end

return searchPackage
