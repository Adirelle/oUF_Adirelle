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

local function SetFont(self)
	local name, size, flags = nil, self.__fontSize, self.__fontFlags
	if oUF_Adirelle.themeDB.profile then
		local db = oUF_Adirelle.themeDB.profile.fonts[self.__fontKind]
		name = db.name
		size = size * db.scale
		if db.flags ~= "DEFAULT" then
			flags = db.flags
		end
	end
	self:SetFont(SharedMedia:Fetch("font", name), size, flags)
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

-- Unique callback that only forward the message if need be
local function Update()
	oUF_Adirelle:SendMessage('SetFont')
end

-- Global callbacks
SharedMedia.RegisterCallback(addonName..'Fonts', 'LibSharedMedia_SetGlobal', Update)
SharedMedia.RegisterCallback(addonName..'Fonts', 'LibSharedMedia_Registered', Update)
oUF_Adirelle:RegisterMessage('OnFontModified', Update)
oUF_Adirelle:RegisterMessage('OnSettingsModified', Update)

