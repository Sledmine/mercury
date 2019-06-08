------------------------------------------------------------------------------
-- Mercury: Package Manager for Halo Custom Edition 
-- Authors: JerryBrick, Sledmine
-- Version: 1.0
------------------------------------------------------------------------------

-- Required libraries implementation.

local fdownload = require "lib.fdownload"
local utilis = require "lib.utilis"
local registry = require "lib.registry"

local inspect = require "inspect"
local path = require "path"
local cjson = require "cjson"

-- Global variables definition.

local _mercuryVersion = "1.0"
local host = "https://mercury.shadowmods.net/repo" -- URL for the main repo (example: http://lua.repo.net/)
local librarianPath = "librarian.php?pkg=" -- Path for master librarian index

-- Global function creation.

function createEnvironment() -- Setup environment to work, store data, temp files, etc.
    _SOURCEFOLDER = lfs.currentdir()
    _APPDATA = os.getenv("APPDATA")
    _TEMP = os.getenv("TEMP")
    if (utilis.fileExist("config.json")) then
        _HALOCE = cjson.decode(utilis.readFileToString(_APPDATA.."\\mercury\\config.json")).HaloCE
    else
        local registryPath = registry.getkey("HKEY_LOCAL_MACHINE\\SOFTWARE\\WOW6432Node\\Microsoft\\Microsoft Games\\Halo CE")
        if (registryPath ~= nil) then
            _HALOCE = registryPath.values["EXE Path"]["value"]
        end
    end
    _REPOPATH = "\\mercury\\packages"
    _MERC_EXTENSION = ".merc"
    envFolders = {
        _APPDATA.."\\Mercury",
        _APPDATA.."\\Mercury\\installed",
        _TEMP.._REPOPATH,
        _TEMP.._REPOPATH.."\\downloaded",
        _TEMP.._REPOPATH.."\\depacked"
    }
    for i = 1,#envFolders do
        --print("\nCreating folder: "..envFolders[i])
        utilis.createFolder(envFolders[i])
    end
end

function destroyEnvironment() -- Destroy environment previously created, temp folders, trash files, etc
    utilis.deleteFolder(_TEMP.."\\mercury\\", true)
end

function searchPackage(packageName)
    local installedPackages = {}
    if (utilis.fileExist(_APPDATA.."\\mercury\\installed\\packages.json") == true) then
        installedPackages = cjson.decode(utilis.readFileToString(_APPDATA.."\\mercury\\installed\\packages.json"))
        if (installedPackages[packageName] ~= nil) then
            return true
        end
    end
    return false
end

function list()
    local installedPackages = {}
    if (utilis.fileExist(_APPDATA.."\\mercury\\installed\\packages.json") == true) then
        installedPackages = cjson.decode(utilis.readFileToString(_APPDATA.."\\mercury\\installed\\packages.json"))
        print(inspect(installedPackages))
        return true
    end
    print("WARNING!!!: There are not any installed package using Mercury...yet.")
end

local function install(mercPackage)
    local mercPath, mercName, mercExtension = utilis.splitPath(mercPackage)
    local mercFullName = mercPath.."\\"..mercName.._MERC_EXTENSION
    if (utilis.fileExist(mercFullName) == true) then
        print("Trying to depackage '"..mercName.."'.merc...\n")
        local depackageFolder = _TEMP.._REPOPATH.."\\depacked\\"..mercName
        utilis.createFolder(depackageFolder)
        utilis.depackageMerc(mercFullName, depackageFolder)
        local mercJSON = cjson.decode(utilis.readFileToString(depackageFolder.."\\manifest.json"))
        print("Dispatching package files...")
        for k,v in pairs(mercJSON) do
            packageLabel = k
        end
        for k,v in pairs (mercJSON[packageLabel].files) do
            print("Installing '"..k.."'...")
            utilis.copyFile(depackageFolder.."\\"..k, string.gsub(v, "_HALOCE", _HALOCE, 1))
        end
        print("\n'"..mercName..".merc' Installed succesfully!!")
        local installedPackages = {}
        if (utilis.fileExist(_APPDATA.."\\mercury\\installed\\packages.json") == true) then
            installedPackages = cjson.decode(utilis.readFileToString(_APPDATA.."\\mercury\\installed\\packages.json"))
        end
        installedPackages[packageLabel] = mercJSON[packageLabel]
        utilis.writeStringToFile(_APPDATA.."\\mercury\\installed\\packages.json", cjson.encode(installedPackages))
    else
        print("\nSpecified .merc package doesn't exist. ("..mercFullName..")")
    end
end

local function remove(packageLabel)
    installedPackages = cjson.decode(utilis.readFileToString(_APPDATA.."\\mercury\\installed\\packages.json"))
    if (installedPackages[packageLabel] ~= nil) then
        print("Removing package '"..packageLabel.."'...\n")
        for k,v in pairs(installedPackages[packageLabel].files) do
            local file = string.gsub(v..k, "_HALOCE", _HALOCE, 1)
            print("Erasing file: '"..file.."'")
            utilis.deleteFile(file)
        end
        installedPackages[packageLabel] = nil
        utilis.writeStringToFile(_APPDATA.."\\mercury\\installed\\packages.json", cjson.encode(installedPackages))
        print("\nSuccessfully removed '"..packageLabel.."' package.")
    else
        print("Package '"..packageLabel.."' is not installed.")
    end
end

function download(packageLabel)
    local packageSplit = utilis.explode("-", packageLabel)
    local packageName = packageSplit[1]
    local packageVersion = packageSplit[2]
    if (searchPackage(packageName) == true) then
        print("The package you are looking for is already installed in the game... if you need to reinstall it try to remove it or update it.")
        return false
    end
    print("Looking for package '"..packageLabel.."' in Mercury repository...\n")
    local packageHandle = _REPOPATH.."\\"..packageLabel..".json" -- Path and Filename for the JSON file obtained from the server
    print("Fetching package into librarian index...\n")
    local r, c, h, s = fdownload.get(host.."/"..librarianPath..packageLabel, _TEMP.."\\"..packageHandle)
    if (c == 404) then
        print("\nERROR: Repository server can't be reached...")
    elseif (c == 200) then
        if (h["content-length"] == "0") then
            print("\nWARNING!!!: '"..packageLabel.."' package not found in Mercury repository.")
        else
            local packageFile = utilis.readFileToString(_TEMP..packageHandle)
            if (packageFile ~= "") then
                local packageJSON = cjson.decode(utilis.readFileToString(_TEMP..packageHandle))
                if (packageJSON ~= {}) then
                    print("\nSuccess! Package '"..packageLabel.."' found in Mercury repo, parsing meta data....")
                    if (packageSplit[2] == nil) then
                        packageVersion = packageJSON.version
                    end
                    print("\n["..packageName.." | Version = '"..packageVersion.."']\nStarting download...\n")
                    print("Running subpackage tree...\n")
                    if (packageJSON.repo == nil) then -- Repo is the main Mercury repo, read file URL to download subpackages
                        if (packageJSON.paths ~= nil) then
                            for k,v in pairs (packageJSON.paths) do
                                local subpackageURL = host.."/"..v
                                local subpackageSplit = utilis.explode("/", v)
                                local subpackageFile = utilis.arrayPop(subpackageSplit)
                                print("Downloading '"..subpackageFile.."' subpackage...\n")
                                local downloadOutput = _TEMP.._REPOPATH.."\\downloaded\\"..subpackageFile
                                local r, c, h, s = fdownload.get(subpackageURL, downloadOutput) 
                                if (c == 200) then
                                    print("\n'"..packageLabel.."-"..v.."' has been succesfully downloaded.\n\nStarting installation process now...\n")
                                    install(downloadOutput)
                                else
                                    print("\nERROR!!!: '"..v.."' is not more available in the repo as subpackage...\n")
                                end
                            end
                        end
                    else
                        print("\nERROR!!!: The specified package is not in this repository.\n")
                    end
                end
            else
                --print("\nERROR!!: Repository is online but the response is in a unrecognized format, this can be caused by a server error or an outdated Mercury version.")
                print("\nWARNING!!!: '"..packageLabel.."' package not found in Mercury repository.")
            end
        end
    else
        print("ERROR '"..c.."' uknown error...")
    end
end

local function mitosis(name)
    if (utilis.fileExist("mitosisList.json") == true) then
        local fileList
        local folderName = utilis.arrayPop(utilis.explode("\\", _HALOCE))
        local mitosisPath = utilis.explode(folderName, _HALOCE)[1]..name.."\\"
        utilis.createFolder(mitosisPath)
        print(mitosisPath)
        fileList = cjson.decode(utilis.readFileToString("mitosisList.json"))
        for i,v in pairs(fileList) do
            if (utilis.isFile(v) == true) then
                utilis.copyFile(_HALOCE.."\\"..v, mitosisPath..v)
                print("Mitosising '"..v.."'")
            else
                utilis.createFolder(mitosisPath..v)
            end
        end
        print("Successfully mitosed '"..folderName.."'")
    else
        print("There is not a mitosis filelist!")
    end
end

local function mercurySetup()
    -- Create registry entries
    registry.writevalue("HKEY_CLASSES_ROOT\\.merc", "", "REG_SZ", "Mercury Package")
    registry.writevalue("HKEY_CLASSES_ROOT\\.merc\\DefaultIcon", "", "REG_SZ", "\"".._SOURCEFOLDER.."\\assets\\icons\\package.ico\",0")
    registry.writevalue("HKEY_CLASSES_ROOT\\.merc\\shell\\open\\command", "", "REG_SZ", "\"".._SOURCEFOLDER.."\\build\\mercury.exe\" merc %1")
    print("Mercury Successfully setup!")
end

local function printUsage()
    print([[
    usage: mercury <action> <params>

    PARAMETERS INSIDE "[]" CAN BE OPTIONAL!!!

    install : Search for packages hosted in Mercury repos to download and install into the game.
            <package> [<subpackage>]

    list    : List and show info about all the previously installed packages in the game.
            <package> -- use "all" to show all the installed packages.

    merc    : Manually install a specified .merc package.
            <mercPath>

    remove  : Delete previously installed package, subpackage in the game.
            <package> [<subpackage>]

    update  : Update an existent package in the game.
            <package>

    mitosis : Create a new instance of Halo Custom Edition with only neccesary base files to run.
            <instanceName>

    config  : Define critical Mercury parameters as package installation path.
            <field> <value> - in case of 'HaloCE' field you can give the name of mitosised Halo Custom Edition instance.

    setup   : Set all the needed values to introduce Mercury into Windows OS.

    version : Throw version and related info about Mercury.]])
end

function printVersion() 
    print("Mercury: Package Manager for Halo Custom Edition\nVersion: ".._mercuryVersion.."\nGNU General Public License v3.0\nDeveloped by: Jerry Brick, Sledmine.")
end

-- Main program functionality.

createEnvironment()
print(tostring("\nWorking folder: '".._SOURCEFOLDER.."'."))
print(tostring("\nCurrent Halo CE Path: '".._HALOCE.."' change it using 'mercury config'.\n"))
if (#arg == 0) then
    printUsage()
else
    if (arg[1] == "install") then
        if (arg[2] ~= nil) then
            download(arg[2])
        else
            printUsage()
        end
    elseif (arg[1] == "remove") then
        if (arg[2] ~= nil) then
            remove(arg[2])
        else
            printUsage()
        end
    elseif (arg[1] == "list") then
        if (arg[2] ~= nil) then
            list(arg[2])
        else
            printUsage()
        end
    elseif (arg[1] == "merc") then
        if (arg[2] ~= nil) then
            install(arg[2])
        else
            printUsage()
        end
    elseif (arg[1] == "mitosis") then
        if (arg[2] ~= nil) then
            mitosis(arg[2])
        else
            printUsage()
        end
    elseif (arg[1] == "version") then
        printVersion()
    elseif (arg[1] == "setup") then
        mercurySetup()
    else
        print("'"..arg[1].."' is not an available action...")
    end
end

destroyEnvironment()