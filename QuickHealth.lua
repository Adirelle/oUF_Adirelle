--[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local lqh, lqh_minor = LibStub('LibQuickHealth-2.0', true)
if not lqh then return end

-- Use our own namespace
local _G, parent, ns = _G, ...
setfenv(1, ns)

Debug("oUF_Adirelle using LibQuickHealth-2.0 minor:", lqh_minor)

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

local function Update(self, event, unit) 
	return self:UNIT_MAXHEALTH(event, unit)
end

-- Update Health element to use QuickHealth
oUF:RegisterInitCallback(function(self)
	if self.Health then
		SetHandlerEnv(self, self.UNIT_HEALTH, self.UNIT_MAXHEALTH)
		lqh.RegisterCallback(self, "UnitHealthUpdated", Update, self)
	end
end)
