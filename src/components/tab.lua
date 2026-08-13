--============================================================--
--  Crystal UI | components/tab.lua
--  A sidebar tab: its own scrolling page, sections create new
--  macOS "group boxes"; elements flow into the current group.
--============================================================--

local Import = ...
local Utility = Import("src/utility.lua")
local Creator = Import("src/creator.lua")
local Icons = Import("src/icons.lua")

local ElementButton = Import("src/elements/button.lua")
local ElementToggle = Import("src/elements/toggle.lua")
local ElementSlider = Import("src/elements/slider.lua")
local ElementInput = Import("src/elements/input.lua")
local ElementDropdown = Import("src/elements/dropdown.lua")
local ElementColorPicker = Import("src/elements/colorpicker.lua")
local ElementKeybind = Import("src/elements/keybind.lua")
local ElementText = Import("src/elements/paragraph.lua")

local New = Creator.New

local Tab = {}
Tab.__index = Tab

function Tab.New(window, options, Library)
	options = options or {}
	local self = setmetatable({}, Tab)

	self.Window = window
	self.Library = Library
	self.Name = tostring(options.Name or "Tab")
	self.Icon = options.Icon
	self._elements = {}
	self._group = nil          -- current group body frame
	self._groupRows = 0        -- rows inside current group
	self._destroyed = false

	-- sidebar button -----------------------------------------------------------
	local iconKind, iconValue = Icons.Resolve(options.Icon or self.Name)
	local hovered = false
	local iconInst
	if iconKind == "image" then
		iconInst = New("ImageLabel", {
			Name = "Icon",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 8, 0.5, 0),
			Size = UDim2.new(0, 16, 0, 16),
			Image = iconValue,
			ScaleType = Enum.ScaleType.Fit,
		}, nil, { ImageColor3 = "SubText" })
	else
		iconInst = New("TextLabel", {
			Name = "Icon",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 7, 0.5, 0),
			Size = UDim2.new(0, 18, 0, 18),
			Font = Utility.Fonts.Regular,
			TextSize = 14,
			Text = iconValue,
		}, nil, { TextColor3 = "SubText" })
	end

	local tabLabel = New("TextLabel", {
		Name = "Label",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 32, 0, 0),
		Size = UDim2.new(1, -38, 1, 0),
		Font = Utility.Fonts.Regular,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = self.Name,
	}, nil, { TextColor3 = "SubText" })

	-- accent indicator bar (visible only on the selected tab)
	local indicator = New("Frame", {
		Name = "Indicator",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 2, 0.5, 0),
		Size = UDim2.new(0, 3, 0, 16),
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 3,
	}, {
		Creator.Corner(2),
	}, { BackgroundColor3 = "Accent" })

	local button = New("TextButton", {
		Name = "Tab_" .. self.Name,
		Size = UDim2.new(1, 0, 0, 30),
		BorderSizePixel = 0,
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Text = "",
		LayoutOrder = options.LayoutOrder or 0,
	}, {
		Creator.Corner(7),
		indicator,
		iconInst,
		tabLabel,
	}, { BackgroundColor3 = "Selection" })
	button.Parent = window.TabsContainer
	self._indicator = indicator

	self._button = button
	self._iconInst = iconInst
	self._labelInst = tabLabel

	-- page ----------------------------------------------------------------------
	local pageColumn = New("Frame", {
		Name = "Column",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -20, 1, -16),
		Position = UDim2.new(0, 10, 0, 8),
	}, {
		New("UIListLayout", {
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local page = New("ScrollingFrame", {
		Name = "Page_" .. self.Name,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageTransparency = 0.55,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
		Visible = false,
		ClipsDescendants = true,
	}, {
		pageColumn,
	}, { ScrollBarImageColor3 = "Scroll" })
	page.Parent = window.PagesContainer

	self.PageFrame = page
	self.PageColumn = pageColumn

	Creator.AddSignal(window.Connections, button.MouseEnter, function()
		hovered = true
		if window.SelectedTab ~= self then
			Utility.Tween(button, { Time = 0.12 }, { BackgroundTransparency = 0.94 })
		end
	end)
	Creator.AddSignal(window.Connections, button.MouseLeave, function()
		hovered = false
		if window.SelectedTab ~= self then
			Utility.Tween(button, { Time = 0.14 }, { BackgroundTransparency = 1 })
		end
	end)
	Creator.AddSignal(window.Connections, button.Activated, function()
		window:SelectTab(self)
	end)

	function self.SetSelected(selected)
		local palette = Library.Themes.Palette()
		if self._indicator then
			self._indicator.Visible = selected
		end
		if selected then
			button.BackgroundTransparency = 0
			tabLabel.Font = Utility.Fonts.Medium
			tabLabel.TextColor3 = palette.Text
			if iconInst:IsA("ImageLabel") then
				iconInst.ImageColor3 = palette.Text
			else
				iconInst.TextColor3 = palette.Text
			end
		else
			button.BackgroundTransparency = hovered and 0.94 or 1
			tabLabel.Font = Utility.Fonts.Regular
			tabLabel.TextColor3 = palette.SubText
			if iconInst:IsA("ImageLabel") then
				iconInst.ImageColor3 = palette.SubText
			else
				iconInst.TextColor3 = palette.SubText
			end
		end
	end

	-- sidebar search filter
	function self.SetFiltered(visible)
		button.Visible = visible and true or false
	end

	-- group management ------------------------------------------------------------
	function self:_EnsureGroup()
		if self._group and self._group.Parent ~= nil then
			return self._group
		end
		local body = New("Frame", {
			Name = "Group",
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BorderSizePixel = 0,
			ClipsDescendants = true,
		}, {
			Creator.Corner(10),
			Creator.Stroke("GroupStroke", 1, 0.92),
			New("UIListLayout", {
				Padding = UDim.new(0, 0),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		}, { BackgroundColor3 = "Group" })
		body.Parent = pageColumn
		self._group = body
		self._groupRows = 0
		return body
	end

	function self:_MakeCtx()
		local tabSelf = self
		local ctx = {
			Window = window,
			Library = Library,
			Tab = tabSelf,
			Connections = window.Connections,
		}
		function ctx.AttachRow(rowInstance)
			local group = tabSelf:_EnsureGroup()
			if tabSelf._groupRows > 0 then
				New("Frame", {
					Name = "Separator",
					BorderSizePixel = 0,
					Size = UDim2.new(1, -24, 0, 1),
					Position = UDim2.new(0, 12, 0, 0),
					BackgroundTransparency = 0.93,
					LayoutOrder = tabSelf._groupRows * 2,
					Parent = group,
				}, nil, { BackgroundColor3 = "Separator" })
			end
			rowInstance.LayoutOrder = tabSelf._groupRows * 2 + 1
			rowInstance.Parent = group
			tabSelf._groupRows = tabSelf._groupRows + 1
		end
		return ctx
	end

	-- public element factories -----------------------------------------------------
	function self.CreateSection(_, name, icon)
		self._group = nil -- start a NEW group for following elements

		local header = New("TextLabel", {
			Name = "Section",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -4, 0, 18),
			Font = Utility.Fonts.Medium,
			TextSize = 11.5,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = string.upper(tostring(name or "Section")),
			LayoutOrder = 0,
		}, nil, { TextColor3 = "SubText" })

		local headerRow = New("Frame", {
			Name = "SectionRow",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 26),
		}, {
			New("UIPadding", {
				PaddingLeft = UDim.new(0, 4),
				PaddingTop = UDim.new(0, 2),
			}),
			header,
		})
		headerRow.Parent = pageColumn

		local section = {}
		section.Type = "Section"
		section.Instance = headerRow
		function section.Set(_, newName)
			header.Text = string.upper(tostring(newName))
		end
		function section.Destroy()
			pcall(function()
				headerRow:Destroy()
			end)
		end

		self._elements[#self._elements + 1] = section
		return section
	end

	local function track(element)
		self._elements[#self._elements + 1] = element
		return element
	end

	function self.CreateButton(_, options)
		return track(ElementButton.New(options or {}, self:_MakeCtx()))
	end

	function self.CreateToggle(_, options)
		return track(ElementToggle.New(options or {}, self:_MakeCtx()))
	end

	function self.CreateSlider(_, options)
		return track(ElementSlider.New(options or {}, self:_MakeCtx()))
	end

	function self.CreateInput(_, options)
		return track(ElementInput.New(options or {}, self:_MakeCtx()))
	end

	function self.CreateDropdown(_, options)
		return track(ElementDropdown.New(options or {}, self:_MakeCtx()))
	end

	function self.CreateColorPicker(_, options)
		return track(ElementColorPicker.New(options or {}, self:_MakeCtx()))
	end

	function self.CreateKeybind(_, options)
		return track(ElementKeybind.New(options or {}, self:_MakeCtx()))
	end

	function self.CreateParagraph(_, options)
		return track(ElementText.Paragraph(options or {}, self:_MakeCtx()))
	end

	function self.CreateLabel(_, text)
		return track(ElementText.Label(text, self:_MakeCtx()))
	end

	function self.CreateDivider(_)
		return track(ElementText.Divider(self:_MakeCtx()))
	end

	function self.Destroy(_)
		self._destroyed = true
		for _, element in pairs(self._elements) do
			pcall(function()
				element:Destroy()
			end)
		end
		self._elements = {}
		pcall(function()
			button:Destroy()
		end)
		pcall(function()
			page:Destroy()
		end)
	end

	return self
end

return Tab
