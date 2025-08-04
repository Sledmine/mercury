------------------------------------------------------------------------------
-- Download action
-- Sledmine
-- Download any package file
------------------------------------------------------------------------------
local download = {}

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
        dprint("Download path: " .. outputPath)

        local request = curl.download(packageUrl, outputPath)
        return request.statusCode, outputPath
    end
    return false
end

---@param url string
---@param outputPath string
function download.url(url, outputPath)
    local request = curl.download(url, outputPath)
    return request.statusCode
end

return download
