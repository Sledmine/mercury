local json = require "cjson"
local requests = require "requests"
local constants = require "modules.constants"
local paths = environment.paths()
local v = require "semver"
local download = require "modules.download"

---@class githubAuthor
---@field login string
---@field id number
---@field node_id string
---@field avatar_url string
---@field gravatar_id string
---@field url string
---@field html_url string
---@field followers_url string
---@field following_url string
---@field gists_url string
---@field starred_url string
---@field subscriptions_url string
---@field organizations_url string
---@field repos_url string
---@field events_url string
---@field received_events_url string
---@field type string
---@field site_admin boolean

---@class githubAsset
---@field url string
---@field id number
---@field node_id string
---@field name string
---@field label? any
---@field uploader githubAuthor
---@field content_type string
---@field state string
---@field size number
---@field download_count number
---@field created_at string
---@field updated_at string
---@field browser_download_url string

---@class githubApiResponse
---@field url string
---@field assets_url string
---@field upload_url string
---@field html_url string
---@field id number
---@field author githubAuthor
---@field node_id string
---@field tag_name string
---@field target_commitish string
---@field name string
---@field draft boolean
---@field prerelease boolean
---@field created_at string
---@field published_at string
---@field assets githubAsset[]
---@field tarball_url string
---@field zipball_url string
---@field body string

-- Get latest Mercury version available
local function latest()
    -- cprint("Checking for a newer Mercury version... ", true)
    local response = requests.get(constants.latestReleaseApi)
    if response and response.status_code == 200 then
        dprint(response)
        ---@type githubApiResponse
        local release = json.decode(response.text)
        if release and not release.prerelease and not release.draft then
            local tagName = release.tag_name
            local version = tagName:gsub("v", "")
            -- Current version is an older version than the latest release
            if v(constants.mercuryVersion) < v(version) then
                local findOS = "ubuntu"
                local findArch = jit.arch
                if isHostWindows() then
                    findOS = "windows"
                end
                dprint(findOS)
                dprint(findArch)
                for _, asset in pairs(release.assets) do
                    if asset.name:find(findOS) and asset.name:find(findArch) then
                        local outputPath = gpath(paths.mercuryDownloads, "/", asset.name)
                        dprint(outputPath)
                        local url = asset.browser_download_url:gsub("https://github.com",
                                                                    constants.githubPass)
                        dprint(url)
                        cprint("Downloading new Mercury version " .. version)
                        local code = download.url(url, outputPath)
                        if code == 200 then
                            if isHostWindows() then
                                os.execute(("explorer \"%s\""):format(outputPath))
                                -- os.execute(("explorer \"%s\""):format(url))
                            else
                                cprint("Installing binary in system using sudo...")
                                if not IsDebugModeEnabled then
                                    os.execute(([[sudo install "%s" /usr/bin/mercury]]):format(
                                                   outputPath))
                                end
                                -- GNOME only!
                                -- os.execute(("gio open \"%s\" &"):format(outputPath))
                                -- os.execute(("sensible-browser \"%s\""):format(url))
                            end
                            cprint("Success, " .. release.name ..
                                       " has been downloaded succesfully.")
                            return false
                        end
                    end
                end
                cprint("Error, at downloading new Mercury version.")
                return false
            end
        end
    end
    return true
end

return latest
