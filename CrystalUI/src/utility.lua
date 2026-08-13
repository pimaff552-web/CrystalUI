--============================================================--
--  Crystal UI | utility.lua
--  Shared helpers: tweens, colors, drag, safety, fonts.
--  Loaded through the Crystal loader (receives Import as ...).
--============================================================--

local Import = ... -- unused in this leaf module

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Utility = {}

-- Internal error handler (Crystal installs its logger here).
Utility._ErrorHandler = nil

function Utility.SetErrorHandler(fn)
	Utility._ErrorHandler = fn
end

-- SafeCall(context, fn, ...) -> pcall wrapper that reports through the handler.
function Utility.SafeCall(context, fn, ...)
	if type(fn) ~= "function" then
		return true, nil
	end
	local results = table.pack(pcall(fn, ...))
	local ok = table.remove(results, 1)
	if not ok then
		local message = tostring(results[1] or "unknown error")
		if Utility._ErrorHandler then
			Utility._ErrorHandler(context, message)
		else
			warn(("[Crystal UI][%s] %s"):format(tostring(context), message))
		end
		return false, nil
	end
	return true, table.unpack(results, 1, results.n)
end

-- Pick the first available font (guards against missing enum members).
local function pickFont(names, fallback)
	for i = 1, #names do
		local ok, font = pcall(function()
			return Enum.Font[names[i]]
		end)
		if ok and font then
			return font
		end
	end
	return fallback
end

Utility.Fonts = {
	Regular  = pickFont({ "BuilderSans", "Gotham" }, Enum.Font.Gotham),
	Medium   = pickFont({ "BuilderSansMedium", "GothamMedium" }, Enum.Font.GothamMedium),
	Bold     = pickFont({ "BuilderSansBold", "GothamBold" }, Enum.Font.GothamBold),
	ExtraBold = pickFont({ "BuilderSansExtraBold", "GothamBlack" }, Enum.Font.GothamBold),
	Mono     = pickFont({ "RobotoMono", "Code" }, Enum.Font.Code),
}

-- tween helper: Utility.Tween(instance, {Time=, Style=, Direction=, ...} or TweenInfo, goalTable)
function Utility.Tween(instance, params, goal)
	if instance == nil or goal == nil then
		return nil
	end
	local info
	if typeof(params) == "TweenInfo" then
		info = params
	else
		params = params or {}
		info = TweenInfo.new(
			params.Time or 0.2,
			params.Style or Enum.EasingStyle.Quint,
			params.Direction or Enum.EasingDirection.Out,
			params.RepeatCount or 0,
			params.Reverses or false,
			params.DelayTime or 0
		)
	end
	local ok, tween = pcall(function()
		return TweenService:Create(instance, info, goal)
	end)
	if ok and tween then
		tween:Play()
		return tween
	end
	return nil
end

-- Instant style apply (no animation), with pcall per property.
function Utility.SetProperties(instance, props)
	for key, value in pairs(props) do
		pcall(function()
			instance[key] = value
		end)
	end
end

function Utility.Clamp(value, minValue, maxValue)
	if value < minValue then return minValue end
	if value > maxValue then return maxValue end
	return value
end

function Utility.Round(value, increment)
	increment = increment or 1
	if increment == 0 then
		return value
	end
	return math.floor((value / increment) + 0.5) * increment
end

-- decimal places suggested by an increment (for slider labels)
function Utility.DecimalPlaces(increment)
	local text = tostring(increment)
	local dot = string.find(text, "%.")
	if dot then
		return #text - dot
	end
	local sci = string.find(text, "e%-")
	if sci then
		return tonumber(string.sub(text, sci + 2)) or 0
	end
	return 0
end

function Utility.ColorToHex(color)
	local function byte(v)
		return string.format("%02X", math.floor(Utility.Clamp(v, 0, 1) * 255 + 0.5))
	end
	return "#" .. byte(color.R) .. byte(color.G) .. byte(color.B)
end

function Utility.HexToColor(hex)
	if type(hex) ~= "string" then
		return nil
	end
	hex = string.gsub(hex, "#", "")
	if #hex == 3 then
		hex = string.gsub(hex, "(.)(.)(.)", "%1%1%2%2%3%3")
	end
	if #hex ~= 6 then
		return nil
	end
	local r = tonumber(string.sub(hex, 1, 2), 16)
	local g = tonumber(string.sub(hex, 3, 4), 16)
	local b = tonumber(string.sub(hex, 5, 6), 16)
	if not (r and g and b) then
		return nil
	end
	return Color3.fromRGB(r, g, b)
end

function Utility.DeepCopy(source)
	if type(source) ~= "table" then
		return source
	end
	local copy = {}
	for key, value in pairs(source) do
		copy[key] = Utility.DeepCopy(value)
	end
	return copy
end

-- Recursive merge: anything present in `overrides` wins.
function Utility.Merge(defaults, overrides)
	local out = Utility.DeepCopy(defaults)
	if type(overrides) ~= "table" then
		return out
	end
	for key, value in pairs(overrides) do
		if type(value) == "table" and type(out[key]) == "table" then
			out[key] = Utility.Merge(out[key], value)
		else
			out[key] = value
		end
	end
	return out
end

function Utility.IsMobile()
	local ok, result = pcall(function()
		return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	end)
	return ok and result or false
end

function Utility.ViewportSize()
	local ok, size = pcall(function()
		local camera = workspace.CurrentCamera
		if camera then
			return camera.ViewportSize
		end
		return Vector2.new(1280, 720)
	end)
	if ok and size then
		return size
	end
	return Vector2.new(1280, 720)
end

function Utility.FormatKey(keyCode)
	if typeof(keyCode) == "EnumItem" then
		return keyCode.Name
	end
	return tostring(keyCode)
end

local SHORT_KEYS = {
	RightShift = "RShift",
	LeftShift = "LShift",
	RightControl = "RCtrl",
	LeftControl = "LCtrl",
	RightAlt = "RAlt",
	LeftAlt = "LAlt",
	Backspace = "Bksp",
	CapsLock = "Caps",
	Escape = "Esc",
	Return = "Enter",
	Space = "Space",
	Unknown = "None",
}

function Utility.ShortKeyName(keyCode)
	local name = Utility.FormatKey(keyCode)
	return SHORT_KEYS[name] or name
end

-- Disconnect helper: accepts connections AND cleanup functions.
function Utility.DisconnectAll(list)
	if type(list) ~= "table" then
		return
	end
	for i = 1, #list do
		local item = list[i]
		if typeof(item) == "RBXScriptConnection" then
			pcall(function()
				item:Disconnect()
			end)
		elseif type(item) == "function" then
			pcall(item)
		end
		list[i] = nil
	end
end

-- Draggable behaviour. opts:
--   GetScale() -> number        (compensate UIScale)
--   Enabled()  -> boolean       (gate)
--   OnStart(), OnMove(target, delta), OnEnd()
function Utility.Drag(frame, handle, opts)
	opts = opts or {}
	local dragging = false
	local dragStart = nil
	local startPos = nil
	local connections = {}

	local function finishDrag()
		if dragging then
			dragging = false
			if opts.OnEnd then
				Utility.SafeCall("Drag", opts.OnEnd)
			end
		end
	end

	connections[#connections + 1] = handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			if opts.Enabled and not opts.Enabled() then
				return
			end
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			if opts.OnStart then
				Utility.SafeCall("Drag", opts.OnStart)
			end
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					finishDrag()
				end
			end)
		end
	end)

	connections[#connections + 1] = UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local scale = 1
		if opts.GetScale then
			scale = opts.GetScale() or 1
			if scale == 0 then
				scale = 1
			end
		end
		local delta = (input.Position - dragStart) / scale
		local target = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
		if opts.OnMove then
			local result = opts.OnMove(target, delta)
			if typeof(result) == "UDim2" then
				target = result
			end
		end
		frame.Position = target
	end)

	return function()
		finishDrag()
		Utility.DisconnectAll(connections)
	end
end

-- Measures single-line text width.
function Utility.TextWidth(text, size, font)
	local TextService = game:GetService("TextService")
	local ok, bounds = pcall(function()
		return TextService:GetTextSize(text or "", size, font, Vector2.new(10000, 10000))
	end)
	if ok and bounds then
		return bounds.X
	end
	return 0
end

-- Trims whitespace.
function Utility.Trim(text)
	return string.gsub(text or "", "^%s*(.-)%s*$", "%1")
end

-- Executor capability detection -------------------------------------------------

function Utility.CanWriteFiles()
	return type(writefile) == "function"
		and type(readfile) == "function"
		and type(isfile) == "function"
end

function Utility.SetClipboard(text)
	if type(setclipboard) == "function" then
		return pcall(setclipboard, tostring(text))
	end
	return false
end

function Utility.GetProtectedGuiParent()
	local parent = nil
	pcall(function()
		if type(gethui) == "function" then
			parent = gethui()
		end
	end)
	if parent then
		return parent
	end
	pcall(function()
		if syn and type(syn.protect_gui) == "function" then
			-- legacy synapse protection: unprotected parent, but CoreGui works
		end
	end)
	local okCore, coreGui = pcall(function()
		return game:GetService("CoreGui")
	end)
	if okCore and coreGui then
		local okTest = pcall(function()
			local probe = Instance.new("Folder")
			probe.Parent = coreGui
			probe:Destroy()
		end)
		if okTest then
			return coreGui
		end
	end
	local player = Players.LocalPlayer
	if player then
		local okPlayerGui, playerGui = pcall(function()
			return player:WaitForChild("PlayerGui", 10)
		end)
		if okPlayerGui and playerGui then
			return playerGui
		end
	end
	return nil
end

function Utility.RandomId(length)
	local chars = "abcdefghijklmnopqrstuvwxyz0123456789"
	local out = {}
	for i = 1, (length or 8) do
		local index = math.random(1, #chars)
		out[i] = string.sub(chars, index, index)
	end
	return table.concat(out)
end

return Utility
