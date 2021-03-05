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
local FONT = SharedMedia.MediaType.FONT
local STATUSBAR = SharedMedia.MediaType.STATUSBAR

local function SetFont(self)
	local name, size, flags = SharedMedia.DefaultMedia[FONT], self.__fontSize, self.__fontFlags
	if oUF_Adirelle.themeDB.profile then
		local db = oUF_Adirelle.themeDB.profile.fonts[self.__fontKind]
		name = db.name
		size = size * db.scale
		if db.flags ~= "DEFAULT" then
			flags = db.flags
		end
	end
	local actualFont = SharedMedia:Fetch(FONT, name)
	if actualFont then
		self:SetFont(actualFont, size, flags)
	end
end

-- The meta to allow unit frames to register their fontstrings
oUF:RegisterMetaFunction('RegisterFontString', function(self, fontstring, kind, size, flags, noShadow)
	assert(fontstring:IsObjectType('FontString'), "RegisterFontString(object, kind): object should be a FontString")
	if not fontstring.RegisterMessage then
		oUF_Adirelle.EmbedMessaging(fontstring)
		fontstring:RegisterMessage('SetFont', SetFont)
	end
	fontstring:SetTextColor(1, 1, 1, 1)
	if noShadow then
		fontstring:SetShadowColor(0, 0, 0, 0)
	else
		fontstring:SetShadowColor(0, 0, 0, 1)
		fontstring:SetShadowOffset(1, -1)
	end
	fontstring.__fontKind, fontstring.__fontSize, fontstring.__fontFlags = kind, size or 10, flags or ""
	SetFont(fontstring) -- Update once immediately
end)

-- The statusbar texture (with default)
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

-- Top-level callbacks
local function UpdateFont()
	oUF_Adirelle:SendMessage('SetFont')
end

local function UpdateStatusBar()
	local textureSetting = oUF_Adirelle.themeDB.profile and oUF_Adirelle.themeDB.profile.statusbar or SharedMedia.DefaultMedia[STATUSBAR]
	local newTexture = SharedMedia:Fetch(STATUSBAR, textureSetting)
	if newTexture and newTexture ~= texture then
		texture = newTexture
		oUF_Adirelle:SendMessage('SetStatusBarTexture')
	end
end

local function UpdateBoth()
	UpdateFont()
	return UpdateStatusBar()
end

-- Setting handling
oUF_Adirelle:RegisterMessage('OnFontModified', UpdateFont)
oUF_Adirelle:RegisterMessage('OnTextureModified', UpdateStatusBar)
oUF_Adirelle:RegisterMessage('OnSettingsModified', UpdateBoth)

-- LSM callbacks
local function LSM_Update(mediaType)
	if mediaType == FONT then
		return UpdateFont()
	end
	if mediaType == STATUSBAR then
		return UpdateStatusBar()
	end
end

SharedMedia.RegisterCallback(addonName, 'LibSharedMedia_SetGlobal', LSM_Update)
SharedMedia.RegisterCallback(addonName, 'LibSharedMedia_Registered', LSM_Update)
