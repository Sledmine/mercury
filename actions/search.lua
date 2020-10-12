local json = require "cjson"

local function searchPackage(packageLabel)
    local installedPackages = environment.packages()
    if (installedPackages and installedPackages[packageLabel]) then
        return installedPackages[packageLabel]
    end
    return false
end

return searchPackage
