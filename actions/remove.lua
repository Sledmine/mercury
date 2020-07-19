------------------------------------------------------------------------------
-- Remove: Remove any package file
-- Authors: Sledmine
-- Version: 3.0
------------------------------------------------------------------------------

local json = require 'cjson'
local search = require 'Mercury.actions.search'

local function remove(packageLabel, noBackups, eraseBackups)
    if (search(packageLabel)) then
        local installedPackages = json.decode(fileToString(_HALOCE_INSTALLED_PACKAGES))
        print("Removing package '" .. packageLabel .. "'...")
        for k, v in pairs(installedPackages[packageLabel].files) do
            -- Replace constant files path
            local file = string.gsub(v .. k, '_HALOCE', _HALOCE, 1)
            file = string.gsub(file, '_MYGAMES', _MYGAMES, 1)

            -- Start erasing proccess
            cprint("\nTrying to erase: '" .. file .. "'...")
            local result, desc, error = deleteFile(file)
            if (result) then
                cprint('OK!!!: File erased succesfully.\nChecking for backup files...')
                if (fileExist(file .. '.bak') and not noBackups) then
                    print('Backup file found, RESTORING now...')
                    move(file .. '.bak', file)
                    if (fileExist(file)) then
                        cprint('OK!!!: File succesfully restored.')
                    else
                        print('Error at trying to RESTORE backup file...')
                    end
                elseif (fileExist(file .. '.bak') and eraseBackups) then
                    cprint('ERASE BACKUPS ACTIVATED: Backup file found, DELETING now...')
                    deleteFile(file .. '.bak')
                    if (fileExist(file)) then
                        print('Error at trying to DELETE backup file...')
                    else
                        cprint('OK!!!: File succesfully deleted.')
                    end
                else
                    print('No backup is going to be restored for this file.')
                end
            else
                if (error == 2 or error == 3) then
                    cprint(
                        'WARNING!!: File not found for erasing, probably misplaced or manually removed.'
                    )
                else
                    print("Error at trying to erase file, reason: '" .. desc .. "' aborting uninstallation now!!!")
                    return false
                end
            end
        end
        installedPackages[packageLabel] = nil
        stringToFile(_HALOCE_INSTALLED_PACKAGES, json.encode(installedPackages))
        cprint(
            "\nDONE!!: Successfully removed '" ..
                packageLabel .. "' package."
        )
        return true
    end
    cprint("WARNING!!!: Package '" .. packageLabel .. "' is NOT installed.\n")
    return false
end

return remove
