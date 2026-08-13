--============================================================--
--  Crystal UI | components/window.lua
--  The macOS window: traffic lights, unified title bar, sidebar
--  with search, tab pages, popovers, dialogs, resize/zoom,
--  minimize, dock button, loading screen, acrylic hookup.
--
--  Window.New(config, Library) -> window
--============================================================--

local Import = ...
local Utility = Import("src/utility.lua")
local Creator = Import("src/creator.lua")
local Icons = Import("src/icons.lua")
local Tab = Import("src/components/tab.lua")
local Dialog = Import("src/components/dialog.lua")
local Acrylic = Import("src/acrylic.lua")

local New = Creator.New
local UserInputService = game:GetService("UserInputService")

local Window = {}

local TITLE_H = 40
local SIDEBAR_W = 190
local MIN_W = 480
local MIN_H = 330

local DEFAULT_SIZE = { 690, 460 }

function Window.New(config, Library)
	config = config or {}
	local Themes = Library.Themes

	local self = {}
	self.Library = Library
	self.Config = config
	self.Tabs = {}
	self.SelectedTab = nil
	self.Connections = {}
	self.Visible = false
	self.Minimized = false
	self.Zoomed = false
	self._destroyed = false
	self._popover = nil -- {frame=, shadow=, backdrop=, onClose=}

	local gui = Library:EnsureGui()

	-- state --------------------------------------------------------------------
	local baseW = DEFAULT_SIZE[1]
	local baseH = DEFAULT_SIZE[2]
	if typeof(config.Size) == "UDim2" then
		if config.Size.X.Offset > 0 then
			baseW = config.Size.X.Offset
		end
		if config.Size.Y.Offset > 0 then
			baseH = config.Size.Y.Offset
		end
	end
	baseW = math.max(baseW, MIN_W)
	baseH = math.max(baseH, MIN_H)
	local normalW = baseW
	local normalH = baseH

	local adaptiveScale = 1
	local userVisible = false

	-- adaptive scale --------------------------------------------------------------
	local scaleFx = New("UIScale", { Name = "AdaptiveScale", Scale = 1 })

	local function computeAdaptive()
		local vp = Utility.ViewportSize()
		local sx = (vp.X - 28) / math.max(baseW, 1)
		local sy = (vp.Y - 60) / math.max(baseH, 1)
		adaptiveScale = Utility.Clamp(math.min(sx, sy, 1), 0.45, 1)
		if config.AutoScale == false then
			adaptiveScale = 1
		end
		if scaleFx and scaleFx.Parent ~= nil then
			scaleFx.Scale = adaptiveScale * (self._introScale or 1)
		end
	end

	-- root ----------------------------------------------------------------------
	local shadow = New("Frame", {
		Name = "Shadow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 6),
		Size = UDim2.new(1, 26, 1, 30),
		BackgroundTransparency = 0.72,
		BorderSizePixel = 0,
		ZIndex = 1,
	}, {
		Creator.Corner(16),
	}, { BackgroundColor3 = "Shadow" })

	-- title bar content ---------------------
	local function makeTrafficCircle(name, colorKey, xOffset, glyph)
		local label = New("TextLabel", {
			Name = "Glyph",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Font = Utility.Fonts.Bold,
			TextSize = 9,
			Text = glyph,
			TextTransparency = 1,
			ZIndex = 12,
		}, nil, { TextColor3 = "TrafficGlyph" })
		local circle = New("TextButton", {
			Name = name,
			Position = UDim2.new(0, xOffset, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Size = UDim2.new(0, 12, 0, 12),
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			ZIndex = 12,
		}, {
			Creator.Corner(6),
			label,
		}, { BackgroundColor3 = colorKey })
		return circle, label
	end

	local trafficHolder = New("Frame", {
		Name = "Traffic",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(0, 56, 1, 0),
		ZIndex = 11,
	})

	local closeBtn, closeGlyph = makeTrafficCircle("Close", "Close", 0, "\u{00D7}")
	local minBtn, minGlyph = makeTrafficCircle("Min", "Min", 20, "\u{2013}")
	local maxBtn, maxGlyph = makeTrafficCircle("Max", "Max", 40, "\u{002B}")
	closeBtn.Parent = trafficHolder
	minBtn.Parent = trafficHolder
	maxBtn.Parent = trafficHolder

	Creator.AddSignal(self.Connections, trafficHolder.MouseEnter, function()
		closeGlyph.TextTransparency = 0
		minGlyph.TextTransparency = 0
		maxGlyph.TextTransparency = 0
	end)
	Creator.AddSignal(self.Connections, trafficHolder.MouseLeave, function()
		closeGlyph.TextTransparency = 1
		minGlyph.TextTransparency = 1
		maxGlyph.TextTransparency = 1
	end)

	local titleName = New("TextLabel", {
		Name = "Name",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		Font = Utility.Fonts.Bold,
		TextSize = 13,
		Text = tostring(config.Name or "Crystal UI"),
	}, nil, { TextColor3 = "Text" })

	local titleChildren = {
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		titleName,
	}

	if config.Subtitle and config.Subtitle ~= "" then
		titleChildren[#titleChildren + 1] = New("TextLabel", {
			Name = "Subtitle",
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 1, 0),
			Font = Utility.Fonts.Regular,
			TextSize = 11.5,
			Text = tostring(config.Subtitle),
			LayoutOrder = 2,
		}, nil, { TextColor3 = "SubText" })
	end

	local titleCenter = New("Frame", {
		Name = "TitleCenter",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		ZIndex = 10,
	}, titleChildren)
	titleChildren = nil

	local titleBar = New("Frame", {
		Name = "TitleBar",
		Size = UDim2.new(1, 0, 0, TITLE_H),
		BorderSizePixel = 0,
		ZIndex = 10,
	}, {
		trafficHolder,
		titleCenter,
		New("Frame", {
			Name = "Hairline",
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 0, 1, 0),
			Size = UDim2.new(1, 0, 0, 1),
			BorderSizePixel = 0,
			BackgroundTransparency = 0.92,
			ZIndex = 10,
		}, nil, { BackgroundColor3 = "Separator" }),
	}, { BackgroundColor3 = "Window" })

	-- body: sidebar + content --------
	local searchBox = New("TextBox", {
		Name = "Search",
		Size = UDim2.new(1, 0, 0, 26),
		BorderSizePixel = 0,
		Font = Utility.Fonts.Regular,
		TextSize = 12,
		Text = "",
		PlaceholderText = "\u{1F50D}  Search",
		ClearTextOnFocus = false,
		LayoutOrder = -10,
	}, {
		Creator.Corner(7),
		Creator.Stroke("ControlStroke", 1, 0.92),
		New("UIPadding", {
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
		}),
	}, { BackgroundColor3 = "Control", TextColor3 = "Text", PlaceholderColor3 = "Placeholder" })

	local tabsList = New("ScrollingFrame", {
		Name = "Tabs",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, -32),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		LayoutOrder = 1,
	}, {
		New("UIListLayout", {
			Padding = UDim.new(0, 3),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local sidebar = New("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, SIDEBAR_W, 1, 0),
		BorderSizePixel = 0,
	}, {
		New("UIPadding", {
			PaddingTop = UDim.new(0, 10),
			PaddingBottom = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
		}),
		New("UIListLayout", {
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		searchBox,
		tabsList,
	}, { BackgroundColor3 = "Sidebar" })

	self.TabsContainer = tabsList

	local pagesContainer = New("Frame", {
		Name = "Pages",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
	})
	self.PagesContainer = pagesContainer

	local popovers = New("Frame", {
		Name = "Popovers",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 60,
		Visible = true,
	})
	self.PopoversFrame = popovers

	local dialogLayer = New("Frame", {
		Name = "Dialogs",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 80,
	})
	self.DialogLayer = dialogLayer

	local content = New("Frame", {
		Name = "Content",
		Position = UDim2.new(0, SIDEBAR_W + 1, 0, 0),
		Size = UDim2.new(1, -(SIDEBAR_W + 1), 1, 0),
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, {
		pagesContainer,
		popovers,
		dialogLayer,
	}, { BackgroundColor3 = "Window" })

	local sidebarDivider = New("Frame", {
		Name = "Divider",
		Position = UDim2.new(0, SIDEBAR_W, 0, 0),
		Size = UDim2.new(0, 1, 1, 0),
		BorderSizePixel = 0,
		BackgroundTransparency = 0.9,
	}, nil, { BackgroundColor3 = "Separator" })

	local body = New("Frame", {
		Name = "Body",
		Position = UDim2.new(0, 0, 0, TITLE_H),
		Size = UDim2.new(1, 0, 1, -TITLE_H),
		BackgroundTransparency = 1,
	}, {
		sidebar,
		sidebarDivider,
		content,
	})
	self.BodyFrame = body

	local cloak = New("Frame", {
		Name = "Cloak",
		Size = UDim2.new(1, 0, 1, 0),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 5,
	}, {
		Creator.Corner(13),
		Creator.Stroke("GroupStroke", 1, 0.85),
		titleBar,
		body,
	}, { BackgroundColor3 = "Window" })

	local resizeGrip = New("TextButton", {
		Name = "ResizeGrip",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -2, 1, -2),
		Size = UDim2.new(0, 18, 0, 18),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 40,
	}, {
		New("Frame", {
			Name = "L1",
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -4, 1, -4),
			Size = UDim2.new(0, 10, 0, 1.4),
			Rotation = -45,
			BorderSizePixel = 0,
			BackgroundTransparency = 0.55,
		}, nil, { BackgroundColor3 = "SubText" }),
		New("Frame", {
			Name = "L2",
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -7, 1, -7),
			Size = UDim2.new(0, 5, 0, 1.4),
			Rotation = -45,
			BorderSizePixel = 0,
			BackgroundTransparency = 0.55,
		}, nil, { BackgroundColor3 = "SubText" }),
	})
	resizeGrip.Parent = cloak

	local root = New("Frame", {
		Name = "Root",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, baseW, 0, baseH),
		BackgroundTransparency = 1,
		Visible = false,
	}, {
		scaleFx,
		shadow,
		cloak,
	})
	root.Parent = gui
	self.Root = root

	computeAdaptive()

	-- viewport resize -> recompute adaptive scale
	local camera = workspace.CurrentCamera
	if camera then
		self.Connections[#self.Connections + 1] = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			computeAdaptive()
		end)
	end

	-- helpers ------------------------------------------------------------------
	local function refreshAcrylic()
		local want = (userVisible and config.Acrylic == true) and true or false
		Acrylic.SetWanted(want)
	end

	local function currentSize()
		if self.Zoomed then
			local vp = Utility.ViewportSize()
			local s = math.max(adaptiveScale, 0.0001)
			return math.min(1040, (vp.X * 0.96) / s), math.min(700, (vp.Y * 0.92) / s)
		end
		return normalW, normalH
	end

	-- dock button (re-open pill) ------------------------------------------------
	local dockIconKind, dockIconValue = Icons.Resolve(config.Icon or "gem")
	local dockIcon
	if dockIconKind == "image" then
		dockIcon = New("ImageLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 18, 0, 18),
			Image = dockIconValue,
			ScaleType = Enum.ScaleType.Fit,
		}, nil, { ImageColor3 = "Accent" })
	else
		dockIcon = New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 20, 0, 20),
			Font = Utility.Fonts.Regular,
			TextSize = 16,
			Text = dockIconValue,
		}, nil, { TextColor3 = "Accent" })
	end

	local dockButton = New("TextButton", {
		Name = "DockButton",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.new(0, 42, 0, 42),
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		Visible = false,
		ZIndex = 900,
	}, {
		Creator.Corner(21),
		Creator.Stroke("GroupStroke", 1, 0.8),
		dockIcon,
	}, { BackgroundColor3 = "Popover" })
	dockIcon.Parent = dockButton
	dockIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	dockIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
	dockButton.Parent = gui

	local dockDragStop = Utility.Drag(dockButton, dockButton, {})
	self.Connections[#self.Connections + 1] = dockDragStop

	-- visibility ----------------------------------------------------------------
	local showing = false
	local function updateDock()
		dockButton.Visible = (not showing) or Utility.IsMobile()
	end

	function self:Show()
		if self._destroyed then
			return
		end
		showing = true
		userVisible = true
		root.Visible = true
		self._introScale = 0.965
		computeAdaptive()
		local target = adaptiveScale
		Utility.Tween(scaleFx, { Time = 0.22, Style = Enum.EasingStyle.Quint }, { Scale = target })
		task.delay(0.24, function()
			self._introScale = 1
			computeAdaptive()
		end)
		if self.Minimized then
			root.Size = UDim2.new(0, select(1, currentSize()), 0, TITLE_H)
		else
			root.Size = UDim2.new(0, select(1, currentSize()), 0, select(2, currentSize()))
		end
		body.Visible = not self.Minimized
		refreshAcrylic()
		updateDock()
		self.Visible = true
	end

	function self:Hide()
		if self._destroyed then
			return
		end
		showing = false
		userVisible = false
		self:ClosePopover()
		local target = math.max(adaptiveScale - 0.03, 0.01)
		Utility.Tween(scaleFx, { Time = 0.16, Style = Enum.EasingStyle.Quad }, { Scale = target })
		task.delay(0.17, function()
			if not showing then
				root.Visible = false
				computeAdaptive()
			end
		end)
		refreshAcrylic()
		updateDock()
		self.Visible = false
	end

	function self:ToggleVisibility()
		if showing then
			self:Hide()
		else
			self:Show()
		end
	end

	Creator.AddSignal(self.Connections, dockButton.Activated, function()
		self:ToggleVisibility()
	end)

	-- minimize / zoom ------------------------------------------------------------
	function self:Minimize(value)
		if self._destroyed then
			return
		end
		local wantMin = value
		if wantMin == nil then
			wantMin = not self.Minimized
		end
		if wantMin == self.Minimized then
			return
		end
		self:ClosePopover()
		self.Minimized = wantMin
		local w, h = currentSize()
		if wantMin then
			Utility.Tween(root, { Time = 0.22, Style = Enum.EasingStyle.Quint }, {
				Size = UDim2.new(0, w, 0, TITLE_H),
			})
			task.delay(0.2, function()
				if self.Minimized then
					body.Visible = false
				end
			end)
			resizeGrip.Visible = false
		else
			body.Visible = true
			Utility.Tween(root, { Time = 0.24, Style = Enum.EasingStyle.Quint }, {
				Size = UDim2.new(0, w, 0, h),
			})
			resizeGrip.Visible = not self.Zoomed and config.Resizable ~= false
		end
	end

	function self:Zoom()
		if self._destroyed or self.Minimized then
			return
		end
		self:ClosePopover()
		if self.Zoomed then
			self.Zoomed = false
			Utility.Tween(root, { Time = 0.25, Style = Enum.EasingStyle.Quint }, {
				Size = UDim2.new(0, normalW, 0, normalH),
			})
			resizeGrip.Visible = config.Resizable ~= false
		else
			self.Zoomed = true
			local w, h = currentSize()
			Utility.Tween(root, { Time = 0.25, Style = Enum.EasingStyle.Quint }, {
				Size = UDim2.new(0, w, 0, h),
			})
			resizeGrip.Visible = false
		end
	end

	function self:Close()
		if config.CloseBehavior == "Destroy" then
			Library:Destroy()
		else
			self:Hide()
		end
	end

	Creator.AddSignal(self.Connections, closeBtn.Activated, function()
		self:Close()
	end)
	Creator.AddSignal(self.Connections, minBtn.Activated, function()
		self:Minimize()
	end)
	Creator.AddSignal(self.Connections, maxBtn.Activated, function()
		self:Zoom()
	end)

	-- dragging -------------------------------------------------------------------
	self.Connections[#self.Connections + 1] = Utility.Drag(root, titleBar, {
		GetScale = function()
			return scaleFx.Scale
		end,
		OnStart = function()
			self:ClosePopover()
		end,
	})

	-- resize ----------------------------------------------------------------------
	local resizing = false
	local resizeStartPos = nil
	local resizeStartSize = nil

	Creator.AddSignal(self.Connections, resizeGrip.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			if self.Minimized or self.Zoomed then
				return
			end
			resizing = true
			resizeStartPos = input.Position
			resizeStartSize = Vector2.new(normalW, normalH)
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					resizing = false
				end
			end)
		end
	end)

	self.Connections[#self.Connections + 1] = UserInputService.InputChanged:Connect(function(input)
		if not resizing then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local s = math.max(scaleFx.Scale, 0.0001)
		local delta = (input.Position - resizeStartPos) / s
		local vp = Utility.ViewportSize()
		normalW = Utility.Clamp(resizeStartSize.X + delta.X, MIN_W, (vp.X * 1.5) / s)
		normalH = Utility.Clamp(resizeStartSize.Y + delta.Y, MIN_H, (vp.Y * 1.5) / s)
		baseW = normalW
		baseH = normalH
		root.Size = UDim2.new(0, normalW, 0, normalH)
		computeAdaptive()
	end)

	-- toggle keybind ---------------------------------------------------------------
	local toggleKey = nil
	if typeof(config.ToggleKey) == "EnumItem" then
		toggleKey = config.ToggleKey
	elseif type(config.ToggleKey) == "string" and config.ToggleKey ~= "" then
		pcall(function()
			toggleKey = Enum.KeyCode[config.ToggleKey]
		end)
	end
	if toggleKey == nil then
		toggleKey = Enum.KeyCode.RightShift
	end

	self.Connections[#self.Connections + 1] = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or self._destroyed then
			return
		end
		if input.KeyCode == toggleKey then
			self:ToggleVisibility()
		end
	end)

	-- sidebar search filter ---------------------------------------------------------
	local suppressSearch = false
	Creator.AddSignal(self.Connections, searchBox:GetPropertyChangedSignal("Text"), function()
		if suppressSearch then
			return
		end
		local query = Utility.Trim(string.lower(searchBox.Text))
		for _, tab in pairs(self.Tabs) do
			if tab and tab.SetFiltered then
				if query == "" then
					tab:SetFiltered(tab.UserHidden ~= true)
				else
					local name = string.lower(tab.Name or "")
					tab:SetFiltered(string.find(name, query, 1, true) ~= nil)
				end
			end
		end
	end)

	-- popovers -----------------------------------------------------------------------
	function self:ClosePopover()
		local pop = self._popover
		if not pop then
			return
		end
		self._popover = nil
		local onClose = pop.onClose
		if pop.frame then
			Utility.Tween(pop.frame, { Time = 0.12 }, { Position = pop.finalPos + UDim2.new(0, 0, 0, 4) })
		end
		task.delay(0.13, function()
			pcall(function()
				if pop.frame then pop.frame:Destroy() end
			end)
			pcall(function()
				if pop.backdrop then pop.backdrop:Destroy() end
			end)
		end)
		if onClose then
			Utility.SafeCall("Popover", onClose)
		end
	end

	-- OpenPopover(anchorFrame, width, maxHeight, builder, opts{OnClose})
	function self:OpenPopover(anchor, width, maxHeight, builder, opts)
		self:ClosePopover()
		opts = opts or {}
		if not anchor or anchor.Parent == nil then
			return nil
		end

		local backdrop = New("TextButton", {
			Name = "Backdrop",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Text = "",
			ZIndex = 60,
			AutoButtonColor = false,
		})

		local popFrame = New("Frame", {
			Name = "Popover",
			Size = UDim2.new(0, width, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BorderSizePixel = 0,
			ZIndex = 61,
			ClipsDescendants = true,
		}, {
			Creator.Corner(10),
			Creator.Stroke("PopoverStroke", 1, 0.86),
			New("UISizeConstraint", {
				MaxSize = Vector2.new(width, maxHeight or 260),
			}),
		}, { BackgroundColor3 = "Popover" })

		backdrop.Parent = popovers
		popFrame.Parent = popovers

		local entry = {
			frame = popFrame,
			backdrop = backdrop,
			onClose = opts.OnClose,
			finalPos = UDim2.new(0, 0, 0, 0),
		}
		self._popover = entry

		Creator.AddSignal(self.Connections, backdrop.Activated, function()
			self:ClosePopover()
		end)

		Utility.SafeCall("Popover", builder, popFrame)

		-- position (right-aligned to anchor, flip up when needed)
		local function place()
			if not popFrame or popFrame.Parent == nil then
				return
			end
			local contentAbs = popovers.AbsolutePosition
			local contentSize = popovers.AbsoluteSize
			local anchorAbs = anchor.AbsolutePosition
			local anchorSize = anchor.AbsoluteSize
			local popH = popFrame.AbsoluteSize.Y
			if popH < 10 then
				popH = math.min(maxHeight or 260, 260)
			end

			local x = anchorAbs.X - contentAbs.X + anchorSize.X - width - 4
			x = Utility.Clamp(x, 8, math.max(contentSize.X - width - 8, 8))

			local belowY = anchorAbs.Y - contentAbs.Y + anchorSize.Y + 6
			local aboveY = anchorAbs.Y - contentAbs.Y - popH - 6
			local y = belowY
			if belowY + popH > contentSize.Y - 8 and aboveY >= 8 then
				y = aboveY
			elseif belowY + popH > contentSize.Y - 8 then
				y = math.max(8, contentSize.Y - popH - 8)
			end

			entry.finalPos = UDim2.new(0, x, 0, y)
			popFrame.Position = UDim2.new(0, x, 0, y + 5)
			Utility.Tween(popFrame, { Time = 0.14, Style = Enum.EasingStyle.Quad }, {
				Position = UDim2.new(0, x, 0, y),
			})
		end

		task.defer(place)
		task.defer(function()
			task.wait(0.05)
			place()
		end)

		return popFrame
	end

	-- dialogs ---------------------------------------------------------------------
	function self:Dialog(options)
		return Dialog.New(self, options or {}, Library)
	end

	-- tabs ------------------------------------------------------------------------
	function self:SelectTab(target)
		local tab = nil
		if type(target) == "number" then
			tab = self.Tabs[target]
		elseif type(target) == "string" then
			for _, t in pairs(self.Tabs) do
				if t.Name == target then
					tab = t
				end
			end
		else
			tab = target
		end
		if not tab or tab == self.SelectedTab then
			return
		end
		self:ClosePopover()
		self.SelectedTab = tab
		for _, t in pairs(self.Tabs) do
			if t.SetSelected then
				t:SetSelected(t == tab)
			end
			if t.PageFrame then
				t.PageFrame.Visible = (t == tab)
			end
		end
	end

	function self:CreateTab(options)
		options = options or {}
		if options.LayoutOrder == nil then
			options.LayoutOrder = #self.Tabs
		end
		local tab = Tab.New(self, options, Library)
		self.Tabs[#self.Tabs + 1] = tab
		if #self.Tabs == 1 and options.UserHidden ~= true then
			self:SelectTab(tab)
		end
		return tab
	end

	-- debug console -----------------------------------------------------------------
	local consoleLogFrame = nil
	local consoleLines = 0

	local function appendConsoleEntry(entry)
		if not consoleLogFrame or consoleLogFrame.Parent == nil then
			return
		end
		local colorKey = "SubText"
		if entry.Level == "warn" then
			colorKey = "Warning"
		elseif entry.Level == "error" then
			colorKey = "Danger"
		elseif entry.Level == "success" then
			colorKey = "Success"
		end
		New("TextLabel", {
			Name = "Line",
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, -12, 0, 0),
			Font = Utility.Fonts.Mono,
			TextSize = 11,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			RichText = false,
			Text = entry.Full,
			LayoutOrder = os.clock() * 1000,
			Parent = consoleLogFrame,
		}, nil, { TextColor3 = colorKey })
		consoleLines = consoleLines + 1
		if consoleLines > 250 then
			for _, child in pairs(consoleLogFrame:GetChildren()) do
				if child:IsA("TextLabel") then
					child:Destroy()
					consoleLines = consoleLines - 1
					break
				end
			end
		end
	end

	local function buildConsoleTab()
		local tab = self:CreateTab({
			Name = "Console",
			Icon = "terminal",
			LayoutOrder = 999,
			UserHidden = true,
		})
		local button = tab._button
		if button then
			button.Visible = false
			button.LayoutOrder = 999
		end
		self._consoleButton = button
		self._consoleTab = tab

		local copyBtn = New("TextButton", {
			Name = "Copy",
			Size = UDim2.new(0, 70, 0, 24),
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			LayoutOrder = 3,
		}, {
			Creator.Corner(6),
			New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				Font = Utility.Fonts.Medium,
				TextSize = 11.5,
				Text = "Copy",
			}, nil, { TextColor3 = "Text" }),
		}, { BackgroundColor3 = "Control" })

		local clearBtn = New("TextButton", {
			Name = "Clear",
			Size = UDim2.new(0, 70, 0, 24),
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			LayoutOrder = 2,
		}, {
			Creator.Corner(6),
			New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				Font = Utility.Fonts.Medium,
				TextSize = 11.5,
				Text = "Clear",
			}, nil, { TextColor3 = "Text" }),
		}, { BackgroundColor3 = "Control" })

		local toolbar = New("Frame", {
			Name = "Toolbar",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 26),
			Parent = tab.PageColumn,
		}, {
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				Padding = UDim.new(0, 6),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			clearBtn,
			copyBtn,
		})
		clearBtn.Parent = toolbar
		copyBtn.Parent = toolbar
		toolbar.LayoutOrder = -5

		local logScroll = New("ScrollingFrame", {
			Name = "LogScroll",
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 0),
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 3,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			LayoutOrder = 1,
			ClipsDescendants = true,
		}, {
			Creator.Corner(10),
			New("UIPadding", {
				PaddingTop = UDim.new(0, 8),
				PaddingBottom = UDim.new(0, 8),
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
			}),
			New("UIListLayout", {
				Padding = UDim.new(0, 2),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		}, { BackgroundColor3 = "Group", ScrollBarImageColor3 = "Scroll" })

		local constraint = New("UISizeConstraint", {})
		constraint.Parent = logScroll
		logScroll.Parent = tab.PageColumn

		consoleLogFrame = logScroll
		self._consoleList = logScroll

		-- size: leave room for toolbar
		logScroll.Size = UDim2.new(1, 0, 0, 330)

		Creator.AddSignal(self.Connections, clearBtn.Activated, function()
			for _, child in pairs(logScroll:GetChildren()) do
				if child:IsA("TextLabel") then
					child:Destroy()
				end
			end
			consoleLines = 0
		end)
		Creator.AddSignal(self.Connections, copyBtn.Activated, function()
			local parts = {}
			for _, child in pairs(logScroll:GetChildren()) do
				if child:IsA("TextLabel") then
					parts[#parts + 1] = child.Text
				end
			end
			Utility.SetClipboard(table.concat(parts, "\n"))
			Library:Notify({ Title = "Console", Content = "Logs copied to clipboard.", Duration = 2, Icon = "check" })
		end)

		-- drain buffered entries
		Library:_DrainLogs(function(entry)
			appendConsoleEntry(entry)
		end)
		Library._ConsoleAppender = function(entry)
			appendConsoleEntry(entry)
		end
	end

	if config.Debug then
		buildConsoleTab()
	end

	-- watermark ---------------------------------------------------------------------
	if config.Watermark ~= false and config.Watermark ~= nil then
		-- created when config.Watermark == true explicitly
	end
	if config.Watermark == true or config.Watermark == nil then
		-- default ON unless explicitly false
	end

	-- loading + reveal -----------------------------------------------------------------
	function self:Reveal()
		if self._destroyed then
			return
		end
		local loadingEnabled = config.LoadingEnabled
		if loadingEnabled == nil then
			loadingEnabled = true
		end

		if not loadingEnabled then
			self:Show()
			return
		end

		local dim = New("Frame", {
			Name = "LoadingDim",
			Size = UDim2.new(1, 0, 1, 0),
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			ZIndex = 1400,
		}, nil, { BackgroundColor3 = "Overlay" })
		dim.Parent = gui

		local spinnerRing = New("Frame", {
			Name = "Ring",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 26),
			Size = UDim2.new(0, 26, 0, 26),
			BackgroundTransparency = 1,
			ZIndex = 1402,
		}, {
			Creator.Corner(13),
			New("UIStroke", {
				Thickness = 2.5,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}, nil, { Color = "Accent" }),
		})
		local ringStroke = spinnerRing:FindFirstChildOfClass("UIStroke")
		local gradient = New("UIGradient", {
			Rotation = 0,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.55, 1),
				NumberSequenceKeypoint.new(1, 1),
			}),
		})
		if ringStroke then
			gradient.Parent = ringStroke
		end

		local cardIconKind, cardIconValue = Icons.Resolve(config.Icon or "gem")
		local cardIcon
		if cardIconKind == "image" then
			cardIcon = New("ImageLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(0, 44, 0, 44),
				Image = cardIconValue,
				ZIndex = 1402,
			})
		else
			cardIcon = New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(0, 44, 0, 44),
				Font = Utility.Fonts.Regular,
				TextSize = 34,
				Text = cardIconValue,
				ZIndex = 1402,
			}, nil, { TextColor3 = "Accent" })
		end

		local card = New("Frame", {
			Name = "LoadingCard",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 260, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BorderSizePixel = 0,
			ZIndex = 1402,
		}, {
			Creator.Corner(16),
			Creator.Stroke("PopoverStroke", 1, 0.85),
			New("UIPadding", {
				PaddingTop = UDim.new(0, 26),
				PaddingBottom = UDim.new(0, 54),
			}),
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0, 6),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			cardIcon,
			New("TextLabel", {
				Name = "Title",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 22),
				Font = Utility.Fonts.Bold,
				TextSize = 16,
				Text = tostring(config.LoadingTitle or config.Name or "Crystal UI"),
				ZIndex = 1402,
				LayoutOrder = 2,
			}, nil, { TextColor3 = "Text" }),
			New("TextLabel", {
				Name = "Subtitle",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 16),
				Font = Utility.Fonts.Regular,
				TextSize = 12,
				Text = tostring(config.LoadingSubtitle or "Loading interface…"),
				ZIndex = 1402,
				LayoutOrder = 3,
			}, nil, { TextColor3 = "SubText" }),
			spinnerRing,
		}, { BackgroundColor3 = "Popover" })
		spinnerRing.LayoutOrder = 4
		spinnerRing.AnchorPoint = Vector2.new(0.5, 0)
		spinnerRing.Position = UDim2.new(0.5, 0, 0, 0)
		spinnerRing.Size = UDim2.new(0, 26, 0, 26)
		local spinnerHolder = New("Frame", {
			Name = "SpinnerHolder",
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 26, 0, 30),
			LayoutOrder = 4,
		})
		spinnerRing.Parent = spinnerHolder
		spinnerRing.Position = UDim2.new(0.5, 0, 0, 2)
		spinnerHolder.Parent = card
		card.Parent = dim

		Utility.Tween(dim, { Time = 0.25 }, { BackgroundTransparency = 0.35 })

		-- spinner loop
		local spinAlive = true
		task.spawn(function()
			while spinAlive and gradient and gradient.Parent ~= nil do
				local tw = Utility.Tween(gradient, { Time = 0.9, Style = Enum.EasingStyle.Linear }, { Rotation = 360 })
				if tw then
					tw.Completed:Wait()
					if gradient and gradient.Parent ~= nil then
						gradient.Rotation = 0
					end
				else
					break
				end
			end
		end)

		task.delay(1.35, function()
			spinAlive = false
			Utility.Tween(dim, { Time = 0.25 }, { BackgroundTransparency = 1 })
			Utility.Tween(card, { Time = 0.2 }, { Position = UDim2.new(0.5, 0, 0.5, 8) })
			task.delay(0.26, function()
				pcall(function()
					dim:Destroy()
				end)
			end)
			self:Show()
		end)
	end

	-- theme hook --------------------------------------------------------------------
	function self:SetTheme(themeName)
		return Themes.SetTheme(themeName)
	end

	-- destroy ------------------------------------------------------------------------
	function self:Destroy()
		if self._destroyed then
			return
		end
		self._destroyed = true
		self:ClosePopover()
		for _, tab in pairs(self.Tabs) do
			pcall(function()
				tab:Destroy()
			end)
		end
		self.Tabs = {}
		Utility.DisconnectAll(self.Connections)
		pcall(function()
			dockButton:Destroy()
		end)
		pcall(function()
			root:Destroy()
		end)
		refreshAcrylic()
	end

	refreshAcrylic()
	return self
end

return Window
