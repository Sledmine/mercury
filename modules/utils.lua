------------------------------------------------------------------------------
-- Utils module
-- Authors: Sledmine
-- Some util functions
------------------------------------------------------------------------------
local fs = require "fs"
local path = require "path"
local glue = require "glue"
local md5 = require "md5"
local uv
if pcall(require, "luv") then
    uv = require "luv"
end

local terminalColor = {
    ["black"] = "[90m",
    ["red"] = "[91m",
    ["green"] = "[92m",
    ["yellow"] = "[93m",
    ["blue"] = "[94m",
    ["magenta"] = "[95m",
    ["cyan"] = "[96m",
    ["white"] = "[97m",
    ["reset"] = "[0m"
}

local keywordsWithColor = {
    ["Done"] = terminalColor.green,
    ["Downloading"] = terminalColor.blue,
    ["Success"] = terminalColor.green,
    ["Searching"] = terminalColor.blue,
    ["Error"] = terminalColor.red,
    ["Warning"] = terminalColor.yellow,
    ["Packing"] = terminalColor.magenta,
    -- ["Copying"] = terminalColor.magenta,
    ["Backup"] = terminalColor.cyan,
    ["Removing"] = terminalColor.red,
    ["Symlinking"] = terminalColor.green,
    ["CONF"] = terminalColor.cyan,
    ["Upgrading"] = terminalColor.yellow,
    ["Getting"] = terminalColor.cyan,
    ["Installing"] = terminalColor.magenta,
    ["Compiling"] = terminalColor.cyan
}

---Overloaded color printing function
---@param message string | table | any
---@param noNewLine? boolean
function cprint(message, noNewLine)
    if (type(message) == "table" or not message) then
        print(inspect(message))
    else
        local newMessage = message
        for _, keyword in pairs(glue.keys(keywordsWithColor)) do
            if (string.find(message, keyword, 1, true)) then
                local newKeyword = "[" .. keyword:upper() .. "]"
                if not getenv("MERCURY_NO_COLOR") or getenv("MERCURY_NO_COLOR") == "0" then
                    newMessage = string.gsub(message, keyword, keywordsWithColor[keyword] ..
                                                 newKeyword .. terminalColor.reset)
                else
                    newMessage = string.gsub(message, keyword, newKeyword)
                end
            end
        end
        io.stdout:write(newMessage)
        if not noNewLine then
            io.stdout:write("\n")
            io.stdout:flush()
        end
    end
end

--- Debug print for testing purposes only
function dprint(value)
    if (IsDebugModeEnabled and value) then
        if (type(value) == "table") then
            print(inspect(value))
        else
            cprint(tostring(value))
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

---@alias folder string
---@alias fileName string
---@alias extension string
--- Return elements from a file or folder path
---@return string? folder, string? fileName, string extension 
function splitPath(inputPath)
    local inputPath = gpath(inputPath)    
    if inputPath then
        local folder = path.dir(inputPath)
        local fileName
        if isHostWindows() then
            local splitPath = glue.string.split(inputPath, "\\")
            fileName = splitPath[#splitPath]
            table.remove(splitPath, #splitPath)
            folder = table.concat(splitPath, "\\")
        end
        fileName = fileName or path.file(inputPath)
        local extension = path.ext(inputPath)
        if (fileName and fileName ~= "" and extension) then
            fileName = string.gsub(fileName, "." .. extension, "")
        else
            fileName = nil
        end
        if folder == "" or folder == "." then
            folder = nil
        end
        return folder, fileName, extension
    end
    error("No given file or folder path to split!")
end

function createFolder(folderPath)
    if not exists(folderPath) then
        return fs.mkdir(folderPath, true)
    end
    return false
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

--- Copy file to specific destination
function copyFileWindows(sourcePath, destinationPath)
    local reason
    if (sourcePath and destinationPath) then
        if (not exists(sourcePath)) then
            dprint("Error, specified source file does not exist!")
            dprint(sourcePath)
            return false
        end
        local isSourceReadable = glue.canopen(sourcePath)
        if (isSourceReadable) then
            local source = assert(uv.fs_open(sourcePath, "r", 438))
            local destination = assert(uv.fs_open(destinationPath, "w", 438))
            reason = errorMessage
            if (destination) then
                local bytesToRead = 1024 * 1024 -- 1MB
                while true do
                    local bytes = uv.fs_read(source, bytesToRead)
                    if bytes == "" then
                        break
                    end
                    uv.fs_write(destination, bytes)
                end
                -- assert(SHA256(sourcePath) == SHA256(destinationPath))
                uv.fs_close(source)
                uv.fs_close(destination)
                return true
            else
                dprint("Error, " .. destinationPath .. " destination can not be open.")
            end
        else
            dprint("Error, " .. sourcePath .. " source can not be open.")
        end
    end
    return false, reason
end

--- Copy file to specific destination
function copyFileLinux(sourcePath, destinationPath)
    if (sourcePath and destinationPath) then
        if (not exists(sourcePath)) then
            dprint("Error, specified source file does not exist!")
            dprint(sourcePath)
            return false
        end
        local isSourceReadable = glue.canopen(sourcePath)
        if (isSourceReadable) then
            local source = assert(io.open(sourcePath, "rb"))
            local destination = io.open(destinationPath, "wb")
            if (destination) then
                local bytesToRead = 64 * 1024
                while true do
                    local bytes = source:read(bytesToRead)
                    if not bytes then
                        break
                    end
                    destination:write(bytes)
                end
                -- assert(SHA256(sourcePath) == SHA256(destinationPath))
                source:close()
                destination:close()
                return true
            else
                dprint("Error, " .. destinationPath .. " destination can not be open.")
            end
        else
            dprint("Error, " .. sourcePath .. " source can not be open.")
        end
    end
    return false
end

function copyFile(sourcePath, destinationPath)
    if isHostWindows() then
        return pcall(copyFileWindows, sourcePath, destinationPath)
    end
    return copyFileLinux(sourcePath, destinationPath)
end

--- Move file to specific destination
---@param sourcePath string
---@param destinationPath string
---@return boolean
function moveFile(sourcePath, destinationPath)
    if (sourcePath and destinationPath) then
        if (not exists(sourcePath)) then
            dprint("Error, specified source file does not exist!")
            dprint(sourcePath)
            return false
        end
        if (exists(destinationPath)) then
            delete(destinationPath)
        end
        return fs.move(sourcePath, destinationPath)
    end
    return false
end

--- Attempt to read a file (unicode friendly)
---@param path string
---@return string
function readFile(path)
    if isHostWindows() then
        local file = assert(uv.fs_open(path, "r", 438))
        local stat = assert(uv.fs_fstat(file))
        local data = assert(uv.fs_read(file, stat.size, 0))
        uv.fs_close(file)
        return data
    end
    return glue.readfile(path, "t")
end

--- Attempt to write a text file (unicode friendly)
---@param path string
---@param data string
function writeFile(path, data)
    if isHostWindows() then
        local file = assert(uv.fs_open(path, "w", 438))
        uv.fs_write(file, data)
        uv.fs_close(file)
        return true
    end
    return luna.file.write(path, data)
end

--- Return true if the given path exists
---@param fileOrFolderPath string
---@return boolean
function exists(fileOrFolderPath)
    if fileOrFolderPath then
        return fs.is(fileOrFolderPath)
    end
    -- TODO We might need to throw an error here instead
    return false
end

--- Return true if the given path is a file
---@param filePath string
---@return boolean
function isFile(filePath)
    return path.ext(filePath)
end

--- Return a Unix like path from a Windows path
function upath(windowspath)
    return windowspath:gsub("\\", "/")
end

--- Return a Windows path from a Unix path
function wpath(unixpath)
    return unixpath:gsub("/", "\\")
end

--- Generate a path from a list of strings
---@vararg string
---@return string
function gpath(...)
    local args = {...}
    local stringPath
    if args then
        if #args > 0 then
            stringPath = ""
        end
        for _, currentPath in pairs(args) do
            if (isHostWindows()) then
                stringPath = stringPath .. wpath(currentPath)
            else
                stringPath = stringPath .. upath(currentPath)
            end
        end
    end
    return stringPath
end

--- Return a list of files in a directory
---@param dir string
---@param recursive boolean
---@return string[]
function filesIn(dir, recursive)
    local files = {}
    for name, d in fs.dir(dir) do
        if not name then
            print("error: ", d)
            break
        end
        local entryType = d:attr "type"
        local entryPath = d:path()
        -- print(entryType, entryPath, name)
        if (entryType == "dir" and recursive) then
            glue.extend(files, filesIn(entryPath, recursive))
        elseif (entryType == "file") then
            glue.append(files, entryPath)
        end
    end
    return files
end

---Get SHA256 checksum of a file
---@param filePath string
---@return string?
function SHA256(filePath)
    local stream = assert(io.popen("sha256sum " .. filePath, "r"))
    if stream then
        local result = stream:read("*all")
        stream:close()
        if result ~= "" then
            local splitOutput = glue.string.split(result, " ")
            return splitOutput[1]
        end
    end
end

---Get MD5 checksum of a file
---@param filePath string
---@return string?
function MD5(filePath)
    local stream = assert(io.open(filePath, "rb"))
    local digest = md5.digest()
    while true do
        local block = stream:read(1024 * 1024)
        if not block then
            break
        end
        digest(block)
    end
    if stream then
        return digest():tohex()
    end
end

--- Execute command line based on OS platform
---@param command string
---@param mute? boolean
---@return boolean?, number?
function run(command, mute)
    -- Binaries should be isolated on Windows, use binaries from executable folder
    if isHostWindows() then
        if mute then
            command = command .. " 1>nul"
        end
        local exedir = fs.exedir()
        if exedir:find("mingw") then
            
            local success, exitcode, code = os.execute(command)
            return success, code
        else
            local success, exitcode, code = os.execute("set PATH=" .. exedir .. ";%PATH% && " .. command)
            return success, code
        end
    end
    if mute then
        command = command .. " 1>/dev/null"
    end
    local success, exitcode, code = os.execute(command)
    return success, code
end

--- Return true if the host is Windows
---@return boolean
function isHostWindows()
    return jit.os == "Windows"
end

--- Verify assertion and exit if assertion is false
---@param assertion boolean | number | table | string
---@return boolean?
function verify(assertion, message)
    if not assertion then
        cprint("Error " .. message .. ".")
        config.clean()
        os.exit(1)
    end
    return true
end

--- Replace string of another string in a string escaping pattern chars
---@param str string
---@param find string
---@param replace string
---@return string
function replace(str, find, replace)
    local find = find:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
    local replaced = str:gsub(find, replace)
    return replaced
end

--- Get an environment variable
---@param name string
---@return string?
function getenv(name)
    if isHostWindows() then
        return uv.os_getenv(name)
    end
    return os.getenv(name)
end

--- Create a symlink
---@param symlink string
---@param path string
---@param isDirectory boolean
---@return boolean, string?
function createSymlink(symlink, path, isDirectory)
    cprint("Symlinking " .. symlink .. " -> " .. path)
    if isHostWindows() then
        if isDirectory then
            local result = os.execute("mklink /D " .. symlink .. " " .. path)
            return result or false, "command_failed"
        end
        local result = os.execute("mklink " .. symlink .. " " .. path)
        return result or false, "command_failed"
    end
    -- return os.execute("ln -s " .. path .. " " .. symlink)
    return fs.mksymlink(symlink, path, isDirectory)
end

--- Return current working directory
---@return string
function pwd()
    return fs.cd()
end

--- Return the directory of the current executable
---@return string
function exedir()
    return fs.exedir()
end

-- Define chars to use for the tree
local treeChars = {trunk = "│", branch = "├─", leaf = "└─"}

-- Function that prints tree based on keys from a table
-- Use proper tree char if next key does not have sub levels
function printTree(tree, indent)
    indent = indent or ""
    for key, value in pairs(tree) do
        if type(value) == "table" then
            if next(value) then
                print(indent .. treeChars.branch .. key)
                printTree(value, indent .. treeChars.trunk .. " ")
            else
                print(indent .. treeChars.leaf .. key)
            end
        else
            print(indent .. treeChars.leaf .. tostring(value))
        end
    end
end
