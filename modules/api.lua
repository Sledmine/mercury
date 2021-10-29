----------------------------------------------------------------------
-- API Consumer
-- Sledmine
-- Consumer for the Vulcano API
----------------------------------------------------------------------
local api = {}

local fdownload = require "Mercury.modules.fdownload"
local constants = require "Mercury.modules.constants"
local requests = require "requests"

api.protocol = "https"
api.repositoryHost = constants.repositoryHost
api.version = "v1"

--- Generate an URL using api definitions
local function vulcanoUrl()
    return api.protocol .. "://" .. api.repositoryHost .. "/" .. api.version
end

--- Generate a genesis URL using api definitions
local function genesisIndexUrl()
    return vulcanoUrl() .. "/fetch"
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
    local packageUrl = vulcanoUrl() .. "/package/" .. packageLabel
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
    local packageUrl = vulcanoUrl() .. "/update" .. packageLabel
    local apiUrl = packageUrl .. "/" .. packageVersion
    dprint(apiUrl)
    local status, response = get(apiUrl)
    cprint("done.")
    return status, response
end

function api.fetch()
    local response = requests.get(genesisIndexUrl())
    return response.status_code, response.text
end

return api
