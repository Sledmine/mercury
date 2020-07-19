local json = require "cjson"
local glue = require "glue"
local path = require "path"

local depackage = require "Mercury.actions.unpack"

local PackageMercury = require "Mercury.entities.packageMercury"

-- Install any mercury package
local function insert(mercPath, forceInstallation, noBackups)
    local mercPath, mercName, mercExtension = splitPath(mercPath)
    local mercFullName = mercPath .. "\\" .. mercName .. _MERC_EXTENSION
    if (fileExist(mercFullName)) then
        -- Depackage specified merc file
        dprint("Trying to depackage '" .. mercName .. ".merc' ...\n")
        local depackageFolder = _MERCURY_DEPACKED .. "\\" .. mercName
        if (not folderExist(depackageFolder)) then
            dprint("Creating folder: " .. depackageFolder)
            createFolder(depackageFolder)
        end
        local depackageResult = depackage(mercFullName, depackageFolder)
        if (depackageResult) then
            -- Load package manifest data
            local manifestJson = fileToString(depackageFolder .. "\\manifest.json")
            ---@type packageMercury
            local mercuryPackage = PackageMercury:new(manifestJson)
            cprint(mercName .. " is being installed...\n")
            for file, path in pairs(mercuryPackage.files) do
                -- Replace environment variables
                local outputPath = path
                local outputFile = outputPath .. file
                dprint("Installing '" .. file .. "' ...")
                dprint("Output: '" .. outputFile .. "' ...")
                -- Current file is a folder
                if (not folderExist(outputPath)) then
                    dprint("Creating folder: " .. outputPath)
                    createFolder(outputPath)
                end
                if (fileExist(outputFile)) then
                    if (forceInstallation) then
                        cprint("WARNING: Forced mode enabled, erasing conflicting files..")
                        local result, desc, error = deleteFile(outputFile)
                        if (result) then
                            cprint("Deleted : '" .. file .. "'\n")
                        else
                            cprint("Error at trying to erase file: '" .. file .. "'\n")
                            return false
                        end
                    end
                    if (not noBackups) then
                        cprint("WARNING: There are conflicting files, creating a backup...")
                        local result, desc, error = move(outputFile, outputFile .. ".bak")
                        if (result) then
                            print("Backup created for '" .. file .. "'\n")
                        else
                            cprint("Error at trying to create a backup for: '" .. file .. "\n")
                            return false
                        end
                    end
                end
                if (copyFile(depackageFolder .. "\\" .. file, outputFile) == true) then
                    dprint("File succesfully installed.")
                    dprint(outputFile)
                else
                    print("Error at trying to install file: '" .. file .. "'")
                    print(mercName .. ".merc' installation encountered one or more problems, aborting now!!")
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
            -- Substract required package properties and install them
            installedPackages[mercuryPackage.package] = mercuryPackage:getProperties()
            local installedPackagesJson = json.encode(installedPackages)
            glue.writefile(_HALOCE_INSTALLED_PACKAGES, installedPackagesJson, "t")
            return true
        end
    else
        print("Specified .merc package doesn't exist. (" .. mercFullName .. ")")
    end
    return false
end

return insert
