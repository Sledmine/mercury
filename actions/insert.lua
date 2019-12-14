local json = require "cjson"
local path = require "path"

local depackage = require "Mercury.actions.depackage"

-- Install any mercury package
local function insert(mercPath, noBackups)
    local mercPath, mercName, mercExtension = splitPath(mercPath)
    local mercFullName = mercPath .. "\\" .. mercName .. _MERC_EXTENSION
    if (fileExist(mercFullName)) then
        -- Depackage specified merc file
        cprint("%{yellow bright}Trying to depackage '" .. mercName .. ".merc' ...\n")
        local depackageFolder = _MERCURY_DEPACKED .. "\\" .. mercName
        createFolder(depackageFolder)
        if (depackage(mercFullName, depackageFolder)) then
            -- Load package manifest data
            local mercManifest = json.decode(fileToString(depackageFolder .. "\\manifest.json"))
            -- Get package name, TODO THIS THING NEEDS SOME KIND OF REIMPLEMENTATION NOWWWWWW!!!
            for k,v in pairs(mercManifest) do
                packageLabel = k
            end
            print("Dispatching package files .. \n")
            for file, path in pairs(mercManifest[packageLabel].files) do
                -- Replace environment variables
                local replacedHaloPath = string.gsub(path, "_HALOCE", _HALOCE, 1)
                local replacedMyGamesPath = string.gsub(replacedHaloPath, "_MYGAMES", _MYGAMES, 1)
                local outputPath = replacedMyGamesPath
                local outputFile = outputPath .. file
                cprint("Installing '" .. file .. "' .. .")
                cprint("Output: '" .. outputPath .. file .. "' .. .")
                -- Current file is a folder
                if (not folderExist(outputPath)) then
                    cprint("%{yellow bright}Creating folder: " .. outputPath)
                    createFolder(outputPath)
                end
                if (fileExist(outputFile) and not noBackups) then
                    cprint("%{yellow bright}WARNING!!!: %{reset}There is an existing file with the same name, renaming it to .bak for restoring purposes.")
                    local result, desc, error = move(outputPath .. file, outputPath .. file .. ".bak")
                    if (result) then
                        print("Succesfully created backup for: '" .. file .. "'")
                    else
                        cprint("%{red bright}\nERROR!!!: %{reset}Error at trying to create a backup for: '" .. file .. "' aborting installation now!!!")
                        cprint("\n%{red bright}\nERROR!!!: %{reset}'"  .. mercName .. ".merc' installation encountered one or more problems!!")
                        return false
                    end
                elseif (fileExist(outputFile) and noBackups) then
                    cprint("%{red bright}FORCED MODE: %{reset}Found file with the same name, erasing it for compatibilty purposes.")
                    local result, desc, error = deleteFile(outputPath .. file)
                    if (result) then
                        cprint("%{green bright}OK!!!: %{reset}Succesfully deleted: '" .. file .. "'")
                    else
                        cprint("%{red bright}\nERROR!!!: %{reset}Error at trying to erase file: '" .. file .. "', reason: '" .. desc ..  "' aborting installation now!!!")
                        cprint("\n'%{red bright}ERROR!!!: %{reset}" .. mercName .. ".merc' installation encountered one or more problems!!")
                        return false
                    end
                end
                if (copyFile(depackageFolder .. "\\" .. file, outputPath .. file) == true) then
                    print("File succesfully installed.\n")
                else
                    print("Error at trying to install file: '" .. file .. "' aborting installation now!!!")
                    print("\n'ERROR: " .. mercName .. ".merc' installation encountered one or more problems, aborting now!!")
                    return false
                end
            end
            cprint("%{green bright}DONE!!!: %{reset}Package '" .. mercName .. ".merc' succesfully installed!!")
            return true
        end
    else
        print("\nSpecified .merc package doesn't exist. (" .. mercFullName .. ")")
    end
    return false
end

return insert