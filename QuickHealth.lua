--[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local lqh, lqh_minor = LibStub('LibQuickHealth-2.0', true)
if not lqh then return end
oUF.Debug("OuF using LibQuickHealth-2.0", lqh_minor)

-- Use our own namespace
local parent, ns = ...
setfenv(1, ns)

-- Prepare an environment where lqh.UnitHealth replaces built-in UnitHealth
local lqhEnv = setmetatable({
	UnitHealth = lqh.UnitHealth
}, {
	__index = _G,
	__newindex = function(self, key, value)
		_G[key] = value
	end
})

local function Update(self, event, unit)
	if self.unit == unit and self.UNIT_HEALTH then
		self:Debug(event, unit)
		return self:UNIT_HEALTH(event, unit)
	end
end

-- Update Health element to use QuickHealth
oUF:RegisterCallback(function(self)
	if self.Health then
		if type(self.UNIT_HEALTH) == "function" then
			oUF.Debug(self, "Using QuickHealth")
			setfenv(self.UNIT_HEALTH, lqhEnv)
			lqh.RegisterCallback(self, "UnitHealthUpdated", Update, self)
		elseif self.UNIT_HEALTH then
			oUF.Debug(self, "Not using QuickHealth because this is not a function:", self.UNIT_HEALTH)
		end
	end
end)

