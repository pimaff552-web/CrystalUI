--[[
MacOSUI - Loadstring-ready Roblox UI Library
Style: macOS-inspired windowing, sidebar tabs, soft translucency, accent highlights.
API inspiration: Rayfield / Fluent / WindUI style builder methods.
Authoring target: execute on Roblox client via loadstring(game:HttpGet("RAW_URL"))()

Notes:
- Requires a common exploit/runtime that supports Drawing/Instance APIs? No: this library uses standard Roblox Instances only.
- Uses CoreGui when possible, falls back to PlayerGui.
- Library returns a table with a CreateWindow(config) function.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local function getGuiParent()
    local ok, coreGui = pcall(function() return game:GetService("CoreGui") end)
    if ok and coreGui then
        return coreGui
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local Library = {}
Library.__index = Library
Library.Version = "1.0.0"

local Theme = {
    Accent = Color3.fromRGB(99, 102, 241),
    AccentSoft = Color3.fromRGB(129, 140, 248),
    Background = Color3.fromRGB(18, 18, 24),
    Surface = Color3.fromRGB(28, 28, 36),
    SurfaceAlt = Color3.fromRGB(38, 38, 48),
    Overlay = Color3.fromRGB(245, 245, 247),
    Text = Color3.fromRGB(238, 238, 240),
    MutedText = Color3.fromRGB(165, 165, 178),
    Stroke = Color3.fromRGB(62, 62, 76),
    Success = Color3.fromRGB(52, 199, 89),
    Warning = Color3.fromRGB(255, 159, 10),
    Danger = Color3.fromRGB(255, 69, 58),
}

local Fonts = {
    Title = Enum.Font.GothamBold,
    Body = Enum.Font.Gotham,
    Medium = Enum.Font.GothamMedium,
    Semibold = Enum.Font.GothamSemibold,
}

local function create(className, props)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    return obj
end

local function corner(parent, radius)
    local c = create("UICorner", {CornerRadius = UDim.new(0, radius or 10), Parent = parent})
    return c
end

local function stroke(parent, color, thickness, transparency)
    local s = create("UIStroke", {
        Color = color or Theme.Stroke,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
    return s
end

local function pad(parent, l, r, t, b)
    return create("UIPadding", {
        PaddingLeft = UDim.new(0, l or 0),
        PaddingRight = UDim.new(0, r or l or 0),
        PaddingTop = UDim.new(0, t or 0),
        PaddingBottom = UDim.new(0, b or t or 0),
        Parent = parent,
    })
end

local function list(parent, fillDir, padding)
    return create("UIListLayout", {
        FillDirection = fillDir or Enum.FillDirection.Vertical,
        Padding = UDim.new(0, padding or 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = parent,
    })
end

local function aspect(parent, ratio)
    return create("UIAspectRatioConstraint", {
        AspectRatio = ratio,
        Parent = parent,
    })
end

local function tween(obj, ti, props)
    local tw = TweenService:Create(obj, ti, props)
    tw:Play()
    return tw
end

local function makeDraggable(handle, target)
    local dragging = false
    local dragInput
    local dragStart
    local startPos

    local function update(input)
        local delta = input.Position - dragStart
        target.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

local function applyHover(button, defaultBg, hoverBg)
    button.MouseEnter:Connect(function()
        tween(button, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = hoverBg,
        })
    end)
    button.MouseLeave:Connect(function()
        tween(button, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = defaultBg,
        })
    end)
end

local function safeCallback(cb, ...)
    if typeof(cb) == "function" then
        local ok, err = pcall(cb, ...)
        if not ok then
            warn("[MacOSUI] Callback error:", err)
        end
    end
end

local function autoCanvas(scroll, layout, extra)
    local function update()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + (extra or 0))
    end
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)
    update()
end

local ElementFactory = {}
ElementFactory.__index = ElementFactory

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

function Library:Notify(config)
    config = config or {}
    local parent = getGuiParent()
    local screen = parent:FindFirstChild("MacOSUI_Notifications")

    if not screen then
        screen = create("ScreenGui", {
            Name = "MacOSUI_Notifications",
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            Parent = parent,
        })

        local holder = create("Frame", {
            Name = "Holder",
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -18, 0, 18),
            Size = UDim2.new(0, 320, 1, -36),
            BackgroundTransparency = 1,
            Parent = screen,
        })
        list(holder, Enum.FillDirection.Vertical, 10)
    end

    local holder = screen.Holder
    local card = create("Frame", {
        BackgroundColor3 = Theme.Surface,
        BackgroundTransparency = 0.05,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = holder,
    })
    corner(card, 14)
    stroke(card, Theme.Stroke, 1, 0.15)
    pad(card, 14, 14, 12, 12)

    local cardList = list(card, Enum.FillDirection.Vertical, 6)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 22),
        Font = Fonts.Semibold,
        Text = tostring(config.Title or "Notification"),
        TextColor3 = Theme.Text,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card,
    })

    create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Fonts.Body,
        TextWrapped = true,
        Text = tostring(config.Content or ""),
        TextColor3 = Theme.MutedText,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card,
    })

    local bar = create("Frame", {
        Size = UDim2.new(1, 0, 0, 3),
        BackgroundColor3 = Theme.SurfaceAlt,
        BorderSizePixel = 0,
        Parent = card,
    })
    corner(bar, 99)

    local fill = create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = config.Color or Theme.Accent,
        BorderSizePixel = 0,
        Parent = bar,
    })
    corner(fill, 99)

    local duration = tonumber(config.Duration) or 4
    tween(fill, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 1, 0)})

    task.delay(duration, function()
        if card and card.Parent then
            tween(card, TweenInfo.new(0.2), {BackgroundTransparency = 1})
            for _, child in ipairs(card:GetDescendants()) do
                if child:IsA("TextLabel") then
                    tween(child, TweenInfo.new(0.2), {TextTransparency = 1})
                elseif child:IsA("Frame") then
                    tween(child, TweenInfo.new(0.2), {BackgroundTransparency = math.clamp((child.BackgroundTransparency or 0) + 1, 0, 1)})
                elseif child:IsA("UIStroke") then
                    tween(child, TweenInfo.new(0.2), {Transparency = 1})
                end
            end
            task.wait(0.23)
            card:Destroy()
        end
    end)
end

function Library:CreateWindow(config)
    config = config or {}

    local self = setmetatable({}, Window)
    self.Title = tostring(config.Title or "MacOS UI")
    self.Subtitle = tostring(config.Subtitle or "Modern Interface")
    self.Theme = table.clone(Theme)
    self.Tabs = {}
    self.Flags = {}
    self.IsMinimized = false
    self.Keybind = config.Keybind or Enum.KeyCode.RightShift

    local parent = getGuiParent()
    local old = parent:FindFirstChild("MacOSUI_Main")
    if old then
        old:Destroy()
    end

    local screen = create("ScreenGui", {
        Name = "MacOSUI_Main",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = parent,
    })
    self.ScreenGui = screen

    local root = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, config.Width or 760, 0, config.Height or 520),
        BackgroundColor3 = self.Theme.Background,
        BackgroundTransparency = 0.08,
        Parent = screen,
    })
    self.Root = root
    corner(root, 18)
    stroke(root, self.Theme.Stroke, 1, 0.05)

    local shadow = create("ImageLabel", {
        Name = "Shadow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 10),
        Size = UDim2.new(1, 60, 1, 60),
        BackgroundTransparency = 1,
        Image = "rbxassetid://1316045217",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.55,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(10, 10, 118, 118),
        ZIndex = 0,
        Parent = root,
    })
    shadow:Lower()

    local titleBar = create("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1,
        Parent = root,
    })
    pad(titleBar, 16, 16, 10, 8)

    local traffic = create("Frame", {
        Name = "TrafficLights",
        Size = UDim2.new(0, 58, 0, 16),
        BackgroundTransparency = 1,
        Parent = titleBar,
    })

    local trafficLayout = list(traffic, Enum.FillDirection.Horizontal, 8)
    trafficLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    local colors = {
        {Theme.Danger, "Close"},
        {Theme.Warning, "Minimize"},
        {Theme.Success, "Hide"},
    }

    local trafficButtons = {}
    for _, info in ipairs(colors) do
        local b = create("TextButton", {
            Name = info[2],
            Text = "",
            AutoButtonColor = false,
            Size = UDim2.new(0, 12, 0, 12),
            BackgroundColor3 = info[1],
            Parent = traffic,
        })
        corner(b, 999)
        trafficButtons[info[2]] = b
    end

    local titleHolder = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 74, 0, 0),
        Size = UDim2.new(1, -140, 1, 0),
        Parent = titleBar,
    })

    create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        Position = UDim2.new(0, 0, 0, 0),
        Font = Fonts.Semibold,
        Text = self.Title,
        TextColor3 = self.Theme.Text,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleHolder,
    })

    create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 14),
        Position = UDim2.new(0, 0, 0, 18),
        Font = Fonts.Body,
        Text = self.Subtitle,
        TextColor3 = self.Theme.MutedText,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleHolder,
    })

    local body = create("Frame", {
        Name = "Body",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 44),
        Size = UDim2.new(1, 0, 1, -44),
        Parent = root,
    })

    local sidebar = create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 190, 1, 0),
        BackgroundColor3 = self.Theme.Surface,
        BackgroundTransparency = 0.14,
        Parent = body,
    })
    corner(sidebar, 0)
    stroke(sidebar, self.Theme.Stroke, 1, 0.6)
    pad(sidebar, 12, 12, 12, 12)

    local sidebarTitle = create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        Font = Fonts.Semibold,
        Text = "Navigation",
        TextColor3 = self.Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = sidebar,
    })

    local tabButtonsHolder = create("ScrollingFrame", {
        Name = "TabButtons",
        Position = UDim2.new(0, 0, 0, 26),
        Size = UDim2.new(1, 0, 1, -26),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.None,
        Parent = sidebar,
    })
    local tabButtonsLayout = list(tabButtonsHolder, Enum.FillDirection.Vertical, 8)
    autoCanvas(tabButtonsHolder, tabButtonsLayout, 4)

    local content = create("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 190, 0, 0),
        Size = UDim2.new(1, -190, 1, 0),
        Parent = body,
    })
    pad(content, 14, 14, 14, 14)

    local pages = create("Frame", {
        Name = "Pages",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = content,
    })

    self.Sidebar = sidebar
    self.TabButtonsHolder = tabButtonsHolder
    self.Pages = pages
    self.Connections = {}

    trafficButtons.Close.MouseButton1Click:Connect(function()
        self:Destroy()
    end)
    trafficButtons.Minimize.MouseButton1Click:Connect(function()
        self:Minimize()
    end)
    trafficButtons.Hide.MouseButton1Click:Connect(function()
        self:Toggle()
    end)

    makeDraggable(titleBar, root)

    table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == self.Keybind then
            self:Toggle()
        end
    end))

    return self
end

function Window:Toggle()
    self.Root.Visible = not self.Root.Visible
end

function Window:Minimize()
    self.IsMinimized = not self.IsMinimized
    local targetSize = self.IsMinimized and UDim2.new(0, self.Root.AbsoluteSize.X, 0, 44) or UDim2.new(0, self.Root.AbsoluteSize.X, 0, 520)
    if not self.IsMinimized then
        targetSize = UDim2.new(0, self.Root.AbsoluteSize.X, 0, self._LastExpandedHeight or 520)
    else
        self._LastExpandedHeight = self.Root.AbsoluteSize.Y
    end
    tween(self.Root, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = targetSize})
    if self.Root:FindFirstChild("Body") then
        self.Root.Body.Visible = not self.IsMinimized
    end
end

function Window:Destroy()
    for _, c in ipairs(self.Connections) do
        pcall(function() c:Disconnect() end)
    end
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
end

function Window:SetTheme(partial)
    for k, v in pairs(partial or {}) do
        if self.Theme[k] ~= nil then
            self.Theme[k] = v
        end
    end
end

function Window:_selectTab(tabObj)
    for _, tab in ipairs(self.Tabs) do
        local active = (tab == tabObj)
        tab.Page.Visible = active
        tween(tab.Button, TweenInfo.new(0.15), {
            BackgroundColor3 = active and self.Theme.Accent or self.Theme.SurfaceAlt,
            BackgroundTransparency = active and 0.1 or 0.45,
        })
        tab.ButtonLabel.TextColor3 = active and Color3.new(1,1,1) or self.Theme.Text
        if tab.IconAccent then
            tab.IconAccent.BackgroundColor3 = active and Color3.new(1,1,1) or self.Theme.Accent
        end
    end
end

function Window:CreateTab(config)
    config = config or {}
    local selfTab = setmetatable({}, Tab)
    selfTab.Window = self
    selfTab.Title = tostring(config.Title or "Tab")
    selfTab.Icon = tostring(config.Icon or "")
    selfTab.Elements = {}

    local button = create("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = self.Theme.SurfaceAlt,
        BackgroundTransparency = 0.45,
        Size = UDim2.new(1, 0, 0, 38),
        Text = "",
        Parent = self.TabButtonsHolder,
    })
    corner(button, 12)
    stroke(button, self.Theme.Stroke, 1, 0.45)

    local iconAccent = create("Frame", {
        BackgroundColor3 = self.Theme.Accent,
        Size = UDim2.new(0, 6, 0, 6),
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 10, 0.5, 0),
        BorderSizePixel = 0,
        Parent = button,
    })
    corner(iconAccent, 999)

    local label = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 24, 0, 0),
        Size = UDim2.new(1, -30, 1, 0),
        Font = Fonts.Medium,
        Text = (selfTab.Icon ~= "" and (selfTab.Icon .. "  ") or "") .. selfTab.Title,
        TextColor3 = self.Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = button,
    })

    local page = create("ScrollingFrame", {
        Name = selfTab.Title .. "Page",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = self.Theme.Stroke,
        CanvasSize = UDim2.new(),
        Visible = false,
        Parent = self.Pages,
    })
    pad(page, 0, 4, 0, 4)
    local pageLayout = list(page, Enum.FillDirection.Vertical, 10)
    autoCanvas(page, pageLayout, 8)

    selfTab.Button = button
    selfTab.ButtonLabel = label
    selfTab.IconAccent = iconAccent
    selfTab.Page = page
    selfTab.Layout = pageLayout

    button.MouseButton1Click:Connect(function()
        self:_selectTab(selfTab)
    end)
    applyHover(button, self.Theme.SurfaceAlt, Color3.fromRGB(55, 55, 68))

    table.insert(self.Tabs, selfTab)
    if #self.Tabs == 1 then
        self:_selectTab(selfTab)
    end

    return selfTab
end

function Tab:_createContainer(title, description)
    local card = create("Frame", {
        BackgroundColor3 = self.Window.Theme.Surface,
        BackgroundTransparency = 0.08,
        Size = UDim2.new(1, -2, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = self.Page,
    })
    corner(card, 14)
    stroke(card, self.Window.Theme.Stroke, 1, 0.2)
    pad(card, 14, 14, 12, 12)
    local cardList = list(card, Enum.FillDirection.Vertical, 8)

    if title then
        create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            Font = Fonts.Semibold,
            Text = tostring(title),
            TextColor3 = self.Window.Theme.Text,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = card,
        })
    end

    if description and description ~= "" then
        create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Font = Fonts.Body,
            TextWrapped = true,
            Text = tostring(description),
            TextColor3 = self.Window.Theme.MutedText,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = card,
        })
    end

    return card, cardList
end

function Tab:CreateSection(config)
    config = config or {}
    local card = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -2, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = self.Page,
    })
    list(card, Enum.FillDirection.Vertical, 4)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        Font = Fonts.Semibold,
        Text = tostring(config.Title or "Section"),
        TextColor3 = self.Window.Theme.Text,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card,
    })

    if config.Description then
        create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Font = Fonts.Body,
            TextWrapped = true,
            Text = tostring(config.Description),
            TextColor3 = self.Window.Theme.MutedText,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = card,
        })
    end

    return card
end

function Tab:CreateParagraph(config)
    config = config or {}
    local card = self:_createContainer(config.Title or "Paragraph", config.Content or config.Description or "")
    return card
end

function Tab:CreateLabel(config)
    config = config or {}
    local label = create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -2, 0, 18),
        Font = Fonts.Body,
        Text = tostring(config.Text or "Label"),
        TextColor3 = self.Window.Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.Page,
    })

    local api = {}
    function api:Set(text)
        label.Text = tostring(text)
    end
    return api
end

function Tab:CreateButton(config)
    config = config or {}
    local card = self:_createContainer(config.Title or "Button", config.Description or "")
    local btn = create("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = self.Window.Theme.Accent,
        Size = UDim2.new(1, 0, 0, 36),
        Text = tostring(config.ButtonText or config.Text or "Execute"),
        Font = Fonts.Semibold,
        TextColor3 = Color3.new(1,1,1),
        TextSize = 13,
        Parent = card,
    })
    corner(btn, 10)
    applyHover(btn, self.Window.Theme.Accent, self.Window.Theme.AccentSoft)
    btn.MouseButton1Click:Connect(function()
        safeCallback(config.Callback)
    end)

    local api = {}
    function api:SetText(text)
        btn.Text = tostring(text)
    end
    return api
end

function Tab:CreateToggle(config)
    config = config or {}
    local state = config.Default == true
    local flag = config.Flag
    if flag then
        self.Window.Flags[flag] = state
    end

    local card = self:_createContainer(config.Title or "Toggle", config.Description or "")

    local row = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 34),
        Parent = card,
    })

    local title = create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -62, 1, 0),
        Font = Fonts.Medium,
        Text = tostring(config.Text or "Enabled"),
        TextColor3 = self.Window.Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    local switch = create("TextButton", {
        AutoButtonColor = false,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 48, 0, 26),
        Text = "",
        BackgroundColor3 = state and self.Window.Theme.Accent or self.Window.Theme.SurfaceAlt,
        Parent = row,
    })
    corner(switch, 999)

    local knob = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = state and UDim2.new(1, -24, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
        Size = UDim2.new(0, 22, 0, 22),
        BackgroundColor3 = Color3.fromRGB(255,255,255),
        Parent = switch,
    })
    corner(knob, 999)

    local api = {}
    local function set(val)
        state = val and true or false
        if flag then self.Window.Flags[flag] = state end
        tween(switch, TweenInfo.new(0.15), {BackgroundColor3 = state and self.Window.Theme.Accent or self.Window.Theme.SurfaceAlt})
        tween(knob, TweenInfo.new(0.15), {Position = state and UDim2.new(1, -24, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)})
        safeCallback(config.Callback, state)
    end

    function api:Set(val)
        set(val)
    end
    function api:Get()
        return state
    end

    switch.MouseButton1Click:Connect(function()
        set(not state)
    end)

    task.defer(function()
        safeCallback(config.Callback, state)
    end)

    return api
end

function Tab:CreateSlider(config)
    config = config or {}
    local min = tonumber(config.Min or 0) or 0
    local max = tonumber(config.Max or 100) or 100
    local increment = tonumber(config.Increment or 1) or 1
    local value = tonumber(config.Default or min) or min
    value = math.clamp(value, min, max)
    local flag = config.Flag
    if flag then
        self.Window.Flags[flag] = value
    end

    local card = self:_createContainer(config.Title or "Slider", config.Description or "")
    local row = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 22),
        Parent = card,
    })

    create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0.65, 0, 1, 0),
        Font = Fonts.Medium,
        Text = tostring(config.Text or "Value"),
        TextColor3 = self.Window.Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    local valueLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0.65, 0, 0, 0),
        Size = UDim2.new(0.35, 0, 1, 0),
        Font = Fonts.Semibold,
        Text = tostring(value),
        TextColor3 = self.Window.Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = row,
    })

    local bar = create("Frame", {
        BackgroundColor3 = self.Window.Theme.SurfaceAlt,
        Size = UDim2.new(1, 0, 0, 8),
        Parent = card,
    })
    corner(bar, 999)

    local fill = create("Frame", {
        BackgroundColor3 = self.Window.Theme.Accent,
        Size = UDim2.new((value - min) / math.max(max - min, 1), 0, 1, 0),
        Parent = bar,
    })
    corner(fill, 999)

    local dragging = false
    local api = {}

    local function roundToIncrement(v)
        local snapped = math.floor((v / increment) + 0.5) * increment
        return math.clamp(snapped, min, max)
    end

    local function set(v)
        value = roundToIncrement(v)
        if flag then self.Window.Flags[flag] = value end
        local pct = (value - min) / math.max(max - min, 1)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        valueLabel.Text = tostring(value)
        safeCallback(config.Callback, value)
    end

    function api:Set(v)
        set(v)
    end
    function api:Get()
        return value
    end

    local function updateFromX(x)
        local pct = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local raw = min + ((max - min) * pct)
        set(raw)
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromX(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromX(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    task.defer(function()
        safeCallback(config.Callback, value)
    end)

    return api
end

function Tab:CreateInput(config)
    config = config or {}
    local flag = config.Flag
    local textValue = tostring(config.Default or "")
    if flag then self.Window.Flags[flag] = textValue end

    local card = self:_createContainer(config.Title or "Input", config.Description or "")
    create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        Font = Fonts.Medium,
        Text = tostring(config.Placeholder or config.Text or "Enter text"),
        TextColor3 = self.Window.Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card,
    })

    local box = create("TextBox", {
        BackgroundColor3 = self.Window.Theme.SurfaceAlt,
        Size = UDim2.new(1, 0, 0, 36),
        Text = textValue,
        PlaceholderText = tostring(config.PlaceholderText or "Type here..."),
        ClearTextOnFocus = false,
        Font = Fonts.Body,
        TextColor3 = self.Window.Theme.Text,
        PlaceholderColor3 = self.Window.Theme.MutedText,
        TextSize = 13,
        Parent = card,
    })
    corner(box, 10)
    stroke(box, self.Window.Theme.Stroke, 1, 0.35)
    pad(box, 12, 12, 0, 0)

    local api = {}
    local function commit()
        textValue = box.Text
        if flag then self.Window.Flags[flag] = textValue end
        safeCallback(config.Callback, textValue)
    end

    box.FocusLost:Connect(function(enterPressed)
        if config.ClearOnFocusLost and not enterPressed then
            box.Text = ""
        end
        commit()
    end)

    function api:Set(v)
        box.Text = tostring(v)
        commit()
    end
    function api:Get()
        return box.Text
    end

    return api
end

function Tab:CreateDropdown(config)
    config = config or {}
    local options = config.Options or config.Values or {}
    local multi = config.MultiSelect == true
    local flag = config.Flag
    local default = config.Default
    local open = false
    local selected = multi and {} or nil

    if multi and typeof(default) == "table" then
        for _, v in ipairs(default) do
            selected[v] = true
        end
    else
        selected = default
    end

    if flag then
        self.Window.Flags[flag] = multi and selected or selected
    end

    local card = self:_createContainer(config.Title or "Dropdown", config.Description or "")
    local button = create("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = self.Window.Theme.SurfaceAlt,
        Size = UDim2.new(1, 0, 0, 38),
        Text = "",
        Parent = card,
    })
    corner(button, 10)
    stroke(button, self.Window.Theme.Stroke, 1, 0.35)

    local label = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -40, 1, 0),
        Font = Fonts.Medium,
        TextColor3 = self.Window.Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = button,
    })

    local arrow = create("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.new(0, 14, 0, 14),
        Font = Fonts.Semibold,
        Text = "⌄",
        TextColor3 = self.Window.Theme.MutedText,
        TextSize = 16,
        Parent = button,
    })

    local dropdown = create("Frame", {
        BackgroundColor3 = self.Window.Theme.SurfaceAlt,
        ClipsDescendants = true,
        Size = UDim2.new(1, 0, 0, 0),
        Visible = true,
        Parent = card,
    })
    corner(dropdown, 10)
    stroke(dropdown, self.Window.Theme.Stroke, 1, 0.35)

    local optionsScroll = create("ScrollingFrame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        CanvasSize = UDim2.new(),
        Parent = dropdown,
    })
    pad(optionsScroll, 8, 8, 8, 8)
    local optionLayout = list(optionsScroll, Enum.FillDirection.Vertical, 6)
    autoCanvas(optionsScroll, optionLayout, 6)

    local api = {}

    local function selectedText()
        if multi then
            local items = {}
            for _, item in ipairs(options) do
                if selected[item] then
                    table.insert(items, tostring(item))
                end
            end
            return #items > 0 and table.concat(items, ", ") or (config.Placeholder or "Select options")
        else
            return selected and tostring(selected) or (config.Placeholder or "Select option")
        end
    end

    local function fireCallback()
        if flag then self.Window.Flags[flag] = multi and selected or selected end
        if multi then
            local result = {}
            for _, item in ipairs(options) do
                if selected[item] then
                    table.insert(result, item)
                end
            end
            safeCallback(config.Callback, result)
        else
            safeCallback(config.Callback, selected)
        end
    end

    local function refreshLabel()
        label.Text = selectedText()
    end

    local function rebuild()
        for _, child in ipairs(optionsScroll:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        for _, item in ipairs(options) do
            local active = multi and selected[item] or selected == item
            local opt = create("TextButton", {
                AutoButtonColor = false,
                BackgroundColor3 = active and self.Window.Theme.Accent or self.Window.Theme.Surface,
                Size = UDim2.new(1, 0, 0, 32),
                Text = tostring(item),
                Font = Fonts.Medium,
                TextColor3 = self.Window.Theme.Text,
                TextSize = 13,
                Parent = optionsScroll,
            })
            corner(opt, 8)
            applyHover(opt, active and self.Window.Theme.Accent or self.Window.Theme.Surface, active and self.Window.Theme.AccentSoft or Color3.fromRGB(47, 47, 58))

            opt.MouseButton1Click:Connect(function()
                if multi then
                    selected[item] = not selected[item]
                else
                    selected = item
                    open = false
                end
                rebuild()
                refreshLabel()
                fireCallback()
                local target = open and math.min(#options * 38 + 12, 180) or 0
                tween(dropdown, TweenInfo.new(0.16), {Size = UDim2.new(1, 0, 0, target)})
                arrow.Text = open and "⌃" or "⌄"
            end)
        end
    end

    button.MouseButton1Click:Connect(function()
        open = not open
        local target = open and math.min(#options * 38 + 12, 180) or 0
        tween(dropdown, TweenInfo.new(0.16), {Size = UDim2.new(1, 0, 0, target)})
        arrow.Text = open and "⌃" or "⌄"
    end)

    function api:Set(value)
        if multi and typeof(value) == "table" then
            selected = {}
            for _, v in ipairs(value) do
                selected[v] = true
            end
        else
            selected = value
        end
        rebuild()
        refreshLabel()
        fireCallback()
    end

    function api:Refresh(newOptions)
        options = newOptions or {}
        rebuild()
        refreshLabel()
    end

    function api:Get()
        if multi then
            local result = {}
            for _, item in ipairs(options) do
                if selected[item] then
                    table.insert(result, item)
                end
            end
            return result
        end
        return selected
    end

    refreshLabel()
    rebuild()
    task.defer(fireCallback)
    return api
end

function Tab:CreateKeybind(config)
    config = config or {}
    local current = config.Default or Enum.KeyCode.E
    local waiting = false
    local flag = config.Flag
    if flag then self.Window.Flags[flag] = current end

    local card = self:_createContainer(config.Title or "Keybind", config.Description or "")
    local row = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 34),
        Parent = card,
    })

    create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0.6, 0, 1, 0),
        Font = Fonts.Medium,
        Text = tostring(config.Text or "Bind Key"),
        TextColor3 = self.Window.Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    local bindButton = create("TextButton", {
        AutoButtonColor = false,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 120, 0, 32),
        BackgroundColor3 = self.Window.Theme.SurfaceAlt,
        Font = Fonts.Medium,
        TextColor3 = self.Window.Theme.Text,
        TextSize = 13,
        Text = current.Name,
        Parent = row,
    })
    corner(bindButton, 9)
    applyHover(bindButton, self.Window.Theme.SurfaceAlt, Color3.fromRGB(55, 55, 68))

    local api = {}

    local function setKey(key)
        current = key
        if flag then self.Window.Flags[flag] = current end
        bindButton.Text = current.Name
        safeCallback(config.Changed, current)
    end

    bindButton.MouseButton1Click:Connect(function()
        waiting = true
        bindButton.Text = "Press a key..."
    end)

    table.insert(self.Window.Connections, UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if waiting and input.UserInputType == Enum.UserInputType.Keyboard then
            waiting = false
            setKey(input.KeyCode)
            return
        end
        if input.KeyCode == current then
            safeCallback(config.Callback, current)
        end
    end))

    function api:Set(key)
        setKey(key)
    end
    function api:Get()
        return current
    end

    return api
end

function Tab:CreateColorPicker(config)
    config = config or {}
    local value = config.Default or Color3.fromRGB(255, 255, 255)
    local flag = config.Flag
    if flag then self.Window.Flags[flag] = value end

    local presets = config.Presets or {
        Color3.fromRGB(255, 69, 58),
        Color3.fromRGB(255, 159, 10),
        Color3.fromRGB(255, 214, 10),
        Color3.fromRGB(52, 199, 89),
        Color3.fromRGB(48, 209, 88),
        Color3.fromRGB(10, 132, 255),
        Color3.fromRGB(94, 92, 230),
        Color3.fromRGB(191, 90, 242),
        Color3.fromRGB(255, 55, 95),
        Color3.fromRGB(142, 142, 147),
    }

    local card = self:_createContainer(config.Title or "Color Picker", config.Description or "")
    local row = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 34),
        Parent = card,
    })

    local preview = create("Frame", {
        Size = UDim2.new(0, 34, 0, 34),
        BackgroundColor3 = value,
        Parent = row,
    })
    corner(preview, 10)
    stroke(preview, self.Window.Theme.Stroke, 1, 0.2)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 46, 0, 0),
        Size = UDim2.new(1, -46, 1, 0),
        Font = Fonts.Medium,
        Text = tostring(config.Text or "Pick Accent Color"),
        TextColor3 = self.Window.Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    local gridHolder = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = card,
    })
    local grid = create("UIGridLayout", {
        CellPadding = UDim2.new(0, 8, 0, 8),
        CellSize = UDim2.new(0, 28, 0, 28),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = gridHolder,
    })

    local api = {}
    local function set(c)
        value = c
        if flag then self.Window.Flags[flag] = value end
        preview.BackgroundColor3 = value
        safeCallback(config.Callback, value)
    end

    for _, c in ipairs(presets) do
        local swatch = create("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = c,
            Text = "",
            Parent = gridHolder,
        })
        corner(swatch, 8)
        stroke(swatch, self.Window.Theme.Stroke, 1, 0.25)
        swatch.MouseButton1Click:Connect(function()
            set(c)
        end)
    end

    function api:Set(c)
        set(c)
    end
    function api:Get()
        return value
    end

    task.defer(function()
        safeCallback(config.Callback, value)
    end)

    return api
end

function Tab:CreateDivider(config)
    config = config or {}
    local holder = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -2, 0, 20),
        Parent = self.Page,
    })

    local line = create("Frame", {
        BorderSizePixel = 0,
        BackgroundColor3 = self.Window.Theme.Stroke,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0, 1),
        Parent = holder,
    })

    if config.Text then
        local text = create("TextLabel", {
            BackgroundColor3 = self.Window.Theme.Background,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            Font = Fonts.Body,
            Text = tostring(config.Text),
            TextColor3 = self.Window.Theme.MutedText,
            TextSize = 12,
            Parent = holder,
        })
        pad(text, 8, 8, 0, 0)
    end

    return holder
end

function Tab:CreateSpacer(height)
    return create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, tonumber(height) or 8),
        Parent = self.Page,
    })
end

function Window:GetFlag(flag)
    return self.Flags[flag]
end

function Window:SetFlag(flag, value)
    self.Flags[flag] = value
end

function Library:GetVersion()
    return self.Version
end

return Library
