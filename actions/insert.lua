------------------------------------------------------------------------------
-- Insert
-- Sledmine
-- Insert all the files from a Mercury Package into the game
------------------------------------------------------------------------------
local json = require "cjson"
local glue = require "glue"
local path = require "path"

local depackage = require "Mercury.actions.unpack"
local download = require "Mercury.actions.download"

local PackageMercury = require "Mercury.entities.packageMercury"

local descriptions = {
    eraseFileError = "Error, at trying to erase some files.",
    backupCreationError = "Error, at trying to create some backup files.",
    installationError = "Error, at trying to install a package.",
    depedencyError = "Error, at trying to install a package dependency.",
    mercFileDoesNotExist = "Error, mercury local package does not exist."
}

-- Install any mercury package
local function insert(mercPath, forceInstallation, noBackups)
    local mercPath, mercName, mercExtension = splitPath(mercPath)
    local mercFullPath = mercPath .. "\\" .. mercName .. _MERC_EXTENSION
    if (fileExist(mercFullPath)) then
        -- Depackage specified merc file
        dprint("Trying to depackage '" .. mercName .. ".merc' ...")
        local depackageFolderPath = _MERCURY_DEPACKED .. "\\" .. mercName
        if (not folderExist(depackageFolderPath)) then
            dprint("Creating folder: " .. depackageFolderPath)
            createFolder(depackageFolderPath)
        end
        local depackageResult = depackage(mercFullPath, depackageFolderPath)
        if (depackageResult) then
            -- Load package manifest data
            local manifestJson = fileToString(depackageFolderPath .. "\\manifest.json")
            ---@type packageMercury
            local mercuryPackage = PackageMercury:new(manifestJson)
            -- Get other package dependencies
            if (mercuryPackage.dependencies) then
                cprint("Getting package dependencies...")
                for dependencyIndex, dependency in pairs(mercuryPackage.dependencies) do
                    local downloadResult, description, mercPath =
                        download(dependency.label, dependency.version)
                    if (downloadResult) then
                        -- Recursive dependency installation
                        insert(mercPath, forceInstallation, noBackups)
                    else
                        return false, descriptions.depedencyError
                    end
                end
            end
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
                        cprint("Warning, Forced mode enabled, erasing conflicting files...", true)
                        local result, desc, error = deleteFile(outputFile)
                        if (result) then
                            dprint("Deleted : '" .. file .. "'")
                            cprint("done.")
                        else
                            cprint("Error, at trying to erase file: '" .. file .. "'")
                            return false, descriptions.eraseFileError
                        end
                    elseif (not noBackups) then
                        cprint("Warning, conflicting file found, creating backup...", true)
                        local result, desc, error = move(outputFile, outputFile .. ".bak")
                        if (result) then
                            cprint("done.")
                            cprint("Backup created for '" .. file .. "'")
                        else
                            cprint("Error, at trying to create a backup for: '" .. file .. "")
                            return false, descriptions.backupCreationError
                        end
                    end
                end
                if (copyFile(depackageFolderPath .. "\\" .. file, outputFile) == true) then
                    dprint("File succesfully installed.")
                    dprint(outputFile)
                else
                    cprint("Error, at trying to install file: '" .. file .. "'")
                    return false, descriptions.installationError
                end
            end
            local installedPackages = environment.packages()
            if (not installedPackages) then
                installedPackages = {}
            end
            -- Substract required package properties and store them
            installedPackages[mercuryPackage.label] = mercuryPackage:getProperties()
            -- Update current environment packages data with the new one
            environment.packages(installedPackages)
            return true
        end
    end
    dprint("Error, " .. mercFullPath .. " does not exist.")
    return false, descriptions.mercFileDoesNotExist
end

return insert
