------------------------------------------------------------------------------
-- Download action
-- Sledmine
-- Download any package file
------------------------------------------------------------------------------
local download = {}

local fdownload = require "modules.fdownload"
local paths = config.paths()

---@param packageMeta packageMetadata
function download.package(packageMeta)
    for index, packageUrl in pairs(packageMeta.mirrors) do
        local urlSplit = packageUrl:split "/"
        local packageFileName = urlSplit[#urlSplit]
        local outputPath = gpath(paths.mercuryDownloads, "/", packageFileName)
        -- Check if file was already downloaded, helps with crash recovery and cache
        if not exists(outputPath) then
            local result, code, headers, status = fdownload.get(packageUrl, outputPath)
            return code, outputPath
        end
        return 200, outputPath
    end
    return false
end

function download.url(url, outputPath)
    local result, code, headers, status = fdownload.get(url, outputPath)
    return code
end

return download
