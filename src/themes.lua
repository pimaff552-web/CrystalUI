--============================================================--
--  Crystal UI | themes.lua
--  macOS theme palettes + live theme switching engine.
--  Elements register "theme tags" (property -> palette key);
--  Themes.SetTheme tweens every tagged instance to the new
--  palette, then fires change callbacks for stateful colors.
--============================================================--

local Import = ...
local Utility = Import("src/utility.lua")

local Themes = {}
Themes.Current = "Dark"
Themes.Objects = setmetatable({}, { __mode = "k" }) -- instance -> {property = key}
Themes._Connections = {}

local White = Color3.fromRGB(255, 255, 255)

Themes.List = {
	Dark = {
		Window        = Color3.fromRGB(30, 30, 32),
		Sidebar       = Color3.fromRGB(38, 38, 41),
		SidebarHover  = Color3.fromRGB(255, 255, 255),
		Selection     = Color3.fromRGB(58, 58, 63),
		Group         = Color3.fromRGB(39, 39, 43),
		GroupStroke   = Color3.fromRGB(255, 255, 255),
		Separator     = Color3.fromRGB(255, 255, 255),
		RowHover      = Color3.fromRGB(255, 255, 255),
		Text          = Color3.fromRGB(245, 245, 247),
		SubText       = Color3.fromRGB(152, 152, 160),
		Placeholder   = Color3.fromRGB(110, 110, 118),
		Accent        = Color3.fromRGB(10, 132, 255),
		AccentHover   = Color3.fromRGB(48, 150, 255),
		OnAccent      = White,
		Control       = Color3.fromRGB(47, 47, 52),
		ControlHover  = Color3.fromRGB(56, 56, 62),
		ControlStroke = Color3.fromRGB(255, 255, 255),
		SwitchOff     = Color3.fromRGB(58, 58, 63),
		Knob          = White,
		Track         = Color3.fromRGB(58, 58, 63),
		Scroll        = Color3.fromRGB(255, 255, 255),
		Danger        = Color3.fromRGB(255, 69, 58),
		Warning       = Color3.fromRGB(255, 214, 10),
		Success       = Color3.fromRGB(48, 209, 88),
		Close         = Color3.fromRGB(255, 95, 87),
		Min           = Color3.fromRGB(254, 188, 46),
		Max           = Color3.fromRGB(40, 200, 64),
		TrafficGlyph  = Color3.fromRGB(77, 13, 7),
		Overlay       = Color3.fromRGB(0, 0, 0),
		Shadow        = Color3.fromRGB(0, 0, 0),
		Popover       = Color3.fromRGB(43, 43, 48),
		PopoverStroke = Color3.fromRGB(255, 255, 255),
	},

	Light = {
		Window        = Color3.fromRGB(245, 245, 247),
		Sidebar       = Color3.fromRGB(236, 236, 240),
		SidebarHover  = Color3.fromRGB(0, 0, 0),
		Selection     = Color3.fromRGB(220, 220, 226),
		Group         = Color3.fromRGB(255, 255, 255),
		GroupStroke   = Color3.fromRGB(0, 0, 0),
		Separator     = Color3.fromRGB(0, 0, 0),
		RowHover      = Color3.fromRGB(0, 0, 0),
		Text          = Color3.fromRGB(29, 29, 31),
		SubText       = Color3.fromRGB(110, 110, 115),
		Placeholder   = Color3.fromRGB(174, 174, 178),
		Accent        = Color3.fromRGB(0, 122, 255),
		AccentHover   = Color3.fromRGB(20, 140, 255),
		OnAccent      = White,
		Control       = Color3.fromRGB(236, 236, 239),
		ControlHover  = Color3.fromRGB(228, 228, 232),
		ControlStroke = Color3.fromRGB(0, 0, 0),
		SwitchOff     = Color3.fromRGB(233, 233, 234),
		Knob          = White,
		Track         = Color3.fromRGB(228, 228, 232),
		Scroll        = Color3.fromRGB(0, 0, 0),
		Danger        = Color3.fromRGB(255, 59, 48),
		Warning       = Color3.fromRGB(255, 149, 0),
		Success       = Color3.fromRGB(40, 205, 65),
		Close         = Color3.fromRGB(255, 95, 87),
		Min           = Color3.fromRGB(254, 188, 46),
		Max           = Color3.fromRGB(40, 200, 64),
		TrafficGlyph  = Color3.fromRGB(77, 13, 7),
		Overlay       = Color3.fromRGB(0, 0, 0),
		Shadow        = Color3.fromRGB(0, 0, 0),
		Popover       = Color3.fromRGB(255, 255, 255),
		PopoverStroke = Color3.fromRGB(0, 0, 0),
	},

	Midnight = {
		Window        = Color3.fromRGB(0, 0, 0),
		Sidebar       = Color3.fromRGB(10, 10, 13),
		SidebarHover  = Color3.fromRGB(255, 255, 255),
		Selection     = Color3.fromRGB(30, 30, 36),
		Group         = Color3.fromRGB(14, 14, 18),
		GroupStroke   = Color3.fromRGB(255, 255, 255),
		Separator     = Color3.fromRGB(255, 255, 255),
		RowHover      = Color3.fromRGB(255, 255, 255),
		Text          = Color3.fromRGB(242, 242, 247),
		SubText       = Color3.fromRGB(142, 142, 150),
		Placeholder   = Color3.fromRGB(99, 99, 106),
		Accent        = Color3.fromRGB(94, 92, 230),
		AccentHover   = Color3.fromRGB(114, 112, 240),
		OnAccent      = White,
		Control       = Color3.fromRGB(20, 20, 26),
		ControlHover  = Color3.fromRGB(28, 28, 34),
		ControlStroke = Color3.fromRGB(255, 255, 255),
		SwitchOff     = Color3.fromRGB(42, 42, 48),
		Knob          = White,
		Track         = Color3.fromRGB(42, 42, 48),
		Scroll        = Color3.fromRGB(255, 255, 255),
		Danger        = Color3.fromRGB(255, 69, 58),
		Warning       = Color3.fromRGB(255, 214, 10),
		Success       = Color3.fromRGB(48, 209, 88),
		Close         = Color3.fromRGB(255, 95, 87),
		Min           = Color3.fromRGB(254, 188, 46),
		Max           = Color3.fromRGB(40, 200, 64),
		TrafficGlyph  = Color3.fromRGB(77, 13, 7),
		Overlay       = Color3.fromRGB(0, 0, 0),
		Shadow        = Color3.fromRGB(0, 0, 0),
		Popover       = Color3.fromRGB(18, 18, 24),
		PopoverStroke = Color3.fromRGB(255, 255, 255),
	},
}

function Themes.RegisterTheme(name, palette)
	if type(name) ~= "string" or type(palette) ~= "table" then
		return false
	end
	local base = Utility.DeepCopy(Themes.List.Dark)
	Themes.List[name] = Utility.Merge(base, palette)
	return true
end

function Themes.Get(name)
	return Themes.List[name] or Themes.List.Dark
end

function Themes.Palette()
	return Themes.Get(Themes.Current)
end

function Themes.ThemeNames()
	local names = {}
	for name, _ in pairs(Themes.List) do
		names[#names + 1] = name
	end
	table.sort(names)
	return names
end

-- Applies a palette key instantly to one property.
local function applyKey(instance, property, key, palette)
	local value = palette[key]
	if typeof(value) ~= "Color3" then
		return
	end
	pcall(function()
		instance[property] = value
	end)
end

-- Tag an instance: tags = { BackgroundColor3 = "Group", TextColor3 = "Text" }
function Themes.Tag(instance, tags)
	if instance == nil or type(tags) ~= "table" then
		return instance
	end
	Themes.Objects[instance] = tags
	local palette = Themes.Palette()
	local colorProps = {}
	for property, key in pairs(tags) do
		colorProps[property] = palette[key] or instance[property]
	end
	pcall(function()
		Utility.SetProperties(instance, colorProps)
	end)
	return instance
end

function Themes.Untag(instance)
	Themes.Objects[instance] = nil
end

-- Live theme switch with animation.
function Themes.SetTheme(nameOrTable, animTime)
	local palette
	if type(nameOrTable) == "string" then
		if not Themes.List[nameOrTable] then
			return false
		end
		Themes.Current = nameOrTable
		palette = Themes.List[nameOrTable]
	elseif type(nameOrTable) == "table" then
		Themes.Current = "__Custom__"
		Themes.List.__Custom__ = Utility.Merge(Utility.DeepCopy(Themes.List.Dark), nameOrTable)
		palette = Themes.List.__Custom__
	else
		return false
	end

	animTime = animTime or 0.25
	for instance, tags in pairs(Themes.Objects) do
		if typeof(instance) == "Instance" then
			local goal = {}
			local has = false
			for property, key in pairs(tags) do
				local value = palette[key]
				if typeof(value) == "Color3" then
					goal[property] = value
					has = true
				end
			end
			if has then
				Utility.Tween(instance, { Time = animTime, Style = Enum.EasingStyle.Quad }, goal)
			end
		else
			Themes.Objects[instance] = nil
		end
	end

	local callbacks = Themes._Connections
	for i = 1, #callbacks do
		Utility.SafeCall("Themes", callbacks[i], Themes.Current, palette)
	end
	return true
end

-- Callbacks receive (themeName, palette). Used by stateful elements (switches).
function Themes.OnChanged(callback)
	Themes._Connections[#Themes._Connections + 1] = callback
	local index = #Themes._Connections
	return function()
		Themes._Connections[index] = function() end
	end
end

return Themes
