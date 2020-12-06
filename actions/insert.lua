------------------------------------------------------------------------------
-- Insert
-- Sledmine
-- Insert all the files from a Mercury Package into the game
------------------------------------------------------------------------------
local json = require "cjson"
local glue = require "glue"
local path = require "path"

local unpack = require "actions.unpack"
local search = require "actions.search"

local PackageMercury = require "entities.packageMercury"

local errorTable = {
    eraseFileError = "an error ocurred at erasing some files",
    backupCreationError = "an error ocurred at creating a backup file",
    installationError = "at trying to install a package",
    updateError = "at trying to update a file",
    depedencyError = "at trying to install a package dependency",
    mercFileDoesNotExist = "mercury local package does not exist"
}

-- Install any mercury package
local function insert(mercPath, forced, noPurge)
    local _, mercFilename = splitPath(mercPath)
    if (exist(mercPath)) then
        -- Unpack merc file
        dprint("Trying to unpack '" .. mercFilename .. ".merc' ...")
        local unpackPath = MERCURY_DEPACKED .. "\\" .. mercFilename
        if (not exist(unpackPath)) then
            dprint("Creating folder: " .. unpackPath)
            createFolder(unpackPath)
        end
        local unpackResult = unpack(mercPath, unpackPath)
        if (unpackResult) then
            -- Load package manifest data
            local manifestJson = glue.readfile(unpackPath .. "\\manifest.json")
            ---@type packageMercury
            local mercuryPackage = PackageMercury:new(manifestJson)

            -- Get other package dependencies
            if (mercuryPackage.dependencies) then
                cprint("Checking for package dependencies...")
                -- // TODO Some version lookup should be done here for dependencies, not being forced
                for dependencyIndex, dependency in pairs(mercuryPackage.dependencies) do
                    local existingDependency = search(dependency.label)
                    if (existingDependency) then
                        if (existingDependency.version ~= dependency.version) then
                            local result, error = install.package(dependency.label,
                                                                  dependency.version, true)
                            if (not result) then
                                return false, errorTable.depedencyError
                            end
                        end
                    else
                        local result, error = install.package(dependency.label, dependency.version,
                                                              true, true)
                        if (not result) then
                            return false, errorTable.depedencyError
                        end
                    end
                end
            end

            -- Insert new files into the game
            if (mercuryPackage.files) then
                cprint("Inserting " .. mercFilename .. " files... ")
                for fileIndex, file in pairs(mercuryPackage.files) do
                    -- File path from mercury unpack path
                    local inputFile = unpackPath .. "\\" .. file.path
                    -- File path for insertion
                    local outputFile = file.outputPath .. file.path
                    local outputFilePath = splitPath(outputFile)

                    -- Create folder for current file
                    if (not exist(outputFilePath)) then
                        createFolder(outputFilePath)
                    end

                    dprint("Inserting file \"" .. file.path .. "\" ...")
                    dprint("Output: \"" .. outputFile .. "\" ...")

                    if (exist(outputFile)) then
                        if (forced) then
                            cprint("Warning, Forced mode was enabled, erasing conflict file: \"" ..
                                       file.path .. "\"... ", true)
                            local result, desc, error = delete(outputFile)
                            if (result) then
                                cprint("done.")
                            else
                                cprint("Error, at trying to erase file: '" .. file.path .. "'")
                                return false, errorTable.eraseFileError
                            end
                        else
                            cprint("Warning, creating backup for conflict file: \"" .. file.path ..
                                       "\"... ", true)
                            local result, desc, error = move(outputFile, outputFile .. ".bak")
                            if (result) then
                                cprint("done.")
                            else
                                cprint("Error, at trying to create a backup for: '" .. file.path .. "")
                                return false, errorTable.backupCreationError
                            end
                        end
                    end

                    -- Copy file into game folder
                    if (copyFile(inputFile, outputFile)) then
                        dprint("File succesfully installed.")
                        dprint(outputFile)
                    else
                        cprint("Error, at trying to install file: '" .. file.path .. "'")
                        return false, errorTable.installationError
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
                        return false, errorTable.updateError
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
                installedPackages[mercuryPackage.label] =
                    glue.update(oldProperties, updateProperties)
            else
                installedPackages[mercuryPackage.label] = mercuryPackage:getProperties()
            end
            -- Update current environment packages data with the new one
            environment.packages(installedPackages)
            return true
        end
    end
    dprint("Error, " .. mercPath .. " does not exist.")
    return false, errorTable.mercFileDoesNotExist
end

return insert
