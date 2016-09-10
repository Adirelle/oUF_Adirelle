--[=[
Adirelle's oUF layout
(c) 2009-2016 Adirelle (adirelle@gmail.com)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
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

