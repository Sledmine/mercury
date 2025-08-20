------------------------------------------------------------------------------
-- Download action
-- Sledmine
-- Download any package file
------------------------------------------------------------------------------
local download = {}
local constants = require "modules.constants"

local paths = config.paths()

---@param meta packageMetadata
function download.package(meta)
    local code = 404
    local downloadOutput
    for _, packageUrl in pairs(meta.mirrors) do
        local urlSplit = packageUrl:split "/"
        local packageFileName = urlSplit[#urlSplit]
        local outputPath = gpath(paths.mercuryDownloads, "/", packageFileName)

        -- Check if file was already downloaded, helps with crash recovery and cache
        if exists(outputPath) and meta.checksum == MD5(outputPath) then
            return 200, outputPath
        end
        dprint("Download path: " .. outputPath)

        local request = curl.head {
            url = packageUrl,
            allowRedirects = true,
            headers = {
                ["User-Agent"] = "Mercury/" .. constants.mercuryVersion,
            }
        }
        if not request.ok then
            cprint("Warning " .. packageUrl .. " failed, trying next mirror...")
            goto continue
        end

        local request = curl.download {
            url = packageUrl,
            output = outputPath,
            allowRedirects = true,
            headers = {
                ["User-Agent"] = "Mercury/" .. constants.mercuryVersion,
            }
        }
        if request.ok then
            code = request.statusCode
            downloadOutput = outputPath
            break
        end
        ::continue::
    end
    return code, downloadOutput
end

---@param url string
---@param outputPath string
function download.url(url, outputPath)
    local request = curl.download {
        url = url,
        output = outputPath,
        allowRedirects = true,
        headers = {
            ["User-Agent"] = "Mercury/" .. constants.mercuryVersion,
        }
    }
    return request.statusCode
end

return download
