--============================================================--
--  Crystal UI | elements/slider.lua
--  macOS slider: thin track, accent fill, round knob, value
--  readout on the right.
--
--  Tab:CreateSlider({ Name, Description?, Range={min,max},
--     Increment, Suffix, CurrentValue, Flag?, Callback })
--============================================================--

local Import = ...
local Utility = Import("src/utility.lua")
local Creator = Import("src/creator.lua")
local Shared = Import("src/elements/shared.lua")

local New = Creator.New
local UserInputService = game:GetService("UserInputService")

local Slider = {}

local SLIDER_W = 150
local TRACK_H = 4
local KNOB_SIZE = 16

function Slider.New(options, Ctx)
	options = options or {}
	local row, _, control, left = Shared.Row(Ctx, options)

	local range = options.Range or { 0, 100 }
	local min = tonumber(range[1]) or 0
	local max = tonumber(range[2]) or 100
	if max <= min then
		max = min + 1
	end
	local increment = tonumber(options.Increment) or 1
	if increment <= 0 then
		increment = 0 -- free
	end
	local suffix = tostring(options.Suffix or "")
	local decimals = Utility.DecimalPlaces(increment)

	-- value readout
	local valueLabel = New("TextLabel", {
		Name = "Value",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 44, 0, 20),
		Font = Utility.Fonts.Medium,
		TextSize = 12.5,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = "",
	}, nil, { TextColor3 = "SubText" })

	local fill = New("Frame", {
		Name = "Fill",
		Size = UDim2.new(0.5, 0, 1, 0),
		BorderSizePixel = 0,
		ZIndex = 2,
	}, {
		Creator.Corner(2),
	}, { BackgroundColor3 = "Accent" })

	local knob = New("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, KNOB_SIZE, 0, KNOB_SIZE),
		BorderSizePixel = 0,
		ZIndex = 4,
	}, {
		Creator.Corner(math.floor(KNOB_SIZE / 2)),
		New("UIStroke", {
			Thickness = 1,
			Color = Color3.fromRGB(0, 0, 0),
			Transparency = 0.82,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
	}, { BackgroundColor3 = "Knob" })

	local track = New("TextButton", {
		Name = "Track",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, SLIDER_W, 0, 22), -- fat hit zone, thin visible bar
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 3,
	}, {
		New("Frame", {
			Name = "Bar",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.new(1, 0, 0, TRACK_H),
			BorderSizePixel = 0,
			ZIndex = 1,
		}, {
			Creator.Corner(2),
		}, { BackgroundColor3 = "Track" }),
		fill,
		knob,
	})

	local holder = New("Frame", {
		Name = "Holder",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -50, 0.5, 0),
		Size = UDim2.new(0, SLIDER_W, 0, 24),
	})
	holder.Parent = control
	track.Parent = holder
	valueLabel.Parent = control

	control.Size = UDim2.new(0, SLIDER_W + 50, 0, 24)
	Shared.ReserveLeft(left, SLIDER_W + 50)

	local self = Shared.Object(Ctx, "Slider", row, options)
	self.Value = min

	local dragging = false

	local function display(value)
		if decimals > 0 then
			return string.format("%." .. decimals .. "f", value)
		end
		return tostring(math.floor(value + 0.5))
	end

	local function paint(value, animated)
		local alpha = Utility.Clamp((value - min) / (max - min), 0, 1)
		local knobPos = UDim2.new(alpha, 0, 0.5, 0)
		local fillSize = UDim2.new(alpha, 0, 1, 0)
		if animated then
			Utility.Tween(knob, { Time = 0.1 }, { Position = knobPos })
			Utility.Tween(fill, { Time = 0.1 }, { Size = fillSize })
		else
			knob.Position = knobPos
			fill.Size = fillSize
		end
		valueLabel.Text = display(value) .. (suffix ~= "" and (" " .. suffix) or suffix)
	end

	-- put the fill inside the thin bar
	fill.Parent = track:FindFirstChild("Bar")

	local function setFromX(x, fire)
		local bar = track:FindFirstChild("Bar") or track
		local absX = bar.AbsolutePosition.X
		local absW = math.max(bar.AbsoluteSize.X, 1)
		local alpha = Utility.Clamp((x - absX) / absW, 0, 1)
		local raw = min + (max - min) * alpha
		if increment > 0 then
			raw = Utility.Round(raw, increment)
		else
			raw = Utility.Round(raw, 0.01)
		end
		raw = Utility.Clamp(raw, min, max)
		if raw ~= self.Value then
			self.Value = raw
			paint(raw, false)
			if fire ~= false then
				Utility.SafeCall("Slider:" .. tostring(options.Name), options.Callback, raw)
				self:_touchConfig()
			end
		end
	end

	function self.Set(value, fireCallback)
		local num = tonumber(value) or min
		if increment > 0 then
			num = Utility.Round(num, increment)
		end
		num = Utility.Clamp(num, min, max)
		local changed = num ~= self.Value
		self.Value = num
		paint(num, not dragging)
		if fireCallback ~= false then
			Utility.SafeCall("Slider:" .. tostring(options.Name), options.Callback, num)
			self:_touchConfig()
		elseif changed then
			self:_touchConfig()
		end
	end

	Creator.AddSignal(self._conns, track.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			Utility.Tween(knob, { Time = 0.1 }, { Size = UDim2.new(0, KNOB_SIZE + 4, 0, KNOB_SIZE + 4) })
			setFromX(input.Position.X)
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					if knob and knob.Parent ~= nil then
						Utility.Tween(knob, { Time = 0.12 }, { Size = UDim2.new(0, KNOB_SIZE, 0, KNOB_SIZE) })
					end
				end
			end)
		end
	end)

	self._conns[#self._conns + 1] = UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			setFromX(input.Position.X)
		end
	end)

	Shared.RowHover(row, self._conns)

	function self.Serialize()
		return self.Value
	end

	function self.Deserialize(v)
		return tonumber(v) or min
	end

	-- initial value (deferred so AbsoluteSize is valid)
	task.defer(function()
		if self._destroyed then
			return
		end
		local initial = options.CurrentValue
		if initial == nil then
			initial = min
		end
		local num = tonumber(initial) or min
		if increment > 0 then
			num = Utility.Round(num, increment)
		end
		num = Utility.Clamp(num, min, max)
		self.Value = num
		paint(num, false)
	end)

	return self
end

return Slider
