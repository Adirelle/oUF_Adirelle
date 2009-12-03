--[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local oUF = assert(_G.oUF, "oUF_Adirelle requires oUF")

local texture = [[Interface\TargetingFrame\UI-StatusBar]]
local objects = {}

local function UpdateTexture(object)
	local setter, callback = object.SetStatusBarTexture or object.SetTexture, object.PostTextureUpdate
	setter(object, texture)
	if callback then
		callback(object, texture)
	end
end

local frame_prototype = oUF.frame_metatable and oUF.frame_metatable.__index or oUF
function frame_prototype:RegisterStatusBarTexture(object, callback)
	local setter = object.SetStatusBarTexture or object.SetTexture
	assert(type(setter) == "function", "object has neither :SetTexture nor :SetStatusBarTexture") 
	assert(callback == nil or type(callback) == "function", "callback should be either nil or a function")
	objects[object] = self
	object.PostTextureUpdate = callback or object.PostTextureUpdate
end

oUF:RegisterInitCallback(function(self)
	for object, frame in pairs(objects) do
		if frame == self then
			UpdateTexture(object)
		end
	end
end)

local lsm = LibStub('LibSharedMedia-3.0', true)
if lsm then
	texture = lsm:Fetch("statusbar", 'BantoBar')	
	lsm.RegisterCallback(objects, 'LibSharedMedia_SetGlobal', function(_, media, value)
		if media == "statusbar" then
			texture = lsm:Fetch("statusbar", value)
			for object in pairs(objects) do
				UpdateTexture(object)
			end
		end
	end)
end
	
