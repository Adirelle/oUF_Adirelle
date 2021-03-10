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

local IsAddOnLoaded = _G.IsAddOnLoaded
local LoadAddOn = _G.LoadAddOn

local function noop()
end

oUF_Adirelle.Config = {
	Reset = noop,
	Close = noop,
	Toggle = function(self)
		return self:Close() or self:Open()
	end,
	Open = function(self, ...)
		if not IsAddOnLoaded("oUF_Adirelle_Config") then
			self.Open = noop
			LoadAddOn("oUF_Adirelle_Config")
		end
		return self:Open(...)
	end,
}
