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
local json = require "cjson"
local v = require "semver"

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
    -- FIXME I'm suspectig something around here is causing a memory leak
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

--- Pack a folder into a merc package
---@param packDir string
---@param mercPath string
function merc.pack(packDir, mercPath, template, fix, feature, breaking)
    if (template) then
        local manifest = {
            label = "",
            name = "",
            description = "",
            version = "",
            author = "",
            category = ""
        }
        for property, value in pairs(manifest) do
            print("-> Set " .. property .. ":")
            local value = io.read("l")
            if (value and value ~= "") then
                manifest[property] = value
            end 
        end
        manifest.files = {}
        manifest.manifestVersion = "1.1.0"
        cprint("Success, package folder with manifest template has been created.")
        glue.writefile(packDir .. "/manifest.json", json.encode(manifest), "t")
        return true
    end
    local manifest = json.decode(glue.readfile(packDir .. "/manifest.json", "t"))
    if (packDir and mercPath and manifest) then
        cprint("Packing given directory... ", true)
        local packageZip = minizip2.open(mercPath .. "/" .. manifest.label .. "-" .. manifest.version .. ".zip", "w")
        if (packageZip) then
            packageZip:add_all(packDir)
            packageZip:close()
            cprint("done.")
            return true
        end
        cprint("Error, at creating Mercury package.")
    end
    return false
end

return merc
