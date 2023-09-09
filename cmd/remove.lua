------------------------------------------------------------------------------
-- Remove action
-- Authors: Sledmine
-- Remove any mercury package
------------------------------------------------------------------------------
local json = require "cjson"
local glue = require "glue"

local PackageMercury = require "entities.packageMercury"

local search = require "cmd.search"

local errors = {
    indexErasement = "an error occurred at erasing package from the index",
    packageNotInstalled = "specified package is not installed",
    fileSystemError = "an error occurred at trying to erase files from the system"
}

--  TODO Migrate the return of this action to an errors table
local function erasePackageFromIndex(packageLabel)
    -- Get current instance packages
    local installedPackages = config.packages()
    if installedPackages then
        -- Erase data for this package
        installedPackages[packageLabel] = nil
        -- Update current environment packages data with the new one
        return config.packages(installedPackages)
    end
    return false
end

--- Remove/uninstall a package from the game
---@param packageLabel string Label of the package to remove
---@param noRestore? boolean Do not restore previous backup files
---@param eraseBackups? boolean Erase previous backup files
---@param recursive? boolean Erase all the dependencies of this package
---@param index? boolean Forced remove by erasing the package entry from the packages index
---@param keepOptionals? boolean Keep optional files
local function remove(packageLabel, noRestore, eraseBackups, recursive, index, keepOptionals)
    if search(packageLabel) then
        local installedPackages = config.packages() or {}
        cprint("Removing package " .. packageLabel .. "...")
        -- Load package as entity to provide normalization and extra package methods
        local package = PackageMercury:new(installedPackages[packageLabel])
        -- Remove dependencies recursively
        if recursive then
            -- cprint("Warning remove is in recursive mode.")
            local packageDependencies = package.dependencies
            if packageDependencies and #packageDependencies > 0 then
                for dependency in each(packageDependencies) do
                    remove(dependency.label, noRestore, eraseBackups, recursive, index,
                           keepOptionals)
                end
            end
        end
        if index then
            if erasePackageFromIndex(packageLabel) then
                cprint("Done package " .. packageLabel .. " has been forced removed by entry.")
                return true
            else
                cprint("Error at trying to remove package from index")
                return false, errors.indexErasement
            end
        end
        -- Normal remove, search for package files and erase them
        for fileIndex, file in pairs(package.files) do
            if keepOptionals and file.type == "optional" then
                goto continue
            end
            -- Path to the existing file to erase
            local finalFilePath = file.outputPath

            -- Start erasing proccess
            dprint("Erasing \"" .. finalFilePath .. "\"... ")
            local result, description, errorCode = delete(finalFilePath)
            if result then
                dprint("Done file erased.")
                if exists(finalFilePath .. ".bak") then
                    if eraseBackups then
                        cprint("Erasing backup for \"" .. file.path .. "\"... ", true)
                        local backupFilePath = finalFilePath .. ".bak"
                        delete(backupFilePath)
                        if (exists(backupFilePath)) then
                            cprint("Error at deleting backup for \"" .. backupFilePath .. "\"")
                        else
                            cprint("done.")
                        end
                    end
                    if not eraseBackups and not noRestore then
                        cprint("Restoring backup for \"" .. file.path .. "\"... ", true)
                        move(finalFilePath .. ".bak", finalFilePath)
                        if (exists(finalFilePath)) then
                            cprint("done.")
                        else
                            cprint("Error at restore backup for \"" .. finalFilePath .. "\"")
                        end
                    end
                end
            else
                -- TODO Find info for these codes, those are related with the fs
                if errorCode == 2 or errorCode == 3 then
                    cprint("Warning \"" .. file.path ..
                               "\" was not found, previously erased or moved")
                else
                    cprint("Error, at trying to erase \"" .. file.path .. "\"")
                    cprint("Reason, " .. description .. " aborting removal now.")
                    cprint("Try forced remove instead!")
                    return false, errors.fileSystemError
                end
            end
            ::continue::
        end
        if erasePackageFromIndex(packageLabel) then
            return true
        else
            cprint("Error, at trying to erase package from index.")
            return false, errors.indexErasement
        end
    end
    cprint("Warning package \"" .. packageLabel .. "\" is not installed.")
    return false, errors.packageNotInstalled
end

return remove
