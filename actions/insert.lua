local json = require 'cjson'
local path = require 'path'

local depackage = require 'Mercury.actions.depackage'

-- Install any mercury package
local function insert(mercPath, noBackups)
    local mercPath, mercName, mercExtension = splitPath(mercPath)
    local mercFullName = mercPath .. '\\' .. mercName .. _MERC_EXTENSION
    if (fileExist(mercFullName)) then
        -- Depackage specified merc file
        dprint("Trying to depackage '" .. mercName .. ".merc' ...\n")
        local depackageFolder = _MERCURY_DEPACKED .. '\\' .. mercName
        createFolder(depackageFolder)
        if (depackage(mercFullName, depackageFolder)) then
            -- Load package manifest data
            local mercManifest = json.decode(fileToString(depackageFolder .. '\\manifest.json'))
            cprint('Installing package files... \n')
            for file, path in pairs(mercManifest.files) do
                -- Replace environment variables
                local replacedHaloPath = string.gsub(path, '_HALOCE', _HALOCE, 1)
                local replacedMyGamesPath = string.gsub(replacedHaloPath, '_MYGAMES', _MYGAMES, 1)
                local outputPath = replacedMyGamesPath
                local outputFile = outputPath .. file
                cprint("Installing '" .. file .. "' ...")
                dprint("Output: '" .. outputPath .. file .. "' ...")
                -- Current file is a folder
                if (not folderExist(outputPath)) then
                    dprint('Creating folder: ' .. outputPath)
                    createFolder(outputPath)
                end
                if (fileExist(outputFile) and not noBackups) then
                    cprint(
                        'WARNING!!!: There is an existing file with the same name, renaming it to .bak for restoring purposes.'
                    )
                    local result, desc, error = move(outputPath .. file, outputPath .. file .. '.bak')
                    if (result) then
                        print("Succesfully created backup for: '" .. file .. "'")
                    else
                        cprint(
                            "\nERROR!!!: Error at trying to create a backup for: '" ..
                                file .. "' aborting installation now!!!"
                        )
                        cprint(
                            "\n\nERROR!!!: '" ..
                                mercName .. ".merc' installation encountered one or more problems!!"
                        )
                        return false
                    end
                elseif (fileExist(outputFile) and noBackups) then
                    cprint(
                        'FORCED MODE: Found file with the same name, erasing it for compatibilty purposes.'
                    )
                    local result, desc, error = deleteFile(outputPath .. file)
                    if (result) then
                        cprint("OK!!!: Succesfully deleted: '" .. file .. "'")
                    else
                        cprint(
                            "\nERROR!!!: Error at trying to erase file: '" ..
                                file .. "', reason: '" .. desc .. "' aborting installation now!!!"
                        )
                        cprint(
                            "\n'ERROR!!!: " ..
                                mercName .. ".merc' installation encountered one or more problems!!"
                        )
                        return false
                    end
                end
                if (copyFile(depackageFolder .. '\\' .. file, outputPath .. file) == true) then
                    print('File succesfully installed.\n')
                else
                    print("Error at trying to install file: '" .. file .. "' aborting installation now!!!")
                    print(
                        "\n'ERROR: " ..
                            mercName .. ".merc' installation encountered one or more problems, aborting now!!"
                    )
                    return false
                end
            end
            local installedPackages
            if (fileExist(_HALOCE_INSTALLED_PACKAGES)) then
                installedPackages = json.decode(fileToString(_HALOCE_INSTALLED_PACKAGES))
            else
                createFolder(_MERCURY_INSTALLED)
                installedPackages = {}
            end
            installedPackages[mercManifest.label] = mercManifest
            stringToFile(_HALOCE_INSTALLED_PACKAGES, json.encode(installedPackages))
            cprint("DONE!!: Package '" .. mercName .. ".merc' has been added to the game!!")
            return true
        end
    else
        print("\nSpecified .merc package doesn't exist. (" .. mercFullName .. ')')
    end
    return false
end

return insert
