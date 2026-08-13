--============================================================--
--  Crystal UI | icons.lua
--  Icon resolution. Accepts:
--    * icon names  -> built-in glyph (renders everywhere, no assets)
--    * "rbxassetid://123" / 123 / "http(s)://..." -> ImageLabel
--  This avoids broken community asset IDs entirely.
--============================================================--

local Import = ... -- unused

local Icons = {}

local Glyphs = {
	-- navigation / general
	home = "\u{1F3E0}", house = "\u{1F3E0}", menu = "\u{2261}", search = "\u{1F50D}",
	settings = "\u{2699}\u{FE0F}", gear = "\u{2699}\u{FE0F}", sliders = "\u{1F39A}\u{FE0F}",
	user = "\u{1F464}", users = "\u{1F465}", person = "\u{1F464}",
	bell = "\u{1F514}", notification = "\u{1F514}", info = "\u{2139}\u{FE0F}",
	warning = "\u{26A0}\u{FE0F}", alert = "\u{26A0}\u{FE0F}", error = "\u{274C}",
	check = "\u{2713}", checkmark = "\u{2713}", x = "\u{2715}", close = "\u{2715}",
	plus = "\u{2795}", minus = "\u{2796}", edit = "\u{270F}\u{FE0F}", pencil = "\u{270F}\u{FE0F}",
	trash = "\u{1F5D1}\u{FE0F}", delete = "\u{1F5D1}\u{FE0F}", save = "\u{1F4BE}",
	download = "\u{2B07}\u{FE0F}", upload = "\u{2B06}\u{FE0F}", refresh = "\u{1F504}",
	sync = "\u{1F504}", link = "\u{1F517}", globe = "\u{1F310}", web = "\u{1F310}",

	-- code / dev
	code = "\u{1F4BB}", terminal = "\u{2328}\u{FE0F}", bug = "\u{1F41B}",
	wrench = "\u{1F527}", hammer = "\u{1F528}", cpu = "\u{1F9E0}", brain = "\u{1F9E0}",
	database = "\u{1F5C4}\u{FE0F}", server = "\u{1F5A5}\u{FE0F}", console = "\u{1F5A5}\u{FE0F}",

	-- gaming
	sword = "\u{2694}\u{FE0F}", shield = "\u{1F6E1}\u{FE0F}", target = "\u{1F3AF}",
	gun = "\u{1F52B}", gamepad = "\u{1F3AE}", joystick = "\u{1F579}\u{FE0F}",
	dice = "\u{1F3B2}", puzzle = "\u{1F9E9}", trophy = "\u{1F3C6}", crown = "\u{1F451}",
	gem = "\u{1F48E}", diamond = "\u{1F48E}", crystal = "\u{1F48E}", coin = "\u{1FA99}",
	money = "\u{1F4B5}", dollar = "\u{1F4B5}", gift = "\u{1F381}", fire = "\u{1F525}",
	lightning = "\u{26A1}", zap = "\u{26A1}", star = "\u{2B50}", heart = "\u{2764}\u{FE0F}",
	rocket = "\u{1F680}", plane = "\u{2708}\u{FE0F}", car = "\u{1F697}", map = "\u{1F5FA}\u{FE0F}",
	compass = "\u{1F9ED}", flag = "\u{1F6A9}", anchor = "\u{2693}",

	-- media / files
	folder = "\u{1F4C1}", file = "\u{1F4C4}", image = "\u{1F5BC}\u{FE0F}",
	camera = "\u{1F4F7}", video = "\u{1F4F9}", music = "\u{1F3B5}", mic = "\u{1F3A4}",
	headphones = "\u{1F3A7}", volume = "\u{1F50A}", mute = "\u{1F507}", play = "\u{25B6}\u{FE0F}",
	pause = "\u{23F8}\u{FE0F}", stop = "\u{23F9}\u{FE0F}",

	-- communication
	chat = "\u{1F4AC}", message = "\u{1F4AC}", mail = "\u{2709}\u{FE0F}",
	send = "\u{1F4E4}", inbox = "\u{1F4E5}", phone = "\u{1F4F1}", mobile = "\u{1F4F1}",

	-- misc
	lock = "\u{1F512}", unlock = "\u{1F513}", key = "\u{1F511}", eye = "\u{1F441}\u{FE0F}",
	pin = "\u{1F4CD}", bookmark = "\u{1F516}", tag = "\u{1F3F7}\u{FE0F}",
	calendar = "\u{1F4C5}", clock = "\u{1F550}", timer = "\u{23F1}\u{FE0F}",
	wifi = "\u{1F4F6}", battery = "\u{1F50B}", sun = "\u{2600}\u{FE0F}", moon = "\u{1F319}",
	cloud = "\u{2601}\u{FE0F}", rainbow = "\u{1F308}", snowflake = "\u{2744}\u{FE0F}",
	sparkles = "\u{2728}", magic = "\u{2728}", robot = "\u{1F916}", ghost = "\u{1F47B}",
	skull = "\u{1F480}", package = "\u{1F4E6}", cart = "\u{1F6D2}", shop = "\u{1F6D2}",
	chart = "\u{1F4CA}", graph = "\u{1F4C8}", analytics = "\u{1F4C8}",
	book = "\u{1F4D6}", docs = "\u{1F4DA}", question = "\u{2753}", help = "\u{2753}",

	-- brand
	discord = "\u{1F4AC}", roblox = "\u{1F3AE}", macos = "\u{1F34E}", apple = "\u{1F34E}",

	-- chevrons / arrows
	["chevron-down"] = "\u{25BE}", ["chevron-up"] = "\u{25B4}",
	["chevron-right"] = "\u{25B8}", ["chevron-left"] = "\u{25C2}",
	arrowup = "\u{2191}", arrowdown = "\u{2193}", arrowleft = "\u{2190}", arrowright = "\u{2192}",
}

-- Resolve(icon) -> kind ("text" | "image"), value
function Icons.Resolve(value)
	if value == nil or value == "" then
		return "text", "\u{2726}" -- four-point star fallback
	end
	local valueType = typeof(value)
	if valueType == "number" then
		return "image", "rbxassetid://" .. tostring(value)
	end
	if valueType == "string" then
		local trimmed = string.gsub(value, "^%s*(.-)%s*$", "%1")
		if string.match(trimmed, "^rbxassetid://") then
			return "image", trimmed
		end
		if string.match(trimmed, "^%d+$") then
			return "image", "rbxassetid://" .. trimmed
		end
		if string.match(trimmed, "^https?://") then
			return "image", trimmed
		end
		local lower = string.lower(trimmed)
		if Glyphs[lower] then
			return "text", Glyphs[lower]
		end
		-- Unknown name: use it literally if it is short (likely an emoji the user passed)
		if utf8 and utf8.len(trimmed) and utf8.len(trimmed) <= 3 then
			return "text", trimmed
		end
		return "text", "\u{2726}"
	end
	return "text", "\u{2726}"
end

-- Creates either a TextLabel (glyph) or ImageLabel (asset).
function Icons.CreateIcon(value, props)
	local kind, resolved = Icons.Resolve(value)
	local className = (kind == "image") and "ImageLabel" or "TextLabel"
	local inst = Instance.new(className)
	inst.BackgroundTransparency = 1
	inst.Name = "Icon"
	if kind == "image" then
		inst.Image = resolved
		inst.ScaleType = Enum.ScaleType.Fit
	else
		inst.Text = resolved
		inst.Font = Enum.Font.Gotham
		inst.TextScaled = false
	end
	if type(props) == "table" then
		for key, val in pairs(props) do
			pcall(function()
				inst[key] = val
			end)
		end
	end
	return inst, kind
end

function Icons.IsGlyph(value)
	local kind = Icons.Resolve(value)
	return kind == "text"
end

return Icons
