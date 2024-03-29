-----------------------------------------------------------------------------
-- FDownload: Module to download files using ftp, http, https
-- Sledmine
-- Author: Diego Nehab
-- Source: (https://github.com/diegonehab/luasocket/blob/master/etc/get.lua)
-----------------------------------------------------------------------------
local socket = require "socket"
local http = require "socket.http"
local https = require "socket.https"
local timeout = 60
local ftp = require "socket.ftp"
local url = require "socket.url"
local ltn12 = require "ltn12"
local constants = require "modules.constants"

local _M = {}

-- formats a number of seconds into human readable form
function nicetime(s)
    local l = "s"
    if s > 60 then
        s = s / 60
        l = "m"
        if s > 60 then
            s = s / 60
            l = "h"
            if s > 24 then
                s = s / 24
                l = "d" -- hmmm
            end
        end
    end
    if l == "s" then
        return string.format("%5.0f%s", s, l)
    else
        return string.format("%5.2f%s", s, l)
    end
end

-- formats a number of bytes into human readable form
function nicesize(b)
    local l = "B"
    if b > 1024 then
        b = b / 1024
        l = "KB"
        if b > 1024 then
            b = b / 1024
            l = "MB"
            if b > 1024 then
                b = b / 1024
                l = "GB" -- hmmm
            end
        end
    end
    return string.format("%7.2f%2s", b, l)
end

-- returns a string with the current state of the download
local remaining_s = "%s received, %s/s throughput, %2.0f%% done, %s remaining"
local elapsed_s = "%s received, %s/s throughput, %s elapsed                "
local 
function gauge(got, delta, size)
    local rate = got / delta
    -- return a progress bar if we have a size
    if size and size >= 1 then
        local progress = got / size
        local progressSize = constants.maximumProgressSize * progress
        local bar = string.rep(constants.progressSymbolFull, progressSize)
        bar = bar .. string.rep(constants.progressSymbolEmpty, constants.maximumProgressSize - progressSize)
        return string.format("%s %2.0f%% (%s)", bar, 100 * progress, nicesize(got))
    else
        -- return full bar size progress with elapsed time
        local bar = string.rep(constants.progressSymbolFull, constants.maximumProgressSize)
        return string.format("%s 100%% (%s)                   ", bar, nicesize(got))
    end
end

-- creates a new instance of a receive_cb that saves to disk
-- kind of copied from luasocket's manual callback examples
function stats(size)
    local start = socket.gettime()
    local last = start
    local got = 0
    return function(chunk)
        -- elapsed time since start
        local current = socket.gettime()
        if chunk then
            -- total bytes received
            got = got + string.len(chunk)
            -- not enough time for estimate
            if current - last > 1 then
                io.stderr:write("\r", gauge(got, current - start, size))
                io.stderr:flush()
                last = current
            end
        else
            -- close up
            io.stderr:write("\r", gauge(got, current - start), "\n")
            io.stderr:flush()
        end
        return chunk
    end
end

-- determines the size of a https file
function gethttpssize(u)
    local r, c, h = https.request {
        method = "HEAD",
        url = u
    }
    if c == 200 then
        return tonumber(h["content-length"])
    end
end

-- determines the size of a http file
function gethttpsize(u)
    local r, c, h = http.request {
        method = "HEAD",
        url = u
    }
    if c == 200 then
        return tonumber(h["content-length"])
    end
end

-- downloads a file using the https protocol
function getbyhttps(u, file)
    local d
    -- create a function to redirect data in case of not giving an output file
    local function redirect(input)
        d = input
    end
    local save = ltn12.sink.file(file or io.stdout)
    -- save data to file if it was specified otherway return it as string
    if file then
        save = ltn12.sink.chain(stats(gethttpssize(u)), save)
    else
        save = redirect
    end
    https.TIMEOUT = timeout
    local r, c, h, s = https.request {
        url = u,
        sink = save
    }
    --[[if c ~= 200 then io.stderr:write(s or c, "\n")
    end]]
    return r, c, h, s, d
end

-- downloads a file using the http protocol
function getbyhttp(u, file)
    local d
    -- create a function to redirect data in case of not giving an output file
    local function redirect(input)
        d = input
    end
    local save = ltn12.sink.file(file or io.stdout)
    -- save data to file if it was specified otherway return it as string
    if file then
        save = ltn12.sink.chain(stats(gethttpsize(u)), save)
    else
        save = redirect
    end
    http.TIMEOUT = timeout
    local r, c, h, s = http.request {
        url = u,
        sink = save
    }
    --[[if c ~= 200 then io.stderr:write(s or c, "\n")
    end]]
    return r, c, h, s, d
end

-- downloads a file using the ftp protocol
function getbyftp(u, file)
    local save = ltn12.sink.file(file or io.stdout)
    -- only print feedback if output is not stdout
    -- and we don't know how big the file is
    if file then
        save = ltn12.sink.chain(stats(), save)
    end
    local gett = url.parse(u)
    gett.sink = save
    gett.type = "i"
    local ret, err = ftp.get(gett)
    if err then
        print(err)
    end
end

-- determines the scheme
function getscheme(u)
    -- this is an heuristic to solve a common invalid url poblem
    if not string.find(u, "//") then                         
        u = "//" .. u
    end
    local parsed = url.parse(u, {scheme = "http"})
    return parsed.scheme
end

-- gets a file either by http or ftp, saving as <name>
function get(u, name)
    if (u) then
        local fout = name and io.open(name, "wb")
        local scheme = getscheme(u)
        if scheme == "ftp" then
            getbyftp(u, fout)
        elseif scheme == "http" then
            return getbyhttp(u, fout)
        elseif scheme == "https" then
            return getbyhttps(u, fout)
        else
            print("unknown scheme" .. scheme)
        end
    else
        error(debug.traceback("An HTTP based download should have a url!", 2))
    end
end

_M.get = get

return _M
