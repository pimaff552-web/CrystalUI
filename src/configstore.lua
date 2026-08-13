--============================================================--
--  Crystal UI | configstore.lua
--  File-backed JSON config storage (executor filesystem).
--  Degrades gracefully in environments without writefile.
--============================================================--

local Import = ...
local Utility = Import("src/utility.lua")

local HttpService = game:GetService("HttpService")

local ConfigStore = {}

function ConfigStore.IsSupported()
	return Utility.CanWriteFiles()
end

local function ensureFolder(folder)
	if not folder or folder == "" then
		return
	end
	pcall(function()
		if type(isfolder) == "function" and type(makefolder) == "function" then
			if not isfolder(folder) then
				makefolder(folder)
			end
		end
	end)
end

local function buildPath(folder, file)
	if folder and folder ~= "" then
		return folder .. "/" .. file
	end
	return file
end

-- Read JSON file -> table ({} on any failure).
function ConfigStore.Read(folder, file)
	if not ConfigStore.IsSupported() then
		return {}
	end
	local path = buildPath(folder, file) .. ".json"
	local ok, result = pcall(function()
		if isfile(path) then
			local raw = readfile(path)
			if raw and #raw > 0 then
				return HttpService:JSONDecode(raw)
			end
		end
		return nil
	end)
	if ok and type(result) == "table" then
		return result
	end
	return {}
end

-- Write table -> JSON file. Returns success boolean.
function ConfigStore.Write(folder, file, data)
	if not ConfigStore.IsSupported() then
		return false
	end
	if type(data) ~= "table" then
		return false
	end
	local ok, err = pcall(function()
		ensureFolder(folder)
		local encoded = HttpService:JSONEncode(data)
		writefile(buildPath(folder, file) .. ".json", encoded)
	end)
	if not ok then
		warn(("[Crystal UI] Config write failed: %s"):format(tostring(err)))
	end
	return ok
end

function ConfigStore.Delete(folder, file)
	if not ConfigStore.IsSupported() then
		return false
	end
	local path = buildPath(folder, file) .. ".json"
	local ok = pcall(function()
		if isfile(path) and type(delfile) == "function" then
			delfile(path)
		end
	end)
	return ok
end

-- Plain string helpers (used by the key system).
function ConfigStore.ReadRaw(path)
	if type(isfile) ~= "function" or type(readfile) ~= "function" then
		return nil
	end
	local ok, content = pcall(function()
		if isfile(path) then
			return readfile(path)
		end
		return nil
	end)
	if ok then
		return content
	end
	return nil
end

function ConfigStore.WriteRaw(path, content)
	if type(writefile) ~= "function" then
		return false
	end
	local folder = string.match(path, "^(.*)/[^/]*$")
	if folder then
		ensureFolder(folder)
	end
	local ok = pcall(writefile, path, content)
	return ok
end

return ConfigStore
