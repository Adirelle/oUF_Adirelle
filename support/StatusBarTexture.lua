--[=[
Adirelle's oUF layout
(c) 2009-2011 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local _G, addonName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

local SharedMedia = oUF_Adirelle.GetLib('LibSharedMedia-3.0')
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
			bar:SetStatusBarTexture(defaultTexture)
		elseif bar:IsObjectType("Texture") then
			bar:SetTexture(defaultTexture)
		else
			assert(false, "object should be a Texture or a StatusBar")
		end
	end)
	
end
