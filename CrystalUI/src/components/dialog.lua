--============================================================--
--  Crystal UI | components/dialog.lua
--  macOS alert dialog: dimmed overlay, centered card, buttons.
--
--  Window:Dialog({ Title, Content, Buttons = {
--      { Title = "Sure", Style = "Default"|"Cancel"|"Danger", Callback = fn },
--  }})
--============================================================--

local Import = ...
local Utility = Import("src/utility.lua")
local Creator = Import("src/creator.lua")

local New = Creator.New
local UserInputService = game:GetService("UserInputService")

local Dialog = {}

function Dialog.New(window, options, Library)
	options = options or {}
	local self = {}
	local connections = {}
	local dismissed = false

	local layer = window.DialogLayer
	if not layer then
		return nil
	end

	-- remove previous dialog
	local old = layer:FindFirstChild("DialogDim")
	if old then
		old:Destroy()
	end

	local function dismiss()
		if dismissed then
			return
		end
		dismissed = true
		Utility.DisconnectAll(connections)
		local dim = layer:FindFirstChild("DialogDim")
		if dim then
			local card = dim:FindFirstChild("Card")
			if card then
				Utility.Tween(card, { Time = 0.18 }, { Position = UDim2.new(0.5, 0, 0.5, 10) })
			end
			Utility.Tween(dim, { Time = 0.18 }, { BackgroundTransparency = 1 })
			task.delay(0.2, function()
				pcall(function()
					dim:Destroy()
				end)
			end)
		end
	end

	-- buttons row
	local buttonsFrame = New("Frame", {
		Name = "Buttons",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -24, 0, 28),
		Position = UDim2.new(0, 12, 0, 0),
	}, {
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local body = New("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
	}, {
		New("UIListLayout", {
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		}),
		New("UIPadding", {
			PaddingTop = UDim.new(0, 18),
			PaddingBottom = UDim.new(0, 16),
		}),
		New("TextLabel", {
			Name = "Title",
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, -32, 0, 0),
			Font = Utility.Fonts.Bold,
			TextSize = 14.5,
			TextWrapped = true,
			Text = tostring(options.Title or "Alert"),
			LayoutOrder = 1,
		}, nil, { TextColor3 = "Text" }),
		New("TextLabel", {
			Name = "Content",
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, -32, 0, 0),
			Font = Utility.Fonts.Regular,
			TextSize = 12.5,
			TextWrapped = true,
			Text = tostring(options.Content or ""),
			LayoutOrder = 2,
		}, nil, { TextColor3 = "SubText" }),
		New("Frame", {
			Name = "ButtonsHolder",
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 30),
			LayoutOrder = 3,
		}, {
			New("UIPadding", {
				PaddingLeft = UDim.new(0, 16),
				PaddingRight = UDim.new(0, 16),
			}),
			buttonsFrame,
		}),
	})
	local card = New("Frame", {
		Name = "Card",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 10),
		Size = UDim2.new(0, 360, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0,
	}, {
		Creator.Corner(14),
		Creator.Stroke("PopoverStroke", 1, 0.85),
		body,
	}, { BackgroundColor3 = "Popover" })

	local dim = New("TextButton", {
		Name = "DialogDim",
		Size = UDim2.new(1, 0, 1, 0),
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 50,
		BackgroundTransparency = 1,
	}, {
		card,
	}, { BackgroundColor3 = "Overlay" })
	dim.BackgroundTransparency = 1
	card.ZIndex = 51
	card.Parent = dim
	dim.Parent = layer

	-- animate in
	Utility.Tween(dim, { Time = 0.18 }, { BackgroundTransparency = 0.35 })
	Utility.Tween(card, { Time = 0.24, Style = Enum.EasingStyle.Back, Direction = Enum.EasingDirection.Out }, {
		Position = UDim2.new(0.5, 0, 0.5, 0),
	})

	-- build buttons
	local buttonDefs = options.Buttons
	if type(buttonDefs) ~= "table" or #buttonDefs == 0 then
		buttonDefs = { { Title = "OK", Style = "Default" } }
	end

	local defaultAction = nil
	local cancelAction = nil

	for index, def in pairs(buttonDefs) do
		if type(def) == "table" then
			local style = def.Style or (index == 1 and "Default" or "Cancel")
			local bgKey = "Accent"
			local textKey = "OnAccent"
			if style == "Cancel" then
				bgKey = "Control"
				textKey = "Text"
			elseif style == "Danger" or style == "Destructive" then
				bgKey = "Danger"
				textKey = "OnAccent"
			end

			local title = tostring(def.Title or "OK")
			local width = Utility.Clamp(Utility.TextWidth(title, 12.5, Utility.Fonts.Medium) + 26, 64, 200)

			local btn = New("TextButton", {
				Name = "Btn_" .. title,
				Size = UDim2.new(0, width, 0, 28),
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Text = "",
				LayoutOrder = index,
				ZIndex = 52,
				Parent = buttonsFrame,
			}, {
				Creator.Corner(7),
				New("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 1, 0),
					Font = Utility.Fonts.Medium,
					TextSize = 12.5,
					Text = title,
					ZIndex = 52,
				}, nil, { TextColor3 = textKey }),
			}, { BackgroundColor3 = bgKey })

			local action = function()
				dismiss()
				if def.Callback then
					Utility.SafeCall("Dialog:" .. title, def.Callback)
				end
			end
			if style == "Default" then
				defaultAction = action
			elseif style == "Cancel" then
				cancelAction = action
			end

			Creator.AddSignal(connections, btn.Activated, action)
			Creator.AddSignal(connections, btn.MouseEnter, function()
				local palette = Library.Themes.Palette()
				local key = (style == "Default") and "AccentHover" or bgKey
				Utility.Tween(btn, { Time = 0.1 }, { BackgroundColor3 = palette[key] })
			end)
			Creator.AddSignal(connections, btn.MouseLeave, function()
				local palette = Library.Themes.Palette()
				Utility.Tween(btn, { Time = 0.12 }, { BackgroundColor3 = palette[bgKey] })
			end)
		end
	end

	-- keyboard shortcuts: Enter = default, Escape = cancel
	connections[#connections + 1] = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if dismissed or gameProcessed then
			return
		end
		if input.KeyCode == Enum.KeyCode.Return and defaultAction then
			defaultAction()
		elseif input.KeyCode == Enum.KeyCode.Escape and cancelAction then
			cancelAction()
		elseif input.KeyCode == Enum.KeyCode.Escape then
			dismiss()
		end
	end)

	self.Dismiss = dismiss
	self.Instance = dim
	return self
end

return Dialog
