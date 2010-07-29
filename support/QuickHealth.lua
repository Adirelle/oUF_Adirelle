--[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

-- Use our own namespace
local _G, parent, ns = _G, ...
setfenv(1, ns)

local lqh = GetLib('LibQuickHealth-2.0')
if not lqh then return end

-- Override UnitHealth in addon namespace
UnitHealth = lqh.UnitHealth

-- Prepare an environment where lqh.UnitHealth replaces built-in UnitHealth
local lqhEnv = setmetatable({
	UnitHealth = lqh.UnitHealth
}, {
	__index = _G,
	__newindex = function(self, key, value)
		_G[key] = value
	end
})

local function SetHandlerEnv(self, ...)
	for i = 1, select('#', ...) do
		local handler = select(i, ...)
		if type(handler) == "function" then
			if getfenv(handler) ~= lqhEnv then
				setfenv(handler, lqhEnv)
			end
		elseif type(handler) == "table" then
			for index, v in pairs(handler) do
				if type(v) == "function" and getfenv(v) ~= lqhEnv then
					setfenv(v, lqhEnv)
				end
			end
		end
	end
end

local function HealthUpdated(self, event, guid)
	if guid == UnitGUID(self.unit or "") then
		return self:UpdateElement('Health')
	end
end

-- Update Health element to use QuickHealth
oUF:RegisterInitCallback(function(self)
	if self.Health then
		if self.Health.frequentUpdates then
			self:DisableElement('Health')
			self.Health.frequentUpdates = nil
			self:EnableElement('Health')
			self:Debug('Disabled Health.frequentUpdates for in favor of LibQuickHealth support')
		end
		SetHandlerEnv(self, self.UNIT_HEALTH, self.UNIT_MAXHEALTH, self.Health.Update)
		lqh.RegisterCallback(self, "HealthUpdated", HealthUpdated, self)
		self:Debug('Register for LibQuickHealth updates')
	end
end)

