------------------------------------------------------------------------------
-- Insert
-- Sledmine
-- Insert all the files from a Mercury Package into the game
------------------------------------------------------------------------------
local json = require "cjson"
local glue = require "glue"
local path = require "path"

local unpack = require "actions.unpack"
local download = require "actions.download"

local PackageMercury = require "entities.packageMercury"

local descriptions = {
    eraseFileError = "Error, at trying to erase some files.",
    backupCreationError = "Error, at trying to create some backup files.",
    installationError = "Error, at trying to install a package.",
    updateError = "Error, at trying to update a file.",
    depedencyError = "Error, at trying to install a package dependency.",
    mercFileDoesNotExist = "Error, mercury local package does not exist."
}

-- Install any mercury package
local function insert(mercPath, forceInstallation, noBackups)
    local mercPath, mercName = splitPath(mercPath)
    local mercFullPath = mercPath .. "\\" .. mercName .. _MERC_EXTENSION
    if (exist(mercFullPath)) then
        -- Unpack merc file
        dprint("Trying to unpack '" .. mercName .. ".merc' ...")
        local unpackPath = _MERCURY_DEPACKED .. "\\" .. mercName
        if (not exist(unpackPath)) then
            dprint("Creating folder: " .. unpackPath)
            createFolder(unpackPath)
        end
        local depackageResult = unpack(mercFullPath, unpackPath)
        if (depackageResult) then
            -- Load package manifest data
            local manifestJson = glue.readfile(unpackPath .. "\\manifest.json")
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

            -- Insert new files into the game
            if (mercuryPackage.files) then
                cprint("Installing " .. mercName .. " files...")
                for file, filePath in pairs(mercuryPackage.files) do
                    -- File path from mercury unpack path
                    local inputFile = unpackPath .. "\\" .. file
                    -- File path for insertion
                    local outputFile = filePath .. file

                    dprint("Inserting file '" .. file .. "' ...")
                    dprint("Output: '" .. outputFile .. "' ...")

                    -- Create folder for current file
                    if (not exist(filePath)) then
                        dprint("Creating folder: " .. filePath)
                        createFolder(filePath)
                    end

                    if (exist(outputFile)) then
                        if (forceInstallation) then
                            cprint("Warning, Forced mode enabled, erasing conflicting files...",
                                   true)
                            local result, desc, error = delete(outputFile)
                            if (result) then
                                dprint("Deleted : '" .. file .. "'")
                                cprint("done.")
                            else
                                cprint("Error, at trying to erase file: '" .. file .. "'")
                                return false, descriptions.eraseFileError
                            end
                        elseif (not noBackus) then
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

                    -- Copy file into game folder
                    if (copyFile(inputFile, outputFile)) then
                        dprint("File succesfully installed.")
                        dprint(outputFile)
                    else
                        cprint("Error, at trying to install file: '" .. file .. "'")
                        return false, descriptions.installationError
                    end
                end
            end

            -- Apply updates to files if available
            if (mercuryPackage.updates) then
                for file, filePath in pairs(mercuryPackage.updates) do
                    cprint("Updating " .. file .. " ... ", true)
                    -- File update from mercury unpack path
                    local xD3FilePath = unpackPath .. "\\" .. file .. ".xd3"
                    -- File path for insertion
                    local sourceFilePath = filePath .. file
                    -- File path for temp updated file
                    local updatedFilePath = sourceFilePath .. ".updated"
                    local xDelta3Cmd = "xdelta3 -d -s \"%s\" \"%s\" \"%s\""
                    -- Update file using xdelta3
                    dprint("xD3FilePath: " .. xD3FilePath)
                    dprint("sourceFilePath: " .. sourceFilePath)
                    dprint("updatedFilePath: " .. updatedFilePath)
                    dprint(xDelta3Cmd:format(xD3FilePath, sourceFilePath, updatedFilePath))
                    local xD3Result = os.execute(xDelta3Cmd:format(sourceFilePath, xD3FilePath,
                                                                   updatedFilePath))
                    dprint("updatedFilePath: " .. updatedFilePath)
                    if (exist(updatedFilePath)) then
                        -- //TODO Add validation for these operations
                        -- Rename updated file to source file
                        move(sourceFilePath, sourceFilePath .. ".old")
                        move(updatedFilePath, sourceFilePath)
                        delete(sourceFilePath .. ".old")
                        cprint("done.")
                    else
                        cprint("Error, at updating '" .. file .. "'")
                        return false, descriptions.updateError
                    end
                end
            end

            -- Get current instance packages
            local installedPackages = environment.packages() or {}
            -- Substract required package properties and store them
            if (mercuryPackage.updates) then
                -- //TODO Check out this, there are probably better ways to do this
                local updateProperties = mercuryPackage:getProperties()
                updateProperties.updates = mercuryPackage.updates
                ---@type packageMercuryJson
                local oldProperties = installedPackages[mercuryPackage.label]
                glue.merge(oldProperties.files, updateProperties.updates)
                updateProperties.updates = nil
                installedPackages[mercuryPackage.label] = glue.update(oldProperties, updateProperties)
            else
                installedPackages[mercuryPackage.label] = mercuryPackage:getProperties()
            end
            -- Update current environment packages data with the new one
            environment.packages(installedPackages)
            return true
        end
    end
    dprint("Error, " .. mercFullPath .. " does not exist.")
    return false, descriptions.mercFileDoesNotExist
end

return insert
