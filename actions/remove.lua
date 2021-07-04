------------------------------------------------------------------------------
-- Remove action
-- Authors: Sledmine
-- Remove any mercury package
------------------------------------------------------------------------------
local json = require "cjson"
local glue = require "glue"

local search = require "Mercury.actions.search"

--  TODO Migrate the return of this action to an errors table

local function erasePackageFromIndex(packageLabel)
    -- Get current instance packages
    local installedPackages = environment.packages()
    if (installedPackages) then
        -- Erase data for this package
        installedPackages[packageLabel] = nil
        -- Update current environment packages data with the new one
        environment.packages(installedPackages)
    end
end

--- Remove/uninstall a package from the game
---@param packageLabel string Label of the package to remove
---@param noRestore boolean Do not restore previous backup files
---@param eraseBackups boolean Erase previous backup files
---@param recursive boolean Erase all the dependencies of this package
---@param forced boolean Forced remove by erasing the package entry from the packages index
local function remove(packageLabel, noRestore, eraseBackups, recursive, forced)
    if (search(packageLabel)) then
        local installedPackages = environment.packages()
        cprint("Removing package \"" .. packageLabel .. "\"...")
        local packageMercury = installedPackages[packageLabel]
        -- Remove dependencies recursively
        if (recursive) then
            cprint("Warning, remove is in recursive mode.")
            local packageDependencies = packageMercury.dependencies
            if (packageDependencies and #packageDependencies > 0) then
                for dependency in each(packageDependencies) do
                    remove(dependency.label, noRestore, eraseBackups, recursive, forced)
                end
            end
        end
        if (forced) then
            erasePackageFromIndex(packageLabel)
            cprint("Done, package '" .. packageLabel .. "' has been forced removed by entry.")
            return true
        end
        for fileIndex, file in pairs(packageMercury.files) do
            local filePath = file.outputPath .. file.path
            -- Start erasing proccess
            dprint("Erasing \"" .. file.path .. "\"... ", true)
            local result, description, errorCode = delete(filePath)
            if (result) then
                dprint("Done, file erased.")
                if (exist(filePath .. ".bak") and not noRestore) then
                    if (not noRestore) then
                        cprint("Warning, restoring \"" .. file.path .. "\" backup file... ", true)
                        move(filePath .. ".bak", filePath)
                        if (exist(filePath)) then
                            cprint("done.")
                        else
                            cprint("Error, at trying to restore backup file.")
                        end
                    end
                    if (eraseBackups) then
                        cprint("Warning, Backups erase enabled deleting file now... ", true)
                        delete(filePath .. ".bak")
                        if (exist(filePath)) then
                            cprint("Error, at trying to delete backup file.")
                        else
                            cprint("done.")
                        end
                    end
                end
            else
                if (errorCode == 2 or errorCode == 3) then
                    cprint("Warning, file \"" .. file.path ..
                               "\", probably misplaced or previously removed.")
                else
                    cprint("Error, at trying to erase file.")
                    cprint("Reason, '" .. description .. "' aborting uninstallation now!")
                    return false
                end
            end
        end
        erasePackageFromIndex(packageLabel)
        cprint("Done, package '" .. packageLabel .. "' has been removed.")
        return true
    end
    cprint("Warning, package '" .. packageLabel .. "' is not installed.")
    return false
end

return remove
