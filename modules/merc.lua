------------------------------------------------------------------------------
-- Merc module
-- Sledmine
-- Different methods to handle merc packages
------------------------------------------------------------------------------
local merc = {}

-- TODO Add unit testing for this module

-- TODO Migrate this to minizip2
local minizip = require "minizip"
local minizip2 = require "minizip2"
local glue = require "glue"

--- Unpack a merc package
---@param mercPath string Path to the merc package that will be unpacked
---@param unpackDir string Path of the output files unpacked from the merc package
---@return boolean result
function merc.unpack(mercPath, unpackDir)
    local dir, fileName, ext = splitPath(mercPath)
    dprint("Unpacking: " .. mercPath .. "...")
    dprint("To Dir: " .. unpackDir)
    local packageZip = minizip.open(mercPath, "r")

    -- Set current file as first file
    packageZip:first_file()

    -- Quantity of files in the zip
    local totalEntries = packageZip:get_global_info().entries

    local entriesCount = 0

    -- Iterate over all entries
    for entryIndex = 1, totalEntries do
        -- Store current file name
        local fileName = packageZip:get_file_info().filename
        local filePath = gpath(unpackDir, "/", fileName)

        -- Ignore manifest.json entry file and process all the other entries
        if (fileName ~= "manifest.json") then
            dprint("Entry: " .. entryIndex - 1 .. " / " .. totalEntries - 1)
            dprint("Decompressing \"" .. fileName .. "\"...")
        end

        -- Current entry is not a file, create a folder
        if (not isFile(fileName)) then
            dprint("Creating folder: '" .. fileName .. "'")
            createFolder(filePath)
        else
            -- Current file is indeed a file, just write it
            dprint("Decompressing path " .. filePath)
            glue.writefile(filePath, packageZip:extract(fileName), "b")
        end

        -- Step into next entry
        entriesCount = entriesCount + 1
        packageZip:next_file()
    end

    -- Close zip file
    packageZip:close()

    -- File count equals the number of files to unpack
    if (entriesCount >= totalEntries) then
        dprint("Done, " .. fileName .. " has been unpacked!")
        return true
    end
    cprint("Error, there was a problem at unpacking \"" .. mercPath .. "\".")
    return false
end


function merc.pack(packDir, mercPath)
    if (packDir and mercPath) then
        local packageZip = minizip2.open(mercPath, "w")
        if (packageZip) then
            packageZip:add_all(packDir)
            packageZip:close()

            return true
        end
    end
    return false
end

return merc
