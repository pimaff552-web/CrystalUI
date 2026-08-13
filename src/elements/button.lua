--============================================================--
--  Crystal UI | elements/button.lua
--  macOS settings-row button: title left, accent pill right.
--  Whole row is clickable.
--
--  Tab:CreateButton({ Name, Description?, ButtonText?, Callback })
--============================================================--

local Import = ...
local Utility = Import("src/utility.lua")
local Creator = Import("src/creator.lua")
local Shared = Import("src/elements/shared.lua")

local New = Creator.New

local Button = {}

local DEFAULT_TEXTS = { "Run", "Open", "Start", "Apply", "Execute", "Go" }

function Button.New(options, Ctx)
	options = options or {}
	local row, _, control, left = Shared.Row(Ctx, options)

	local text = options.ButtonText or options.ButtonTitle or "Run"
	if type(text) ~= "string" or text == "" then
		text = "Run"
	end

	local label = New("TextLabel", {
		Name = "Label",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Font = Utility.Fonts.Medium,
		TextSize = 12.5,
		Text = text,
	}, nil, { TextColor3 = "OnAccent" })

	local textWidth = Utility.TextWidth(text, 12.5, Utility.Fonts.Medium)
	local pillWidth = Utility.Clamp(textWidth + 28, 64, 220)

	local pill = New("TextButton", {
		Name = "Pill",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, pillWidth, 0, 26),
		AutoButtonColor = false,
		Text = "",
		BorderSizePixel = 0,
	}, {
		Creator.Corner(7),
		label,
	}, { BackgroundColor3 = "Accent" })

	control.Size = UDim2.new(0, pillWidth, 0, 26)
	pill.Parent = control

	Shared.ReserveLeft(left, pillWidth)

	local self = Shared.Object(Ctx, "Button", row, options)
	self.Value = text

	Shared.RowHover(row, self._conns)

	local lastFire = 0
	local function fire()
		local now = os.clock()
		if now - lastFire < 0.12 then
			return
		end
		lastFire = now
		Utility.Tween(pill, { Time = 0.07 }, { Size = UDim2.new(0, math.max(56, pillWidth - 4), 0, 24) })
		task.delay(0.09, function()
			if pill and pill.Parent ~= nil then
				Utility.Tween(pill, { Time = 0.14, Style = Enum.EasingStyle.Back }, { Size = UDim2.new(0, pillWidth, 0, 26) })
			end
		end)
		Utility.SafeCall("Button:" .. tostring(options.Name), options.Callback)
	end

	Creator.AddSignal(self._conns, pill.Activated, fire)

	-- whole row click target
	local hitZone = New("TextButton", {
		Name = "HitZone",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -(pillWidth + 26), 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		Text = "",
		ZIndex = 2,
		Parent = row,
	})
	Creator.AddSignal(self._conns, hitZone.Activated, fire)

	function self.Set(newText)
		if type(newText) == "string" and newText ~= "" then
			text = newText
			self.Value = newText
			label.Text = newText
		end
	end

	function self.Fire()
		fire()
	end

	return self
end

return Button
