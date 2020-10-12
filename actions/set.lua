local function set(instanceName)
    if (instanceName == "default") then
        getGameRegistryPath()
    end
    local folderName = utilis.arrayPop(utilis.explode("\\", GamePath))
    if (instanceName == "default") then
        instanceName = folderName
    end
    local preGameFolder = utilis.explode(folderName, GamePath)[1]
    local mitosisPath = preGameFolder..instanceName
    if (utilis.folderExist(mitosisPath)) then
        print("SUCCESS!!!: Setting current Halo Custom Edition instance to: "..instanceName)
        config.HaloCE = mitosisPath
        utilis.stringToFile(_MERCURY_CONFIG, json.encode(config))
        return true
    end
    print("ERROR!!!: "..instanceName.." not found as an existent instance.")
    return false
end

return set