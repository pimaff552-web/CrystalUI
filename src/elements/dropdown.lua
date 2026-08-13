--============================================================--
--  Crystal UI | elements/dropdown.lua
--  macOS pop-up button: pill control + floating popover list.
--  Supports multi-select, live search, refresh.
--
--  Tab:CreateDropdown({ Name, Description?, Options = {...},
--     CurrentOption, Multi?, Searchable?, Flag?, Callback })
--============================================================--

local Import = ...
local Utility = Import("src/utility.lua")
local Creator = Import("src/creator.lua")
local Shared = Import("src/elements/shared.lua")

local New = Creator.New

local Dropdown = {}

local ITEM_H = 30
local MAX_POPOVER_H = 250

local function toOptionList(raw)
	local out = {}
	if type(raw) == "table" then
		for _, v in pairs(raw) do
			out[#out + 1] = tostring(v)
		end
	end
	table.sort(out)
	return out
end

function Dropdown.New(options, Ctx)
	options = options or {}
	local row, _, control, left = Shared.Row(Ctx, options)

	local Themes = Ctx.Library.Themes

	local chevron = New("TextLabel", {
		Name = "Chevron",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.new(0, 12, 0, 12),
		Font = Utility.Fonts.Bold,
		TextSize = 10,
		Text = "\u{25BE}",
	}, nil, { TextColor3 = "SubText" })

	local pillText = New("TextLabel", {
		Name = "Selection",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 0),
		Size = UDim2.new(1, -30, 0, 16),
		Font = Utility.Fonts.Regular,
		TextSize = 12.5,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = "",
	}, nil, { TextColor3 = "Text" })

	local pill = New("TextButton", {
		Name = "Pill",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 130, 0, 26),
		AutoButtonColor = false,
		Text = "",
		BorderSizePixel = 0,
	}, {
		Creator.Corner(7),
		Creator.Stroke("ControlStroke", 1, 0.88),
		pillText,
		chevron,
	}, { BackgroundColor3 = "Control" })

	control.Size = UDim2.new(0, 130, 0, 26)
	pill.Parent = control
	Shared.ReserveLeft(left, 130)

	local self = Shared.Object(Ctx, "Dropdown", row, options)
	self.Multi = options.Multi and true or false
	if options.Multiple ~= nil then
		self.Multi = options.Multiple and true or false
	end
	self.Options = toOptionList(options.Options)
	self.Value = self.Multi and {} or nil
	self._open = false

	Shared.RowHover(row, self._conns)

	local function isSelected(option)
		if self.Multi then
			for _, v in pairs(self.Value) do
				if v == option then
					return true
				end
			end
			return false
		end
		return self.Value == option
	end

	local function updatePillText()
		local text
		if self.Multi then
			if #self.Value == 0 then
				text = tostring(options.Placeholder or "None")
			elseif #self.Value == 1 then
				text = self.Value[1]
			else
				text = tostring(#self.Value) .. " selected"
			end
		else
			text = self.Value or tostring(options.Placeholder or "Select…")
		end
		pillText.Text = text
		local w = Utility.TextWidth(text, 12.5, Utility.Fonts.Regular) + 34
		w = Utility.Clamp(w, 96, 200)
		pill.Size = UDim2.new(0, w, 0, 26)
		control.Size = UDim2.new(0, w, 0, 26)
	end

	local function fireCallback()
		if self.Multi then
			local copy = Utility.DeepCopy(self.Value)
			Utility.SafeCall("Dropdown:" .. tostring(options.Name), options.Callback, copy)
		else
			Utility.SafeCall("Dropdown:" .. tostring(options.Name), options.Callback, self.Value)
		end
	end

	local function toggleOption(option)
		if self.Multi then
			if isSelected(option) then
				local next = {}
				for _, v in pairs(self.Value) do
					if v ~= option then
						next[#next + 1] = v
					end
				end
				self.Value = next
			else
				self.Value[#self.Value + 1] = option
			end
			updatePillText()
			fireCallback()
			self:_touchConfig()
		else
			self.Value = option
			updatePillText()
			fireCallback()
			self:_touchConfig()
		end
	end

	-- popover ------------------------------------------------------
	local function buildItems(scroll, query)
		for _, child in pairs(scroll:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		local shown = 0
		local q = Utility.Trim(string.lower(query or ""))
		for _, option in pairs(self.Options) do
			if q == "" or string.find(string.lower(option), q, 1, true) then
				shown = shown + 1
				local selected = isSelected(option)
				local item = New("TextButton", {
					Name = "Item_" .. option,
					Size = UDim2.new(1, -8, 0, ITEM_H),
					Position = UDim2.new(0, 4, 0, 0),
					BackgroundTransparency = 1,
					AutoButtonColor = false,
					Text = "",
					BorderSizePixel = 0,
					LayoutOrder = shown,
				}, {
					Creator.Corner(6),
					New("TextLabel", {
						Name = "Check",
						BackgroundTransparency = 1,
						Position = UDim2.new(0, 8, 0, 0),
						Size = UDim2.new(0, 14, 1, 0),
						Font = Utility.Fonts.Bold,
						TextSize = 11,
						Text = selected and "\u{2713}" or "",
					}, nil, { TextColor3 = "Accent" }),
					New("TextLabel", {
						Name = "Label",
						BackgroundTransparency = 1,
						Position = UDim2.new(0, 27, 0, 0),
						Size = UDim2.new(1, -34, 1, 0),
						Font = selected and Utility.Fonts.Medium or Utility.Fonts.Regular,
						TextSize = 12.5,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextTruncate = Enum.TextTruncate.AtEnd,
						Text = option,
					}, nil, { TextColor3 = "Text" }),
				}, { BackgroundColor3 = "RowHover" })
				item.BackgroundTransparency = 1
				item.Parent = scroll

				item.MouseEnter:Connect(function()
					Utility.Tween(item, { Time = 0.1 }, { BackgroundTransparency = 0.94 })
				end)
				item.MouseLeave:Connect(function()
					Utility.Tween(item, { Time = 0.12 }, { BackgroundTransparency = 1 })
				end)
				item.Activated:Connect(function()
					if self._destroyed then
						return
					end
					toggleOption(option)
					if self.Multi then
						-- repaint selection states
						local queryNow = scroll:GetAttribute("Query") or ""
						buildItems(scroll, queryNow)
					else
						Ctx.Window:ClosePopover()
					end
				end)
			end
		end
		local emptyLabel = scroll:FindFirstChild("Empty")
		if shown == 0 then
			if not emptyLabel then
				New("TextLabel", {
					Name = "Empty",
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 28),
					Font = Utility.Fonts.Regular,
					TextSize = 12,
					Text = "No results",
					Parent = scroll,
				}, nil, { TextColor3 = "Placeholder" })
			end
		elseif emptyLabel then
			emptyLabel:Destroy()
		end
	end

	local function open()
		if self._open then
			Ctx.Window:ClosePopover()
			return
		end
		if #self.Options == 0 then
			Ctx.Library:Notify({
				Title = tostring(options.Name or "Dropdown"),
				Content = "No options available.",
				Duration = 2.5,
				Icon = "warning",
			})
			return
		end

		local searchable = options.Searchable
		if searchable == nil then
			searchable = #self.Options >= 10
		end

		local width = math.max(pill.AbsoluteSize.X, 168)
		width = Utility.Clamp(width + 20, 168, 260)

		Ctx.Window:OpenPopover(pill, width, MAX_POPOVER_H, function(pop)
			local inner = New("Frame", {
				Name = "Inner",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Parent = pop,
			}, {
				New("UIListLayout", {
					Padding = UDim.new(0, 4),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				New("UIPadding", {
					PaddingTop = UDim.new(0, 6),
					PaddingBottom = UDim.new(0, 6),
					PaddingLeft = UDim.new(0, 6),
					PaddingRight = UDim.new(0, 6),
				}),
			})

			local scroll
			if searchable then
				local searchBox = New("TextBox", {
					Name = "Search",
					Size = UDim2.new(1, -8, 0, 26),
					Position = UDim2.new(0, 4, 0, 0),
					BorderSizePixel = 0,
					Font = Utility.Fonts.Regular,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					PlaceholderText = "Search…",
					Text = "",
					ClearTextOnFocus = false,
					LayoutOrder = -1,
					Parent = inner,
				}, {
					Creator.Corner(6),
					Creator.Stroke("ControlStroke", 1, 0.92),
					New("UIPadding", {
						PaddingLeft = UDim.new(0, 8),
						PaddingRight = UDim.new(0, 8),
					}),
				}, { BackgroundColor3 = "Control", TextColor3 = "Text", PlaceholderColor3 = "Placeholder" })

				searchBox:GetPropertyChangedSignal("Text"):Connect(function()
					if scroll and scroll.Parent ~= nil then
						scroll:SetAttribute("Query", searchBox.Text)
						buildItems(scroll, searchBox.Text)
					end
				end)
			end

			local estItems = math.min(#self.Options, 7)
			local listHeight = estItems * ITEM_H + 4

			scroll = New("ScrollingFrame", {
				Name = "List",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ScrollBarThickness = 3,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				CanvasSize = UDim2.new(0, 0, 0, 0),
				LayoutOrder = 1,
				Parent = inner,
			}, {
				New("UIListLayout", {
					Padding = UDim.new(0, 2),
					SortOrder = Enum.SortOrder.LayoutOrder,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
				}),
				New("UISizeConstraint", {
					MaxSize = Vector2.new(9999, 7 * ITEM_H + 6),
				}),
			}, { ScrollBarImageColor3 = "Scroll" })

			buildItems(scroll, "")
		end, {
			OnClose = function()
				self._open = false
				Utility.Tween(chevron, { Time = 0.15 }, { Rotation = 0 })
			end,
		})

		self._open = true
		Utility.Tween(chevron, { Time = 0.15 }, { Rotation = 180 })
	end

	Creator.AddSignal(self._conns, pill.Activated, open)

	-- public API ---------------------------------------------------
	function self.Set(value, fireCallback)
		if self.Multi then
			local cleaned = {}
			if type(value) == "table" then
				for _, v in pairs(value) do
					v = tostring(v)
					local exists = false
					for _, o in pairs(self.Options) do
						if o == v then
							exists = true
						end
					end
					if exists then
						cleaned[#cleaned + 1] = v
					end
				end
			elseif value ~= nil then
				cleaned = { tostring(value) }
			end
			self.Value = cleaned
		else
			local stringValue = nil
			if value ~= nil then
				stringValue = tostring(value)
				local exists = false
				for _, o in pairs(self.Options) do
					if o == stringValue then
						exists = true
					end
				end
				if not exists then
					stringValue = nil
				end
			end
			self.Value = stringValue
		end
		updatePillText()
		if fireCallback ~= false then
			fireCallback()
			self:_touchConfig()
		end
	end

	function self.Refresh(newOptions, keepCurrent)
		self.Options = toOptionList(newOptions)
		local current = self.Value
		if not keepCurrent then
			self.Value = self.Multi and {} or nil
		end
		if keepCurrent then
			self:Set(current, false)
		else
			updatePillText()
		end
	end

	function self.Add(option)
		option = tostring(option)
		for _, o in pairs(self.Options) do
			if o == option then
				return
			end
		end
		self.Options[#self.Options + 1] = option
		table.sort(self.Options)
	end

	function self.Remove(option)
		option = tostring(option)
		local next = {}
		for _, o in pairs(self.Options) do
			if o ~= option then
				next[#next + 1] = o
			end
		end
		self.Options = next
		if self.Multi then
			local kept = {}
			for _, v in pairs(self.Value) do
				if v ~= option then
					kept[#kept + 1] = v
				end
			end
			self.Value = kept
		elseif self.Value == option then
			self.Value = nil
		end
		updatePillText()
	end

	function self.Serialize()
		return self.Value
	end

	function self.Deserialize(v)
		return v
	end

	-- initial selection --------------------------------------------
	updatePillText()
	local initial = options.CurrentOption
	if initial == nil then
		initial = options.Default
	end
	if initial ~= nil then
		task.defer(function()
			if not self._destroyed then
				self:Set(initial)
			end
		end)
	end

	return self
end

return Dropdown
