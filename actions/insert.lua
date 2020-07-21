local json = require "cjson"
local glue = require "glue"
local path = require "path"

local depackage = require "Mercury.actions.unpack"

local PackageMercury = require "Mercury.entities.packageMercury"

local DESCRIPTIONS = {
    ERASE_FILE_ERROR = "Error, at trying to erase some files.",
    BACKUP_CREATING_ERROR = "Error, at trying to create some backup files.",
    INSTALLATION_ERROR = "Error, at trying to install a package.",
    MERC_NOT_EXIST = "Error, mercury local package does not exist.",
}

-- Install any mercury package
local function insert(mercPath, forceInstallation, noBackups)
    local mercPath, mercName, mercExtension = splitPath(mercPath)
    local mercFullName = mercPath .. "\\" .. mercName .. _MERC_EXTENSION
    if (fileExist(mercFullName)) then
        -- Depackage specified merc file
        dprint("Trying to depackage '" .. mercName .. ".merc' ...")
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
            cprint("Installing " .. mercName .. "...")
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
                        cprint("Warning, Forced mode enabled, erasing conflicting files..")
                        local result, desc, error = deleteFile(outputFile)
                        if (result) then
                            cprint("Deleted : '" .. file .. "'")
                        else
                            cprint("Error, at trying to erase file: '" .. file .. "'")
                            return false, DESCRIPTIONS.ERASE_FILE_ERROR
                        end
                    end
                    if (not noBackups) then
                        cprint("Warning, There are conflicting files, creating a backup...")
                        local result, desc, error = move(outputFile, outputFile .. ".bak")
                        if (result) then
                            print("Backup created for '" .. file .. "'")
                        else
                            cprint("Error, at trying to create a backup for: '" .. file .. "")
                            return false, DESCRIPTIONS.BACKUP_CREATING_ERROR
                        end
                    end
                end
                if (copyFile(depackageFolder .. "\\" .. file, outputFile) == true) then
                    dprint("File succesfully installed.")
                    dprint(outputFile)
                else
                    cprint("Error, at trying to install file: '" .. file .. "'")
                    return false, DESCRIPTIONS.INSTALLATION_ERROR
                end
            end
            local installedPackages = environment.packages()
            if (not installedPackages) then
                installedPackages = {}
            end
            -- Substract required package properties and install them
            local packageProperties = mercuryPackage:getProperties()
            installedPackages[mercuryPackage.label] = packageProperties
            -- Create a json string from installed packages
            environment.packages(installedPackages)
            return true
        end
    end
    dprint("Error, " .. mercFullName .. " does not exist.")
    return false, DESCRIPTIONS.MERC_NOT_EXIST
end

return insert
