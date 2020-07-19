------------------------------------------------------------------------------
-- Download: Download any package file
-- Authors: Sledmine
-- Version: 3.0
------------------------------------------------------------------------------
local json = require "cjson"

local fdownload = require "Mercury.lib.fdownload"

-- URL for the main repo (example: http://lua.repo.net/)
local host = "requiem.shadowmods.net"
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
    SUCCESS = "OK.",
}

local function downloadMerc(packageMetadata)
    cprint("Downloading '" .. packageMetadata.name .. "' package...")
    local mercOutput = _MERCURY_DOWNLOADS .. "\\" .. packageMetadata.label .. ".merc"
    dprint(mercOutput)
    local result, errorCode, header, status = fdownload.get(protocol .. packageMetadata.url, mercOutput)
    -- Merc file has been succesfully downloaded
    if (errorCode == 200) then
        if (fileExist(mercOutput)) then
            cprint("\n'" .. packageMetadata.name .. ", Version " .. packageMetadata.version .. "' has been succesfully downloaded.")
            return true, ERROR.SUCCESS, mercOutput
        else
            cprint("\nERROR!!!: Merc '" .. mercOutput .. "' doesn't exist ...\n")
            return false, ERROR.MERC_FILE_NOT_EXIST
        end
    else
        -- An error ocurred at downloading merc file
        cprint("\nWARNING!!!: " .. tostring(errorCode) .. " An error ocurred at downloading '" .. packageMetadata.url .. "'...\n")
        return false, ERROR.MERC_DOWNLOAD_ERROR
    end
end

local function download(packageLabel, packageVersion)
    -- Path and Filename for the JSON file obtained from the server
    cprint("Looking for package '" .. packageLabel .. "' in Mercury repository...")
    -- Making the request to the repository to get the json package
    cprint("Fetching package into librarian index...")
    local packageURL = protocol .. host .. "/" .. librarianPath .. "package=" .. packageLabel
    if (packageVersion) then
        packageURL = protocol .. host .. "/" .. librarianPath .. "package=" .. packageLabel .. "&version=" .. packageVersion
    end
    local result, errorCode, header, status, data
    if (_TEST_MODE) then
        errorCode = 200
        header = {["content-length"] = "1"}
        data = [[{
            "name": "Mercury Package Test",
            "label": "test",
            "author": "Sled",
            "version": "1.0",
            "url": "localhost/mercury/test.merc"
        }]]
    else
        result, errorCode, header, status, data = fdownload.get(packageURL)
    end
    if (errorCode == 404) then
        cprint("\n\nERROR!!!: Repository server can't be reached...")
        return false, ERROR.NO_REPOSITORY_SERVER
    elseif (errorCode == 200) then
        if (header["content-length"] == "0") then
            print("WARNING!!!: '" .. packageLabel .. "' package not found in Mercury repository.")
            return false, ERROR.PACKAGE_NOT_FOUND
        else
            local packageMetadata = json.decode(data)
            dprint(packageMetadata)
            if (packageMetadata ~= {}) then
                cprint("\nGotcha! Package '" .. packageLabel .. "' found in Mercury repo, parsing meta data....")
                if (not packageVersion) then
                    packageVersion = packageMetadata.version
                end
                cprint("\n[ Package: " .. packageLabel .. " | Version = " .. packageVersion .. " ]")
                local downloadedMercsList = {}
                -- There is a .merc download for this merc file
                if (packageMetadata.url) then
                    local downloadResult, error, mercPath = downloadMerc(packageMetadata)
                    if (downloadResult) then
                        dprint("Adding mercPath to the list!: " .. mercPath)
                        table.insert(downloadedMercsList, mercPath)
                    end
                    -- Package has other packages as dependencies
                    if (packageMetadata.dependencies and #packageMetadata.dependencies > 0) then
                        for index, dependencyMetaData in pairs(packageMetadata.dependencies) do
                            local dependencyResult, error, dependencyMercs =
                                download(dependencyMetaData.name, dependencyMetaData.version)
                            if (dependencyResult) then
                                table.merge(downloadedMercsList, dependencyMercs)
                            else
                                return false, ERROR.DEPENDENCY_ERROR
                            end
                        end
                    end
                    return true, ERROR.SUCCESS, downloadedMercsList
                else
                    cprint("ERROR!!!: The specified package is not in this repository.\n")
                    return false, ERROR.PACKAGE_NOT_FOUND
                end
            else
                -- print("\nERROR!!: Repository is online but the response is in a unrecognized format, this can be caused by a server error or an outdated Mercury version.")
                cprint("\nWARNING!!!: '" .. packageLabel .. "' package not found in Mercury repository.")
                return false, ERROR.PACKAGE_NOT_FOUND
            end
        end
    else
        cprint("\nERROR!!!: '" .. tostring(errorCode) .. "' uknown error...")
        return false, ERROR.UNKOWN_ERROR
    end
end

return download
