----------------------------------------------------------------------
-- API Consumer
-- Sledmine
-- Consumer for the Vulcano API
----------------------------------------------------------------------
local api = {}

local fdownload = require "Mercury.modules.fdownload"
local constants = require "Mercury.modules.constants"
local requests = require "requests"

api.repositoryHost = constants.repositoryHost
api.protocol = "https"
api.vulcanoPath = constants.vulcanoPath

--- Generate an URL using api definitions
local function vulcanoUrl()
    return api.protocol .. "://" .. api.repositoryHost .. "/" .. api.vulcanoPath
end

--- Simple GET HTTP method
local function get(url)
    --local result, error, headers, status, response = fdownload.get(url)
    local response = requests.get(url)
    return response.status_code, response.text
end

---@param packageLabel string
---@param packageVersion string
function api.getPackage(packageLabel, packageVersion)
    cprint("Searching for \"" .. packageLabel .. "\" in our repository... ", true)
    local packageUrl = vulcanoUrl() .. "/" .. packageLabel
    local apiUrl = packageUrl
    if (packageVersion) then
        apiUrl = packageUrl .. "/" .. packageVersion
    end
    dprint(apiUrl)
    local status, response = get(apiUrl)
    cprint("done.")
    return status, response
end

---@param packageLabel string
---@param packageVersion string
function api.getUpdate(packageLabel, packageVersion)
    cprint("Searching update for \"" .. packageLabel .. "\" in our repository... ", true)
    local packageUrl = vulcanoUrl() .. "/" .. packageLabel .. "/update" 
    local apiUrl = packageUrl .. "/" .. packageVersion
    dprint(apiUrl)
    local status, response = get(apiUrl)
    cprint("done.")
    return status, response
end

function api.fetch()
    local response = requests.get(constants.packageIndex)
    return response.status_code, response.text
end

return api
