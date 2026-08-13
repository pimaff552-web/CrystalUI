--============================================================--
--  Crystal UI | elements/colorpicker.lua
--  macOS-style color well → expanding HSV picker panel with
--  saturation/value square, hue + alpha bars, hex input.
--
--  Tab:CreateColorPicker({ Name, Description?, Color, Alpha?, Flag?,
--     Callback(Color3, alpha) })
--============================================================--

local Import = ...
local Utility = Import("src/utility.lua")
local Creator = Import("src/creator.lua")
local Shared = Import("src/elements/shared.lua")

local New = Creator.New
local UserInputService = game:GetService("UserInputService")

local ColorPicker = {}

local PANEL_H = 184
local SV_SIZE = 164
local BAR_W = 14

function ColorPicker.New(options, Ctx)
	options = options or {}

	-- container: row + hidden expanding panel -------------------------------
	local proxyCtx = setmetatable({}, { __index = Ctx })
	local container = New("Frame", {
		Name = "ColorPicker",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	})
	proxyCtx.AttachRow = function(inst)
		inst.Parent = container
	end

	local row, _, control, left = Shared.Row(proxyCtx, options)

	Ctx.AttachRow(container)

	-- control: hex label + color well ---------------------------------------
	local hexLabel = New("TextLabel", {
		Name = "Hex",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -34, 0.5, 0),
		Size = UDim2.new(0, 64, 0, 18),
		Font = Utility.Fonts.Mono,
		TextSize = 11.5,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = "#FFFFFF",
	}, nil, { TextColor3 = "SubText" })

	local well = New("Frame", {
		Name = "Well",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 28, 0, 18),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	}, {
		Creator.Corner(5),
		New("UIStroke", {
			Thickness = 1,
			Color = Color3.fromRGB(0, 0, 0),
			Transparency = 0.75,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
	})

	control.Size = UDim2.new(0, 104, 0, 24)
	hexLabel.Parent = control
	well.Parent = control
	Shared.ReserveLeft(left, 104)

	-- panel ------------------------------------------------------------------
	local panel = New("Frame", {
		Name = "Panel",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		Visible = false,
		ClipsDescendants = true,
		Parent = container,
	})
	local panelOpen = false

	local svBase = New("Frame", {
		Name = "SV",
		Position = UDim2.new(0, 12, 0, 10),
		Size = UDim2.new(0, SV_SIZE, 0, SV_SIZE),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromHSV(0, 1, 1),
		Parent = panel,
	}, { Creator.Corner(8) })

	New("Frame", {
		Name = "WhiteLayer",
		Size = UDim2.new(1, 0, 1, 0),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		ZIndex = 2,
		Parent = svBase,
	}, {
		Creator.Corner(8),
		New("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Rotation = 0,
		}),
	})

	New("Frame", {
		Name = "BlackLayer",
		Size = UDim2.new(1, 0, 1, 0),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		ZIndex = 3,
		Parent = svBase,
	}, {
		Creator.Corner(8),
		New("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(1, 0),
			}),
			Rotation = 90,
		}),
	})

	local svCursor = New("Frame", {
		Name = "Cursor",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0, 14, 0, 14),
		BorderSizePixel = 0,
		ZIndex = 5,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Parent = svBase,
	}, {
		Creator.Corner(7),
		New("UIStroke", {
			Thickness = 2,
			Color = Color3.fromRGB(255, 255, 255),
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
	})

	local svHit = New("TextButton", {
		Name = "Hit",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 6,
		Parent = svBase,
	})

	-- hue bar ----------------------------------------------------------------
	local hueBar = New("Frame", {
		Name = "Hue",
		Position = UDim2.new(0, 12 + SV_SIZE + 10, 0, 10),
		Size = UDim2.new(0, BAR_W, 0, SV_SIZE),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Parent = panel,
	}, {
		Creator.Corner(7),
		New("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.00, Color3.fromHSV(0, 1, 1)),
				ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17, 1, 1)),
				ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
				ColorSequenceKeypoint.new(0.50, Color3.fromHSV(0.50, 1, 1)),
				ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67, 1, 1)),
				ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
				ColorSequenceKeypoint.new(1.00, Color3.fromHSV(1, 1, 1)),
			}),
		}),
	})

	local hueCursor = New("Frame", {
		Name = "Cursor",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.new(0, BAR_W + 6, 0, 5),
		BorderSizePixel = 0,
		ZIndex = 3,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Parent = hueBar,
	}, {
		Creator.Corner(3),
		New("UIStroke", {
			Thickness = 1,
			Color = Color3.fromRGB(0, 0, 0),
			Transparency = 0.7,
		}),
	})

	local hueHit = New("TextButton", {
		Name = "Hit",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 4,
		Parent = hueBar,
	})

	-- alpha bar --------------------------------------------------------------
	local alphaBar = New("Frame", {
		Name = "Alpha",
		Position = UDim2.new(0, 12 + SV_SIZE + 10 + BAR_W + 10, 0, 10),
		Size = UDim2.new(0, BAR_W, 0, SV_SIZE),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Parent = panel,
	}, {
		Creator.Corner(7),
		New("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}),
	})

	local alphaCursor = New("Frame", {
		Name = "Cursor",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 1, 0),
		Size = UDim2.new(0, BAR_W + 6, 0, 5),
		BorderSizePixel = 0,
		ZIndex = 3,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Parent = alphaBar,
	}, {
		Creator.Corner(3),
		New("UIStroke", {
			Thickness = 1,
			Color = Color3.fromRGB(0, 0, 0),
			Transparency = 0.7,
		}),
	})

	local alphaHit = New("TextButton", {
		Name = "Hit",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 4,
		Parent = alphaBar,
	})

	-- right column: preview + hex input + rgb readout -------------------------
	local colX = 12 + SV_SIZE + 10 + BAR_W + 10 + BAR_W + 12
	local colWidth = math.max(96, 340 - colX - 12)

	local preview = New("Frame", {
		Name = "Preview",
		Position = UDim2.new(0, colX, 0, 10),
		Size = UDim2.new(0, colWidth, 0, 26),
		BorderSizePixel = 0,
		Parent = panel,
	}, {
		Creator.Corner(7),
		New("UIStroke", {
			Thickness = 1,
			Color = Color3.fromRGB(0, 0, 0),
			Transparency = 0.8,
		}),
	})

	local hexBox = New("TextBox", {
		Name = "HexBox",
		Position = UDim2.new(0, colX, 0, 44),
		Size = UDim2.new(0, colWidth, 0, 24),
		BorderSizePixel = 0,
		Font = Utility.Fonts.Mono,
		TextSize = 12,
		Text = "#FFFFFF",
		ClearTextOnFocus = false,
		Parent = panel,
	}, {
		Creator.Corner(7),
		Creator.Stroke("ControlStroke", 1, 0.88),
	}, { BackgroundColor3 = "Control", TextColor3 = "Text" })

	local rgbLabel = New("TextLabel", {
		Name = "RGB",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, colX, 0, 76),
		Size = UDim2.new(0, colWidth, 0, 30),
		Font = Utility.Fonts.Mono,
		TextSize = 11,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "255, 255, 255",
		Parent = panel,
	}, nil, { TextColor3 = "SubText" })

	local alphaLabel = New("TextLabel", {
		Name = "Alpha",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, colX, 0, 108),
		Size = UDim2.new(0, colWidth, 0, 16),
		Font = Utility.Fonts.Regular,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "Alpha 100%",
		Parent = panel,
	}, nil, { TextColor3 = "SubText" })

	-- state ------------------------------------------------------------------
	local self = Shared.Object(Ctx, "ColorPicker", container, options)

	local startColor = options.Color or options.Default or Color3.fromRGB(255, 255, 255)
	local h, s, v = Color3.toHSV(startColor)
	local alpha = Utility.Clamp(tonumber(options.Alpha) or 1, 0, 1)

	self.Value = startColor
	self.Alpha = alpha

	local suppressCallback = false

	local function currentColor()
		return Color3.fromHSV(h, s, v)
	end

	local function repaint(fire)
		local color = currentColor()
		svBase.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		svCursor.Position = UDim2.new(Utility.Clamp(s, 0, 1), 0, Utility.Clamp(1 - v, 0, 1), 0)
		svCursor.BackgroundColor3 = color
		hueCursor.Position = UDim2.new(0.5, 0, Utility.Clamp(h, 0, 1), 0)
		alphaCursor.Position = UDim2.new(0.5, 0, Utility.Clamp(1 - alpha, 0, 1), 0)
		alphaBar.BackgroundColor3 = color
		preview.BackgroundColor3 = color
		preview.BackgroundTransparency = 1 - alpha
		well.BackgroundColor3 = color
		hexLabel.Text = Utility.ColorToHex(color)
		hexBox.Text = Utility.ColorToHex(color)
		rgbLabel.Text = string.format("%d, %d, %d",
			math.floor(color.R * 255 + 0.5),
			math.floor(color.G * 255 + 0.5),
			math.floor(color.B * 255 + 0.5))
		alphaLabel.Text = string.format("Alpha %d%%", math.floor(alpha * 100 + 0.5))
		if fire ~= false and not suppressCallback then
			Utility.SafeCall("ColorPicker:" .. tostring(options.Name), options.Callback, color, alpha)
			self:_touchConfig()
		end
		self.Value = color
		self.Alpha = alpha
	end

	local function dragHandler(hitFrame, onInput)
		Creator.AddSignal(self._conns, hitFrame.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				local active = true
				onInput(input)
				local moveConn
				moveConn = UserInputService.InputChanged:Connect(function(moveInput)
					if not active then
						return
					end
					if moveInput.UserInputType == Enum.UserInputType.MouseMovement
						or moveInput.UserInputType == Enum.UserInputType.Touch then
						onInput(moveInput)
					end
				end)
				self._conns[#self._conns + 1] = moveConn
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						active = false
						if moveConn then
							moveConn:Disconnect()
						end
					end
				end)
			end
		end)
	end

	dragHandler(svHit, function(input)
		local relX = input.Position.X - svBase.AbsolutePosition.X
		local relY = input.Position.Y - svBase.AbsolutePosition.Y
		s = Utility.Clamp(relX / math.max(svBase.AbsoluteSize.X, 1), 0, 1)
		v = 1 - Utility.Clamp(relY / math.max(svBase.AbsoluteSize.Y, 1), 0, 1)
		repaint()
	end)

	dragHandler(hueHit, function(input)
		local relY = input.Position.Y - hueBar.AbsolutePosition.Y
		h = Utility.Clamp(relY / math.max(hueBar.AbsoluteSize.Y, 1), 0, 1)
		repaint()
	end)

	dragHandler(alphaHit, function(input)
		local relY = input.Position.Y - alphaBar.AbsolutePosition.Y
		alpha = 1 - Utility.Clamp(relY / math.max(alphaBar.AbsoluteSize.Y, 1), 0, 1)
		repaint()
	end)

	Creator.AddSignal(self._conns, hexBox.FocusLost, function(enterPressed)
		local parsed = Utility.HexToColor(hexBox.Text)
		if parsed then
			local nh, ns, nv = Color3.toHSV(parsed)
			if ns > 0.001 then
				h = nh
			end
			s = ns
			v = nv
			repaint()
		else
			hexBox.Text = Utility.ColorToHex(currentColor())
		end
	end)

	-- toggle panel -----------------------------------------------------------
	local function setPanel(open)
		panelOpen = open
		if open then
			panel.Visible = true
			Utility.Tween(panel, { Time = 0.22, Style = Enum.EasingStyle.Quint }, {
				Size = UDim2.new(1, 0, 0, PANEL_H),
			})
		else
			Utility.Tween(panel, { Time = 0.18, Style = Enum.EasingStyle.Quint }, {
				Size = UDim2.new(1, 0, 0, 0),
			})
			task.delay(0.2, function()
				if not panelOpen and panel and panel.Parent ~= nil then
					panel.Visible = false
				end
			end)
		end
	end

	local hitZone = New("TextButton", {
		Name = "HitZone",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -120, 1, 0),
		Text = "",
		ZIndex = 2,
		Parent = row,
	})
	Creator.AddSignal(self._conns, hitZone.Activated, function()
		setPanel(not panelOpen)
	end)
	Creator.AddSignal(self._conns, svHit.Activated, function() end)
	Shared.RowHover(row, self._conns)

	-- public API -------------------------------------------------------------
	function self.Set(color, fireCallback)
		if typeof(color) == "Color3" then
			local nh, ns, nv = Color3.toHSV(color)
			if ns > 0.001 then
				h = nh
			end
			s = ns
			v = nv
		elseif type(color) == "table" and color.r then
			local c = Color3.fromRGB(color.r or 255, color.g or 255, color.b or 255)
			local nh, ns, nv = Color3.toHSV(c)
			if ns > 0.001 then
				h = nh
			end
			s = ns
			v = nv
			if color.a then
				alpha = Utility.Clamp(tonumber(color.a) or 1, 0, 1)
			end
		end
		if fireCallback == false then
			suppressCallback = true
			repaint(false)
			suppressCallback = false
		else
			repaint(true)
		end
	end

	function self.SetAlpha(value, fire)
		alpha = Utility.Clamp(tonumber(value) or 1, 0, 1)
		repaint(fire ~= false)
	end

	function self.Serialize()
		local c = currentColor()
		return {
			r = math.floor(c.R * 255 + 0.5),
			g = math.floor(c.G * 255 + 0.5),
			b = math.floor(c.B * 255 + 0.5),
			a = alpha,
		}
	end

	function self.Deserialize(tbl)
		if type(tbl) == "table" then
			return tbl
		end
		return { r = 255, g = 255, b = 255, a = 1 }
	end

	repaint(false)

	return self
end

return ColorPicker
