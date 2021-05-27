------------------------------------------------------------------------------
-- Download action
-- Sledmine
-- Download any package file
------------------------------------------------------------------------------
local download = {}

local json = require "cjson"
local glue = require "glue"
local fdownload = require "Mercury.lib.fdownload"

---@param packageMeta packageMetadata
function download.package(packageMeta)
    for index, packageUrl in pairs(packageMeta.mirrors) do
        local outputPath = MercuryDownloads .. "/" .. packageMeta.label .. ".merc"
        local result, code, headers, status = fdownload.get(packageUrl, outputPath)
        return code, outputPath
    end
    return false
end

function download.url(url, outputPath)
    local result, code, headers, status = fdownload.get(url, outputPath)
    return code
end

return download
