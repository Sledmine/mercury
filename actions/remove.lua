------------------------------------------------------------------------------
-- Remove action
-- Authors: Sledmine
-- Remove any mercury package
------------------------------------------------------------------------------
local json = require("cjson")
local glue = require("glue")

local search = require "Mercury.actions.search"

--- Remove/uninstall a package from the game
---@param packageLabel string
---@param noBackups boolean
---@param eraseBackups boolean
local function remove(packageLabel, noBackups, eraseBackups)
    ---@type packageMercury[]
    local installedPackages = environment.packages()
    if (installedPackages and search(packageLabel)) then
        cprint("Removing package '" .. packageLabel .. "'...")
        local packageFiles = installedPackages[packageLabel].files
        for fileName, path in pairs(packageFiles) do
            local filePath = path .. fileName
            -- Start erasing proccess
            dprint("Erasing '" .. fileName .. "'...")
            local result, description, errorCode = deleteFile(filePath)
            if (result) then
                dprint("Done, file erased.")
                if (fileExist(filePath .. ".bak") and not noBackups) then
                    cprint("Warning, backup file found, restoring file now...")
                    move(filePath .. ".bak", filePath)
                    if (fileExist(filePath)) then
                        cprint("Done, file succesfully restored.")
                    else
                        cprint("Error, at trying to restore backup file.")
                    end
                elseif (fileExist(filePath .. ".bak") and eraseBackups) then
                    cprint("Warning, Backups erase enabled, deleting file now...")
                    deleteFile(filePath .. ".bak")
                    if (fileExist(filePath)) then
                        cprint("Error, at trying to delete backup file.")
                    else
                        cprint("Done, file succesfully deleted.")
                    end
                --else
                 --   cprint("Warning, there is no backup for this file.")
                end
            else
                if (errorCode == 2 or errorCode == 3) then
                    cprint("Warning, erase file not found, probably misplaced or previously removed")
                else
                    cprint("Error, at trying to erase file.")
                    cprint("Reason, '" .. description .. "' aborting uninstallation now!")
                    return false
                end
            end
        end
        installedPackages[packageLabel] = nil
        environment.packages(installedPackages)
        cprint("Done, package '" .. packageLabel .. "' has been removed.")
        return true
    end
    cprint("Warning, package '" .. packageLabel .. "' is not installed.")
    return false
end

return remove
