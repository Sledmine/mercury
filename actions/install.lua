local install = {}

-- Entities importation
local PackageMetadata = require "entities.packageMetadata"

local errorTable = {
    ["404"] = "package not found",
    ["connection refused"] = "no connection to repository",
}

function install.package(packageLabel, packageVersion, forced, noBackups)
    cprint("Searching for '" .. packageLabel .. "' in repository... ", true)
    local error, response = api.getPackage(packageLabel, packageVersion)
    if (error == 200 and response) then
        cprint("done.")
        local merc = PackageMetadata:new(response)
    else
        -- // TODO: Add better error array handling
        if (type(error) == "table") then
            error = error[1]
        end
        local errorDescription = errorTable[tostring(error)] or "unknown error"
        cprint("Error, " .. errorDescription .. ".")
    end
end

return install
