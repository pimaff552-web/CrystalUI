--============================================================--
--  Crystal UI | notifications.lua
--  macOS-style notification banners: top-right stack, slide-in,
--  hover to pause, click to dismiss, queued overflow.
--
--  Notifications.Bind(screenGui) once, then Notifications.Notify({...})
--============================================================--

local Import = ...
local Utility = Import("src/utility.lua")
local Creator = Import("src/creator.lua")
local Icons = Import("src/icons.lua")

local New = Creator.New

local Notifications = {}

local MAX_VISIBLE = 5
local Width = 320

Notifications._Gui = nil
Notifications._Container = nil
Notifications._Active = 0
Notifications._Queue = {}
Notifications._Connections = {}
Notifications._Destroyed = false

function Notifications.Bind(gui)
	Notifications._Gui = gui
	if Notifications._Container and Notifications._Container.Parent ~= nil then
		return
	end
	Notifications._Container = New("Frame", {
		Name = "Notifications",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 12),
		Size = UDim2.new(0, Width + 10, 1, -24),
		ZIndex = 1000,
		ClipsDescendants = false,
		Parent = gui,
	}, {
		New("UIListLayout", {
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
		}),
	})
end

local function dismissWrapper(wrapper, onDone)
	if not wrapper or wrapper:GetAttribute("Dismissing") then
		return
	end
	wrapper:SetAttribute("Dismissing", true)
	local card = wrapper:FindFirstChild("Card")
	if card then
		Utility.Tween(card, { Time = 0.22, Style = Enum.EasingStyle.Quad }, {
			Position = UDim2.new(1, Width + 24, 0, 0),
		})
	end
	task.delay(0.24, function()
		if wrapper then
			pcall(function()
				wrapper:Destroy()
			end)
		end
		Notifications._Active = math.max(0, Notifications._Active - 1)
		if onDone then
			onDone()
		end
		-- pump queue
		if #Notifications._Queue > 0 and Notifications._Active < MAX_VISIBLE then
			local cfg = table.remove(Notifications._Queue, 1)
			task.defer(function()
				Notifications.Notify(cfg)
			end)
		end
	end)
end

-- cfg: { Title, Content, Subtitle?, Duration?, Icon?, IconImage? }
function Notifications.Notify(cfg)
	if Notifications._Destroyed then
		return nil
	end
	cfg = cfg or {}
	if not Notifications._Gui or not Notifications._Container or Notifications._Container.Parent == nil then
		return nil
	end

	if Notifications._Active >= MAX_VISIBLE then
		Notifications._Queue[#Notifications._Queue + 1] = cfg
		return nil
	end
	Notifications._Active = Notifications._Active + 1

	local duration = tonumber(cfg.Duration) or 5
	local title = tostring(cfg.Title or "Notification")
	local content = cfg.Content and tostring(cfg.Content) or nil
	local icon = cfg.Icon or "bell"

	local iconInst = Icons.CreateIcon(icon, {
		Size = UDim2.fromOffset(18, 18),
		Position = UDim2.fromOffset(8, 8),
		TextSize = 17,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		ImageColor3 = Color3.fromRGB(255, 255, 255),
	}) 

	local iconBadge = New("Frame", {
		Name = "Badge",
		Size = UDim2.fromOffset(34, 34),
		Position = UDim2.fromOffset(12, 12),
		BorderSizePixel = 0,
	}, {
		Creator.Corner(8),
		iconInst,
	}, { BackgroundColor3 = "Accent" })

	local bodyChildren = {
		New("TextLabel", {
			Name = "Title",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 18),
			Font = Utility.Fonts.Bold,
			TextSize = 13.5,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			Text = title,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, nil, { TextColor3 = "Text" }),
	}
	if content then
		bodyChildren[#bodyChildren + 1] = New("TextLabel", {
			Name = "Content",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Font = Utility.Fonts.Regular,
			TextSize = 12.5,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			Text = content,
		}, nil, { TextColor3 = "SubText" })
	end

	local body = New("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(56, 10),
		Size = UDim2.new(1, -66, 1, -20),
	}, {
		New("UIListLayout", {
			Padding = UDim.new(0, 2),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
		table.unpack(bodyChildren),
	})
	bodyChildren = nil

	local card = New("Frame", {
		Name = "Card",
		Position = UDim2.new(1, Width + 24, 0, 0), -- offscreen right
		Size = UDim2.fromOffset(Width, content and 64 or 52),
		AutomaticSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0,
		Active = true,
		Selectable = false,
	}, {
		Creator.Corner(12),
		Creator.Stroke("PopoverStroke", 1, 0.88),
		New("UIPadding", {
			PaddingTop = UDim.new(0, 2),
			PaddingBottom = UDim.new(0, 2),
		}),
		iconBadge,
		body,
	}, { BackgroundColor3 = "Popover" })

	local wrapper = New("Frame", {
		Name = "Wrapper",
		BackgroundTransparency = 1,
		Size = UDim2.new(0, Width, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ClipsDescendants = false,
		Parent = Notifications._Container,
	}, {
		card,
	})

	-- slide in
	Utility.Tween(card, { Time = 0.4, Style = Enum.EasingStyle.Quint, Direction = Enum.EasingDirection.Out }, {
		Position = UDim2.new(0, 0, 0, 0),
	})

	-- lifecycle: hover pause + auto dismiss
	local hovered = false
	local dismissed = false
	local handle = {}

	Creator.AddSignal(Notifications._Connections, card.MouseEnter, function()
		hovered = true
		Utility.Tween(card, { Time = 0.15 }, { BackgroundTransparency = 0 })
	end)
	Creator.AddSignal(Notifications._Connections, card.MouseLeave, function()
		hovered = false
	end)
	Creator.AddSignal(Notifications._Connections, card.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			if not dismissed then
				dismissed = true
				dismissWrapper(wrapper)
			end
		end
	end)

	task.spawn(function()
		local remaining = duration
		while remaining > 0 do
			if dismissed or not wrapper or wrapper.Parent == nil then
				return
			end
			if not hovered then
				remaining = remaining - 0.1
			end
			task.wait(0.1)
		end
		if not dismissed and wrapper and wrapper.Parent ~= nil then
			dismissed = true
			dismissWrapper(wrapper)
		end
	end)

	function handle.Dismiss()
		if not dismissed then
			dismissed = true
			dismissWrapper(wrapper)
		end
	end

	return handle
end

function Notifications.ClearAll()
	if Notifications._Container then
		for _, child in pairs(Notifications._Container:GetChildren()) do
			if child:IsA("Frame") then
				dismissWrapper(child)
			end
		end
	end
	Notifications._Queue = {}
end

function Notifications.Destroy()
	Notifications._Destroyed = true
	Notifications.ClearAll()
	Utility.DisconnectAll(Notifications._Connections)
	Notifications._Container = nil
	Notifications._Gui = nil
end

return Notifications
