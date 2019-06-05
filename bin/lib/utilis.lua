------------------------------------------------------------------------------
-- Utilis: Semi-universal tool library for Mercury
-- Authors: Sledmine
-- Version: 1.0
------------------------------------------------------------------------------

local _M = {}

local lfs = require "lfs"
local fs = require "fs"
local zip = require "minizip"
local inspect = require "inspect"
local path = require "path"

local function splitPath(pathName)
    local dir
    local ext
    local filename 
    if (path.dir(pathName) ~= nil) then
        dir = path.dir(pathName)
    end
    if (path.ext(pathName) ~= nil) then 
        ext = "."..path.ext(pathName)
    end
    if (path.file(pathName) ~= nil and ext ~= nil) then 
        filename = string.gsub(path.file(pathName), "."..path.ext(pathName), "", 1)
    end
    return dir, filename, ext
end

local function readFileToString(file)
    local f = assert(io.open(file, "rb"))
    local content = f:read("*all")
    f:close()
    return content
end

local function writeStringToFile(file, text)
    local f = assert(io.open(file, "w"))
    local content = f:write(text)
    f:close()
end

local function createFolder(folderName)
    os.execute('if not exist "'..folderName..'" ( mkdir "'..folderName..'" )')
end

local function deleteFolder(folderName, withFiles)
    if (withFiles == true) then
        os.execute('rmdir /S /Q "'..folderName..'"')
    else
        os.execute('rmdir "'..folderName..'"')
    end
end

local function deleteFile(filePath)
    os.remove('"'..filePath..'"')
end

local function createFle(filePath)
    os.remove('"'..filePath..'"')
end

local function copyFile(filePath, outputPath)
    deleteFile(filePath)
    os.execute('copy "'..filePath..'" "'..outputPath..'"')
end

local function fileExist(filePath)
    return fs.is(filePath)
end

local function isFile(filepath)
    if (path.ext(filepath) == nil) then
        return false
    end
    return true
end

local function depackageMerc(mercFile, outputPath)
    z = zip.open(mercFile, "r")
    --print(inspect(z:get_global_info()))
    z:first_file()
    for i = 1,z:get_global_info().entries do
        --print(inspect(z:get_file_info()))
        local fileName = z:get_file_info().filename
        if (path.ext(fileName) == nil) then
            print("Creating folder: '"..fileName.."'")
            createFolder(outputPath.."\\"..fileName)
        else
            if (fileName ~= "manifest.json") then
                print("Depacking '"..fileName.."'...")
            end
            local file = io.open(outputPath.."\\"..fileName, "wb")
            file:write(z:extract(fileName))
            file:close()
        end
        z:next_file()
    end
    z:close()
    local dir,file,ext = splitPath(mercFile)
    print("\nSuccesfully depacked "..file..".merc...\n")
end

function explode(div,str) -- Created by: http://richard.warburton.it
    if (div=='') then return false end
    local pos,arr = 0,{}
    -- for each divider found
    for st,sp in function() return string.find(str,div,pos,true) end do
        table.insert(arr,string.sub(str,pos,st-1)) -- Attach chars left of current divider
        pos = sp + 1 -- Jump past current divider
    end
    table.insert(arr,string.sub(str,pos)) -- Attach chars right of last divider
    return arr
end

function arrayPop(array)
    return array[#array]
end

_M.readFileToString = readFileToString
_M.writeStringToFile = writeStringToFile
_M.createFolder = createFolder
_M.deleteFolder = deleteFolder
_M.deleteFile = deleteFile
_M.copyFile = copyFile
_M.fileExist = fileExist
_M.isFile = isFile
_M.depackageMerc = depackageMerc
_M.splitPath = splitPath
_M.explode = explode
_M.arrayPop = arrayPop

return _M