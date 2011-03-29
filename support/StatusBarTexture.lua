--[=[
Adirelle's oUF layout
(c) 2009-2010 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

-- Use our own namespace
local parent, ns = ...
setfenv(1, ns)

local function StatusBar_OnValueChanged(bar, value)
	local texture = bar:GetStatusBarTexture()
	if texture and value then
		local min, max = bar:GetMinMaxValues()
		if max > min then
			local f = math.min(math.max((value-min) / (max-min), 0), 1)
			local fx, fy
			if bar:GetOrientation() == "HORIZONTAL" then
				fx, fy = f, 1
			else
				fx, fy = 1, f
			end
			texture:SetTexCoord(0,fx,0,fy)
		end
	end
end

local SharedMedia = GetLib('LibSharedMedia-3.0')
if SharedMedia then

	local function StatusBar_Callback(bar, media, value)
		if media == "statusbar" then
			local r, g, b, a = bar:GetStatusBarColor()
			bar:SetStatusBarTexture(SharedMedia:Fetch("statusbar", value))
			bar:SetStatusBarColor(r, g, b, a)
		end
	end
	
	local function Texture_Callback(bar, media, value)
		if media == "statusbar" then
			local r, g, b, a = bar:GetVertexColor()
			bar:SetTexture(SharedMedia:Fetch("statusbar", value))
			bar:SetVertexColor(r, g, b, a)
		end
	end

	local defaultTexture = SharedMedia:Fetch("statusbar", 'BantoBar') or [[Interface\TargetingFrame\UI-StatusBar]]
	
	oUF:RegisterMetaFunction('RegisterStatusBarTexture', function(self, bar)
		if bar:IsObjectType("StatusBar") then
			bar:SetStatusBarTexture(defaultTexture)
			SharedMedia.RegisterCallback(bar, 'LibSharedMedia_SetGlobal', StatusBar_Callback, bar)
			bar:HookScript('OnValueChanged', StatusBar_OnValueChanged)
		elseif bar:IsObjectType("Texture") then
			bar:SetTexture(defaultTexture)
			SharedMedia.RegisterCallback(bar, 'LibSharedMedia_SetGlobal', Texture_Callback, bar)
		else
			assert(false, "object should be a Texture or a StatusBar")
		end
	end)
		
else
	-- Not library, just use a default texture, no planned update
	local defaultTexture = [[Interface\TargetingFrame\UI-StatusBar]]

	oUF:RegisterMetaFunction('RegisterStatusBarTexture', function(self, bar)
		if bar:IsObjectType("StatusBar") then
			bar:HookScript('OnValueChanged', StatusBar_OnValueChanged)
			bar:SetStatusBarTexture(defaultTexture)
		elseif bar:IsObjectType("Texture") then
			bar:SetTexture(defaultTexture)
		else
			assert(false, "object should be a Texture or a StatusBar")
		end
	end)
	
end
