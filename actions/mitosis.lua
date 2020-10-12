local json = require "cjson"

local function mitosis(instanceName)
    if (fileExist(".\\data\\mitosis.json") == true) then
        local fileList
        local folderName = arrayPop(explode("\\", GamePath))
        local mitosisPath = explode(folderName, GamePath)[1]..instanceName.."\\"
        createFolder(mitosisPath)
        print(mitosisPath)
        fileList = json.decode(fileToString(".\\data\\mitosis.json"))
        for i,v in pairs(fileList) do
            if (isFile(v) == true) then
                print("Mitosising '"..v.."'")
                if (copyFile(GamePath.."\\"..v, mitosisPath..v) == false) then
                    print("Error at mitosising: '"..v.."'!!!")
                    return false
                end
            else
                createFolder(mitosisPath..v)
            end
        end
        print("Successfully mitosised '"..folderName.."'")
        return true
    else
        print("There is not a mitosis filelist!")
    end
end

return mitosis