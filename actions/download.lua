------------------------------------------------------------------------------
-- Download: Download any package file
-- Authors: Sledmine
-- Version: 3.0
------------------------------------------------------------------------------

local json = require "cjson"

local fdownload = require "Mercury.lib.fdownload"

-- URL for the main repo (example: http://lua.repo.net/)
local host = "mercury.shadowmods.net"
local protocol = "https://"
-- Path for master librarian index
local librarianPath = "librarian.php?"

local ERROR = {
    -- General errors
    UNKOWN_ERROR = "Unknown error.",
    NO_REPOSITORY_SERVER = "Repository server can't be reached.",
    -- Package errors
    PACKAGE_ALREADY_INSTALLED = "Desired package is already installed.",
    PACKAGE_NOT_FOUND = "Package you are looking for is not in the Mercury repository.",
    -- Dependency error
    DEPENDENCY_ERROR = "There was a problem at downloading one or more dependiences.",
    -- Merc errors
    MERC_FILE_NOT_EXIST = "Previously downloaded merc file is not on the expected location.",
    MERC_DOWNLOAD_ERROR = "An error ocurred at downloading merc file.",
    -- No error.
    SUCCESS = "OK."
}

local function downloadMerc(packageMetaData)
    cprint("%{blue bright}Downloading %{white}'".. packageMetaData.name .."' package...")
    local mercOutput = _MERCURY_DOWNLOADS .. "\\" .. packageMetaData.name .. ".merc"
    dprint(mercOutput)
    local result, errorCode, header, status = fdownload.get(protocol .. packageMetaData.URL, mercOutput)
    -- Merc file has been succesfully downloaded
    if (errorCode == 200) then
        if (fileExist(mercOutput)) then
            cprint("%{green bright}\n'".. packageMetaData.name  .. "-" .. packageMetaData.version .."' has been succesfully downloaded.")
            return true, ERROR.SUCCESS, mercOutput
        else
            cprint("%{red bright}\nERROR!!!:%{reset} Merc '" .. mercOutput .."' doesn't exist ...\n")
            return false, ERROR.MERC_FILE_NOT_EXIST
        end
    else
        -- An error ocurred at downloading merc file
        cprint("%{red bright}\nWARNING!!!: " .. tostring(errorCode) .." %{reset}An error ocurred at downloading '" .. packageMetaData.URL .."'...\n")
        return false, ERROR.MERC_DOWNLOAD_ERROR
    end
end

local function download(packageName, packageVersion)
    -- Path and Filename for the JSON file obtained from the server
    cprint("Looking for package '" .. packageName .. "' in Mercury repository...")
    -- Making the request to the repository to get the json package
    cprint("Fetching package into librarian index...")
    local packageURL = protocol .. host .."/" .. librarianPath .. "package=" .. packageName
    if (packageVersion) then
        packageURL = protocol .. host .."/" .. librarianPath .. "package=".. packageName .. "&version=" .. packageVersion
    end
    local result, errorCode, header, status, data = fdownload.get(packageURL)
    if (errorCode == 404) then
        cprint("\n%{red bright}\nERROR!!!: %{reset}Repository server can't be reached...")
        return false, ERROR.NO_REPOSITORY_SERVER
    elseif (errorCode == 200) then
        if (header["content-length"] == "0") then
            print("WARNING!!!: '" .. packageName .. "' package not found in Mercury repository.")
            return false, ERROR.PACKAGE_NOT_FOUND
        else
            local packageMetaData = json.decode(data)
            dprint(packageMetaData)
            if (packageMetaData ~= {}) then
                -- JUST TESTING STUFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                if (packageName == "chimera") then
                packageMetaData.dependencies = {
                    {name = "dsoal"}
                }
                end
                cprint("\n%{green bright}Gotcha! %{reset}Package '" .. packageName .. "' found in Mercury repo, parsing meta data....")
                if (not packageVersion) then
                    packageVersion = packageMetaData.version
                end
                cprint("\n[ %{white bright}Package: %{yellow bright}" .. packageName .. "%{white bright} | Version = %{yellow bright}" .. packageVersion .. "%{reset} ]")
                local downloadedMercsList = {}
                -- There is a .merc download for this merc file
                if (packageMetaData.URL) then
                    local downloadResult, error, mercPath = downloadMerc(packageMetaData)
                    if (downloadResult) then
                        table.insert(downloadedMercsList, mercPath)
                    end
                    -- Package has other packages as dependencies
                    if (packageMetaData.dependencies) then
                        for index, dependencyMetaData in pairs (packageMetaData.dependencies) do
                            local dependencyResult, error, dependencyMercs = download(dependencyMetaData.name, dependencyMetaData.version)
                            if (dependencyResult) then
                                table.merge(downloadedMercsList, dependencyMercs)
                            else
                                return false, ERROR.DEPENDENCY_ERROR
                            end
                        end
                    end
                    return true, ERROR.SUCCESS, downloadedMercsList
                else
                    cprint("%{red bright}ERROR!!!: %{reset}The specified package is not in this repository.\n")
                    return false, ERROR.PACKAGE_NOT_FOUND
                end
            else
                --print("\nERROR!!: Repository is online but the response is in a unrecognized format, this can be caused by a server error or an outdated Mercury version.")
                cprint("%{red bright}\nWARNING!!!: %{reset}'"..packageName.."' package not found in Mercury repository.")
                return false, ERROR.PACKAGE_NOT_FOUND
            end
        end
    else
        cprint("%{red bright}\nERROR!!!: %{reset}'"..tostring(errorCode).."' uknown error...")
        return false, ERROR.UNKOWN_ERROR
    end
end

return download