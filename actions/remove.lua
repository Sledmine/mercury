local utilis = require "Mercury.lib.utilis"
local json = require "cjson"
local colors = require "ansicolors"

local function remove(packageLabel, noBackups, eraseBackups)
    installedPackages = json.decode(utilis.fileToString(_HALOCE.."\\mercury\\installed\\packages.json"))
    if (installedPackages[packageLabel] ~= nil) then
        print("Removing package '"..packageLabel.."'...")
        for k,v in pairs(installedPackages[packageLabel].files) do
            local file = string.gsub(v..k, "_HALOCE", _HALOCE, 1)
            file = string.gsub(file, "_MYGAMES", _MYGAMES, 1)
            print(colors("\n%{blue bright}Trying to erase: %{reset}'"..file.."'..."))
            local result, desc, error = utilis.deleteFile(file)
            if (result) then
                print(colors("%{green bright}OK!!!: %{reset}File erased succesfully.\n\nChecking for backup files...\n"))
                if (utilis.fileExist(file..".bak") and noBackups ~= true) then
                    print("Backup file found, RESTORING now...")
                    utilis.move(file..".bak", file)
                    if (utilis.fileExist(file)) then
                        print(colors("%{green bright}OK!!!: %{reset}File succesfully restored."))
                    else
                        print("Error at trying to RESTORE backup file...")
                    end
                elseif (utilis.fileExist(file..".bak") and eraseBackups == true) then
                    print(colors("%{red bright}ERASE BACKUPS ACTIVATED: %{reset}Backup file found, DELETING now..."))
                    utilis.deleteFile(file..".bak")
                    if (utilis.fileExist(file)) then
                        print("Error at trying to DELETE backup file...")
                    else
                        print(colors("%{green bright}OK!!!: %{reset}File succesfully deleted."))
                    end
                else
                    print("No backup is going to be restored for this file.")
                end
            else
                if (error == 2 or error == 3) then
                    print(colors("%{yellow bright}WARNING!!: %{reset}File not found for erasing, probably misplaced or manually removed."))
                else
                    print("Error at trying to erase file, reason: '"..desc.."' aborting uninstallation now!!!")
                    return false
                end
            end
        end
        installedPackages[packageLabel] = nil
        utilis.stringToFile(_HALOCE.."\\mercury\\installed\\packages.json", json.encode(installedPackages))
        print(colors("\n%{green bright}DONE!!: %{reset}Successfully %{yellow bright}removed %{reset}'"..packageLabel.."' package."))
        return true
    else
        print("Package '"..packageLabel.."' is not installed.")
    end
end

return remove