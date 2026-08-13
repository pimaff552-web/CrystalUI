# Crystal UI — macOS-grade Roblox interface library

Crystal UI is a complete, modular Roblox UI library built around the macOS design
language: traffic-light window controls, a translucent sidebar with search,
popover dropdowns, a native-feeling color picker, and buttery animations —
while matching (and exceeding) the feature set of Rayfield, Fluent and WindUI.

<p float="left">
  <b>Style:</b> macOS Sequoia/Sonoma &nbsp;•&nbsp;
  <b>Loader:</b> one-line <code>loadstring</code> &nbsp;•&nbsp;
  <b>Dependencies:</b> none &nbsp;•&nbsp; <b>Mobile:</b> supported
</p>

---

## ✨ Features

| Area | What you get |
| --- | --- |
| **Window** | Traffic lights (close / minimize / zoom) with hover glyphs, drag, **right-edge resize**, zoom, unified title bar, loading splash with spinner, dock re-open pill, show/hide keybind, **auto-scaling for small screens** |
| **Sidebar** | Live **tab search**, icons per tab, animated selection |
| **Elements** | Button, Toggle (real macOS switch), Slider (click-and-drag bar, decimals, suffix), Input (focus ring, numeric filter), Dropdown (**popover, multi-select, live search, right-aligned**), ColorPicker (**HSV square + hue + alpha + hex**), Keybind (rebind + Toggle/Hold/Always modes), Label, Paragraph, Section, Divider |
| **Overlays** | macOS banner **notifications** (queue, hover-to-pause, click-dismiss) and **alert dialogs** with Default/Cancel/Danger buttons + Enter/Esc shortcuts |
| **Themes** | Dark, Light, Midnight built in · **one-call live switching** · register your own palette tables |
| **Extras** | **Key system** (saved keys, key-from-site URL validation, Get-Key clipboard), **config saving/loading** to disk with flags, **acrylic blur** backdrop, **watermark** (FPS / ping / clock, draggable), **debug console tab** |
| **Safety** | every user callback runs in a protected call and errors are routed to the debug console instead of breaking your UI |

---

## 📦 Installation

1. Upload this folder to a **public GitHub repository** (keep the structure;
   `source.lua` sits at the root, modules live in `src/`).
2. In `source.lua`, change one line:

```lua
local BASE = "https://raw.githubusercontent.com/YOUR_USERNAME/CrystalUI/main/"
```

3. Done. Load it anywhere:

```lua
local Crystal = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/YOUR_USERNAME/CrystalUI/main/source.lua"
))()
```

> No repo yet? Test locally by setting an override before loading:
> `getgenv().CrystalUI_Base = "https://raw.githubusercontent.com/<user>/<repo>/main/"`

---

## 🚀 Quick start

```lua
local Crystal = loadstring(game:HttpGet(".../source.lua"))()

local Window = Crystal:CreateWindow({
    Name = "Crystal UI",
    Subtitle = "macOS Edition",
    Theme = "Dark",         -- Dark | Light | Midnight
    Acrylic = true,
    ToggleKey = "RightShift",
    Watermark = true,
    Debug = true,           -- Console tab
    ConfigurationSaving = { Enabled = true, FolderName = "CrystalUI", FileName = "Demo" },
})

local Tab = Window:CreateTab({ Name = "Home", Icon = "home" })

Tab:CreateToggle({
    Name = "Enable feature",
    CurrentValue = false,
    Flag = "FeatureEnabled",           -- saved + restored automatically
    Callback = function(state)
        print("toggled:", state)
    end,
})
```

See [`example.lua`](example.lua) for a tour of **every** element and feature.

---

## 📚 API reference

### `Crystal:CreateWindow(Config) -> Window`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `Name` | string | `"Crystal UI"` | Title bar text |
| `Subtitle` | string | `nil` | Smaller text next to the title |
| `Icon` | string/number | `"gem"` | Icon name, emoji, or `rbxassetid` |
| `Theme` | string | `"Dark"` | Starting theme |
| `Acrylic` | bool | `false` | Frosted blur while the window is visible |
| `Size` | UDim2 | `690×460` | Initial size (offsets) |
| `Resizable` | bool | `true` | Bottom-right drag handle |
| `ToggleKey` | string/KeyCode | `RightShift` | Show/hide hotkey (e.g. `"RightControl"`) |
| `MinimizeBehavior` | string | `"Hide"` | Yellow button: `"Hide"` hides the whole window · `"Collapse"` keeps the title bar |
| `CloseBehavior` | string | `"Hide"` | `"Hide"` shows the dock pill · `"Destroy"` unloads the UI |
| `LoadingEnabled` | bool | `true` | Splash screen (auto-skipped on mobile) |
| `LoadingTitle` / `LoadingSubtitle` | string | derived | Splash text |
| `Watermark` | bool | `true` | FPS/ping/clock pill |
| `Debug` | bool | `false` | Adds a Console tab (auto-revealed on errors) |
| `ConfigurationSaving` | table | `nil` | `{Enabled, FolderName, FileName}` |
| `KeySystem` / `KeySettings` | bool/table | `nil` | See below |

### Tabs

```lua
local Tab = Window:CreateTab({ Name = "Main", Icon = "home" })
Tab:CreateSection("Header")        -- starts a NEW group; elements below go inside
Tab:CreateButton({ Name, Description?, ButtonText?, Callback })
Tab:CreateToggle({ Name, Description?, CurrentValue?, Flag?, Callback(state) })
Tab:CreateSlider({ Name, Range = {min, max}, Increment?, Suffix?, CurrentValue?, Flag?, Callback(value) })
Tab:CreateInput({ Name, PlaceholderText?, Default?, Numeric?, RemoveTextAfterFocusLost?, Flag?, Callback(text, enterPressed) })
Tab:CreateDropdown({ Name, Options = {...}, CurrentOption?, Multi?, Searchable?, Flag?, Callback(optionOrTable) })
Tab:CreateColorPicker({ Name, Color?, Alpha?, Flag?, Callback(color3, alpha) })
Tab:CreateKeybind({ Name, CurrentKeybind?, Mode? = "Toggle"|"Hold"|"Always", Flag?, Callback(state) })
Tab:CreateLabel("text")
Tab:CreateParagraph({ Title, Content, RichText? })
Tab:CreateDivider()
```

Every element returns a handle:

* `:Set(...)` — change the value/label at runtime (fires the callback unless you pass `false`)
* `.Value` — current value
* `:Destroy()` — remove it
* Dropdowns also have `obj:Refresh(newOptions, keepCurrent?)`, `obj:Add(opt)`, `obj:Remove(opt)`
* Keybinds: `obj:Set("E")`, read `obj.Mode` / `obj.State`

### Values & flags

```lua
Crystal.Options.MyToggle:Set(true)      -- same object the Create call returned
print(Crystal.Options.MyToggle.Value)
Crystal.Flags                           -- table of flag -> element
```

### Library functions

```lua
Crystal:Notify({ Title, Content?, Duration?, Icon? })
Window:Dialog({ Title, Content?, Buttons = {
    { Title = "Delete", Style = "Danger", Callback = fn },   -- Default | Cancel | Danger
}})

Crystal:SetTheme("Light")                 -- instant + animated, works live
Crystal:RegisterTheme("Rose", { Accent = Color3.fromRGB(255, 45, 85) })
Crystal:GetThemes()                       -- {"Dark", "Light", "Midnight", ...}

Crystal:SaveConfiguration()               -- manual save
Crystal:LoadConfiguration()               -- manual load (elements with Flag re-apply)
Crystal:DeleteConfiguration()
Crystal:SetWatermarkVisible(bool)
Crystal:Log("info"|"warn"|"error"|"success", text)   -- routed to the Console tab
Crystal:Destroy()                          -- full cleanup

Window:Show() / Window:Hide() / Window:ToggleVisibility()
Window:Minimize() / Window:Zoom() / Window:Close()
Window:SelectTab(1 | "Home") / Window:CreateTab({...})
Window:SetTheme("Midnight")
```

### Key system

```lua
Crystal:CreateWindow({
    Name = "My Hub",
    KeySystem = true,
    KeySettings = {
        Title = "My Hub — Access",
        Subtitle = "Enter your key",
        Note = "Free key in our Discord",
        Key = { "KEY-1", "KEY-2" },          -- any of these passes
        -- GrabKeyFromSite = true,           -- then Key[1] must be a URL that
        --                                    -- returns the key as plain text
        URL = "https://link-to.get/key",     -- copied by the “Get Key” button
        SaveKey = true,                      -- remember valid keys on disk
        FileName = "MyHubKey",
    },
})
```

Closing the key window unloads the UI. `KeySystem` works with or without
executor file functions (saved keys simply won’t persist without them).

### Icons

`Icon` fields accept **names** (`"home"`, `"settings"`, `"key"`, `"sword"`,
`"chart"`, `"discord"`, 100+ built-ins — see `src/icons.lua`), raw **emoji**
(`"⚡"`), or asset IDs (`6026568198` / `"rbxassetid://…"` / an http URL).

---

## 🗂 Repository layout

```
source.lua                → the only file your users loadstring
src/
  crystal.lua             → public API, flags, config save/load, glue
  creator.lua             → instance factory + theme tagging
  utility.lua             → tween/drag/color/font/safety helpers
  themes.lua              → palettes + live theme engine
  icons.lua               → icon-name resolver (no broken assets)
  acrylic.lua             → Lighting blur management
  configstore.lua         → JSON file storage (writefile-safe)
  notifications.lua       → banner queue/renderer
  watermark.lua           → FPS/ping/clock pill
  keysystem.lua           → key window + validation
  components/
    window.lua            → chrome, traffic lights, popovers, resize…
    tab.lua               → sidebar tabs + pages + groups
    dialog.lua            → alert dialogs
  elements/
    shared.lua            → row builder / separators / flags
    button.lua · toggle.lua · slider.lua · input.lua
    dropdown.lua · colorpicker.lua · keybind.lua · paragraph.lua
example.lua               → runnable demo of every feature
```

---

## 🩹 Troubleshooting

* **"Failed to fetch …"** → the `BASE` URL in `source.lua` doesn’t match your
  repo name/branch, or the repo is private.
* **Configs don’t save** → your executor doesn’t expose `writefile`; the
  library detects this and keeps running without persistence.
* **Blur doesn’t show** → some experiences disable `BlurEffect` rendering on
  low graphics quality; that’s a client graphics setting, not a bug.
* **Verify integrity** → every module is plain Luau; edit freely, keep the
  header comment, and reload with `getgenv().CrystalUI_Base` pointing at your fork.

Built with obsessive care. Enjoy. 💎
