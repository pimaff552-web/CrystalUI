--============================================================--
--  Crystal UI | elements/input.lua
--  macOS text field with accent focus ring.
--
--  Tab:CreateInput({ Name, Description?, PlaceholderText,
--     Default, Numeric, ClearOnFocus?, RemoveTextAfterFocusLost?,
--     Flag?, Callback(text) })
--============================================================--

local Import = ...
local Utility = Import("src/utility.lua")
local Creator = Import("src/creator.lua")
local Shared = Import("src/elements/shared.lua")

local New = Creator.New

local Input = {}

local BOX_W = 170
local BOX_H = 28

function Input.New(options, Ctx)
	options = options or {}
	local row, _, control, left = Shared.Row(Ctx, options)

	local focusRing = New("UIStroke", {
		Name = "FocusRing",
		Thickness = 2,
		Transparency = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, nil, { Color = "Accent" })

	local baseStroke = Creator.Stroke("ControlStroke", 1, 0.88)

	local box = New("TextBox", {
		Name = "Field",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, BOX_W, 0, BOX_H),
		BorderSizePixel = 0,
		Font = Utility.Fonts.Regular,
		TextSize = 12.5,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = tostring(options.Default or options.CurrentValue or ""),
		PlaceholderText = tostring(options.PlaceholderText or options.Placeholder or "Text…"),
		ClearTextOnFocus = options.ClearOnFocus and true or false,
		ClipsDescendants = true,
	}, {
		Creator.Corner(7),
		baseStroke,
		focusRing,
		New("UIPadding", {
			PaddingLeft = UDim.new(0, 9),
			PaddingRight = UDim.new(0, 9),
		}),
	}, { BackgroundColor3 = "Control", TextColor3 = "Text", PlaceholderColor3 = "Placeholder" })

	control.Size = UDim2.new(0, BOX_W, 0, BOX_H)
	box.Parent = control
	Shared.ReserveLeft(left, BOX_W)

	local self = Shared.Object(Ctx, "Input", row, options)
	self.Value = box.Text

	Shared.RowHover(row, self._conns)

	Creator.AddSignal(self._conns, box.Focused, function()
		Utility.Tween(focusRing, { Time = 0.14 }, { Transparency = 0.15 })
		Utility.Tween(baseStroke, { Time = 0.14 }, { Transparency = 1 })
	end)

	Creator.AddSignal(self._conns, box.FocusLost, function(enterPressed)
		Utility.Tween(focusRing, { Time = 0.18 }, { Transparency = 1 })
		Utility.Tween(baseStroke, { Time = 0.18 }, { Transparency = 0.88 })

		local text = box.Text
		if options.Numeric then
			local cleaned = string.gsub(text, "[^%d%.%-%+]", "")
			if cleaned ~= text then
				box.Text = cleaned
				text = cleaned
			end
		end
		self.Value = text
		Utility.SafeCall("Input:" .. tostring(options.Name), options.Callback, text, enterPressed)
		self:_touchConfig()

		if options.RemoveTextAfterFocusLost then
			box.Text = ""
			self.Value = ""
		end
	end)

	function self.Set(text, fireCallback)
		text = tostring(text == nil and "" or text)
		box.Text = text
		self.Value = text
		if fireCallback ~= false then
			Utility.SafeCall("Input:" .. tostring(options.Name), options.Callback, text, true)
			self:_touchConfig()
		end
	end

	function self.Serialize()
		return self.Value
	end

	function self.Deserialize(v)
		return tostring(v == nil and "" or v)
	end

	return self
end

return Input
