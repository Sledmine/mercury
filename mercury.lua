------------------------------------------------------------------------------
-- Mercury: Package Manager for Halo Custom Edition 
-- Authors: JerryBrick, Sledmine
-- Version: 2.0
------------------------------------------------------------------------------

-- Required libraries implementation.

-- Local libraries
local fdownload = require "lib.fdownload"
local utilis = require "lib.utilis"
local registry = require "lib.registry"

-- Global libraries
local inspect = require "inspect"
local path = require "path"
local cjson = require "cjson"
local zip = require "minizip"
local colors = require "ansicolors"

-- Global variables definition.

local _mercuryVersion = "2.0"
local host = "https://mercury.shadowmods.net/repo" -- URL for the main repo (example: http://lua.repo.net/)
local librarianPath = "librarian.php?pkg=" -- Path for master librarian index

-- Global function creation.    

local function createEnvironment(folders) -- Setup environment to work, store data, temp files, etc.
    _SOURCEFOLDER = lfs.currentdir()
    _APPDATA = os.getenv("APPDATA")
    _TEMP = os.getenv("TEMP")
    _ARCH = os.getenv("PROCESSOR_ARCHITECTURE")
    if (utilis.fileExist("config.json")) then
        _HALOCE = cjson.decode(utilis.readFileToString(_APPDATA.."\\mercury\\config.json")).HaloCE
    else
        local registryPath
        if (_ARCH ~= "x86") then
            registryPath = registry.getkey("HKEY_LOCAL_MACHINE\\SOFTWARE\\WOW6432Node\\Microsoft\\Microsoft Games\\Halo CE")
        else
            registryPath = registry.getkey("HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Microsoft Games\\Halo CE")
        end
        local documentsPath = registry.getkey("HKEY_CURRENT_USER\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Shell Folders")
        if (registryPath ~= nil) then
            _HALOCE = registryPath.values["EXE Path"]["value"]
        else
            print("\nError at trying to get Halo Custom Edition installation path, are you using a portable version (?)")
            os.exit()
        end
        if (documentsPath ~= nil) then
            _MYGAMES = documentsPath.values["Personal"]["value"].."\\My Games\\Halo CE"
        else
            print("Error at trying to get 'My Documents' path...")
            os.exit()
        end
    end
    if (folders) then
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
end

local function destroyEnvironment() -- Destroy environment previously created, temp folders, trash files, etc
    utilis.deleteFile(_TEMP.."\\mercury\\", true)
end

local function searchPackage(packageName)
    local installedPackages = {}
    if (utilis.fileExist(_APPDATA.."\\mercury\\installed\\packages.json") == true) then
        installedPackages = cjson.decode(utilis.readFileToString(_APPDATA.."\\mercury\\installed\\packages.json"))
        if (installedPackages[packageName] ~= nil) then
            return true
        end
    end
    return false
end

local function list(packageName, onlyNames, detailList)
    local installedPackages = {}
    if (utilis.fileExist(_APPDATA.."\\mercury\\installed\\packages.json") == true) then
        local installedPackagesFile = utilis.readFileToString(_APPDATA.."\\mercury\\installed\\packages.json")
        if (installedPackagesFile ~= "") then
            installedPackages = cjson.decode(utilis.readFileToString(_APPDATA.."\\mercury\\installed\\packages.json"))
        else
            utilis.deleteFile(_APPDATA.."\\mercury\\installed\\packages.json")
            print("WARNING!!!: There are not any installed package using Mercury...yet.")
        end
        local printInfo = {}
        if (packageName ~= "all") then
            if (searchPackage(packageName)) then
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
    print("WARNING!!!: There are not any installed package using Mercury...yet.")
end

local function depackageMerc(mercFile, outputPath)
    z = zip.open(mercFile, "r")
    z:first_file()
    for i = 1,z:get_global_info().entries do
        local fileName = z:get_file_info().filename
        if (utilis.isFile(fileName) == nil) then
            print("Creating folder: '"..fileName.."'")
            utilis.createFolder(outputPath.."\\"..fileName)
        else
            if (fileName ~= "manifest.json") then
                print("Depacking '"..fileName.."'...")
            end
            --print(outputPath.."\\"..fileName)
            local file = io.open(outputPath.."\\"..fileName, "wb")
            file:write(z:extract(fileName))
            file:close()
        end
        z:next_file()
    end
    z:close()
    local dir,file,ext = utilis.splitPath(mercFile)
    print("\nSuccesfully depacked "..file..".merc...\n")
end

local function remove(packageLabel)
    installedPackages = cjson.decode(utilis.readFileToString(_APPDATA.."\\mercury\\installed\\packages.json"))
    if (installedPackages[packageLabel] ~= nil) then
        print("Removing package '"..packageLabel.."'...")
        for k,v in pairs(installedPackages[packageLabel].files) do
            local file = string.gsub(v..k, "_HALOCE", _HALOCE, 1)
            file = string.gsub(file, "_MYGAMES", _MYGAMES, 1)
            print("\nTrying to erase: '"..file.."'...")
            local result, desc, error = utilis.deleteFile(file)
            if (result) then
                print("File erased succesfully.\nChecking for backup files...")
                if (utilis.fileExist(file..".bak")) then
                    print("Backup file found, restoring now...")
                    utilis.move(file..".bak", file)
                    if (utilis.fileExist(file)) then
                        print("File succesfully restored.")
                    else
                        print("Error at trying to restore backup file...")
                    end
                else
                    print("No backup found for this file.")
                end
            else
                if (error == 2 or error == 3) then
                    print("WARNING!!: File not found for erasing, probably misplaced or manually removed.")
                else
                    print("Error at trying to erase file, reason: '"..desc.."' aborting uninstallation now!!!")
                    return false
                end
            end
        end
        installedPackages[packageLabel] = nil
        utilis.writeStringToFile(_APPDATA.."\\mercury\\installed\\packages.json", cjson.encode(installedPackages))
        print("\nSuccessfully removed '"..packageLabel.."' package.")
        return true
    else
        print("Package '"..packageLabel.."' is not installed.")
    end
end

function download(packageLabel, forceInstallation)
    local packageSplit = utilis.explode("-", packageLabel)
    local packageName = packageSplit[1]
    local packageVersion = packageSplit[2]
    if (searchPackage(packageName)) then
        if (forceInstallation ~= true) then
            print(colors("%{red bright}WARNING!!!: %{reset}The package '"..packageName.."' that you are looking for is already installed in the game. If you need to update or reinstall try to remove it first.\n"))
            return false
        else
            remove(packageName)
        end
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
                    print(colors("\n[ %{white bright}"..packageName.." | Version = '%{yellow bright}"..packageVersion.."%{reset}' ]"))
                    print("\nRunning package tree...\n")
                    if (packageJSON.repo == nil) then -- Repo is the main Mercury repo, read file URL to download subpackages
                        if (packageJSON.paths ~= nil) then
                            for k,v in pairs (packageJSON.paths) do
                                local subpackageURL = host.."/"..v
                                local subpackageSplit = utilis.explode("/", v)
                                local subpackageFile = utilis.arrayPop(subpackageSplit)
                                print(colors("%{blue bright}Downloading %{white}'"..subpackageFile.."' package...\n"))
                                local downloadOutput = _TEMP.._REPOPATH.."\\downloaded\\"..subpackageFile
                                local r, c, h, s = fdownload.get(subpackageURL, downloadOutput) 
                                if (c == 200) then
                                    print(colors("%{green bright}\n'"..packageLabel.."-"..packageVersion.."' has been succesfully downloaded.\n\nStarting installation process now...\n"))
                                    install(downloadOutput)
                                else
                                    print(colors("%{red bright}\nERROR!!!: %{reset}An error ocurred while downloading '"..v.."'...\n"))
                                end
                            end
                        end
                    else
                        print(colors("%{red bright}ERROR!!!: %{reset}The specified package is not in this repository.\n"))
                    end
                end
            else
                --print("\nERROR!!: Repository is online but the response is in a unrecognized format, this can be caused by a server error or an outdated Mercury version.")
                print(colors("%{red bright}\nWARNING!!!: %{reset}'"..packageLabel.."' package not found in Mercury repository."))
            end
        end
    else
        print("ERROR '"..tostring(c[1]).."' uknown error...")
    end
end

function install(mercPackage)
    local mercPath, mercName, mercExtension = utilis.splitPath(mercPackage)
    local mercFullName = mercPath.."\\"..mercName.._MERC_EXTENSION
    if (utilis.fileExist(mercFullName) == true) then
        print("Trying to depackage '"..mercName.."'.merc...\n")
        local depackageFolder = _TEMP.._REPOPATH.."\\depacked\\"..mercName
        utilis.createFolder(depackageFolder)
        depackageMerc(mercFullName, depackageFolder)
        local mercJSON = cjson.decode(utilis.readFileToString(depackageFolder.."\\manifest.json"))
        print("Dispatching package files...")
        for k,v in pairs(mercJSON) do
            packageLabel = k
        end
        for file,path in pairs(mercJSON[packageLabel].files) do
            local outputPath = string.gsub(path, "_HALOCE", _HALOCE, 1)
            outputPath = string.gsub(outputPath, "_MYGAMES", _MYGAMES, 1)
            print("Installing '"..file.."'...")
            print("Output: '"..outputPath..file.."'...")
            if (utilis.fileExist(outputPath) == false) then
                print("Creating folder: "..outputPath)
                utilis.createFolder(outputPath)
            end
            if (utilis.fileExist(outputPath..file)) then
                print("There is an existing file with the same name, renaming it to .bak for restoring purposes.")
                local result, desc, error = utilis.move(outputPath..file, outputPath..file..".bak")
                if (result) then
                    print("Succesfully created backup for: '"..file.."'")
                else
                    print("Error at trying to create a backup for: '"..file.."' aborting installation now!!!")
                    print("\n'ERROR: "..mercName..".merc' installation encountered one or more problems!!")
                    return false
                end
            end
            if (utilis.copyFile(depackageFolder.."\\"..file, outputPath..file) == true) then
                print("File succesfully installed.\n")
            else
                print("Error at trying to install file: '"..file.."' aborting installation now!!!")
                print("\n'ERROR: "..mercName..".merc' installation encountered one or more problems, aborting now!!")
                return false
            end
        end
        local installedPackages = {}
        if (utilis.fileExist(_APPDATA.."\\mercury\\installed\\packages.json") == true) then
            installedPackages = cjson.decode(utilis.readFileToString(_APPDATA.."\\mercury\\installed\\packages.json"))
        end
        installedPackages[packageLabel] = mercJSON[packageLabel]
        utilis.writeStringToFile(_APPDATA.."\\mercury\\installed\\packages.json", cjson.encode(installedPackages))
        if (mercJSON[packageLabel].dependencies ~= nil) then
            print("Fetching required dependencies...")
            for i,dependecyPackage in pairs(mercJSON[packageLabel].dependencies) do
                download(dependecyPackage)
            end
        end
        print("\n'"..mercName..".merc' succesfully installed!!")
        return true
    else
        print("\nSpecified .merc package doesn't exist. ("..mercFullName..")")
    end
    return false
end

local function mitosis(name)
    if (utilis.fileExist("data\\mitosis.json") == true) then
        local fileList
        local folderName = utilis.arrayPop(utilis.explode("\\", _HALOCE))
        local mitosisPath = utilis.explode(folderName, _HALOCE)[1]..name.."\\"
        utilis.createFolder(mitosisPath)
        print(mitosisPath)
        fileList = cjson.decode(utilis.readFileToString("data\\mitosis.json"))
        for i,v in pairs(fileList) do
            if (utilis.isFile(v) == true) then
                utilis.copyFile(_HALOCE.."\\"..v, mitosisPath..v)
                print("Mitosising '"..v.."'")
            else
                utilis.createFolder(mitosisPath..v)
            end
        end
        print("Successfully mitosised '"..folderName.."'")
    else
        print("There is not a mitosis filelist!")
    end
end

local function mercurySetup()
    -- Create registry entries
    registry.writevalue("HKEY_CLASSES_ROOT\\.merc", "", "REG_SZ", "Mercury Package")
    registry.writevalue("HKEY_CLASSES_ROOT\\.merc\\DefaultIcon", "", "REG_SZ", "\"".._SOURCEFOLDER.."\\assets\\icons\\package.ico\",0")
    registry.writevalue("HKEY_CLASSES_ROOT\\.merc\\shell\\open\\command", "", "REG_SZ", "\"".._SOURCEFOLDER.."\\mercury.exe\" merc %1")
    print("Mercury Successfully setup!")
end

local function printUsage()
    print(colors([[
    %{red bright}usage%{reset}: %{green}mercury %{reset}<action> <params>

    %{yellow}PARAMETERS INSIDE "[ ]" ARE OPTIONAL!!!%{reset}

    %{blue bright}install%{reset} : Search for packages hosted in Mercury repos to download and install into the game.
            <package> [<parameters>]

            -f      Force installation, will remove old packages and erase existing backupfiles.

            -nb     Avoid creation of backup files.
            
    %{blue bright}list%{reset}    : List and show info about all the previously installed packages in the game.
            <package> [<parameters>] -- use "all" as package to show all the installed packages.
 
            -l      Only shows package name.

            -d      Print detailed info about the package.

    %{blue bright}merc%{reset}    : Manually install a specified .merc package.
            <mercPath>

    %{blue bright}remove%{reset}  : Delete previously installed package, subpackage in the game.
            <package> [<parameters>]

            -nb     Avoid restoration of backup files.
            
            -eb     This will erase previously created backup files of the package.

    %{blue bright}update%{reset}  : Update an existent package in the game.
            <package> -- use "all" as package to update all the installed packages.

    %{blue bright}mitosis%{reset} : Create a new instance of Halo Custom Edition with only neccesary base files to run.
            <instanceName>

    %{blue bright}config%{reset}  : Define critical Mercury parameters as package installation path.
            <field> <value> - in 'HaloCE' case field you can pass a name of mitosised Halo Custom Edition instance.

    %{blue bright}setup%{reset}   : Set all the needed values to introduce Mercury into Windows OS.

    %{blue bright}version%{reset} : Throw version and related info about Mercury.]]))
end

local function printVersion() 
    print("Mercury: Package Manager for Halo Custom Edition\nVersion: ".._mercuryVersion.."\nGNU General Public License v3.0\nDeveloped by: Jerry Brick, Sledmine.")
end

-- Main program functionality.
createEnvironment(false)
destroyEnvironment() -- Destroy previous environment in case something ended wrong
createEnvironment(true)
print()
print(tostring(colors("\n%{white bright}[ Mercury - Package Manager | Version: %{reset}%{yellow bright}".._mercuryVersion.." %{white}]")))
print(tostring(colors("\n%{yellow bright}Detected Windows architecture: %{white}".._ARCH)))
print(tostring(colors("%{yellow bright}Current Working folder: %{white}'".._SOURCEFOLDER.."'.")))
print(tostring(colors("%{yellow bright}Current Halo CE path: %{white}'".._HALOCE.."'")))
print(tostring(colors("%{yellow bright}Current My Games path: %{white}'".._MYGAMES.."'\n")))
if (#arg == 0) then
    printUsage()
else
    local parameters
    if (arg[1] == "install") then
        if (arg[2] ~= nil) then
            if (arg[3] ~= nil) then
                parameters = ""
                for i = 3,#arg do
                    parameters = arg[i]
                end
            end
            download(arg[2], parameters)
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
            local onlyNames
            local detailList
            if (arg[3] ~= nil) then
                parameters = ""
                for i = 3,#arg do
                    parameters = arg[i]
                end
                if (string.find(parameters, "-l") ~= nil) then
                    onlyNames = true
                end
            end
            list(arg[2], onlyNames, detailList)
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