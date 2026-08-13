local MacLib = {}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

-- Helper function to protect GUI
local function getParent()
    local success, _ = pcall(function()
        if syn and syn.protect_gui then
            return CoreGui
        elseif gethui then
            return gethui()
        else
            return CoreGui
        end
    end)
    if success then return CoreGui else return game.Players.LocalPlayer:WaitForChild("PlayerGui") end
end

-- Dragging function utility
local function makeDraggable(guiElement, handle)
    handle = handle or guiElement
    local dragging, dragInput, dragStart, startPos
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = guiElement.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            guiElement.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

function MacLib:CreateWindow(options)
    local title = options.Title or "macOS App"
    local size = options.Size or UDim2.new(0, 550, 0, 380)
    local toggleKey = options.ToggleKey or Enum.KeyCode.RightControl
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "MacLibGui"
    ScreenGui.ResetOnSpawn = false
    
    local parentTarget = getParent()
    if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end
    ScreenGui.Parent = parentTarget

    -- Main Window
    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Size = size
    Main.Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2)
    Main.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Main.ClipsDescendants = true
    Main.Parent = ScreenGui
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 10)
    MainCorner.Parent = Main
    
    -- Topbar (Titlebar)
    local Topbar = Instance.new("Frame")
    Topbar.Name = "Topbar"
    Topbar.Size = UDim2.new(1, 0, 0, 35)
    Topbar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Topbar.Parent = Main
    makeDraggable(Main, Topbar) -- Make window draggable via topbar
    
    local TopbarCover = Instance.new("Frame")
    TopbarCover.Size = UDim2.new(1, 0, 0, 10)
    TopbarCover.Position = UDim2.new(0, 0, 1, -10)
    TopbarCover.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    TopbarCover.BorderSizePixel = 0
    TopbarCover.Parent = Topbar
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, 0, 1, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = title
    TitleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 13
    TitleLabel.Parent = Topbar
    
    -- macOS Traffic Light Buttons
    local ButtonsFrame = Instance.new("Frame")
    ButtonsFrame.Size = UDim2.new(0, 60, 1, 0)
    ButtonsFrame.Position = UDim2.new(0, 12, 0, 0)
    ButtonsFrame.BackgroundTransparency = 1
    ButtonsFrame.Parent = Topbar
    
    local function createMacButton(color, posIndex, action)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 12, 0, 12)
        btn.Position = UDim2.new(0, posIndex * 20, 0.5, -6)
        btn.BackgroundColor3 = color
        btn.Text = ""
        btn.AutoButtonColor = false
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = btn
        btn.Parent = ButtonsFrame
        btn.MouseButton1Click:Connect(action)
        return btn
    end
    
    -- Floating Toggle Icon
    local ToggleIcon = Instance.new("ImageButton")
    ToggleIcon.Name = "ToggleIcon"
    ToggleIcon.Size = UDim2.new(0, 45, 0, 45)
    ToggleIcon.Position = UDim2.new(0, 15, 0, 15)
    ToggleIcon.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    ToggleIcon.Image = "rbxassetid://6031094670" -- Generic macOS style gear/app icon
    ToggleIcon.Parent = ScreenGui
    
    local IconCorner = Instance.new("UICorner")
    IconCorner.CornerRadius = UDim.new(0, 10)
    IconCorner.Parent = ToggleIcon
    makeDraggable(ToggleIcon) -- Make the floating icon draggable
    
    -- UI Visibility Toggling Logic
    local uiVisible = true
    local function ToggleUIVisibility()
        uiVisible = not uiVisible
        if uiVisible then
            Main.Visible = true
            TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = size}):Play()
        else
            local hideTween = TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0, size.X.Offset, 0, 0)})
            hideTween:Play()
            hideTween.Completed:Wait()
            if not uiVisible then Main.Visible = false end
        end
    end

    ToggleIcon.MouseButton1Click:Connect(ToggleUIVisibility)
    
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == toggleKey then
            ToggleUIVisibility()
        end
    end)
    
    -- Topbar Buttons Logic
    createMacButton(Color3.fromRGB(255, 95, 86), 0, function() ScreenGui:Destroy() end) -- Close
    createMacButton(Color3.fromRGB(255, 189, 46), 1, ToggleUIVisibility) -- Minimize triggers toggle
    createMacButton(Color3.fromRGB(39, 201, 63), 2, function() end) -- Maximize (Aesthetic)
    
    -- Content Area
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Size = UDim2.new(1, 0, 1, -35)
    ContentContainer.Position = UDim2.new(0, 0, 0, 35)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Parent = Main
    
    local Sidebar = Instance.new("ScrollingFrame")
    Sidebar.Size = UDim2.new(0, 140, 1, -10)
    Sidebar.Position = UDim2.new(0, 10, 0, 5)
    Sidebar.BackgroundTransparency = 1
    Sidebar.ScrollBarThickness = 0
    Sidebar.Parent = ContentContainer
    
    local SidebarLayout = Instance.new("UIListLayout")
    SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    SidebarLayout.Padding = UDim.new(0, 5)
    SidebarLayout.Parent = Sidebar
    
    SidebarLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Sidebar.CanvasSize = UDim2.new(0, 0, 0, SidebarLayout.AbsoluteContentSize.Y + 10)
    end)
    
    local Pages = Instance.new("Frame")
    Pages.Size = UDim2.new(1, -165, 1, -10)
    Pages.Position = UDim2.new(0, 155, 0, 5)
    Pages.BackgroundTransparency = 1
    Pages.Parent = ContentContainer
    
    -- Notifications System
    local NotifLayout = Instance.new("Frame")
    NotifLayout.Size = UDim2.new(0, 250, 1, -20)
    NotifLayout.Position = UDim2.new(1, -260, 0, 10)
    NotifLayout.BackgroundTransparency = 1
    NotifLayout.Parent = ScreenGui
    
    local UIListLayoutNotif = Instance.new("UIListLayout")
    UIListLayoutNotif.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayoutNotif.Padding = UDim.new(0, 10)
    UIListLayoutNotif.VerticalAlignment = Enum.VerticalAlignment.Bottom
    UIListLayoutNotif.Parent = NotifLayout

    local WindowLib = {}
    local currentTab = nil
    
    function WindowLib:MakeTab(tabOptions)
        local tabTitle = tabOptions.Name or "Tab"
        
        local TabBtn = Instance.new("TextButton")
        TabBtn.Size = UDim2.new(1, 0, 0, 32)
        TabBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        TabBtn.BackgroundTransparency = 1
        TabBtn.Text = "   " .. tabTitle
        TabBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
        TabBtn.Font = Enum.Font.GothamMedium
        TabBtn.TextSize = 13
        TabBtn.TextXAlignment = Enum.TextXAlignment.Left
        TabBtn.Parent = Sidebar
        
        local TabCorner = Instance.new("UICorner")
        TabCorner.CornerRadius = UDim.new(0, 6)
        TabCorner.Parent = TabBtn
        
        local Page = Instance.new("ScrollingFrame")
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.ScrollBarThickness = 2
        Page.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
        Page.Visible = false
        Page.Parent = Pages
        
        local PageLayout = Instance.new("UIListLayout")
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Padding = UDim.new(0, 8)
        PageLayout.Parent = Page
        
        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 15)
        end)
        
        if not currentTab then
            currentTab = Page
            Page.Visible = true
            TabBtn.BackgroundTransparency = 0.5
            TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
        
        TabBtn.MouseButton1Click:Connect(function()
            for _, child in pairs(Pages:GetChildren()) do if child:IsA("ScrollingFrame") then child.Visible = false end end
            for _, child in pairs(Sidebar:GetChildren()) do
                if child:IsA("TextButton") then
                    TweenService:Create(child, TweenInfo.new(0.2), {BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(150, 150, 150)}):Play()
                end
            end
            Page.Visible = true
            TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.5, TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        end)
        
        local TabLib = {}
        
        -- Existing Elements
        function TabLib:AddButton(btnOpts)
            local btnName = btnOpts.Name or "Button"
            local callback = btnOpts.Callback or function() end
            
            local BtnFrame = Instance.new("TextButton")
            BtnFrame.Size = UDim2.new(1, -10, 0, 36)
            BtnFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            BtnFrame.Text = "   " .. btnName
            BtnFrame.TextColor3 = Color3.fromRGB(220, 220, 220)
            BtnFrame.Font = Enum.Font.Gotham
            BtnFrame.TextSize = 13
            BtnFrame.TextXAlignment = Enum.TextXAlignment.Left
            BtnFrame.AutoButtonColor = false
            BtnFrame.Parent = Page
            
            local BtnCorner = Instance.new("UICorner"); BtnCorner.CornerRadius = UDim.new(0, 6); BtnCorner.Parent = BtnFrame
            
            BtnFrame.MouseEnter:Connect(function() TweenService:Create(BtnFrame, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(55, 55, 55)}):Play() end)
            BtnFrame.MouseLeave:Connect(function() TweenService:Create(BtnFrame, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 45, 45)}):Play() end)
            BtnFrame.MouseButton1Click:Connect(function()
                callback()
                BtnFrame.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
                task.wait(0.1)
                BtnFrame.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
            end)
        end
        
        function TabLib:AddToggle(togOpts)
            local togName = togOpts.Name or "Toggle"
            local default = togOpts.Default or false
            local callback = togOpts.Callback or function() end
            
            local TogFrame = Instance.new("Frame")
            TogFrame.Size = UDim2.new(1, -10, 0, 36)
            TogFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            TogFrame.Parent = Page
            local TogCorner = Instance.new("UICorner"); TogCorner.CornerRadius = UDim.new(0, 6); TogCorner.Parent = TogFrame
            
            local TogLabel = Instance.new("TextLabel")
            TogLabel.Size = UDim2.new(1, -60, 1, 0)
            TogLabel.Position = UDim2.new(0, 12, 0, 0)
            TogLabel.BackgroundTransparency = 1
            TogLabel.Text = togName
            TogLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
            TogLabel.Font = Enum.Font.Gotham
            TogLabel.TextSize = 13
            TogLabel.TextXAlignment = Enum.TextXAlignment.Left
            TogLabel.Parent = TogFrame
            
            local TogBtn = Instance.new("TextButton")
            TogBtn.Size = UDim2.new(0, 42, 0, 22)
            TogBtn.Position = UDim2.new(1, -52, 0.5, -11)
            TogBtn.BackgroundColor3 = default and Color3.fromRGB(39, 201, 63) or Color3.fromRGB(60, 60, 60)
            TogBtn.Text = ""
            TogBtn.AutoButtonColor = false
            TogBtn.Parent = TogFrame
            local BtnCorner = Instance.new("UICorner"); BtnCorner.CornerRadius = UDim.new(1, 0); BtnCorner.Parent = TogBtn
            
            local Indicator = Instance.new("Frame")
            Indicator.Size = UDim2.new(0, 18, 0, 18)
            Indicator.Position = default and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
            Indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Indicator.Parent = TogBtn
            local IndCorner = Instance.new("UICorner"); IndCorner.CornerRadius = UDim.new(1, 0); IndCorner.Parent = Indicator
            
            local toggled = default
            TogBtn.MouseButton1Click:Connect(function()
                toggled = not toggled
                if toggled then
                    TweenService:Create(TogBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(39, 201, 63)}):Play()
                    TweenService:Create(Indicator, TweenInfo.new(0.2), {Position = UDim2.new(1, -20, 0.5, -9)}):Play()
                else
                    TweenService:Create(TogBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}):Play()
                    TweenService:Create(Indicator, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -9)}):Play()
                end
                callback(toggled)
            end)
        end
        
        function TabLib:AddSlider(sldOpts)
            local sldName = sldOpts.Name or "Slider"
            local min = sldOpts.Min or 0
            local max = sldOpts.Max or 100
            local default = sldOpts.Default or min
            local callback = sldOpts.Callback or function() end
            
            local SldFrame = Instance.new("Frame")
            SldFrame.Size = UDim2.new(1, -10, 0, 50)
            SldFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            SldFrame.Parent = Page
            local SldCorner = Instance.new("UICorner"); SldCorner.CornerRadius = UDim.new(0, 6); SldCorner.Parent = SldFrame
            
            local SldLabel = Instance.new("TextLabel")
            SldLabel.Size = UDim2.new(1, -20, 0, 25)
            SldLabel.Position = UDim2.new(0, 12, 0, 0)
            SldLabel.BackgroundTransparency = 1
            SldLabel.Text = sldName
            SldLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
            SldLabel.Font = Enum.Font.Gotham
            SldLabel.TextSize = 13
            SldLabel.TextXAlignment = Enum.TextXAlignment.Left
            SldLabel.Parent = SldFrame
            
            local ValLabel = Instance.new("TextLabel")
            ValLabel.Size = UDim2.new(0, 50, 0, 25)
            ValLabel.Position = UDim2.new(1, -62, 0, 0)
            ValLabel.BackgroundTransparency = 1
            ValLabel.Text = tostring(default)
            ValLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
            ValLabel.Font = Enum.Font.Gotham
            ValLabel.TextSize = 13
            ValLabel.TextXAlignment = Enum.TextXAlignment.Right
            ValLabel.Parent = SldFrame
            
            local SliderBg = Instance.new("TextButton")
            SliderBg.Size = UDim2.new(1, -24, 0, 6)
            SliderBg.Position = UDim2.new(0, 12, 0, 32)
            SliderBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            SliderBg.Text = ""
            SliderBg.AutoButtonColor = false
            SliderBg.Parent = SldFrame
            local BgCorner = Instance.new("UICorner"); BgCorner.CornerRadius = UDim.new(1, 0); BgCorner.Parent = SliderBg
            
            local SliderFill = Instance.new("Frame")
            SliderFill.Size = UDim2.new(math.clamp((default - min) / (max - min), 0, 1), 0, 1, 0)
            SliderFill.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
            SliderFill.Parent = SliderBg
            local FillCorner = Instance.new("UICorner"); FillCorner.CornerRadius = UDim.new(1, 0); FillCorner.Parent = SliderFill
            
            local dragging = false
            local function updateSlider(input)
                local pos = math.clamp((input.Position.X - SliderBg.AbsolutePosition.X) / SliderBg.AbsoluteSize.X, 0, 1)
                SliderFill.Size = UDim2.new(pos, 0, 1, 0)
                local val = math.floor(min + ((max - min) * pos))
                ValLabel.Text = tostring(val)
                callback(val)
            end
            
            SliderBg.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    updateSlider(input)
                end
            end)
            
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateSlider(input)
                end
            end)
        end
        
        function TabLib:AddDropdown(dropOpts)
            local dropName = dropOpts.Name or "Dropdown"
            local options = dropOpts.Options or {}
            local default = dropOpts.Default or "Select..."
            local callback = dropOpts.Callback or function() end
            
            local DropFrame = Instance.new("Frame")
            DropFrame.Size = UDim2.new(1, -10, 0, 36)
            DropFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            DropFrame.ClipsDescendants = true
            DropFrame.Parent = Page
            local DropCorner = Instance.new("UICorner"); DropCorner.CornerRadius = UDim.new(0, 6); DropCorner.Parent = DropFrame
            
            local DropBtn = Instance.new("TextButton")
            DropBtn.Size = UDim2.new(1, 0, 0, 36)
            DropBtn.BackgroundTransparency = 1
            DropBtn.Text = "   " .. dropName
            DropBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
            DropBtn.Font = Enum.Font.Gotham
            DropBtn.TextSize = 13
            DropBtn.TextXAlignment = Enum.TextXAlignment.Left
            DropBtn.Parent = DropFrame
            
            local ValLabel = Instance.new("TextLabel")
            ValLabel.Size = UDim2.new(0, 100, 1, 0)
            ValLabel.Position = UDim2.new(1, -112, 0, 0)
            ValLabel.BackgroundTransparency = 1
            ValLabel.Text = default
            ValLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
            ValLabel.Font = Enum.Font.Gotham
            ValLabel.TextSize = 12
            ValLabel.TextXAlignment = Enum.TextXAlignment.Right
            ValLabel.Parent = D
