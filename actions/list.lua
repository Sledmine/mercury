
local search = require "Mercury.actions.search"
local utilis = require "Mercury.lib.utilis"
local json = require "cjson"

local function listPackages(packageName, onlyNames, detailList)
    local installedPackages = {}
    if (utilis.fileExist(_HALOCE.."\\mercury\\installed\\packages.json") == true) then
        local installedPackagesFile = utilis.fileToString(_HALOCE.."\\mercury\\installed\\packages.json")
        if (installedPackagesFile ~= "") then
            installedPackages = json.decode(installedPackagesFile)
        else
            utilis.deleteFile(_HALOCE.."\\mercury\\installed\\packages.json")
            print(colors("%{red bright}WARNING!!!: %{reset}There are not any installed packages using Mercury...yet."))
        end
        local printInfo = {}
        if (packageName ~= "all") then
            if (searchPackage(packageName)) then
                printInfo[packageName] = {}
                printInfo[packageName].name = installedPackages[packageName].name
                printInfo[packageName].author = installedPackages[packageName].author
                printInfo[packageName].version = installedPackages[packageName].version
            else
                print("The specified package is not installed in the game, yet.")
            end
        else
            printInfo = installedPackages
        end
        for key,value in pairs(printInfo) do
            if (onlyNames) then
                print(printInfo[key].name)
            else
                print("["..key.."]\nName: "..printInfo[key].name.."\nAuthor: "..printInfo[key].author.."\nVersion: "..printInfo[key].version.."\n")
            end
        end
        return false
    end
    print(colors("%{red bright}WARNING!!!: %{reset}There are not any installed packages using Mercury...yet."))
end

return listPackages