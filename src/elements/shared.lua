--============================================================--
--  Crystal UI | elements/shared.lua
--  Shared building blocks for all elements: macOS "settings
--  row" layout (title/description left, control right),
--  automatic hairline separators, flag registration.
--============================================================--

local Import = ...
local Utility = Import("src/utility.lua")
local Creator = Import("src/creator.lua")

local New = Creator.New

local Shared = {}

-- Builds a standard row and attaches it to the group (with separator).
-- Returns: row, titleLabel, controlHolder
function Shared.Row(Ctx, options)
	options = options or {}
	local description = options.Description
	local name = tostring(options.Name or options.Title or "Element")
	local hasDesc = description ~= nil and description ~= ""
	local height = options.Height or (hasDesc and 54 or 44)

	local title = New("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, hasDesc and 0 or 20),
		Font = Utility.Fonts.Medium,
		TextSize = 13.5,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = hasDesc and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
		TextWrapped = true,
		Text = name,
		TextTruncate = hasDesc and Enum.TextTruncate.None or Enum.TextTruncate.AtEnd,
	}, nil, { TextColor3 = "Text" })

	local left = New("Frame", {
		Name = "Left",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(1, -12, 1, 0),
	}, {
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 2),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		title,
	})

	if hasDesc then
		New("TextLabel", {
			Name = "Description",
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			Font = Utility.Fonts.Regular,
			TextSize = 11.5,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			Text = tostring(description),
			LayoutOrder = 2,
		}, nil, { TextColor3 = "SubText" }).Parent = left
	end

	local control = New("Frame", {
		Name = "Control",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.new(0, 40, 0, 24),
		ZIndex = 3,
	})

	local row = New("Frame", {
		Name = "Row_" .. name,
		Size = UDim2.new(1, 0, 0, height),
		AutomaticSize = options.AutoHeight and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, {
		left,
		control,
	}, { BackgroundColor3 = "RowHover", BackgroundTransparency = 1 })

	Ctx.AttachRow(row)

	return row, title, control, left
end

-- Shrinks the left text column so it never overlaps the right control.
function Shared.ReserveLeft(left, controlWidth)
	left.Size = UDim2.new(1, -(12 + controlWidth + 10), 1, 0)
end

-- Hover animation for a row (subtle macOS hover wash).
function Shared.RowHover(row, connections)
	Creator.AddSignal(connections, row.MouseEnter, function()
		Utility.Tween(row, { Time = 0.12 }, { BackgroundTransparency = 0.955 })
	end)
	Creator.AddSignal(connections, row.MouseLeave, function()
		Utility.Tween(row, { Time = 0.15 }, { BackgroundTransparency = 1 })
	end)
end

-- Base object boilerplate shared by every element.
function Shared.Object(Ctx, type_, instance, options)
	local self = {}
	self.Type = type_
	self.Instance = instance
	self._conns = {}
	self._destroyed = false

	-- Flag registration + pending config restore.
	local flag = options.Flag
	if flag and flag ~= "" and Ctx.Library then
		self.Flag = flag
		Ctx.Library:RegisterFlag(self)
		local pending = Ctx.Library:GetPendingConfig(flag)
		if pending ~= nil and self.Set and self.Deserialize then
			task.defer(function()
				if not self._destroyed and self.Instance and self.Instance.Parent ~= nil then
					Utility.SafeCall("Config:" .. tostring(flag), function()
						self:Set(self.Deserialize(pending), true)
					end)
				end
			end)
		end
	end

	function self.Destroy()
		if self._destroyed then
			return
		end
		self._destroyed = true
		if self.Flag and Ctx.Library then
			Ctx.Library:UnregisterFlag(self.Flag)
		end
		Utility.DisconnectAll(self._conns)
		if self.Instance then
			pcall(function()
				self.Instance:Destroy()
			end)
			self.Instance = nil
		end
	end

	-- mark helper used by flag system after Set
	function self:_touchConfig()
		if self.Flag and Ctx.Library then
			Ctx.Library:TouchConfig()
		end
	end

	return self
end

return Shared
