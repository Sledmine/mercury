local json = require "cjson"
local requests = require "requests"
local constants = require "Mercury.modules.constants"
local v = require "semver"

local function latest()
    cprint("Searching, for latest Mercury version... ", true)
    local response = requests.get(constants.latestReleaseApi)
    if (response and response.status_code == 200) then
        local release = json.decode(response.text)
        if (release and not release.prerelease and not release.draft) then
            local tagName = release.tag_name
            local version = tagName:gsub("v", "")
            -- Current version is an older version than the latest release
            if (v(constants.mercuryVersion) < v(version)) then
                cprint(string.format("done. Found version %s.", version))
                local latestRelease = constants.gitHubReleases:gsub("{tagName}", tagName)
                if (jit.os =="Windows") then
                    os.execute(("explorer \"%s\""):format(latestRelease))
                else
                    os.execute(("open \"%s\""):format(latestRelease))
                end
                return true
                --[[for _, asset in pairs(release.assets) do
                    if (asset.name and asset.name:find(Arch)) then
                        cprint("done.")
                        local url = asset.browser_download_url
                        os.execute(string.format("explorer \"%s\"", url))
                    end
                end]]
            end
        end
    end
    cprint("done. Mercury is already on the latest version.")
    return false
end

return latest
