------------------------------------------------------------------------------
-- Download action
-- Sledmine
-- Download any package file
------------------------------------------------------------------------------
local download = {}

local json = require "cjson"
local glue = require "glue"
local fdownload = require "lib.fdownload"

---@param packageMeta packageMetadata
function download.package(packageMeta)
    for index, packageUrl in pairs(packageMeta.mirrors) do
        local outputPath = MercuryDownloads .. "\\" .. packageMeta.label .. ".merc"
        local result, error, headers, status = fdownload.get(packageUrl, outputPath)
        return error, outputPath
    end
    return false
end

function download.url(url, outputPath)
    local result, errorCode, headers, status = fdownload.get(url, outputPath)
    return errorCode
end

return download
