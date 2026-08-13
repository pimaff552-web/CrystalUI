--============================================================--
--  Crystal UI | creator.lua
--  Instance factory with theme tagging + tracked signals.
--
--  local frame = Creator.New("Frame", {
--      Size = UDim2.new(1, 0, 0, 40),
--      Parent = someParent,          -- applied LAST
--  }, {
--      Creator.New("TextLabel", {...}),
--  }, {
--      BackgroundColor3 = "Group",    -- theme tags
--  })
--============================================================--

local Import = ...
local Themes = Import("src/themes.lua")
local Utility = Import("src/utility.lua")

local Creator = {}

function Creator.New(className, props, children, themeTags)
	local ok, instance = pcall(function()
		return Instance.new(className)
	end)
	if not ok then
		error(('[Crystal UI] Creator: invalid class "%s"'):format(tostring(className)))
	end

	local parent = nil
	if type(props) == "table" then
		for key, value in pairs(props) do
			if key == "Parent" then
				parent = value
			else
				local success = pcall(function()
					instance[key] = value
				end)
				if not success then
					warn(('[Crystal UI] Creator: %s.%s rejected'):format(className, tostring(key)))
				end
			end
		end
	end

	if type(children) == "table" then
		for _, child in pairs(children) do
			if typeof(child) == "Instance" then
				child.Parent = instance
			end
		end
	end

	if themeTags then
		Themes.Tag(instance, themeTags)
	end

	if parent ~= nil then
		instance.Parent = parent
	end

	return instance
end

-- Track a signal connection in a list (for later DisconnectAll).
function Creator.AddSignal(list, signal, callback)
	local connection = signal:Connect(callback)
	if type(list) == "table" then
		list[#list + 1] = connection
	end
	return connection
end

-- Standard corner.
function Creator.Corner(radius)
	return Creator.New("UICorner", {
		Name = "Corner",
		CornerRadius = UDim.new(0, radius or 8),
	})
end

-- Standard 1px stroke with theme color + transparency.
function Creator.Stroke(themeKey, thickness, transparency)
	local stroke = Creator.New("UIStroke", {
		Name = "Stroke",
		Thickness = thickness or 1,
		Transparency = transparency or 0.9,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, nil, themeKey and { Color = themeKey } or nil)
	return stroke
end

-- Standard padding.
function Creator.Padding(all)
	return Creator.New("UIPadding", {
		PaddingTop = UDim.new(0, all),
		PaddingBottom = UDim.new(0, all),
		PaddingLeft = UDim.new(0, all),
		PaddingRight = UDim.new(0, all),
	})
end

-- Hover darkening/lightening helper for clickable rows/buttons.
-- Applies transparency shifts of a hover overlay Frame.
function Creator.HoverFx(hoverFrame, normalTransparency, hoverTransparency, connections)
	local show = { BackgroundTransparency = hoverTransparency }
	local hide = { BackgroundTransparency = normalTransparency }
	local parent = hoverFrame.Parent
	if parent then
		Creator.AddSignal(connections, parent.MouseEnter, function()
			Utility.Tween(hoverFrame, { Time = 0.12 }, show)
		end)
		Creator.AddSignal(connections, parent.MouseLeave, function()
			Utility.Tween(hoverFrame, { Time = 0.15 }, hide)
		end)
	end
end

return Creator
