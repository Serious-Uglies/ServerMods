-- Ugly Server Mods - Live Map

local ModuleName  	= "LiveMap"
local MainVersion 	= "1"
local SubVersion 	= "0"
local Build 		= "0100"
local Date			= "23/01/2021"

--## LIBS
local base 			= _G
module('LiveMap', package.seeall)
local require 		= base.require		
local io 			= require('io')
local lfs 			= require('lfs')
local os 			= require('os')

HOOK.writeDebugBase(ModuleName .. ": local required loaded")

-- load LiveMap
function loadCode()
    HOOK.writeDebugBase(ModuleName .. ": loadCode opening LiveMap_inj")  
    local ey = io.open(lfs.writedir() .. "USM/" .. "LiveMap_inj.lua", "r")
    local EmbeddedcodeLiveMap = nil
    if ey then
        HOOK.writeDebugBase(ModuleName .. ": loadCode reading LiveMap_inj") 
        EmbeddedcodeLiveMap = tostring(ey:read("*all"))
        ey:close()    
        HOOK.writeDebugBase(ModuleName .. ": loadCode loading LiveMap_inj into the mission")  
        UTIL.inJectCode("EmbeddedcodeLiveMap", EmbeddedcodeLiveMap)
        HOOK.writeDebugBase(ModuleName .. ": loadCode done & Ready")  
    else
        HOOK.writeDebugBase(ModuleName .. ": LiveMap_inj.lua not found")
	end

end

HOOK.writeDebugBase(ModuleName .. ": local function loadCode loaded")

HOOK.writeDebugBase(ModuleName .. ": Loaded " .. MainVersion .. "." .. SubVersion .. "." .. Build .. ", released " .. Date)




--~=