local _M = {}

require "Mercury.lib.utilis"

local search = require "Mercury.actions.search"
local list = require "Mercury.actions.list"
local download = require "Mercury.actions.download"
local depackage = require "Mercury.actions.depackage"
local install = require "Mercury.actions.install"
local remove = require "Mercury.actions.remove"

local mitosis = require "Mercury.actions.mitosis"
local set = require "Mercury.actions.set"

_M.search = search
_M.list = list
_M.download = download
_M.depackage = depackage
_M.install = install
_M.remove = remove

_M.mitosis = mitosis
_M.set = set

return _M