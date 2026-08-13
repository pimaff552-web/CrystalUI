--============================================================--
--  Crystal UI | elements/keybind.lua
--  Key binding pill. Click to rebind, right-click to change mode
--  (Toggle / Hold / Always).
--
--  Tab:CreateKeybind({ Name, Description?, CurrentKeybind = "Q",
--     Mode = "Toggle"|"Hold"|"Always", Flag?, Callback(State) })
--============================================================--

local Import = ...
local Utility = Import("src/utility.lua")
local Creator = Import("src/creator.lua")
local Shared = Import("src/elements/shared.lua")

local New = Creator.New
local UserInputService = game:GetService("UserInputService")

local Keybind = {}

local MODES = { "Toggle", "Hold", "Always" }

function Keybind.New(options, Ctx)
	options = options or {}
	local row, _, control, left = Shared.Row(Ctx, options)

	local modeLabel = New("TextLabel", {
		Name = "Mode",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, -7),
		Size = UDim2.new(1, 0, 0, 10),
		Font = Utility.Fonts.Regular,
		TextSize = 9,
		Text = "",
		ZIndex = 2,
	}, nil, { TextColor3 = "Placeholder" })

	local keyLabel = New("TextLabel", {
		Name = "Key",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 0, 14),
		Font = Utility.Fonts.Bold,
		TextSize = 11.5,
		Text = "None",
		ZIndex = 2,
	}, nil, { TextColor3 = "Text" })

	local pill = New("TextButton", {
		Name = "Pill",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 64, 0, 26),
		AutoButtonColor = false,
		Text = "",
		BorderSizePixel = 0,
	}, {
		Creator.Corner(6),
		Creator.Stroke("ControlStroke", 1, 0.88),
		keyLabel,
		modeLabel,
	}, { BackgroundColor3 = "Control" })

	control.Size = UDim2.new(0, 64, 0, 26)
	pill.Parent = control
	Shared.ReserveLeft(left, 64)

	local self = Shared.Object(Ctx, "Keybind", row, options)

	self.Key = nil
	self.Mode = "Toggle"
	if type(options.Mode) == "string" then
		for _, m in pairs(MODES) do
			if string.lower(m) == string.lower(options.Mode) then
				self.Mode = m
			end
		end
	end
	self.State = false

	local listening = false

	local function updatePill(listenState)
		local displayKey = self.Key and Utility.ShortKeyName(self.Key) or "None"
		if listenState then
			displayKey = "…"
		end
		keyLabel.Text = displayKey
		local modeText = (self.Mode ~= "Toggle") and string.lower(self.Mode) or ""
		modeLabel.Text = modeText
		keyLabel.Position = (modeText ~= "")
			and UDim2.new(0.5, 0, 0.5, 4)
			or UDim2.new(0.5, 0, 0.5, 0)
		local w = Utility.TextWidth(displayKey, 11.5, Utility.Fonts.Bold) + 22
		w = Utility.Clamp(w, 44, 120)
		pill.Size = UDim2.new(0, w, 0, 26)
		control.Size = UDim2.new(0, w, 0, 26)
	end

	local function fireState(state)
		Utility.SafeCall("Keybind:" .. tostring(options.Name), options.Callback, state)
	end

	local function press()
		if self.Mode == "Toggle" then
			self.State = not self.State
			fireState(self.State)
		elseif self.Mode == "Hold" then
			self.State = true
			fireState(true)
		else -- Always
			fireState(true)
		end
	end

	local function release()
		if self.Mode == "Hold" and self.State then
			self.State = false
			fireState(false)
		end
	end

	-- global key listener ------------------------------------------------------
	self._conns[#self._conns + 1] = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if self._destroyed then
			return
		end
		if listening then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				if input.KeyCode == Enum.KeyCode.Escape then
					listening = false
					updatePill(false)
					return
				end
				listening = false
				self.Key = input.KeyCode
				self.State = false
				updatePill(false)
				self:_touchConfig()
			end
			return
		end
		if gameProcessed then
			return
		end
		if self.Key and input.KeyCode == self.Key then
			press()
		end
	end)

	self._conns[#self._conns + 1] = UserInputService.InputEnded:Connect(function(input)
		if self._destroyed then
			return
		end
		if self.Key and input.KeyCode == self.Key then
			release()
		end
	end)

	-- pill interactions --------------------------------------------------------
	Creator.AddSignal(self._conns, pill.Activated, function()
		listening = true
		updatePill(true)
	end)

	Creator.AddSignal(self._conns, pill.MouseButton2Click, function()
		local index = 1
		for i, m in pairs(MODES) do
			if m == self.Mode then
				index = i
			end
		end
		index = index % #MODES + 1
		self.Mode = MODES[index]
		self.State = false
		updatePill(false)
		if Ctx.Library and Ctx.Library.Notify then
			Ctx.Library:Notify({
				Title = tostring(options.Name or "Keybind"),
				Content = "Mode: " .. self.Mode,
				Duration = 1.6,
				Icon = "key",
			})
		end
		self:_touchConfig()
	end)

	Shared.RowHover(row, self._conns)

	function self.Set(keyName)
		if typeof(keyName) == "EnumItem" then
			self.Key = keyName
		elseif type(keyName) == "string" then
			local ok, keyCode = pcall(function()
				return Enum.KeyCode[keyName]
			end)
			if ok and keyCode then
				self.Key = keyCode
			else
				self.Key = nil
			end
		else
			self.Key = nil
		end
		self.State = false
		listening = false
		updatePill(false)
	end

	function self.Serialize()
		return {
			key = self.Key and self.Key.Name or nil,
			mode = self.Mode,
		}
	end

	function self.Deserialize(v)
		if type(v) == "table" then
			if v.mode then
				for _, m in pairs(MODES) do
					if string.lower(m) == string.lower(tostring(v.mode)) then
						self.Mode = m
					end
				end
			end
			return v.key
		end
		return v
	end

	-- initial key
	local initial = options.CurrentKeybind or options.Default
	if type(initial) == "string" or typeof(initial) == "EnumItem" then
		self:Set(initial)
	end
	updatePill(false)

	return self
end

return Keybind
