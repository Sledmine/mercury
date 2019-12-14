local zip = require "minizip"

local function depackage(mercFile, outputPath)
    mercZip = zip.open(mercFile, "r")

    -- Set current file as first file
    mercZip:first_file()

    -- Store quantity of files in the zip
    local entries = mercZip:get_global_info().entries

    local fileCount = 0
    for i = 1,entries do

        -- Store current file name
        local fileName = mercZip:get_file_info().filename

        if (fileName ~= "manifest.json") then
            cprint("Current entry: " .. i .. "/" .. entries - 1)
            print("Decompressing '" .. fileName .. "'...")
        end
        
        -- Current "file" is a folder create it 
        if (not isFile(fileName)) then
            --print("Creating folder: '" .. fileName .. "'")
            createFolder(outputPath .. "\\" .. fileName)
        else
            -- Current file is indeed a file, just write it
            local file = io.open(outputPath .. "\\" .. fileName, "wb")
            file:write(mercZip:extract(fileName))
            file:close()
        end

        -- Iterate with next file
        fileCount = fileCount + 1
        mercZip:next_file()
    end

    -- Close zip file
    mercZip:close()

    local dir, file, ext = splitPath(mercFile)
    if (fileCount == entries) then
        cprint("%{green bright}Succesfully depacked '" .. file .. ".merc'!\n")
        return true
    end
    cprint("%{red bright}\nERROR!!!: %{reset}An error ocurred at depacking '" .. mercFile .."'...\n")
    return false
end

return depackage