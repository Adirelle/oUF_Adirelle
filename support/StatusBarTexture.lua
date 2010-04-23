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
	if type(bar.textureColor) == "table" then
		local r, g, b, a = unpack(bar.textureColor)
		if not r and bar.r then
			r, g, b, a = bar.r, bar.g, bar.b, bar. a
		end
		if r and g and b then
			if bar:IsObjectType("StatusBar") then
				bar:SetStatusBarColor(r, g, b, a or 1)
			else
				bar:SetVertexColor(r, g, b, a or 1)
			end
		end
	end
	if bar.PostTextureUpdate then
		bar:PostTextureUpdate(texture)
	end
end

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

local frame_prototype = oUF.frame_metatable and oUF.frame_metatable.__index or oUF

-- Usage:
--   self:RegisterStatusBarTexture(bar, callback)
--   self:RegisterStatusBarTexture(bar, colorTable)
--   self:RegisterStatusBarTexture(bar, r, g, b[, a])
function frame_prototype:RegisterStatusBarTexture(bar, arg, ...)
	assert(bar:IsObjectType("StatusBar") or bar:IsObjectType("Texture"), "object should be a Texture or a StatusBar") 
	if type(arg) == "function" then
		bar.PostTextureUpdate = arg or bar.PostTextureUpdate
	elseif type(arg) == "table" then
		bar.textureColor = arg
	elseif tonumber(arg) then
		local r, g, b, a = arg, ...
		if tonumber(g) and tonumber(b) then
			bar.textureColor = { tonumber(r), tonumber(g), tonumber(b), tonumber(a) }
		end
	elseif arg then
		assert(false, "args should be a function, a color table, a (r,g,b,a) tuple or nil")
	end
	bars[bar] = self
	if bar:IsObjectType("StatusBar") then
		bar:HookScript('OnValueChanged', StatusBar_OnValueChanged)
	end
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
	
