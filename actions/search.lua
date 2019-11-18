local json = require "cjson"

local function searchPackage(packageName)
    local installedPackages = {}
    if (fileExist(_HALOCE_INSTALLED_PACKAGES) == true) then
        installedPackages = json.decode(fileToString(_HALOCE_INSTALLED_PACKAGES))
        if (installedPackages[packageName]) then
            return true
        end
    end
    return false
end

return searchPackage