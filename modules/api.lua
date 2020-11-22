----------------------------------------------------------------------
-- API Consumer
-- Sledmine
-- Consumer for the Vulcano API
----------------------------------------------------------------------
local api = {}

local fdownload = require "lib.fdownload"

api.repositoryHost = "genesis.vadam.net"
api.httpProtocol = "https"
api.librarianPath = "api/vulcano"

local errorTable = {
    ["404"] = "package not found",
    ["connection refused"] = "no connection to repository"
}

-- Entities importation
local PackageMetadata = require "entities.packageMetadata"

local function get(url)
    local result, error, headers, status, response = fdownload.get(url)
    return error, response
end

---@param packageLabel string
---@param packageVersion string
function api.getPackage(packageLabel, packageVersion)
    cprint("Searching for '" .. packageLabel .. "' in repository... ", true)
    local librarianUrl = api.httpProtocol .. "://" .. api.repositoryHost .. "/" .. api.librarianPath
    local packageUrl = librarianUrl .. "/" .. packageLabel
    local apiUrl = packageUrl
    if (packageVersion) then
        apiUrl = packageUrl .. "/" .. packageVersion
    end
    local error, response = get(apiUrl)
    if (error == 200 and response) then
        cprint("done.")
        return PackageMetadata:new(response)
    else
        -- // TODO: Add better error array handling
        if (type(error) == "table") then
            error = error[1]
        end
        local errorDescription = errorTable[tostring(error)] or "unknown error"
        cprint("Error, " .. errorDescription .. ".")
    end
end

function api.getUpdate(packageLabel, packageVersion)
    local librarianURL = api.httpProtocol .. "://" .. api.repositoryHost .. "/" .. api.librarianPath
    local packageUrl = librarianURL .. "/" .. packageLabel .. "/update"
    local apiUrl = packageUrl .. "/" .. packageVersion
    return get(apiUrl)
end

return api
