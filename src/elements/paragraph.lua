--============================================================--
--  Crystal UI | elements/paragraph.lua
--  Text blocks: Paragraph (title + wrapped body), Label, Divider.
--
--  Tab:CreateParagraph({ Title, Content })
--  Tab:CreateLabel(text)        -> single line label
--  Tab:CreateDivider()
--============================================================--

local Import = ...
local Utility = Import("src/utility.lua")
local Creator = Import("src/creator.lua")

local New = Creator.New

local Text = {}

-- Paragraph -------------------------------------------------------------
function Text.Paragraph(options, Ctx)
	options = options or {}

	local content = New("TextLabel", {
		Name = "Content",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		Font = Utility.Fonts.Regular,
		TextSize = 12,
		TextWrapped = true,
		RichText = options.RichText and true or false,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Text = tostring(options.Content or ""),
		LayoutOrder = 2,
	}, nil, { TextColor3 = "SubText" })

	local title = New("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		Font = Utility.Fonts.Bold,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Text = tostring(options.Title or ""),
		Visible = options.Title ~= nil and options.Title ~= "",
		LayoutOrder = 1,
	}, nil, { TextColor3 = "Text" })

	local row = New("Frame", {
		Name = "Paragraph",
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
	}, {
		New("UIPadding", {
			PaddingTop = UDim.new(0, 12),
			PaddingBottom = UDim.new(0, 12),
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
		}),
		New("UIListLayout", {
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		title,
		content,
	})

	Ctx.AttachRow(row)

	local self = {}
	self.Type = "Paragraph"
	self.Instance = row

	function self.Set(newOptions)
		if type(newOptions) == "table" then
			if newOptions.Title ~= nil then
				title.Text = tostring(newOptions.Title)
				title.Visible = newOptions.Title ~= ""
			end
			if newOptions.Content ~= nil then
				content.Text = tostring(newOptions.Content)
			end
		else
			content.Text = tostring(newOptions)
		end
	end

	function self.SetTitle(text)
		title.Text = tostring(text)
		title.Visible = text ~= nil and text ~= ""
	end

	function self.SetContent(text)
		content.Text = tostring(text)
	end

	function self.Destroy()
		if row then
			pcall(function()
				row:Destroy()
			end)
			row = nil
		end
	end

	return self
end

-- Label -------------------------------------------------------------------
function Text.Label(text, Ctx)
	local label = New("TextLabel", {
		Name = "Label",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, -24, 0, 20),
		Font = Utility.Fonts.Regular,
		TextSize = 12.5,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Text = tostring(text or ""),
	}, nil, { TextColor3 = "Text" })

	local row = New("Frame", {
		Name = "LabelRow",
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
	}, {
		New("UIPadding", {
			PaddingTop = UDim.new(0, 11),
			PaddingBottom = UDim.new(0, 11),
			PaddingLeft = UDim.new(0, 12),
		}),
		label,
	})

	Ctx.AttachRow(row)

	local self = {}
	self.Type = "Label"
	self.Instance = row

	function self.Set(newText)
		label.Text = tostring(newText)
	end

	function self.Destroy()
		if row then
			pcall(function()
				row:Destroy()
			end)
			row = nil
		end
	end

	return self
end

-- Divider (page-level, sits between groups) --------------------------------
function Text.Divider(Ctx)
	local line = New("Frame", {
		Name = "Divider",
		Size = UDim2.new(1, -24, 0, 1),
		BorderSizePixel = 0,
		BackgroundTransparency = 0.9,
	}, nil, { BackgroundColor3 = "Separator" })

	local row = New("Frame", {
		Name = "DividerRow",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 9),
	}, {
		line,
	})

	line.AnchorPoint = Vector2.new(0.5, 0.5)
	line.Position = UDim2.new(0.5, 0, 0.5, 0)

	-- Dividers attach directly to the page column (not inside a group)
	row.Parent = Ctx.Tab.PageColumn

	local self = {}
	self.Type = "Divider"
	self.Instance = row

	function self.Destroy()
		if row then
			pcall(function()
				row:Destroy()
			end)
			row = nil
		end
	end

	return self
end

return Text
