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
	
	local db
	
	function oUF_Adirelle.UpdateStatusBarTextures(media)
		if media and media ~= "statusbar" then return end
		local texture = SharedMedia:Fetch("statusbar", db and db.statusbar)
		for bar, callback in pairs(bars)  do
			callback(bar, texture)
		end
	end

	SharedMedia.RegisterCallback(addonName, 'LibSharedMedia_SetGlobal', oUF_Adirelle.UpdateStatusBarTextures)
	
	local defaultTexture = SharedMedia:Fetch("statusbar", 'BantoBar') or [[Interface\TargetingFrame\UI-StatusBar]]

	-- The meta to allow unit frames to register their textures	
	oUF:RegisterMetaFunction('RegisterStatusBarTexture', function(self, bar)
		local callback = assert(
			bar:IsObjectType("StatusBar") and StatusBar_Callback
			or bar:IsObjectType("Texture") and Texture_Callback,
			"object should be a Texture or a StatusBar"
		)
		bars[bar] = callback
		callback(bar, defaultTexture)
	end)
	
	-- Database callback to update the texture on profile changes
	oUF_Adirelle.RegisterVariableLoadedCallback(function(newDB)
		db = newDB
		return oUF_Adirelle.UpdateStatusBarTextures()
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
