
local utilis = require "Mercury.lib.utilis"
local json = require "cjson"

local function mitosis(instanceName)
    if (utilis.fileExist(".\\data\\mitosis.json") == true) then
        local fileList
        local folderName = utilis.arrayPop(utilis.explode("\\", _HALOCE))
        local mitosisPath = utilis.explode(folderName, _HALOCE)[1]..instanceName.."\\"
        utilis.createFolder(mitosisPath)
        print(mitosisPath)
        fileList = json.decode(utilis.fileToString(".\\data\\mitosis.json"))
        for i,v in pairs(fileList) do
            if (utilis.isFile(v) == true) then
                print("Mitosising '"..v.."'")
                if (utilis.copyFile(_HALOCE.."\\"..v, mitosisPath..v) == false) then
                    print("Error at mitosising: '"..v.."'!!!")
                    return false
                end
            else
                utilis.createFolder(mitosisPath..v)
            end
        end
        print("Successfully mitosised '"..folderName.."'")
        return true
    else
        print("There is not a mitosis filelist!")
    end
end

return mitosis