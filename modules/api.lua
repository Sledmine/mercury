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


local function get(url)
    local result, error, headers, status, response = fdownload.get(url)
    return error, response
end

---@param packageLabel string
---@param packageVersion string
function api.getPackage(packageLabel, packageVersion)
    local librarianUrl = api.httpProtocol .. "://" .. api.repositoryHost .. "/" .. api.librarianPath
    local packageUrl = librarianUrl .. "/" .. packageLabel
    local apiUrl = packageUrl
    if (packageVersion) then
        apiUrl = packageUrl .. "/" .. packageVersion
    end
    return get(apiUrl)
end

function api.getUpdate(packageLabel, packageVersion)
    local librarianURL = api.httpProtocol .. "://" .. api.repositoryHost .. "/" .. api.librarianPath
    local packageUrl = librarianURL .. "/" .. packageLabel .. "/update" 
    local apiUrl = packageUrl .. "/" .. packageVersion
    return get(apiUrl)
end

return api
