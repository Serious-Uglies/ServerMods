-- Ugly Server Mods - Live Map

local ModuleName  	= "AutoATIS"
local MainVersion 	= "1"
local SubVersion 	= "0"
local Build 		= "0100"
local Date			= "23/01/2021"

--## LIBS
local base 			= _G
module('AutoATIS', package.seeall)
local require 		= base.require		
local io 			= require('io')
local lfs 			= require('lfs')
local os 			= require('os')

local atisPosConfigFile = "ATIS_CaucasusPos.lua"

HOOK.writeDebugBase(ModuleName .. ": local required loaded")

-- load AutoATIS
function loadCode()
    HOOK.writeDebugBase(ModuleName .. ": loadCode opening AutoATIS_inj")  
    local aic = io.open(lfs.writedir() .. "USM/" .. "AutoATIS_inj.lua", "r")
    local acd = io.open(lfs.writedir() .. "USM/" .. "ATIS_CaucasusPos.lua", "r")

    local EmbeddedcodeAutoATIS = nil
    local AtisConfigData = nil

    if aic then
        HOOK.writeDebugBase(ModuleName .. ": loadCode reading AutoATIS_inj") 
        EmbeddedcodeAutoATIS = tostring(aic:read("*all"))
        aic:close()

        HOOK.writeDebugBase(ModuleName .. ": Adding ATIS Conf to mission")  
        HOOK.writeDebugBase(ModuleName .. ": Loading ATIS file")  
        AtisConfigData = tostring(acd:read("*all"))     
        aic:close()

        HOOK.writeDebugBase(ModuleName .. ": Injecting ATIS file")  
        UTIL.inJectCode("AtisConfigData", AtisConfigData)

        HOOK.writeDebugBase(ModuleName .. ": loadCode loading AutoATIS_inj into the mission")  
        UTIL.inJectCode("EmbeddedcodeAutoATIS", EmbeddedcodeAutoATIS)

        HOOK.writeDebugBase(ModuleName .. ": loadCode done & Ready")  
    else
        HOOK.writeDebugBase(ModuleName .. ": AutoATIS_inj.lua not found")
	end

end

HOOK.writeDebugBase(ModuleName .. ": local function loadCode loaded")

HOOK.writeDebugBase(ModuleName .. ": Loaded " .. MainVersion .. "." .. SubVersion .. "." .. Build .. ", released " .. Date)




--~=