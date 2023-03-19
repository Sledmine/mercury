------------------------------------------------------------------------------
-- Download action
-- Sledmine
-- Download any package file
------------------------------------------------------------------------------
local glue = require "glue"

local download = {}

local fdownload = require "modules.fdownload"
local paths = environment.paths()

---@param packageMeta packageMetadata
function download.package(packageMeta)
    for index, packageUrl in pairs(packageMeta.mirrors) do
        local urlSplit = glue.string.split(packageUrl, "/")
        local packageFileName = urlSplit[#urlSplit]
        local outputPath = gpath(paths.mercuryDownloads, "/", packageFileName)
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
