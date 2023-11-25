local paths = config.paths()

---Get map data from a map file
---@param map string
---@return number? mapType
---@return string? mapCRC32
local function getMapData(map)
    local mapPath = gpath(paths.gamePath .. "/maps/" .. map .. ".map")
    local mapFile = io.open(mapPath, "rb")
    local mapTags = {}
    if mapFile then
        mapFile:seek("set", 0x60)
        -- Directly reading the header is faster than using Invader or leeting SAPP do it
        local mapType = tonumber(string.byte(mapFile:read(1))) or 0
        mapFile:seek("set", 0x64)
        ---@type string
        local mapCRC32 = mapFile:read(4)
        mapFile:close()
        return mapType, mapCRC32
    end
end

local function cacheMaps()
    local ignore = {
        "a10",
        "a30",
        "a50",
        "b30",
        "b40",
        "c10",
        "c20",
        "c40",
        "d20",
        "d40",
        "loc",
        "bitmaps",
        "sounds",
        "ui"
    }
    local time = os.clock()
    local mapsCache = {}
    for _, mapPath in pairs(filesIn(paths.gamePath .. "/maps")) do
        if not mapPath:endswith(".map") then
            goto continue
        end
        local _, map = splitPath(mapPath)
        assert(map)
        if not table.indexof(ignore, map) then
            local _, crc32 = getMapData(map)
            assert(crc32, "Failed to get map data for " .. map)
            if crc32 then
                mapsCache[map:lower()] = crc32
            end
        end
        ::continue::
    end
    local cacheFile = io.open(gpath(paths.gamePath, "/cache.hac"), "wb")
    if not cacheFile then
        cprint("Error writing server maps cache")
        return
    end
    local maps = table.keys(mapsCache)
    table.sort(maps)
    for _, map in pairs(maps) do
        local crc32 = mapsCache[map]
        dprint("Caching " .. map)
        cacheFile:write(map)
        cacheFile:write(string.rep("\0", 36 - #map))
        cacheFile:write(crc32)
    end
    cacheFile:close()

    dprint("Cached " .. #mapsCache .. " maps in " .. os.clock() - time .. " seconds")
end

local loadFile = [[
sv_public 0
sv_name {sv_name}
sv_rcon {sv_rcon}
sv_rcon_password {sv_rcon_password}
sv_timelimit 0
sv_maxplayers 16
sv_map "{map}" "{gametype}"
allow_client_side_weapon_projectiles {allow_client_side_weapon_projectiles}
load
]]

local init = {
    "lua 1",
    "antihalofp 1",
    -- "antispam 2",
    "antilagspawn 0",
    "antiglitch 0",
    "no_lead 1",
    -- "save_scores 1",
    -- "mtv 1",
    "disable_timer_offsets 1",
    "msg_prefix \"Server: \"",
    -- "aimbot_ban 5000 1",
    "network_thread 0",
    "auto_update 0"
    -- "full_ipban 1"
}

local function serve(map, gametype, port, template, scripts, isUsingNewDataPath, config)
    map = map or "bloodgulch"
    gametype = gametype or "slayer"
    port = port or 2302
    scripts = scripts or {}
    for _, script in pairs(scripts) do
        table.insert(init, "lua_load " .. script)
    end
    config = config or {}

    local serverDataPath = paths.myGamesPath
    if isUsingNewDataPath then
        serverDataPath = gpath(paths.mercuryTemp, "/server")
    end

    createFolder(serverDataPath)
    createFolder(gpath(serverDataPath, "/sapp"))

    local loadFilePath = gpath(serverDataPath, "/load.txt")
    local initFilePath = gpath(serverDataPath, "/sapp/init.txt")

    local load = loadFile:template{
        map = map,
        gametype = gametype,
        sv_name = map,
        sv_rcon = config.rcon and 1 or 0,
        sv_rcon_password = config.rcon_password or "merc",
        allow_client_side_weapon_projectiles = config.server_side_projectiles and 1 or 0
    }
    writeFile(loadFilePath, string.format(load, map, map, gametype))
    writeFile(initFilePath, table.concat(init, "\n"))

    -- Prepare the command to setup the server
    local setup = "cd \"" .. paths.gamePath .. "\"" .. " && wine "
    if isHostWindows() then
        setup = "cd /D \"" .. paths.gamePath .. "\"" .. " && "
    end

    -- Cache game maps ourselves to avoid SAPP doing it, making the server start faster
    cacheMaps()

    -- Start the server
    local cmd = setup .. "haloceded -path \"" .. serverDataPath .. "\" -exec \"" .. loadFilePath ..
                    "\" -port " .. port

    cprint("Starting server...")
    dprint(cmd)
    run(cmd)
    cprint("\nServer stopped")
end

return serve
