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

local _G, addonName = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
--GLOBALS>

local Config = oUF_Adirelle.Config

local SharedMedia = oUF_Adirelle.GetLib("LibSharedMedia-3.0")
local FONT = SharedMedia.MediaType.FONT
local STATUSBAR = SharedMedia.MediaType.STATUSBAR

oUF_Adirelle.fontKinds = {}
oUF_Adirelle.statusBarKinds = {}

local fontObjects = {}
local fontCount = 0

local function CreateFontObject(kind, size, flags, noShadow)
	fontCount = fontCount + 1
	local fontObject = CreateFont(addonName .. "_Font_" .. fontCount)
	fontObject:SetTextColor(1, 1, 1, 1)
	if noShadow then
		fontObject:SetShadowColor(0, 0, 0, 0)
	else
		fontObject:SetShadowColor(0, 0, 0, 1)
		fontObject:SetShadowOffset(1, -1)
	end

	local UpdateFontObject = function()
		local actualName, actualSize, actualFlags = Config:GetFont(kind, size, flags)
		fontObject:SetFont(SharedMedia:Fetch(FONT, actualName), actualSize, actualFlags)
	end

	oUF_Adirelle.EmbedMessaging(fontObject)
	fontObject:RegisterMessage("SetFont", UpdateFontObject)
	UpdateFontObject()
	Config:RegisterFont(kind)

	return fontObject
end

local function GetFontObject(kind, size, flags, noShadow)
	local key = format("%s_%d_%s_%s", kind, size, flags, tostring(noShadow))
	local fontObject = fontObjects[key]
	if not fontObject then
		fontObject = CreateFontObject(kind, size, flags, noShadow)
		fontObjects[key] = fontObject
	end
	return fontObject
end

-- The meta to allow unit frames to register their fontstrings
oUF:RegisterMetaFunction("RegisterFontString", function(_, fontstring, kind, size, flags, noShadow)
	assert(
		fontstring:IsObjectType("FontString"),
		"RegisterFontString(object, kind): object should be a FontString"
	)
	fontstring:SetFontObject(GetFontObject(kind, size or 10, flags or "", noShadow or false))
end)

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

-- The meta to allow unit frames to register their textures
oUF:RegisterMetaFunction("RegisterStatusBarTexture", function(_, bar, kind)
	local SetTexture = assert(
		bar:IsObjectType("StatusBar") and StatusBar_Callback or bar:IsObjectType("Texture") and Texture_Callback,
		"RegisterStatusBarTexture(object, kind): object should be a Texture or a StatusBar"
	)
	assert(type(kind) == "string", "RegisterStatusBarTexture(object, kind): kind should be a string")
	local callback = function(_, _, key)
		if key and key ~= kind then
			return
		end
		local name = Config:GetStatusBar(kind)
		local texture = SharedMedia:Fetch(STATUSBAR, name)
		SetTexture(bar, texture)
	end
	if not bar.RegisterMessage then
		oUF_Adirelle.EmbedMessaging(bar)
		bar:RegisterMessage("SetStatusBar", callback)
	end
	Config:RegisterStatusBar(kind)
	callback(bar) -- Update once immediately
end)

-- Top-level callbacks
local function UpdateFont()
	oUF_Adirelle:SendMessage("SetFont")
end

local function UpdateStatusBar()
	oUF_Adirelle:SendMessage("SetStatusBar")
end

local function UpdateBoth()
	UpdateFont()
	return UpdateStatusBar()
end

-- Setting handling
oUF_Adirelle:RegisterMessage("OnFontModified", UpdateFont)
oUF_Adirelle:RegisterMessage("OnTextureModified", UpdateStatusBar)
oUF_Adirelle:RegisterMessage("OnSettingsModified", UpdateBoth)

-- LSM callbacks
local function LSM_Update(mediaType)
	if mediaType == FONT then
		return UpdateFont()
	end
	if mediaType == STATUSBAR then
		return UpdateStatusBar()
	end
end

SharedMedia.RegisterCallback(addonName, "LibSharedMedia_SetGlobal", LSM_Update)
SharedMedia.RegisterCallback(addonName, "LibSharedMedia_Registered", LSM_Update)
