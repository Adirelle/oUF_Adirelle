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

local _G, assert = _G, _G.assert
local oUF_Adirelle = assert(_G.oUF_Adirelle)

--<GLOBALS
local IsAddOnLoaded = assert(_G.IsAddOnLoaded)
local LoadAddOn = assert(_G.LoadAddOn)
--GLOBALS>

local function noop()
end

local Config = {
	statusBars = {},
	colors = {},
	fonts = {},

	Reset = noop,
	Close = noop,
}
oUF_Adirelle.Config = Config

function Config:Toggle()
	return self:Close() or self:Open()
end

function Config:Open(...)
	if not IsAddOnLoaded("oUF_Adirelle_Config") then
		self.Open = noop -- prevents infinite loop if loading fail
		LoadAddOn("oUF_Adirelle_Config")
	end
	return self:Open(...)
end

function Config:RegisterStatusBar(key)
	if not self.statusBars[key] then
		self.statusBars[key] = true
		self:Reset()
	end
end

function Config:GetStatusBar(key)
	local themeDB = oUF_Adirelle.themeDB
	return themeDB.profile and themeDB.profile.statusBars[key]
end

function Config:RegisterColor(key)
	if not self.colors[key] then
		self.colors[key] = true
		self:Reset()
	end
end

function Config:RegisterFont(key)
	if not self.fonts[key] then
		self.fonts[key] = true
		self:Reset()
	end
end

function Config:GetFont(key, size, flags)
	local name
	local themeDB = oUF_Adirelle.themeDB
	if themeDB.profile then
		local db = themeDB.profile.fonts[key]
		name = db.name
		size = size * db.scale
		if db.flags ~= "DEFAULT" then
			flags = db.flags
		end
	end
	return name, size, flags
end
