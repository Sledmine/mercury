------------------------------------------------------------------------------
-- Download: Download any package file
-- Authors: Sledmine
-- Version: 3.0
------------------------------------------------------------------------------
local json = require "cjson"
local fdownload = require "Mercury.lib.fdownload"

-- Entities importation
local PackageMetadata = require "Mercury.entities.packageMetadata"

-- URL for the main repo (example: http://lua.repo.net/)
repositoryHost = "localhost"
httpProtocol = "http://"

-- Path for master librarian index
local librarianPath = "packages?"

local DESCRIPTION = {
    -- General errors
    UNKOWN_ERROR = "Unknown error.",
    NO_REPOSITORY_SERVER = "Repository server can't be reached.",
    NO_RESPONSE = "No response from the server.",
    NO_PACKAGE_URL = "No package url found in repository response.",
    -- Package errors
    PACKAGE_ALREADY_INSTALLED = "Desired package is already installed.",
    PACKAGE_NOT_FOUND = "Package you are looking for is not in the Mercury repository.",
    -- Dependency error
    DEPENDENCY_ERROR = "There was a problem at downloading one or more dependiences.",
    -- Merc errors
    MERC_FILE_NOT_EXIST = "Previously downloaded merc file is not on the expected location.",
    MERC_DOWNLOAD_ERROR = "An error ocurred at downloading merc file.",
    -- No error.
    SUCCESS = "SUCCESS",
}

--- Download a merc file given package metadata
---@param packageMeta packageMetadata
local function downloadMerc(packageMeta)
    cprint("Downloading '" .. packageMeta.name .. "' package...")
    local mercOutput = _MERCURY_DOWNLOADS .. "\\" .. packageMeta.label .. ".merc"
    dprint("Mercury file output: " .. mercOutput)
    local mercUrl = httpProtocol .. packageMeta.url
    local result, errorCode, header, status = fdownload.get(mercUrl, mercOutput)
    -- Merc file has been succesfully downloaded
    if (errorCode == 200) then
        if (fileExist(mercOutput)) then
            cprint(packageMeta.name .. ", Version " .. packageMeta.version ..
                       "' has been downloaded.")
            return true, DESCRIPTION.SUCCESS, mercOutput
        else
            dprint("ERROR!!!: Merc '" .. mercOutput .. "' doesn't exist ...\n")
            return false, DESCRIPTION.MERC_FILE_NOT_EXIST
        end
    else
        -- An error ocurred at downloading merc file
        cprint(tostring(errorCode) .. " - Error at downloading '" .. packageMeta.url .. "'\n")
        return false, DESCRIPTION.MERC_DOWNLOAD_ERROR
    end
end

--- Download a package from the repository
---@param packageLabel string
---@param packageVersion string
local function download(packageLabel, packageVersion)
    -- Path and Filename for the JSON file obtained from the server
    cprint("Looking for package '" .. packageLabel .. "' in Mercury repository...\n")
    local repositoryUrl = httpProtocol .. repositoryHost .. "/" .. librarianPath
    local packageRequestUrl = repositoryUrl .. "package=" .. packageLabel
    if (packageVersion) then
        packageRequestUrl = repositoryUrl .. "package=" .. packageLabel .. "&version=" .. packageVersion
    end
    dprint("URL: " .. packageRequestUrl)
    local result, errorCode, headers, status, responseData = fdownload.get(packageRequestUrl)
    if (errorCode == 404) then
        return false, DESCRIPTION.NO_REPOSITORY_SERVER
    elseif (errorCode == 200) then
        if (headers["content-length"] == "0") then
            return false, DESCRIPTION.PACKAGE_NOT_FOUND
        else
            if (responseData) then
                ---@type packageMetadata
                local packageMeta = PackageMetadata:new(responseData)
                if (not packageVersion) then
                    packageVersion = packageMeta.version
                end
                print("[ Package: " .. packageLabel .. " | Version = " .. packageVersion .. " ]\n")
                local downloadedFiles = {}
                -- There is a .merc download url for this package
                if (packageMeta.url) then
                    local downloadResult, errorString, mercPath = downloadMerc(packageMeta)
                    if (downloadResult) then
                        dprint("Appending " .. mercPath)
                        table.insert(downloadedFiles, mercPath)
                    end
                    -- Package has other packages as dependencies
                    if (packageMeta.dependencies and #packageMeta.dependencies > 0) then
                        for index, dependencyMetaData in pairs(packageMeta.dependencies) do
                            local dependencyResult, errorString, dependencyMercs =
                                download(dependencyMetaData.name, dependencyMetaData.version)
                            if (dependencyResult) then
                                table.merge(downloadedFiles, dependencyMercs)
                            else
                                return false, DESCRIPTION.DEPENDENCY_ERROR
                            end
                        end
                    end
                    return true, DESCRIPTION.SUCCESS, downloadedFiles
                else
                    return false, DESCRIPTION.NO_PACKAGE_URL
                end
            else
                return false, DESCRIPTION.NO_RESPONSE
            end
        end
    else
        if (errorCode[1]) then
            cprint("Error - " .. errorCode[1] .. ".\n")
        else
            cprint(tostring(errorCode))
        end
        return false, DESCRIPTION.UNKOWN_ERROR
    end
end

return download
