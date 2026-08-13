--============================================================--
--  Crystal UI | acrylic.lua
--  Frosted-glass backdrop. Uses a Lighting BlurEffect that is
--  only active while a visible window has Acrylic enabled.
--============================================================--

local Import = ...
local Utility = Import("src/utility.lua")

local Lighting = game:GetService("Lighting")

local Acrylic = {}
Acrylic._Blur = nil
Acrylic._Enabled = false
Acrylic._Wanted = false   -- window visible AND acrylic configured

local BLUR_NAME = "CrystalUIBlur"
local BLUR_SIZE = 22

local function ensureBlur()
	if Acrylic._Blur and Acrylic._Blur.Parent ~= nil then
		return Acrylic._Blur
	end
	local existing = Lighting:FindFirstChild(BLUR_NAME)
	if existing then
		Acrylic._Blur = existing
		return existing
	end
	local ok, blur = pcall(function()
		local b = Instance.new("BlurEffect")
		b.Name = BLUR_NAME
		b.Size = 0
		b.Parent = Lighting
		return b
	end)
	if ok then
		Acrylic._Blur = blur
		return blur
	end
	return nil
end

local function destroyBlur()
	if Acrylic._Blur then
		pcall(function()
			Acrylic._Blur:Destroy()
		end)
		Acrylic._Blur = nil
	end
end

-- Call whenever window visibility or config changes.
-- wanted = (windowVisible) and (acrylicConfigured)
function Acrylic.SetWanted(wanted)
	Acrylic._Wanted = wanted and true or false
	if Acrylic._Wanted == Acrylic._Enabled then
		return
	end
	Acrylic._Enabled = Acrylic._Wanted

	if Acrylic._Enabled then
		local blur = ensureBlur()
		if blur then
			blur.Size = 0
			Utility.Tween(blur, { Time = 0.45, Style = Enum.EasingStyle.Sine }, { Size = BLUR_SIZE })
		end
	else
		local blur = Acrylic._Blur
		if blur then
			local tween = Utility.Tween(blur, { Time = 0.3, Style = Enum.EasingStyle.Sine }, { Size = 0 })
			if tween then
				task.delay(0.35, function()
					if not Acrylic._Enabled then
						destroyBlur()
					end
				end)
			else
				destroyBlur()
			end
		end
	end
end

function Acrylic.IsEnabled()
	return Acrylic._Enabled
end

function Acrylic.ForceOff()
	Acrylic._Wanted = false
	Acrylic._Enabled = false
	destroyBlur()
end

return Acrylic
