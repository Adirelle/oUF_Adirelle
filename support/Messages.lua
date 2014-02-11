--[=[
Adirelle's oUF layout
(c) 2009-2014 Adirelle (adirelle@gmail.com)
All rights reserved.
--]=]

local _G, addonName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
local _G = _G
local CreateFrame = _G.CreateFrame
local next = _G.next
local pairs = _G.pairs
local rawget = _G.rawget
local setmetatable = _G.setmetatable
local tinsert = _G.tinsert
local tremove = _G.tremove
local type = _G.type
--GLOBALS>

-- The big table
local callbacks = {}

-- Used to create a list of callbacks for a given frame
local callbackListMeta = {
	__call = function(list, ...)
		for i, callback in ipairs(list) do
			callback(...)
		end
	end
}

-- Used to wrap methods calls
local methodCallbacks = setmetatable({}, {
	__index = function(t, name)
		local callback = function(self, ...) return self[name](self, ...) end
		t[name] = callback
		return callback
	end,
})

-- Register a message callback
local function RegisterMessage(self, message, callback)
	-- Argument checks
	assert(type(message) == "string", "RegisterMessage(self, message, callback): message should be a string, not a "..type(message))
	assert(type(callback) == "string" or type(callback) == "function", "RegisterMessage(self, message, callback): callback should be a string or a function, not a "..type(callback))

	-- Get a function to handle method callbacks
	if type(callback) == "string" then
		assert(type(self) == "table", "RegisterMessage(self, message, callback): cannot register method callback for a "..type(self))
		callback = methodCallbacks[callback]
	end

	-- Initialize the callback table for that message
	if not callbacks[message] then
		callbacks[message] = {}
	end

	-- Register the callback
	local existing = callbacks[message][self]
	if type(existing) == "function" then
		if existing ~= callback then
			callbacks[message][self] = setmetatable({ existing, callback }, callbackListMeta)
		else
			return false
		end
	elseif type(existing) == "table" then
		for i = 1, #existing do
			if existing[i] == callback then
				return false
			end
		end
		tinsert(existing, callback)
	else
		callbacks[message][self] = callback
	end
	return true
end

local function UnregisterMessage(self, message, callback)
	-- Argument checks
	assert(type(message) == "string", "UnregisterMessage(self, message, callback): message should be a string, not a "..type(message))
	assert(type(callback) == "string" or type(callback) == "function", "UnregisterMessage(self, message, callback): callback should be a string or a function, not a "..type(callback))

	-- Fetch existing callback(s)
	local existing = callbacks[message] and callbacks[message][self]

	-- No callback has been registered for this message and this target
	if not existing then
		return false
	end

	-- Get a function to handle method callbacks
	if type(callback) == "string" then
		callback = rawget(methodCallbacks, callback)
		if not callback then
			-- Do not bother removing the callback if it never existed in the first place
			return false
		end
	end

	-- Remove the callback
	local found = false
	if existing == callback then
		callbacks[message][self] = nil
		found = true

	elseif type(existing) == "table" then
		for i = 1, #existing do
			if existing[i] == callback then
				found = true
				tremove(existing, i)
				if #existing == 0 then
					callbacks[message][self] = nil
				end
				break
			end
		end
	end

	-- Remove empty tables
	if not next(callbacks[message]) then
		callbacks[message] = nil
	end

	return found
end

-- Send a message
local function SendMessage(self, message, ...)
	if not callbacks[message] then return end
	for target, callback in pairs(callbacks[message]) do
		callback(target, message, ...)
	end
end

-- Trigger a message for one frame
local function TriggerMessage(self, message, ...)
	local callback = callbacks[message] and callbacks[message][self]
	if callback then
		return callback(self, message, ...)
	end
end

-- Register these functions as unit frame methods
oUF:RegisterMetaFunction("RegisterMessage", RegisterMessage)
oUF:RegisterMetaFunction("UnregisterMessage", UnregisterMessage)
oUF:RegisterMetaFunction("SendMessage", SendMessage)
oUF:RegisterMetaFunction("TriggerMessage", TriggerMessage)

-- The function to embed messaging methods into another table
function oUF_Adirelle.EmbedMessaging(target)
	if not target.Debug then
		target.Debug = oUF.Debug
	end
	target.RegisterMessage = RegisterMessage
	target.UnregisterMessage = UnregisterMessage
	target.SendMessage = SendMessage
	target.TriggerMessage = TriggerMessage
end

-- Embed messaging into oUF_Adirelle itself
oUF_Adirelle:EmbedMessaging()

-- Build an simple event broadcast system on top of the messaging system
local eventFrame = CreateFrame("Frame")
eventFrame:SetScript('OnEvent', SendMessage)

-- Register an event for target, also register it to eventFrame if need be
local function RegisterEvent(target, event, callback)
	if RegisterMessage(target, event, callback) then
		if callbacks[event] and not eventFrame:IsEventRegistered(event) then
			eventFrame:RegisterEvent(event)
		end
		return true
	end
end

-- Unregister an event for target, also unregister it from eventFrame if it is unused
local function UnregisterEvent(target, event, callback)
	if UnregisterMessage(target, event, callback) then
		if not callbacks[event] and eventFrame:IsEventRegistered(event) then
			eventFrame:UnregisterEvent(event)
		end
		return true
	end
end

-- Embed our register methods into the target object
function oUF_Adirelle.EmbedEventMessaging(target)
	target.RegisterEvent = RegisterEvent
	target.UnregisterEvent = UnregisterEvent
end

-- Embed it into ourself
oUF_Adirelle:EmbedEventMessaging()

