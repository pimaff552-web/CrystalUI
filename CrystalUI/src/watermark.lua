--============================================================--
--  Crystal UI | watermark.lua
--  Floating macOS-pill watermark: name, FPS, ping, clock.
--  Draggable. Watermark.New(gui, {Name}) -> handle
--============================================================--

local Import = ...
local Utility = Import("src/utility.lua")
local Creator = Import("src/creator.lua")

local New = Creator.New
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local Watermark = {}

function Watermark.New(gui, opts)
	opts = opts or {}
	local self = {}
	local connections = {}
	local alive = true

	local nameText = tostring(opts.Name or "Crystal UI")

	local label = New("TextLabel", {
		Name = "Label",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		Font = Utility.Fonts.Medium,
		TextSize = 12,
		Text = "",
	}, nil, { TextColor3 = "Text" })

	local gem = New("TextLabel", {
		Name = "Gem",
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 18, 1, 0),
		Font = Utility.Fonts.Bold,
		TextSize = 13,
		Text = "\u{1F48E}",
	}, nil, { TextColor3 = "Accent" })

	local pill = New("TextButton", {
		Name = "Watermark",
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.new(0, 14, 0, 14),
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 0, 26),
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		Active = true,
		Draggable = false,
	}, {
		Creator.Corner(13),
		Creator.Stroke("GroupStroke", 1, 0.88),
		New("UIPadding", {
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
		}),
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		gem,
		label,
	}, { BackgroundColor3 = "Popover" })
	pill.Parent = gui

	-- drag support (mouse + touch)
	local stopDrag = Utility.Drag(pill, pill, {})
	connections[#connections + 1] = stopDrag

	-- fps counter
	local frames = 0
	local fps = 0
	connections[#connections + 1] = RunService.RenderStepped:Connect(function()
		frames = frames + 1
	end)

	local function getPing()
		local ok, ping = pcall(function()
			local item = Stats.Network.ServerStatsItem["Data Ping"]
			return item:GetValue()
		end)
		if ok and ping then
			return math.floor(ping + 0.5)
		end
		return 0
	end

	task.spawn(function()
		local tick_count = 0
		while alive and pill and pill.Parent ~= nil do
			task.wait(0.5)
			fps = frames * 2
			frames = 0
			tick_count = tick_count + 1
			local timeText = os.date("%H:%M")
			local ping = 0
			if tick_count % 2 == 0 then
				ping = getPing()
			else
				ping = self._lastPing or 0
			end
			self._lastPing = ping
			if alive and label and label.Parent ~= nil then
				label.Text = string.format("%s  ·  %d FPS  ·  %d ms  ·  %s", nameText, fps, ping, timeText)
			end
		end
	end)

	function self.SetVisible(visible)
		if pill then
			pill.Visible = visible and true or false
		end
	end

	function self.SetName(newName)
		nameText = tostring(newName or nameText)
	end

	function self.Destroy()
		alive = false
		Utility.DisconnectAll(connections)
		if pill then
			pcall(function()
				pill:Destroy()
			end)
			pill = nil
		end
	end

	return self
end

return Watermark
