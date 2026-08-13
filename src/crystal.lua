--============================================================--
--  Crystal UI | src/crystal.lua
--  Main library module. Everything flows from here.
--
--  local Crystal = loadstring(game:HttpGet(
--      "https://raw.githubusercontent.com/<you>/CrystalUI/main/source.lua"
--  ))()
--============================================================--

local Import = ...

local Utility = Import("src/utility.lua")
local Themes = Import("src/themes.lua")
local Icons = Import("src/icons.lua")
local ConfigStore = Import("src/configstore.lua")
local Notifications = Import("src/notifications.lua")
local Acrylic = Import("src/acrylic.lua")
local WindowComponent = Import("src/components/window.lua")

local HttpService = game:GetService("HttpService")

local Crystal = {}

Crystal.Version = "1.1.0"
Crystal.Name = "Crystal UI"
Crystal.Options = setmetatable({}, {
	__index = function(_, key)
		return rawget(Crystal, "_flagMap") and Crystal._flagMap[key] or nil
	end,
})

Crystal.Themes = Themes
Crystal.Flags = {}
Crystal._flagMap = {}
Crystal._Window = nil
Crystal._Gui = nil
Crystal._WatermarkHandle = nil
Crystal._LogBuffer = {}
Crystal._ConsoleAppender = nil
Crystal._ConfigDirty = false
Crystal._ConfigSaving = false
Crystal._ConfigFolder = nil
Crystal._ConfigFile = nil
Crystal._destroyed = false

-- logging -----------------------------------------------------------------
function Crystal:Log(level, message)
	level = tostring(level or "info")
	local text = tostring(message)
	local stamp = os.date("%H:%M:%S")
	local entry = {
		Level = level,
		Text = text,
		Full = string.format("[%s] [%s] %s", stamp, string.upper(level), text),
	}
	if level == "error" then
		warn("[Crystal UI] " .. text)
	elseif level == "warn" then
		warn("[Crystal UI] " .. text)
	else
		print("[Crystal UI] " .. text)
	end
	if self._ConsoleAppender then
		Utility.SafeCall("Console", self._ConsoleAppender, entry)
	else
		self._LogBuffer[#self._LogBuffer + 1] = entry
		if #self._LogBuffer > 250 then
			table.remove(self._LogBuffer, 1)
		end
	end
end

function Crystal:_DrainLogs(append)
	for _, entry in pairs(self._LogBuffer) do
		Utility.SafeCall("Console", append, entry)
	end
	self._LogBuffer = {}
end

Utility.SetErrorHandler(function(context, message)
	warn(("[Crystal UI][%s] %s"):format(tostring(context), tostring(message)))
	if Crystal._ConsoleAppender then
		Utility.SafeCall("Console", Crystal._ConsoleAppender, {
			Level = "error",
			Full = string.format("[%s] [ERROR] %s: %s", os.date("%H:%M:%S"), tostring(context), tostring(message)),
		})
	end
end)

-- gui root -------------------------------------------------------------------
function Crystal:EnsureGui()
	if self._Gui and self._Gui.Parent ~= nil then
		return self._Gui
	end

	local parent = Utility.GetProtectedGuiParent()
	if not parent then
		error("[Crystal UI] Could not find a valid GUI parent.")
	end

	-- wipe leftovers from a previous session
	for _, child in pairs(parent:GetChildren()) do
		if child.Name == "CrystalUI" then
			pcall(function()
				child:Destroy()
			end)
		end
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "CrystalUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 999999
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = parent

	self._Gui = gui
	Notifications.Bind(gui)
	return gui
end

-- flags ----------------------------------------------------------------------
function Crystal:RegisterFlag(element)
	if element and element.Flag then
		self._flagMap[element.Flag] = element
	end
end

function Crystal:UnregisterFlag(flag)
	self._flagMap[flag] = nil
end

function Crystal:GetPendingConfig(flag)
	if self._PendingConfig and self._PendingConfig[flag] ~= nil then
		return self._PendingConfig[flag]
	end
	return nil
end

-- config persistence -----------------------------------------------------------
function Crystal:TouchConfig()
	self._ConfigDirty = true
	if self._ConfigSaving then
		return
	end
	self._ConfigSaving = true
	task.delay(0.5, function()
		self._ConfigSaving = false
		if self._ConfigDirty then
			self._ConfigDirty = false
			self:SaveConfiguration()
		end
	end)
end

function Crystal:SaveConfiguration()
	if not self._ConfigFile then
		return false
	end
	local data = {}
	for flag, element in pairs(self._flagMap) do
		if element and element.Serialize then
			local ok, value = pcall(function()
				return element:Serialize()
			end)
			if ok and value ~= nil then
				data[flag] = value
			end
		end
	end
	local written = ConfigStore.Write(self._ConfigFolder, self._ConfigFile, data)
	if written then
		self:Log("info", "Config saved (" .. tostring(self._ConfigFile) .. ")")
	end
	return written
end

function Crystal:LoadConfiguration()
	if not self._ConfigFile then
		return false
	end
	local data = ConfigStore.Read(self._ConfigFolder, self._ConfigFile)
	local applied = 0
	for flag, element in pairs(self._flagMap) do
		if element and element.Set and data[flag] ~= nil and element.Deserialize then
			Utility.SafeCall("ConfigLoad:" .. tostring(flag), function()
				element:Set(element:Deserialize(data[flag]), true)
			end)
			applied = applied + 1
		end
	end
	if applied > 0 then
		self:Log("info", "Config loaded (" .. tostring(applied) .. " values)")
	end
	return applied > 0
end

function Crystal:DeleteConfiguration()
	if not self._ConfigFile then
		return false
	end
	return ConfigStore.Delete(self._ConfigFolder, self._ConfigFile)
end

-- notifications ----------------------------------------------------------------
function Crystal:Notify(cfg)
	self:EnsureGui()
	return Notifications.Notify(cfg or {})
end

-- theme ------------------------------------------------------------------------
function Crystal:SetTheme(nameOrPalette)
	return Themes.SetTheme(nameOrPalette)
end

function Crystal:RegisterTheme(name, palette)
	return Themes.RegisterTheme(name, palette)
end

function Crystal:GetThemes()
	return Themes.ThemeNames()
end

function Crystal:GetTheme()
	return Themes.Current
end

-- misc --------------------------------------------------------------------------
function Crystal:IsMobile()
	return Utility.IsMobile()
end

-- window --------------------------------------------------------------------------
function Crystal:CreateWindow(config)
	config = config or {}
	self:EnsureGui()

	-- destroy any previous window first
	if self._Window then
		pcall(function()
			self._Window:Destroy()
		end)
		self._Window = nil
	end

	local KeySystem = Import("src/keysystem.lua")
	local Watermark = Import("src/watermark.lua")

	local window = WindowComponent.New(config, self)
	self._Window = window

	-- watermark (default ON unless explicitly false)
	if config.Watermark ~= false then
		self._WatermarkHandle = Watermark.New(self._Gui, {
			Name = tostring(config.Name or "Crystal UI"),
		})
	end

	-- config wiring
	local cs = config.ConfigurationSaving
	if type(cs) == "table" and cs.Enabled then
		self._ConfigFolder = tostring(cs.FolderName or "CrystalUI")
		self._ConfigFile = tostring(cs.FileName or "CrystalConfig")
		self._PendingConfig = ConfigStore.Read(self._ConfigFolder, self._ConfigFile)
	else
		self._ConfigFolder = nil
		self._ConfigFile = nil
		self._PendingConfig = nil
	end

	-- key system gate
	local function reveal()
		if Utility.IsMobile() then
			window:Show()
		else
			window:Reveal()
		end
		self:Log("success", "Window ready")
	end

	if config.KeySystem then
		local keySettings = config.KeySettings or {}
		if KeySystem.ValidateSaved(keySettings) then
			self:Log("success", "Saved key accepted")
			task.defer(reveal)
		else
			KeySystem.Run(self._Gui, keySettings, self, function()
				self:Log("success", "Key accepted")
				reveal()
			end, function()
				-- aborted (red traffic light)
				self:Destroy()
			end)
		end
	else
		task.defer(reveal)
	end

	return window
end

-- dialog passthrough ---------------------------------------------------------------
function Crystal:Dialog(options)
	self:EnsureGui()
	if self._Window then
		return self._Window:Dialog(options)
	end
	-- fallback tiny dialog when no window exists
	self:Notify({
		Title = (options and options.Title) or "Crystal UI",
		Content = options and options.Content or nil,
		Duration = 5,
		Icon = "info",
	})
	return nil
end

function Crystal:SetWatermarkVisible(visible)
	if self._WatermarkHandle then
		self._WatermarkHandle.SetVisible(visible)
	end
end

function Crystal:ForceSave()
	return self:SaveConfiguration()
end

-- destroy ----------------------------------------------------------------------------
function Crystal:Destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true
	if self._Window then
		pcall(function()
			self._Window:Destroy()
		end)
		self._Window = nil
	end
	if self._WatermarkHandle then
		pcall(function()
			self._WatermarkHandle.Destroy()
		end)
		self._WatermarkHandle = nil
	end
	Notifications.Destroy()
	Acrylic.ForceOff()
	self._ConsoleAppender = nil
	if self._Gui then
		pcall(function()
			self._Gui:Destroy()
		end)
		self._Gui = nil
	end
end

print(("[Crystal UI] v%s loaded — welcome."):format(Crystal.Version))

return Crystal
