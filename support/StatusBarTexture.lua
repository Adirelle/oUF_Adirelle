--[=[
Adirelle's oUF layout
(c) 2009-2011 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local _G, addonName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

local texture = [[Interface\TargetingFrame\UI-StatusBar]]

local SharedMedia = oUF_Adirelle.GetLib('LibSharedMedia-3.0')
if SharedMedia then

	local bars = {}

	local function StatusBar_Callback(bar, texture)
		local r, g, b, a = bar:GetStatusBarColor()
		bar:SetStatusBarTexture(texture)
		bar:SetStatusBarColor(r, g, b, a)
	end
	
	local function Texture_Callback(bar, texture)
		local r, g, b, a = bar:GetVertexColor()
		bar:SetTexture(texture)
		bar:SetVertexColor(r, g, b, a)
	end
	
	local profile
	
	function oUF_Adirelle.UpdateStatusBarTextures(event, media)
		if media and media ~= "statusbar" then return end
		texture = SharedMedia:Fetch("statusbar", profile and profile.statusbar)		
		oUF_Adirelle.Debug('UpdateStatusBarTextures', event, media, '=>', texture)
		for bar, callback in pairs(bars)  do
			callback(bar, texture)
		end
	end

	SharedMedia.RegisterCallback(addonName, 'LibSharedMedia_SetGlobal', oUF_Adirelle.UpdateStatusBarTextures)

	-- The meta to allow unit frames to register their textures	
	oUF:RegisterMetaFunction('RegisterStatusBarTexture', function(self, bar)
		local callback = assert(
			bar:IsObjectType("StatusBar") and StatusBar_Callback
			or bar:IsObjectType("Texture") and Texture_Callback,
			"object should be a Texture or a StatusBar"
		)
		bars[bar] = callback
		callback(bar, texture)
	end)
	
	-- Database callback to update the texture on profile changes
	oUF_Adirelle.RegisterVariableLoadedCallback(function(_, newProfile, force, event)
		if force or event == 'OnThemeModified' then
			profile = newProfile			
			return oUF_Adirelle.UpdateStatusBarTextures(event)
		end
	end)

else
	-- Not library, just use a default texture, no planned update

	oUF:RegisterMetaFunction('RegisterStatusBarTexture', function(self, bar)
		if bar:IsObjectType("StatusBar") then
			bar:SetStatusBarTexture(texture)
		elseif bar:IsObjectType("Texture") then
			bar:SetTexture(texture)
		else
			assert(false, "object should be a Texture or a StatusBar")
		end
	end)
	
end
