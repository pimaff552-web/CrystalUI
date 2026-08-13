--============================================================--
--  Crystal UI | elements/toggle.lua
--  macOS switch. Row click toggles. Animated knob + track.
--
--  Tab:CreateToggle({ Name, Description?, CurrentValue, Flag?, Callback })
--============================================================--

local Import = ...
local Utility = Import("src/utility.lua")
local Creator = Import("src/creator.lua")
local Shared = Import("src/elements/shared.lua")

local New = Creator.New

local Toggle = {}

local TRACK_W = 42
local TRACK_H = 25
local KNOB = 21

function Toggle.New(options, Ctx)
	options = options or {}
	local row, _, control, left = Shared.Row(Ctx, options)

	local Themes = Ctx.Library.Themes

	local knob = New("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 2, 0.5, 0),
		Size = UDim2.new(0, KNOB, 0, KNOB),
		BorderSizePixel = 0,
		ZIndex = 2,
	}, {
		Creator.Corner(math.floor(KNOB / 2)),
		New("UIStroke", {
			Thickness = 1,
			Color = Color3.fromRGB(0, 0, 0),
			Transparency = 0.9,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
	}, { BackgroundColor3 = "Knob" })

	local track = New("TextButton", {
		Name = "Track",
		Size = UDim2.new(0, TRACK_W, 0, TRACK_H),
		Text = "",
		AutoButtonColor = false,
		BorderSizePixel = 0,
	}, {
		Creator.Corner(math.floor(TRACK_H / 2)),
		knob,
	})

	control.Size = UDim2.new(0, TRACK_W, 0, TRACK_H)
	track.Parent = control

	Shared.ReserveLeft(left, TRACK_W)

	local self = Shared.Object(Ctx, "Toggle", row, options)
	self.Value = false

	-- dynamic color: not theme-tagged (state-dependent); refresh on theme change.
	local function paint(animated)
		local palette = Themes.Palette()
		local trackColor = self.Value and palette.Accent or palette.SwitchOff
		local knobX = self.Value and (TRACK_W - KNOB - 2) or 2
		if animated then
			Utility.Tween(track, { Time = 0.18, Style = Enum.EasingStyle.Quad }, { BackgroundColor3 = trackColor })
			Utility.Tween(knob, { Time = 0.18, Style = Enum.EasingStyle.Quad }, {
				Position = UDim2.new(0, knobX, 0.5, 0),
				Size = UDim2.new(0, KNOB, 0, KNOB),
			})
		else
			track.BackgroundColor3 = trackColor
			knob.Position = UDim2.new(0, knobX, 0.5, 0)
		end
	end

	paint(false)

	-- track starts untagged; register theme-change refresh
	self._themeUnsub = Ctx.Library.Themes.OnChanged(function()
		if not self._destroyed and track and track.Parent ~= nil then
			paint(false)
		end
	end)

	function self.Set(value, fireCallback)
		local bool = value and true or false
		if bool == self.Value then
			return
		end
		self.Value = bool
		paint(true)
		if fireCallback ~= false then
			Utility.SafeCall("Toggle:" .. tostring(options.Name), options.Callback, bool)
		end
		if fireCallback ~= false then
			self:_touchConfig()
		end
	end

	-- press animation
	local pressing = false
	Creator.AddSignal(self._conns, track.MouseButton1Down, function()
		pressing = true
		Utility.Tween(knob, { Time = 0.1 }, { Size = UDim2.new(0, KNOB + 3, 0, KNOB) })
	end)
	Creator.AddSignal(self._conns, track.MouseButton1Up, function()
		if pressing then
			pressing = false
			Utility.Tween(knob, { Time = 0.15, Style = Enum.EasingStyle.Back }, { Size = UDim2.new(0, KNOB, 0, KNOB) })
		end
	end)

	Creator.AddSignal(self._conns, track.Activated, function()
		self:Set(not self.Value)
	end)

	-- row click toggles too
	local hitZone = New("TextButton", {
		Name = "HitZone",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -(TRACK_W + 26), 1, 0),
		Text = "",
		ZIndex = 2,
		Parent = row,
	})
	Creator.AddSignal(self._conns, hitZone.Activated, function()
		self:Set(not self.Value)
	end)
	Shared.RowHover(row, self._conns)

	-- initial value
	if options.CurrentValue ~= nil then
		task.defer(function()
			if not self._destroyed then
				self.Value = options.CurrentValue and true or false
				paint(false)
			end
		end)
	end

	function self.Serialize()
		return self.Value
	end

	function self.Deserialize(v)
		return v and true or false
	end

	local baseDestroy = self.Destroy
	function self.Destroy()
		if self._themeUnsub then
			pcall(self._themeUnsub)
			self._themeUnsub = nil
		end
		baseDestroy()
	end

	return self
end

return Toggle
