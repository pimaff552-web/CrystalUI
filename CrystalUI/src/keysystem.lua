--============================================================--
--  Crystal UI | keysystem.lua
--  Key-authentication window (Rayfield-compatible settings).
--
--  KeySettings = {
--      Title = "Key System",
--      Subtitle = "Crystal UI",
--      Note = "Get your key from our Discord",
--      Key = { "MyKey123", "BackupKey" }   -- or { "https://site/key.txt" }
--      GrabKeyFromSite = false,
--      SaveKey = true,
--      FileName = "CrystalKey",
--      URL = "https://link-to-get-key",     -- optional (Get Key button)
--  }
--============================================================--

local Import = ...
local Utility = Import("src/utility.lua")
local Creator = Import("src/creator.lua")
local ConfigStore = Import("src/configstore.lua")

local New = Creator.New

local KeySystem = {}

local function normalizeSettings(settings)
	settings = settings or {}
	return {
		Title = tostring(settings.Title or "Key System"),
		Subtitle = tostring(settings.Subtitle or "Verification required"),
		Note = settings.Note and tostring(settings.Note) or nil,
		Key = type(settings.Key) == "table" and settings.Key
			or (settings.Key and { tostring(settings.Key) } or { "Crystal" }),
		SaveKey = settings.SaveKey and true or false,
		FileName = tostring(settings.FileName or "CrystalKey"),
		GrabKeyFromSite = settings.GrabKeyFromSite and true or false,
		URL = settings.URL and tostring(settings.URL) or nil,
	}
end

local function buildKeyPath(ks)
	return ks.FileName .. ".key"
end

-- returns boolean valid, string|nil error
local function validateKey(ks, entered)
	entered = Utility.Trim(tostring(entered or ""))
	if entered == "" then
		return false, "Enter a key first."
	end

	if ks.GrabKeyFromSite then
		local url = ks.Key[1]
		if not url then
			return false, "Key URL not configured."
		end
		for attempt = 1, 2 do
			local ok, response = pcall(function()
				return game:HttpGet(url, true)
			end)
			if ok and type(response) == "string" then
				local expected = Utility.Trim(response)
				if expected == entered then
					return true, nil
				end
				return false, "Invalid key."
			end
			task.wait(0.4 * attempt)
		end
		return false, "Could not reach key server."
	end

	for _, valid in pairs(ks.Key) do
		if Utility.Trim(tostring(valid)) == entered then
			return true, nil
		end
	end
	return false, "Invalid key."
end

-- Silent check used before showing the window.
function KeySystem.ValidateSaved(settings)
	local ks = normalizeSettings(settings)
	if not ks.SaveKey then
		return false
	end
	if type(readfile) ~= "function" or type(isfile) ~= "function" then
		return false
	end
	local saved = ConfigStore.ReadRaw(buildKeyPath(ks))
	if not saved or saved == "" then
		return false
	end
	local ok = validateKey(ks, saved)
	return ok == true
end

local function saveKey(ks, key)
	if not ks.SaveKey then
		return
	end
	ConfigStore.WriteRaw(buildKeyPath(ks), key)
end

function KeySystem.ResetSaved(settings)
	local ks = normalizeSettings(settings)
	local path = buildKeyPath(ks)
	pcall(function()
		if type(isfile) == "function" and type(delfile) == "function" and isfile(path) then
			delfile(path)
		end
	end)
end

-- force a zindex on a whole subtree
local function ZIndexFix(instance, z)
	pcall(function()
		instance.ZIndex = z
	end)
	for _, child in pairs(instance:GetDescendants()) do
		pcall(function()
			child.ZIndex = z + 1
		end)
	end
end

-- KeySystem.Run(gui, settings, Library, onSuccess(key), onAbort())
function KeySystem.Run(gui, settings, Library, onSuccess, onAbort)
	local ks = normalizeSettings(settings)
	local conns = {}

	local errorLabel = New("TextLabel", {
		Name = "Error",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 14),
		Font = Utility.Fonts.Medium,
		TextSize = 11,
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 4,
	}, nil, { TextColor3 = "Danger" })

	local submitState = { Busy = false }

	-- input
	local keyBox = New("TextBox", {
		Name = "KeyInput",
		Size = UDim2.new(1, 0, 0, 30),
		BorderSizePixel = 0,
		Font = Utility.Fonts.Mono,
		TextSize = 12.5,
		Text = "",
		PlaceholderText = "Enter key…",
		ClearTextOnFocus = false,
		LayoutOrder = 3,
	}, {
		Creator.Corner(8),
		Creator.Stroke("ControlStroke", 1, 0.85),
	}, { BackgroundColor3 = "Control", TextColor3 = "Text", PlaceholderColor3 = "Placeholder" })

	-- buttons
	local buttonsRow = New("Frame", {
		Name = "Buttons",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 30),
		LayoutOrder = 5,
	}, {
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			Padding = UDim.new(0, 8),
		}),
	})

	local function makeButton(text, bgKey, textKey, width)
		local btnLabel = New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Font = Utility.Fonts.Medium,
			TextSize = 12.5,
			Text = text,
			ZIndex = 2,
		}, nil, { TextColor3 = textKey })
		local btn = New("TextButton", {
			Name = "Btn_" .. text,
			Size = UDim2.new(0, width or (Utility.TextWidth(text, 12.5, Utility.Fonts.Medium) + 30), 1, 0),
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
		}, {
			Creator.Corner(8),
			btnLabel,
		}, { BackgroundColor3 = bgKey })
		btn.Parent = buttonsRow
		return btn, btnLabel
	end

	local copyLink = ks.URL or (ks.GrabKeyFromSite and ks.Key[1]) or nil
	local getKeyBtn = nil
	if copyLink then
		getKeyBtn = makeButton("Get Key", "Control", "Text")
		getKeyBtn.LayoutOrder = 1
	end
	local submitBtn, submitLabel = makeButton("Submit", "Accent", "OnAccent")
	submitBtn.LayoutOrder = 2

	local body = New("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, -32, 0, 0),
		Position = UDim2.new(0, 16, 0, 0),
	}, {
		New("UIListLayout", {
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Top,
		}),
		New("UIPadding", {
			PaddingTop = UDim.new(0, 32),
			PaddingBottom = UDim.new(0, 16),
		}),
		New("TextLabel", {
			Name = "Title",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 20),
			Font = Utility.Fonts.Bold,
			TextSize = 16,
			Text = ks.Title,
			TextXAlignment = Enum.TextXAlignment.Center,
			LayoutOrder = 1,
		}, nil, { TextColor3 = "Text" }),
		New("TextLabel", {
			Name = "Subtitle",
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			Font = Utility.Fonts.Regular,
			TextSize = 12,
			TextWrapped = true,
			Text = ks.Subtitle,
			TextXAlignment = Enum.TextXAlignment.Center,
			LayoutOrder = 2,
		}, nil, { TextColor3 = "SubText" }),
		keyBox,
		errorLabel,
		buttonsRow,
	})

	if ks.Note then
		New("TextLabel", {
			Name = "Note",
			BackgroundTransparency = 0.999,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			Font = Utility.Fonts.Regular,
			TextSize = 11,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Center,
			Text = ks.Note,
			LayoutOrder = 6,
		}, nil, { TextColor3 = "Placeholder" }).Parent = body
	end

	-- traffic lights (close only is functional)
	local traffic = New("Frame", {
		Name = "Traffic",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, 12),
		Size = UDim2.new(0, 64, 0, 14),
	})

	local function trafficCircle(colorKey, xOffset, glyph)
		local circle = New("TextButton", {
			Name = colorKey,
			Position = UDim2.new(0, xOffset, 0, 0),
			Size = UDim2.new(0, 12, 0, 12),
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
		}, {
			Creator.Corner(6),
			New("TextLabel", {
				Name = "Glyph",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				Font = Utility.Fonts.Bold,
				TextSize = 9,
				Text = glyph,
				TextTransparency = 1,
				ZIndex = 2,
			}, nil, { TextColor3 = "TrafficGlyph" }),
		}, { BackgroundColor3 = colorKey })
		circle.Parent = traffic
		return circle
	end

	local closeBtn = trafficCircle("Close", 0, "\u{00D7}")
	trafficCircle("Min", 20, "\u{2013}")
	trafficCircle("Max", 40, "\u{002B}")

	Creator.AddSignal(conns, traffic.MouseEnter, function()
		for _, circle in pairs(traffic:GetChildren()) do
			if circle:IsA("TextButton") then
				local glyph = circle:FindFirstChild("Glyph")
				if glyph then
					glyph.TextTransparency = 0
				end
			end
		end
	end)
	Creator.AddSignal(conns, traffic.MouseLeave, function()
		for _, circle in pairs(traffic:GetChildren()) do
			if circle:IsA("TextButton") then
				local glyph = circle:FindFirstChild("Glyph")
				if glyph then
					glyph.TextTransparency = 1
				end
			end
		end
	end)

	local card = New("Frame", {
		Name = "KeyCard",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 8),
		Size = UDim2.new(0, 380, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0,
	}, {
		Creator.Corner(14),
		Creator.Stroke("GroupStroke", 1, 0.85),
		traffic,
		body,
	}, { BackgroundColor3 = "Window" })

	traffic.Parent = card

	local dim = New("Frame", {
		Name = "KeyDim",
		Size = UDim2.new(1, 0, 1, 0),
		BorderSizePixel = 0,
		BackgroundTransparency = 0.35,
		ZIndex = 1500,
	}, nil, { BackgroundColor3 = "Overlay" })
	card.ZIndex = 1501
	ZIndexFix(card, 1501)
	card.Parent = dim
	dim.Parent = gui

	Utility.Tween(card, { Time = 0.3, Style = Enum.EasingStyle.Back }, {
		Position = UDim2.new(0.5, 0, 0.5, 0),
	})

	-- logic --------------------------------------------------------------------
	local finished = false

	local function shake()
		local original = UDim2.new(0.5, 0, 0.5, 0)
		Utility.Tween(card, { Time = 0.05 }, { Position = original - UDim2.new(0, 8, 0, 0) })
		task.delay(0.06, function()
			if card and card.Parent ~= nil then
				Utility.Tween(card, { Time = 0.05 }, { Position = original + UDim2.new(0, 8, 0, 0) })
			end
		end)
		task.delay(0.12, function()
			if card and card.Parent ~= nil then
				Utility.Tween(card, { Time = 0.07 }, { Position = original })
			end
		end)
	end

	local function showError(text)
		errorLabel.Text = tostring(text)
		shake()
	end

	local function finishSuccess(key)
		if finished then
			return
		end
		finished = true
		saveKey(ks, key)
		Utility.Tween(card, { Time = 0.2 }, { Position = UDim2.new(0.5, 0, 0.5, 14) })
		Utility.Tween(dim, { Time = 0.22 }, { BackgroundTransparency = 1 })
		task.delay(0.24, function()
			Utility.DisconnectAll(conns)
			pcall(function()
				dim:Destroy()
			end)
			if onSuccess then
				Utility.SafeCall("KeySystem", onSuccess, key)
			end
		end)
	end

	local function abort()
		if finished then
			return
		end
		finished = true
		Utility.DisconnectAll(conns)
		pcall(function()
			dim:Destroy()
		end)
		if onAbort then
			Utility.SafeCall("KeySystem", onAbort)
		end
	end

	local function submit()
		if submitState.Busy or finished then
			return
		end
		submitState.Busy = true
		submitLabel.Text = "Checking…"
		errorLabel.Text = ""
		local entered = Utility.Trim(keyBox.Text)
		task.spawn(function()
			local valid, err = validateKey(ks, entered)
			submitState.Busy = false
			if finished then
				return
			end
			submitLabel.Text = "Submit"
			if valid then
				errorLabel.Text = ""
				finishSuccess(entered)
			else
				showError(err or "Invalid key.")
			end
		end)
	end

	Creator.AddSignal(conns, submitBtn.Activated, submit)
	Creator.AddSignal(conns, keyBox.FocusLost, function(enterPressed)
		if enterPressed then
			submit()
		end
	end)
	if getKeyBtn then
		Creator.AddSignal(conns, getKeyBtn.Activated, function()
			local copied = Utility.SetClipboard(copyLink)
			if copied then
				errorLabel.Text = ""
				Library:Notify({
					Title = ks.Title,
					Content = "Key link copied to clipboard.",
					Duration = 3,
					Icon = "link",
				})
			else
				Library:Notify({
					Title = ks.Title,
					Content = copyLink,
					Duration = 6,
					Icon = "link",
				})
			end
		end)
	end
	Creator.AddSignal(conns, closeBtn.Activated, abort)

	return {
		Dismiss = abort,
		Instance = dim,
	}
end

return KeySystem
