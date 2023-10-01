----------------------------------------------------------------------
-- API Consumer
-- Sledmine
-- Consumer for the Vulcano API
----------------------------------------------------------------------
local api = {}

local fdownload = require "modules.fdownload"
local constants = require "modules.constants"
local requests = require "requests"
local json = require "cjson"

api.protocol = "https"
api.repositoryHost = constants.repositoryHost
api.version = "v1"

---@class packageMetadata
---@field name string
---@field label string
---@field author string
---@field version string
---@field internalVersion string
---@field category string
---@field conflicts string[]
---@field mirrors string[]
---@field nextVersion string
---@field image? string
---@field checksum string

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
    -- local result, error, headers, status, response = fdownload.get(url)
    local response = requests.get(url)
    return response.status_code, response.text
end

---@param packageLabel string
---@param packageVersion? string
---@return packageMetadata?
function api.getPackage(packageLabel, packageVersion)
    --cprint("Searching for \"" .. packageLabel .. "\" in our repository... ", true)
    local packageUrl = vulcanoUrl() .. "/package/" .. packageLabel
    if packageVersion then
        packageUrl = packageUrl .. "/" .. packageVersion
    end
    dprint(packageUrl)
    local status, response = get(packageUrl)
    if status == 200 and response then
        local meta = json.decode(response)
        if meta then
            dprint("Package metadata:")
            dprint(meta)
            return meta
        end
    end
end

---@param packageLabel string
---@param packageVersion string
---@return packageMetadata?
function api.getUpdate(packageLabel, packageVersion)
    --cprint("Searching update for \"" .. packageLabel .. "-" .. packageVersion .. "\" in our repository... ", true)
    local packageUrl = vulcanoUrl() .. "/update/" .. packageLabel .. "/" .. packageVersion
    dprint(packageUrl)
    local status, response = get(packageUrl)
    if status == 200 and response then
        local meta = json.decode(response)
        dprint("Update metadata:")
        dprint(meta)
        if meta then
            return meta
        end
    end
end

function api.fetch()
    local response = requests.get(genesisIndexUrl())
    return response.status_code, response.text
end

return api
