--============================================================--
--   ____                _        _   _   _ ___
--  / ___|_ __ _   _ ___| |_ __ _| | | | | |_ _|
-- | |   | '__| | | / __| __/ _` | | | | | || |
-- | |___| |  | |_| \__ \ || (_| | | | |_| || |
--  \____|_|   \__, |___/\__\__,_|_|  \___/|___|
--             |___/
--  Crystal UI — macOS-grade interface library for Roblox.
--  Version 1.0.0
--
--  USAGE:
--    local Crystal = loadstring(game:HttpGet(
--        "https://raw.githubusercontent.com/YOUR_USERNAME/CrystalUI/main/source.lua"
--    ))()
--
--  SETUP (one line): change BASE below to your GitHub repo,
--  or set getgenv().CrystalUI_Base BEFORE loading to override at runtime.
--============================================================--

local BASE = "https://raw.githubusercontent.com/pimaff552-web/CrystalUI/main/"

do
	local ok, override = pcall(function()
		if type(getgenv) == "function" and type(getgenv().CrystalUI_Base) == "string" then
			return getgenv().CrystalUI_Base
		end
		return nil
	end)
	if ok and type(override) == "string" and override ~= "" then
		BASE = override
	end
end

if string.sub(BASE, -1) ~= "/" then
	BASE = BASE .. "/"
end

local Cache = {}

-- Cache-buster: GitHub's raw CDN can serve stale files for several minutes
-- after you re-upload. A unique query parameter forces a fresh copy.
local CACHE_BUST = "?cb=" .. tostring(math.floor((os.clock() % 100000) * 1000))

local function httpGet(path)
	local url = BASE .. path .. CACHE_BUST
	local lastErr = nil
	for attempt = 1, 3 do
		local ok, result = pcall(function()
			return game:HttpGet(url, true)
		end)
		if ok and type(result) == "string" and #result > 0 then
			return result
		end
		lastErr = result
		task.wait(0.35 * attempt)
	end
	error(("[Crystal UI] Failed to fetch %s: %s"):format(url, tostring(lastErr)))
end

local function Import(path)
	if Cache[path] ~= nil then
		return Cache[path]
	end
	local source = httpGet(path)
	local chunk, compileErr = loadstring(source, "=" .. path)
	if not chunk then
		error(("[Crystal UI] Failed to compile %s: %s"):format(path, tostring(compileErr)))
	end
	local result = chunk(Import)
	Cache[path] = result
	return result
end

local Crystal = Import("src/crystal.lua")

return Crystal
