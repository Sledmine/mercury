local json = require "cjson"
local template = require "resty.template"

local f = io.open("packagesList.json", "r")
local jsonContent = f:read("*all")

local packages = json.decode(jsonContent)

template.render("packagesIndex.html", {
    packages = packages
})