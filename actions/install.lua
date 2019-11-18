
local json = require "cjson"
local path = require "path"

local depackage = require "Mercury.actions.depackage"
local download = require "Mercury.actions.download"

-- Install any mercury package
function install(mercPackage, noBackups)
    local mercPath, mercName, mercExtension = splitPath(mercPackage)
    local mercFullName = mercPath .. "\\" .. mercName .. _MERC_EXTENSION
    if (fileExist(mercFullName)) then
        -- Depackage specified merc file
        cprint("%{yellow bright}Trying to depackage '" .. mercName .. ".merc' .. .\n")
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
                    print(colors("%{yellow bright}WARNING!!!: %{reset}There is an existing file with the same name, renaming it to .bak for restoring purposes."))
                    local result, desc, error = move(outputPath .. file, outputPath .. file .. ".bak")
                    if (result) then
                        print("Succesfully created backup for: '" .. file .. "'")
                    else
                        print(colors("%{red bright}\nERROR!!!: %{reset}Error at trying to create a backup for: '" .. file .. "' aborting installation now!!!"))
                        print(colors("\n%{red bright}\nERROR!!!: %{reset}'"  .. mercName .. ".merc' installation encountered one or more problems!!"))
                        return false
                    end
                elseif(fileExist(outputFile) and noBackups) then
                    print(colors("%{red bright}FORCED MODE: %{reset}Found file with the same name, erasing it for compatibilty purposes."))
                    local result, desc, error = deleteFile(outputPath .. file)
                    if (result) then
                        print(colors("%{green bright}OK!!!: %{reset}Succesfully deleted: '" .. file .. "'"))
                    else
                        print(colors("%{red bright}\nERROR!!!: %{reset}Error at trying to erase file: '" .. file .. "', reason: '" .. desc ..  "' aborting installation now!!!"))
                        print(colors("\n'%{red bright}ERROR!!!: %{reset}" .. mercName .. ".merc' installation encountered one or more problems!!"))
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
            -- Create array for installed packages
            local installedPackages = {}
            -- There are previously installed packages
            if (fileExist(_HALOCE_INSTALLED_PACKAGES)) then
                installedPackages = json.decode(fileToString(_HALOCE_INSTALLED_PACKAGES))
            end
            installedPackages[packageLabel] = mercManifest[packageLabel]
            stringToFile(_HALOCE_INSTALLED_PACKAGES, json.encode(installedPackages))
            if (mercManifest[packageLabel].dependencies) then
                print("Fetching required dependencies .. .\n")
                for i,dependecyPackage in pairs(mercManifest[packageLabel].dependencies) do
                    download(dependecyPackage)
                end
            end
            print(colors("%{green bright}DONE!!!: %{reset}Package '" .. mercName .. ".merc' succesfully installed!!"))
            return true
        end
    else
        print("\nSpecified .merc package doesn't exist. (" .. mercFullName .. ")")
    end
    return false
end

return install