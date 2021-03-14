--[=[
Adirelle's oUF layout
(c) 2009-2021 Adirelle (adirelle@gmail.com)

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

local _G = _G
local oUF_Adirelle = _G.oUF_Adirelle

--<GLOBALS
--GLOBALS>

oUF_Adirelle.GetLib("LibMovable-1.0").Embed(oUF_Adirelle)

-- Return the "anchors" table for the given frame
local function GetDatabase(frame)
	return oUF_Adirelle.layoutDB and oUF_Adirelle.layoutDB.profile.anchors[frame.dbKey]
end

-- Enable/disable methods
local function LM10_Enable(frame)
	return frame:SetEnabledSetting(true)
end
local function LM10_Disable(frame)
	return frame:SetEnabledSetting(false)
end

local RegisterMovable = oUF_Adirelle.RegisterMovable
function oUF_Adirelle.RegisterMovable(frame, key, label, mask)
	frame:Debug("Registering movable", key, label, mask)

	-- The frame can be disabled
	oUF_Adirelle.RegisterTogglableFrame(frame, key, label)

	-- Mix in our methods
	frame.LM10_IsEnabled = frame.GetEnabledSetting
	frame.LM10_Enable = LM10_Enable
	frame.LM10_Disable = LM10_Disable

	-- Now do register this frame as movable
	RegisterMovable(oUF_Adirelle, frame, GetDatabase, label, mask)
end

-- Update the position when settings are loaded
oUF_Adirelle:RegisterMessage("OnSettingsModified", "UpdateMovableLayout")

-- LibMovable compat layer
function oUF_Adirelle.IsLocked()
	return oUF_Adirelle:AreMovablesLocked()
end
function oUF_Adirelle.ToggleLock()
	if oUF_Adirelle:AreMovablesLocked() then
		oUF_Adirelle:UnlockMovables()
	else
		oUF_Adirelle:LockMovables()
	end
end
