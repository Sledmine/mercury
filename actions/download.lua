local json = require "cjson"

local remove = require "Mercury.actions.remove"
local search = require "Mercury.actions.search"
--local install = require "Mercury.actions.install"
local fdownload = require "Mercury.lib.fdownload"

local function download(packageLabel, forceInstallation, noBackups)
    local packageSplit = explode("-", packageLabel)
    local packageName = packageSplit[1] or packageLabel
    local packageVersion = packageSplit[2]

    if (search(packageName)) then
        if (forceInstallation) then
            remove(packageName, true, true)
        else
            cprint("%{red bright}WARNING!!!: %{reset}Package '" .. packageName .. "' is already installed.\n")
            return false
        end
    end

    -- Path and Filename for the JSON file obtained from the server
    print("Looking for package '" .. packageLabel .. "' in Mercury repository...\n")

    -- Making the request to the repository to get the json package
    print("Fetching package into librarian index...\n")
    local packageURL = protocol .. host .."/" .. librarianPath .. "package=" .. packageName
    if (packageVersion) then
        packageURL = protocol .. host .."/" .. librarianPath .. "package=".. packageName .. "&version=" .. packageVersion
    end
    local result, errorCode, header, status, data = fdownload.get(packageURL)
    if (errorCode == 404) then
        cprint("\n%{red bright}\nERROR!!!: %{reset}Repository server can't be reached...")
    elseif (errorCode == 200) then
        if (header["content-length"] == "0") then
            print("WARNING!!!: '"..packageLabel.."' package not found in Mercury repository.")
        else
            local packageJSON = json.decode(data)
            if (packageJSON ~= {}) then
                print("\nSuccess! Package '"..packageLabel.."' found in Mercury repo, parsing meta data....")
                if (packageVersion == nil) then
                    packageVersion = packageJSON.version
                end
                cprint("\n[ %{white bright}"..packageName.." | Version = '%{yellow bright}"..packageVersion.."%{reset}' ]")
                print("\nRunning package tree...\n")
                if (packageJSON.repo == nil) then -- Repo is the main Mercury repo, read file URL to download subpackages
                    if (packageJSON.paths) then
                        for key,mercList in pairs (packageJSON.paths) do
                            local mercURL = protocol..mercList
                            local mercSplit = explode("/", mercList)
                            local mercFile = arrayPop(mercSplit)
                            cprint("%{blue bright}Downloading %{white}'".. mercFile .."' package...")
                            local downloadOutput = _MERCURY_DOWNLOADS .. "\\" .. mercFile
                            local result, errorCode, header, status = fdownload.get(mercURL, downloadOutput)
                            -- Merc file has been succesfully downloaded
                            if (errorCode == 200) then
                                if (fileExist(downloadOutput)) then
                                    cprint("%{green bright}\n'".. packageLabel .. "-" .. packageVersion .."' has been succesfully downloaded.")
                                    cprint("\n%{reset}Starting installation process now...\n")
                                    install(downloadOutput)
                                else
                                    cprint("%{red bright}\nERROR!!!:%{reset} Package '" .. mercFile .."' doesn't exist ...\n")
                                end
                            else
                                -- An error ocurred at downloading merc file
                                cprint("%{red bright}\nERROR!!!: %{reset}An error ocurred at downloading '" .. mercURL .."'...\n")
                            end
                        end
                    end
                else
                    cprint("%{red bright}ERROR!!!: %{reset}The specified package is not in this repository.\n")
                end
            else
                --print("\nERROR!!: Repository is online but the response is in a unrecognized format, this can be caused by a server error or an outdated Mercury version.")
                cprint("%{red bright}\nWARNING!!!: %{reset}'"..packageLabel.."' package not found in Mercury repository.")
            end
        end
    else
        cprint("%{red bright}\nERROR!!!: %{reset}'"..tostring(errorCode[1]).."' uknown error...")
    end
end

return download