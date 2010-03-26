--[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

-- Use our own namespace
local parent, ns = ...
setfenv(1, ns)

local texture = [[Interface\TargetingFrame\UI-StatusBar]]
local bars = {}

local function UpdateTexture(bar)
	local textureObject = bar
	if bar:IsObjectType("StatusBar") then
		bar:SetStatusBarTexture(texture)
		textureObject = bar:GetStatusBarTexture()
	else
		bar:SetTexture(texture)
	end
	textureObject:SetHorizTile(false)
	textureObject:SetVertTile(false)
	if bar.PostTextureUpdate then
		bar:PostTextureUpdate(texture)
	end
end

local frame_prototype = oUF.frame_metatable and oUF.frame_metatable.__index or oUF
function frame_prototype:RegisterStatusBarTexture(bar, callback)
	assert(bar:IsObjectType("StatusBar") or bar:IsObjectType("Texture"), "object should be a Texture or a StatusBar") 
	assert(callback == nil or type(callback) == "function", "callback should be either nil or a function")
	bars[bar] = self
	bar.PostTextureUpdate = callback or bar.PostTextureUpdate
end

oUF:RegisterInitCallback(function(self)
	for bar, frame in pairs(bars) do
		if frame == self then
			UpdateTexture(bar)
		end
	end
end)

local SharedMedia = GetLib('LibSharedMedia-3.0')
if SharedMedia then
	texture = SharedMedia:Fetch("statusbar", 'BantoBar')	
	SharedMedia.RegisterCallback(bars, 'LibSharedMedia_SetGlobal', function(_, media, value)
		if media == "statusbar" then
			texture = SharedMedia:Fetch("statusbar", value)
			for bar in pairs(bars) do
				UpdateTexture(bar)
			end
		end
	end)
end
	
