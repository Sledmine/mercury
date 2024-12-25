local paths = config.paths()

---Link files in the project directory to Balltze plugins directory
---@param projectPath string
local function link(projectPath, projectName)
    local split = upath(projectPath):split("/")
    local projectName = split[#split]:replace(" ", "_"):replace("-", "_")
    local luaFilesPath = gpath(projectPath, "/lua")

    for _, path in pairs(filesIn(luaFilesPath)) do
        local _, name, extension = splitPath(path)
        if extension == "lua" then
            local fileName = name .. "." .. extension
            fileName = fileName:replace(" ", "_"):replace("-", "_")
            if not createSymlink(gpath(paths.balltzePlugins, "/", fileName), path) then
                cprint("Error linking file: " .. fileName)
                return false
            end
        end
    end

    local pluginLuaPath = gpath(paths.balltzePlugins, "/lua_", projectName)
    local pluginLuaModulesPath = gpath(pluginLuaPath, "/modules")
    if not exists(pluginLuaPath) then
        createFolder(pluginLuaPath)
    end
    if not createSymlink(pluginLuaModulesPath, gpath(luaFilesPath ,"/modules"), true) then
        cprint("Error linking modules folder")
        return false
    end
    return true
end

return link
