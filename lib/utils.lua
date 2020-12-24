------------------------------------------------------------------------------
-- Utils module
-- Authors: Sledmine
-- Some util functions
------------------------------------------------------------------------------
local fs = require "fs"
local path = require "path"
local glue = require "glue"

--- Overloaded color printing function
function cprint(text, nextLine)
    if (type(text) ~= "string") then
        print(inspect(text))
    else
        local colorText = string.gsub(text, "Done", "[92mDone[0m")
        colorText = string.gsub(colorText, "done.", "[92mdone[0m.")
        colorText = string.gsub(colorText, "Downloading", "[94mDownloading[0m")
        colorText = string.gsub(colorText, "Success", "[92mSuccess[0m")
        colorText = string.gsub(colorText, "Searching", "[94mSearching[0m")
        colorText = string.gsub(colorText, "Error", "[91mError[0m")
        colorText = string.gsub(colorText, "Warning", "[93mWarning[0m")
        colorText = string.gsub(colorText, "Unpacking", "[93mUnpacking[0m")
        colorText = string.gsub(colorText, "Inserting", "[93mInserting[0m")
        colorText = string.gsub(colorText, "Bundling", "[93mBundling[0m")
        colorText = string.gsub(colorText, "Compiling", "[93mCompiling[0m")
        colorText = string.gsub(colorText, "Removing", "[91mRemoving[0m")
        io.write(colorText)
        if (not nextLine) then
            io.write("\n")
        end
    end
end

--- Debug print for testing purposes only
function dprint(value)
    if (IsDebugModeEnabled and value) then
        if (type(value) == "table") then
            print(inspect(value))
        else
            cprint(value)
            print("\n")
        end
    end
end

--- Provide simple list/array iterator
function each(t)
    local i = 0
    local n = #t
    return function()
        i = i + 1
        if i <= n then
            return t[i], i
        end
    end
end

function splitPath(fileOrFolderPath)
    if (fileOrFolderPath) then
        local directory = path.dir(fileOrFolderPath)
        if (directory == ".") then
            directory = nil
        end
        local extension = path.ext(fileOrFolderPath)
        local fileName = path.file(fileOrFolderPath)
        if (fileName and fileName ~= "" and extension) then
            fileName = string.gsub(fileName, "." .. extension, "")
        else
            fileName = nil
        end
        return directory, fileName, extension
    end
    error("No given file or folder path to split!")
end

function createFolder(folderPath)
    return fs.mkdir(folderPath, true)
end

function move(sourceFile, destinationFile)
    return fs.move(sourceFile, destinationFile)
end

function delete(fileOrFolderPath, recursive)
    if (recursive) then
        return fs.remove(fileOrFolderPath, true)
    end
    return fs.remove(fileOrFolderPath)
end

function copyFile(sourceFile, destinationFile)
    if (sourceFile and destinationFile) then
        if (fs.is(sourceFile) == false) then
            cprint("Error, specified source file does not exist!")
            cprint(sourceFile)
            return false
        end
        local sourceF = io.open(sourceFile, "rb")
        local destinationF = io.open(destinationFile, "wb")
        if (sourceF and destinationF) then
            destinationF:write(sourceF:read("*a"))
            io.close(sourceF)
            io.close(destinationF)
            return true
        end
        if (not sourceF) then
            dprint("Error, " .. sourceFile .. " source file can't be opened.")
        end
        if (not destinationF) then
            dprint("Error, file: \"" .. destinationFile .. "\" can't be opened.")
        end
        return false
    end
    cprint("Error, at trying to copy files, one of the specified paths is null.")
    return false
end

function exist(fileOrFolderPath)
    return fs.is(fileOrFolderPath)
end

function isFile(filePath)
    return path.ext(filePath)
end
