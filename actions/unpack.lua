------------------------------------------------------------------------------
-- API consumer tests
-- Sledmine
-- Tests for api consumer
------------------------------------------------------------------------------

local zip = require "minizip"
local glue = require "glue"

--- Unpack a merc package
---@param mercFilePath string
---@param outputPath string
---@return boolean result
local function unpack(mercFilePath, outputPath)
    local dir, fileName, ext = splitPath(mercFilePath)
    dprint("Unpacking " .. fileName .. "...")
    dprint("mercFile: " .. mercFilePath)
    dprint("outputPath: " .. outputPath)
    mercZip = zip.open(mercFilePath, "r")

    -- Set current file as first file
    mercZip:first_file()

    -- Quantity of files in the zip
    local totalEntries = mercZip:get_global_info().entries

    local entriesCount = 0
    for i = 1, totalEntries do
        -- Store current file name
        local fileName = mercZip:get_file_info().filename
        local filePath = outputPath .. "\\" .. fileName
        if (fileName ~= "manifest.json") then
            dprint("Current entry: " .. i - 1 .. "/" .. totalEntries - 1)
            dprint("Decompressing '" .. fileName .. "'...")
        end

        -- Current entry is not a file, create a folder
        if (not isFile(fileName)) then
            dprint("Creating folder: '" .. fileName .. "'")
            createFolder(filePath)
        else
            -- Current file is indeed a file, just write it
            dprint("Current decompressed file path: " .. filePath)
            glue.writefile(filePath, mercZip:extract(fileName), "b")
        end

        -- Step into next entry/file
        entriesCount = entriesCount + 1
        mercZip:next_file()
    end

    -- Close zip file
    mercZip:close()

    -- File count equals the number of files to unpack
    if (entriesCount == totalEntries) then
        dprint("Done, " .. fileName .. " has been unpacked!")
        return true
    end
    cprint("Error, there was a problem at unpacking '" .. mercFilePath .. "'!")
    return false
end

return unpack
