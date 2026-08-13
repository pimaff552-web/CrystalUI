--============================================================--
--  Crystal UI — full feature demo
--  Paste this into your executor / studio test harness.
--============================================================--

local Crystal = loadstring(game:HttpGet(
	"https://raw.githubusercontent.com/YOUR_USERNAME/CrystalUI/main/source.lua"
))()

local Window = Crystal:CreateWindow({
	Name = "Crystal UI",
	Subtitle = "macOS Edition",
	Icon = "gem",                          -- icon name, emoji, or rbxassetid
	LoadingEnabled = true,
	LoadingTitle = "Crystal UI",
	LoadingSubtitle = " polishing pixels…",
	Theme = "Dark",                        -- "Dark" | "Light" | "Midnight" | custom
	Acrylic = true,                        -- frosted blur behind the window
	Size = UDim2.fromOffset(690, 460),
	Resizable = true,
	ToggleKey = "RightShift",              -- show/hide keybind
	Watermark = true,                      -- FPS / ping / clock pill
	Debug = true,                          -- adds a Console tab to the sidebar

	ConfigurationSaving = {
		Enabled = true,
		FolderName = "CrystalUI",
		FileName = "Demo",
		-- elements with a Flag save & restore automatically
	},

	-- Uncomment to enable the key system:
	-- KeySystem = true,
	-- KeySettings = {
	--     Title = "Crystal Premium",
	--     Subtitle = "Enter your access key",
	--     Note = "Free keys at discord.gg/yourserver",
	--     Key = { "CRYSTAL-DEMO-2026" },  -- or GrabKeyFromSite below
	--     -- GrabKeyFromSite = true,
	--     -- Key = { "https://yoursite.com/raw-key.txt" },
	--     URL = "https://discord.gg/yourserver",   -- copied by "Get Key"
	--     SaveKey = true,
	--     FileName = "CrystalDemoKey",
	-- },
})

----------------------------------------------------------------
-- HOME TAB
----------------------------------------------------------------
local HomeTab = Window:CreateTab({ Name = "Home", Icon = "home" })

HomeTab:CreateParagraph({
	Title = "Welcome to Crystal UI",
	Content = "A macOS-grade interface for Roblox. Traffic-light window controls, "
		.. "living themes, popover dropdowns, a native-feeling color picker, key "
		.. "system, configs, dialogs, notifications, watermark and a debug console "
		.. "— all in one library.",
})

HomeTab:CreateSection("Quick actions")

HomeTab:CreateButton({
	Name = "Show notification",
	Description = "macOS banner, top-right.",
	ButtonText = "Show",
	Callback = function()
		Crystal:Notify({
			Title = "Crystal UI",
			Content = "Hello from a notification! Hover to keep me alive, click to dismiss.",
			Duration = 4,
			Icon = "bell",
		})
	end,
})

HomeTab:CreateButton({
	Name = "Open a dialog",
	Description = "Native-style alert with actions.",
	ButtonText = "Open",
	Callback = function()
		Window:Dialog({
			Title = "Delete configuration?",
			Content = "This removes every saved value for this script. This action cannot be undone.  Are you sure?",
			Buttons = {
				{ Title = "Cancel", Style = "Cancel" },
				{ Title = "Delete", Style = "Danger", Callback = function()
					Crystal:DeleteConfiguration()
					Crystal:Notify({ Title = "Crystal", Content = "Config deleted.", Icon = "trash", Duration = 3 })
				end },
				{ Title = "Keep", Style = "Default" },
			},
		})
	end,
})

----------------------------------------------------------------
-- CONTROLS TAB
----------------------------------------------------------------
local ControlsTab = Window:CreateTab({ Name = "Controls", Icon = "settings" })

ControlsTab:CreateSection("Switches")

ControlsTab:CreateToggle({
	Name = "Enable feature",
	Description = "macOS-style switch, springy knob included.",
	CurrentValue = false,
	Flag = "EnableFeature",
	Callback = function(state)
		print("feature:", state)
	end,
})

ControlsTab:CreateToggle({
	Name = "Auto save",
	CurrentValue = true,
	Flag = "AutoSave",
	Callback = function(state) end,
})

ControlsTab:CreateSection("Values")

ControlsTab:CreateSlider({
	Name = "Walk speed",
	Range = { 16, 500 },
	Increment = 1,
	Suffix = "studs",
	CurrentValue = 16,
	Flag = "WalkSpeed",
	Callback = function(v)
		pcall(function()
			game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = v
		end)
	end,
})

ControlsTab:CreateSlider({
	Name = "Jump power",
	Range = { 50, 300 },
	Increment = 5,
	CurrentValue = 50,
	Flag = "JumpPower",
	Callback = function(v) end,
})

ControlsTab:CreateSlider({
	Name = "Precision",
	Description = "Supports float increments + decimals.",
	Range = { 0, 1 },
	Increment = 0.01,
	CurrentValue = 0.5,
	Flag = "Precision",
	Callback = function(v) end,
})

ControlsTab:CreateInput({
	Name = "Player name",
	PlaceholderText = "Type a name…",
	Default = "",
	Flag = "PlayerName",
	Callback = function(text, enterPressed)
		print("input:", text, "enter:", enterPressed)
	end,
})

ControlsTab:CreateInput({
	Name = "Amount",
	Description = "Numeric-only field.",
	PlaceholderText = "0",
	Numeric = true,
	Flag = "Amount",
	Callback = function(text) end,
})

----------------------------------------------------------------
-- SELECTION TAB
----------------------------------------------------------------
local SelectTab = Window:CreateTab({ Name = "Selection", Icon = "list" })

SelectTab:CreateSection("Dropdowns")

SelectTab:CreateDropdown({
	Name = "Weapon",
	Description = "Single-select dropdown.",
	Options = { "Sword", "Bow", "Staff", "Dagger", "Hammer", "Scythe" },
	CurrentOption = "Sword",
	Flag = "Weapon",
	Callback = function(option)
		print("weapon:", option)
	end,
})

local MultiDrop = SelectTab:CreateDropdown({
	Name = "Auras",
	Description = "Multi-select with automatic search past 10 items.",
	Options = { "Fire", "Ice", "Storm", "Void", "Light", "Shadow", "Nature", "Blood",
		"Arcane", "Cosmic", "Solar", "Lunar", "Astral" },
	CurrentOption = { "Fire", "Void" },
	Multi = true,
	Flag = "Auras",
	Callback = function(selected)
		print("auras:", table.concat(selected, ", "))
	end,
})

SelectTab:CreateButton({
	Name = "Add random aura",
	ButtonText = "Add",
	Callback = function()
		MultiDrop:Add("Aura #" .. tostring(math.random(100, 999)))
	end,
})

SelectTab:CreateSection("Colors & Keys")

SelectTab:CreateColorPicker({
	Name = "Accent tint",
	Description = "HSV square, hue + alpha bars, hex input.",
	Color = Color3.fromRGB(10, 132, 255),
	Flag = "Tint",
	Callback = function(color, alpha)
		-- try it: use the color anywhere you like
	end,
})

SelectTab:CreateKeybind({
	Name = "Fly",
	Description = "Click to rebind · right-click to cycle mode.",
	CurrentKeybind = "F",
	Mode = "Toggle",
	Flag = "FlyKey",
	Callback = function(active)
		Crystal:Notify({
			Title = "Fly",
			Content = active and "Enabled" or "Disabled",
			Duration = 1.4,
			Icon = active and "check" or "x",
		})
	end,
})

----------------------------------------------------------------
-- APPEARANCE TAB
----------------------------------------------------------------
local LookTab = Window:CreateTab({ Name = "Appearance", Icon = "sparkles" })

LookTab:CreateSection("Theme")

LookTab:CreateDropdown({
	Name = "Window theme",
	Options = Crystal:GetThemes(),
	CurrentOption = "Dark",
	Callback = function(theme)
		Crystal:SetTheme(theme)
	end,
})

LookTab:CreateToggle({
	Name = "Watermark",
	CurrentValue = true,
	Callback = function(state)
		Crystal:SetWatermarkVisible(state)
	end,
})

LookTab:CreateButton({
	Name = "Save config now",
	Description = "Configs also save automatically.",
	ButtonText = "Save",
	Callback = function()
		Crystal:SaveConfiguration()
		Crystal:Notify({ Title = "Config", Content = "All flags written to disk.", Icon = "save", Duration = 2.5 })
	end,
})

----------------------------------------------------------------
-- CATALOG TAB (every remaining element for reference)
----------------------------------------------------------------
local CatalogTab = Window:CreateTab({ Name = "Catalog", Icon = "star" })

CatalogTab:CreateLabel("Simple one-line label")

CatalogTab:CreateParagraph({
	Title = "Rich paragraph",
	Content = "Paragraphs wrap automatically and can be updated later with :Set({ Title = ..., Content = ... }).",
})

CatalogTab:CreateDivider()

local dynLabel = CatalogTab:CreateLabel("Update me from code")

CatalogTab:CreateButton({
	Name = "Update the label above",
	ButtonText = "Update",
	Callback = function()
		dynLabel:Set("Updated at " .. os.date("%H:%M:%S"))
	end,
})

-- element values live here too:
Crystal:Notify({
	Title = "Crystal UI loaded",
	Content = "RightShift toggles the window · everything works on mobile too.",
	Duration = 5,
	Icon = "gem",
})

print("[Crystal UI] demo running")
