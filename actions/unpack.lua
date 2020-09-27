local zip = require "minizip"
local glue = require "glue"

--- Unpack a merc package
---@param mercFile string
---@param outputPath string
---@return boolean result
local function unpack(mercFile, outputPath)
    local dir, file, ext = splitPath(mercFile)
    dprint("Unpacking " .. file .. "...")
    dprint("mercFile: " .. mercFile .. "outputPath: " .. outputPath)
    mercZip = zip.open(mercFile, "r")

    -- Set current file as first file
    mercZip:first_file()

    -- Quantity of files in the zip
    local entries = mercZip:get_global_info().entries

    local fileCount = 0
    for i = 1, entries do
        -- Store current file name
        local fileName = mercZip:get_file_info().filename
        local filePath = outputPath .. '\\' .. fileName
        if (fileName ~= "manifest.json") then
            dprint("Current entry: " .. i - 1 .. "/" .. entries - 1)
            dprint("Decompressing '" .. fileName .. "'...")
        end

        -- Current "file" is a folder create it
        if (not isFile(fileName)) then
            dprint("Creating folder: '" .. fileName .. "'")
            createFolder(filePath)
        else
            -- Current file is indeed a file, just write it
            dprint("Current decompressed file path: " .. filePath)
            glue.writefile(filePath, mercZip:extract(fileName), "b")
            --[[
            local file = io.open(filePath, 'wb')
            file:write(mercZip:extract(fileName))
            file:close()
            ]]
        end

        -- Step into another file
        fileCount = fileCount + 1
        mercZip:next_file()
    end

    -- Close zip file
    mercZip:close()

    -- File count equals the number of files to unpack
    if (fileCount == entries) then
        dprint("Done, " .. file .. " has been unpacked!")
        return true
    end
    cprint("Error, there was a problem at unpacking '" .. mercFile .. "'!")
    return false
end

return unpack
