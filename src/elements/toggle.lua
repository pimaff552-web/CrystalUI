--============================================================--
--  Crystal UI | elements/toggle.lua
--  macOS switch — ONE interactive surface covering the whole
--  row (title, description AND the switch itself). Impossible
--  to double-fire, big touch target, spring-animated knob.
--
--  Tab:CreateToggle({ Name, Description?, CurrentValue, Flag?, Callback })
--============================================================--

local Import = ...
local Utility = Import("src/utility.lua")
local Creator = Import("src/creator.lua")
local Shared = Import("src/elements/shared.lua")

local New = Creator.New

local Toggle = {}

local TRACK_W = 46
local TRACK_H = 27
local KNOB = 23

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
		ZIndex = 5,
		Active = false,
	}, {
		Creator.Corner(math.floor(KNOB / 2)),
		New("UIStroke", {
			Thickness = 1,
			Color = Color3.fromRGB(0, 0, 0),
			Transparency = 0.78,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
	}, { BackgroundColor3 = "Knob" })

	-- visual only: no input handling here, the row hit-zone owns ALL clicks
	local track = New("Frame", {
		Name = "Track",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, TRACK_W, 0, TRACK_H),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(60, 60, 66),
		ZIndex = 4,
		Active = false,
	}, {
		Creator.Corner(math.floor(TRACK_H / 2)),
		New("UIStroke", {
			Thickness = 1,
			Transparency = 0.92,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, nil, { Color = "ControlStroke" }),
		knob,
	})

	control.Size = UDim2.new(0, TRACK_W, 0, TRACK_H)
	control.Active = false
	track.Parent = control

	Shared.ReserveLeft(left, TRACK_W)

	local self = Shared.Object(Ctx, "Toggle", row, options)
	self.Value = options.CurrentValue and true or false

	local function paint(animated)
		if self._destroyed then
			return
		end
		local palette = Themes.Palette()
		local trackColor = self.Value and palette.Accent or palette.SwitchOff
		local knobX = self.Value and (TRACK_W - KNOB - 2) or 2
		if animated then
			Utility.Tween(track, { Time = 0.18, Style = Enum.EasingStyle.Quad }, { BackgroundColor3 = trackColor })
			Utility.Tween(knob, { Time = 0.18, Style = Enum.EasingStyle.Quint }, {
				Position = UDim2.new(0, knobX, 0.5, 0),
			})
		else
			track.BackgroundColor3 = trackColor
			knob.Position = UDim2.new(0, knobX, 0.5, 0)
		end
	end

	paint(false)

	-- theme switching must repaint the stateful track color
	self._themeUnsub = Themes.OnChanged(function()
		paint(false)
	end)

	function self.Set(value, fireCallback)
		local bool = value and true or false
		if bool == self.Value then
			paint(false) -- keep visuals honest even for no-op sets
			return
		end
		self.Value = bool
		paint(true)
		if fireCallback ~= false then
			Utility.SafeCall("Toggle:" .. tostring(options.Name), options.Callback, bool)
			self:_touchConfig()
		end
	end

	-- the ONE and ONLY interactive surface: full row
	local hitZone = New("TextButton", {
		Name = "HitZone",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Text = "",
		ZIndex = 6,
		Active = true,
		AutoButtonColor = false,
		Parent = row,
	})

	local pressing = false
	Creator.AddSignal(self._conns, hitZone.MouseButton1Down, function()
		pressing = true
		Utility.Tween(knob, { Time = 0.1 }, { Size = UDim2.new(0, KNOB + 3, 0, KNOB) })
	end)
	Creator.AddSignal(self._conns, hitZone.MouseButton1Up, function()
		if pressing then
			pressing = false
			Utility.Tween(knob, { Time = 0.15, Style = Enum.EasingStyle.Back }, { Size = UDim2.new(0, KNOB, 0, KNOB) })
		end
	end)
	Creator.AddSignal(self._conns, hitZone.MouseLeave, function()
		if pressing then
			pressing = false
			Utility.Tween(knob, { Time = 0.15 }, { Size = UDim2.new(0, KNOB, 0, KNOB) })
		end
	end)

	Creator.AddSignal(self._conns, hitZone.Activated, function()
		self:Set(not self.Value)
	end)

	Shared.RowHover(row, self._conns)

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
