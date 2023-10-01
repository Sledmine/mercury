------------------------------------------------------------------------------
-- Download action
-- Sledmine
-- Download any package file
------------------------------------------------------------------------------
local download = {}

local fdownload = require "modules.fdownload"
local paths = config.paths()

---@param meta packageMetadata
function download.package(meta)
    for index, packageUrl in pairs(meta.mirrors) do
        local urlSplit = packageUrl:split "/"
        local packageFileName = urlSplit[#urlSplit]
        local outputPath = gpath(paths.mercuryDownloads, "/", packageFileName)
        -- Check if file was already downloaded, helps with crash recovery and cache
        if exists(outputPath) and meta.checksum == MD5(outputPath) then
            return 200, outputPath
        end
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
