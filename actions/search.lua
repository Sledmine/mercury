local json = require "cjson"

local function searchPackage(packageLabel)
    local installedPackages = {}
    if (fileExist(_HALOCE_INSTALLED_PACKAGES)) then
        installedPackages = json.decode(fileToString(_HALOCE_INSTALLED_PACKAGES))
        if (installedPackages[packageLabel]) then
            return true
        end
    end
    return false
end

return searchPackage