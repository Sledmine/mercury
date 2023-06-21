local luna = {
    _VERSION = "1.0.0",
}

luna.string = {}

--- Split a string into a table of substrings by `sep`.
---@param s string
---@param sep string
---@return string[]
---@nodiscard
function string.split(s, sep)
    assert(s ~= nil, "string.split: s must not be nil")
    local fields = {}
    local pattern = string.format("([^%s]+)", sep)
    local _ = s:gsub(pattern, function(c)
        fields[#fields + 1] = c
    end)
    return fields
end

--- Return a string with all leading whitespace removed.
---@param s string
---@return string
---@nodiscard
function string.ltrim(s)
    assert(s ~= nil, "string.ltrim: s must not be nil")
    return s:match "^%s*(.-)$"
end

--- Return a string with all trailing whitespace removed.
---@param s string
---@return string
---@nodiscard
function string.rtrim(s)
    assert(s ~= nil, "string.rtrim: s must not be nil")
    return s:match "^(.-)%s*$"
end

--- Return a string with all leading and trailing whitespace removed.
---@param s string
---@return string
---@nodiscard
function string.trim(s)
    assert(s ~= nil, "string.trim: s must not be nil")
    -- return s:match "^%s*(.-)%s*$"
    return string.ltrim(string.rtrim(s))
end

--- Return a string with all ocurrences of `pattern` replaced with `replacement`.
---
--- **NOTE**: Pattern is a plain string, not a Lua pattern. Use `string.gsub` for Lua patterns.
---@param s string
---@param pattern string
---@param replacement string
---@return string
---@nodiscard
function string.replace(s, pattern, replacement)
    assert(s ~= nil, "string.replace: s must not be nil")
    assert(pattern ~= nil, "string.replace: pattern must not be nil")
    assert(replacement ~= nil, "string.replace: replacement must not be nil")
    local pattern = pattern:gsub("%%", "%%%%"):gsub("%z", "%%z"):gsub("([%^%$%(%)%.%[%]%*%+%-%?])",
                                                                      "%%%1")
    local replaced, _ = s:gsub(pattern, replacement)
    return replaced
end

--- Return a hex encoded string.
---@param s string
---@return string
---@nodiscard
function string.tohex(s)
    assert(s ~= nil, "string.hex: s must not be nil")
    return (s:gsub(".", function(c)
        return string.format("%02x", string.byte(c))
    end))
end

--- Return a hex decoded string.
---@param s string
---@return string
---@nodiscard
function string.fromhex(s)
    assert(s ~= nil, "string.fromhex: s must not be nil")
    return (s:gsub("..", function(cc)
        return string.char(tonumber(cc, 16))
    end))
end

--- Resturn if a string starts with a given substring.
---@param s string
---@param start string
---@return boolean
---@nodiscard
function string.startswith(s, start)
    assert(s ~= nil, "string.startswith: s must not be nil")
    assert(start ~= nil, "string.startswith: start must not be nil")
    return string.sub(s, 1, string.len(start)) == start
end

--- Resturn if a string ends with a given substring.
---@param s string
---@param ending string
---@return boolean
---@nodiscard
function string.endswith(s, ending)
    assert(s ~= nil, "string.endswith: s must not be nil")
    assert(ending ~= nil, "string.endswith: ending must not be nil")
    return ending == "" or string.sub(s, -string.len(ending)) == ending
end

--- Return a string with template variables replaced with values from a table.
---@param s string
---@param t table<string, string | number | boolean>
---@return string
---@nodiscard
function string.template(s, t)
    assert(s ~= nil, "string.template: s must not be nil")
    assert(t ~= nil, "string.template: t must not be nil")
    return (s:gsub("{(.-)}", function(k)
        return t[k] or ""
    end))
end

--- Return if a string includes a given substring.
---@param s string
---@param substring string
---@return boolean
---@nodiscard
function string.includes(s, substring)
    assert(s ~= nil, "string.includes: s must not be nil")
    assert(substring ~= nil, "string.includes: substring must not be nil")
    return string.find(s, substring, 1, true) ~= nil
end

luna.string.split = string.split
luna.string.ltrim = string.ltrim
luna.string.rtrim = string.rtrim
luna.string.trim = string.trim
luna.string.replace = string.replace
luna.string.tohex = string.tohex
luna.string.fromhex = string.fromhex
luna.string.startswith = string.startswith
luna.string.endswith = string.endswith
luna.string.template = string.template
luna.string.includes = string.includes

luna.table = {}

--- Return a deep copy of a table.
---@generic T
---@param t T
---@return T
---@nodiscard
function table.copy(t)
    assert(t ~= nil, "table.copy: t must not be nil")
    assert(type(t) == "table", "table.copy: t must be a table")
    local u = {}
    for k, v in pairs(t) do
        u[k] = type(v) == "table" and table.copy(v) or v
    end
    return setmetatable(u, getmetatable(t))
end

--- Find and return first index of `value` in `t`.
---@generic V
---@param t table<number, V>: { [number]: V }
---@param value V
---@return number?
---@nodiscard
function table.indexof(t, value)
    assert(t ~= nil, "table.find: t must not be nil")
    assert(type(t) == "table", "table.find: t must be a table")
    for i, v in ipairs(t) do
        if v == value then
            return i
        end
    end
end

-- TODO Check annotations, it seems like flipping a table key pairs with generics doesn't work.
--- Return a table with all keys and values swapped.
---@generic K, V
---@param t table<K, V>
---@return table<V, K>
---@nodiscard
function table.flip(t)
    assert(t ~= nil, "table.flip: t must not be nil")
    assert(type(t) == "table", "table.flip: t must be a table")
    local u = {}
    for k, v in pairs(t) do
        u[v] = k
    end
    return u
end

--- Returns the first element of `t` that satisfies the predicate `f`.
---@generic K, V
---@param t table<K, V>
---@param f fun(v: V, k: K): boolean
---@return V?
---@nodiscard
function table.find(t, f)
    assert(t ~= nil, "table.find: t must not be nil")
    assert(type(t) == "table", "table.find: t must be a table")
    assert(f ~= nil, "table.find: f must not be nil")
    assert(type(f) == "function", "table.find: f must be a function")
    for k, v in pairs(t) do
        if f(v, k) then
            return v
        end
    end
end

--- Returns a list of all keys in `t`.
---@generic K, V
---@param t table<K, V>
---@return K[]
---@nodiscard
function table.keys(t)
    assert(t ~= nil, "table.keys: t must not be nil")
    assert(type(t) == "table", "table.keys: t must be a table")
    local keys = {}
    for k in pairs(t) do
        keys[#keys + 1] = k
    end
    return keys
end

--- Returns a list of all values in `t`.
---@generic K, V
---@param t table<K, V>
---@return V[]
---@nodiscard
function table.values(t)
    assert(t ~= nil, "table.values: t must not be nil")
    assert(type(t) == "table", "table.values: t must be a table")
    local values = {}
    for _, v in pairs(t) do
        values[#values + 1] = v
    end
    return values
end

--- Returns a table with all elements of `t` that satisfy the predicate `f`.
--- 
--- **NOTE**: It keeps original keys in the new table.
---@generic K, V
---@param t table<K, V>
---@param f fun(v: V, k: K): boolean
---@return table<K, V>
---@nodiscard
function table.filter(t, f)
    assert(t ~= nil, "table.filter: t must not be nil")
    assert(type(t) == "table", "table.filter: t must be a table")
    assert(f ~= nil, "table.filter: f must not be nil")
    assert(type(f) == "function", "table.filter: f must be a function")
    local filtered = {}
    for k, v in pairs(t) do
        if f(v, k) then
            filtered[k] = v
        end
    end
    return filtered
end

--- Returns a table with all elements of `t` mapped by the function `f`.
---
--- **NOTE**: It keeps original keys in the new table.
---@generic K, V, R
---@param t table<K, V>
---@param f fun(v: V, k: K): R
---@return table<K, R>
---@nodiscard
function table.map(t, f)
    assert(t ~= nil, "table.map: t must not be nil")
    assert(type(t) == "table", "table.map: t must be a table")
    assert(f ~= nil, "table.map: f must not be nil")
    assert(type(f) == "function", "table.map: f must be a function")
    local mapped = {}
    for k, v in pairs(t) do
        mapped[k] = f(v, k)
    end
    return mapped
end

--- Returns a table merged from all tables passed as arguments.
---@generic K, V
---@vararg table<K, V>
---@return table<K, V>
---@nodiscard
function table.merge(...)
    local merged = {}
    for _, t in ipairs { ... } do
        for k, v in pairs(t) do
            merged[k] = v
        end
    end
    return merged
end

luna.table.copy = table.copy
luna.table.indexof = table.indexof
luna.table.flip = table.flip
luna.table.find = table.find
luna.table.keys = table.keys
luna.table.values = table.values
luna.table.filter = table.filter
luna.table.map = table.map

luna.file = {}

--- Read a file as text and return its contents.
---@param path string
---@return string?
---@nodiscard
function luna.file.read(path)
    assert(path ~= nil, "file.read: path must not be nil")
    local file = io.open(path, "r")
    if file then
        local content = file:read "*a"
        file:close()
        return content
    end
end

--- Write text to a file.
---@param path string
---@param content string
---@return boolean
function luna.file.write(path, content)
    assert(path ~= nil, "file.write: path must not be nil")
    assert(content ~= nil, "file.write: content must not be nil")
    local file = io.open(path, "w")
    if file then
        file:write(content)
        file:close()
        return true
    end
    return false
end

return luna
