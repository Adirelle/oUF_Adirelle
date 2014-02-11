--[=[
Adirelle's oUF layout
(c) 2009-2014 Adirelle (adirelle@gmail.com)
All rights reserved.
--]=]

local _G, addonName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
--GLOBALS>

local SharedMedia = oUF_Adirelle.GetLib('LibSharedMedia-3.0')

-- The texture to apply (upvalue)
local texture = [[Interface\TargetingFrame\UI-StatusBar]]

local function StatusBar_Callback(bar)
	local r, g, b, a = bar:GetStatusBarColor()
	bar:SetStatusBarTexture(texture)
	bar:SetStatusBarColor(r, g, b, a)
end

local function Texture_Callback(bar)
	local r, g, b, a = bar:GetVertexColor()
	bar:SetTexture(texture)
	bar:SetVertexColor(r, g, b, a)
end

-- The meta to allow unit frames to register their textures
oUF:RegisterMetaFunction('RegisterStatusBarTexture', function(self, bar)
	local callback = assert(
		bar:IsObjectType("StatusBar") and StatusBar_Callback
		or bar:IsObjectType("Texture") and Texture_Callback,
		"RegisterStatusBarTexture(object): object should be a Texture or a StatusBar"
	)
	oUF_Adirelle.EmbedMessaging(bar)
	bar:RegisterMessage('SetStatusBarTexture', callback)
	callback(bar) -- Update once immediately
end)

-- Unique callback that only forward the message if need be
local function Update()
	local newTexture = SharedMedia:Fetch("statusbar", oUF_Adirelle.themeDB and oUF_Adirelle.themeDB.profile.statusbar)
	if newTexture ~= texture then
		texture = newTexture
		oUF_Adirelle:SendMessage('SetStatusBarTexture')
	end
end

-- Global callbacks
SharedMedia.RegisterCallback(addonName..'StatusBar', 'LibSharedMedia_SetGlobal', Update)
SharedMedia.RegisterCallback(addonName..'StatusBar', 'LibSharedMedia_Registered', Update)
oUF_Adirelle:RegisterMessage('OnTextureModified', Update)
oUF_Adirelle:RegisterMessage('OnSettingsModified', Update)

