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
local net 			= require('net')
UTIL				= require("UTIL")


local atisPosConfigFile = "ATIS_CombinedPos.lua"
local atisFreqConfigFile = "ATIS_Frequencies.json"

-- table net.json2lua(string json )

--[[
AtisConf = {}
AtisConf["Batumi"] = {}
AtisConf["Batumi"]["ATISFreq"] = 260.15
AtisConf["Batumi"]["TowerFreqA"] = 260.100
AtisConf["Batumi"]["TowerFreqB"] = 131.100
AtisConf["Batumi"]["Tacan"] = 16
AtisConf["Senaki-Kolkhi"] = {}
AtisConf["Senaki-Kolkhi"]["ATISFreq"] = 251.150
AtisConf["Senaki-Kolkhi"]["TowerFreqA"] = 251.100
AtisConf["Senaki-Kolkhi"]["TowerFreqB"] = 121.900
AtisConf["Senaki-Kolkhi"]["Tacan"] = 31
AtisConf["Kutaisi"] = {}
AtisConf["Kutaisi"]["ATISFreq"] = 270.650
AtisConf["Kutaisi"]["TowerFreqA"] = 270.600
AtisConf["Kutaisi"]["TowerFreqB"] = 125.500
AtisConf["Kutaisi"]["Tacan"] = 44
]]--

HOOK.writeDebugBase(ModuleName .. ": local required loaded")

-- load AutoATIS
function loadCode()
    HOOK.writeDebugBase(ModuleName .. ": loadCode opening AutoATIS_inj")  
    local autoAtisInject = io.open(lfs.writedir() .. "USM/" .. "AutoATIS_inj.lua", "r")
    local autoAtisPos = io.open(lfs.writedir() .. "USM/" .. atisPosConfigFile, "r")
    local autoAtisFreq = io.open(lfs.writedir() .. "USM/" .. atisFreqConfigFile, "r")

    local AtisConfigCode = nil
    local AtisConfigData = nil
    local AtisConfigFreq = nil

    if autoAtisInject then
        HOOK.writeDebugBase(ModuleName .. ": loadCode reading AutoATIS_inj") 
        AtisConfigCode = tostring(autoAtisInject:read("*all"))
        autoAtisInject:close()

        HOOK.writeDebugBase(ModuleName .. ": Loading ATIS file")  
        AtisConfigData = tostring(autoAtisPos:read("*all"))     
        autoAtisPos:close()

        HOOK.writeDebugBase(ModuleName .. ": Loading ATIS freqs")
        AtisConfigFreqJson = tostring(autoAtisFreq:read("*all"))
        HOOK.writeDebugBase("AtisConfigFreqJson: " .. AtisConfigFreqJson)  

        HOOK.writeDebugBase(ModuleName .. ": Converting from lua")
        AtisConfigFreq = net.json2lua(AtisConfigFreqJson)

        HOOK.writeDebugBase(ModuleName .. ": IntegratedserializeWithCycles")
        local AtisConfigFreqString = UTIL.IntegratedserializeWithCycles("AtisConfigFreq", AtisConfigFreq)
        HOOK.writeDebugBase(ModuleName .. ": AtisConfigFreqString:\n" .. AtisConfigFreqString)
        autoAtisFreq:close()

        HOOK.writeDebugBase(ModuleName .. ": Injecting ATIS freq data")  
        UTIL.inJectTable("AtisConfigFreq", AtisConfigFreq)

        HOOK.writeDebugBase(ModuleName .. ": Injecting ATIS config data")  
        UTIL.inJectCode("AtisConfigData", AtisConfigData)

        HOOK.writeDebugBase(ModuleName .. ": Injecting ATIS conf")  
        UTIL.inJectCode("AtisConfigCode", AtisConfigCode)

        HOOK.writeDebugBase(ModuleName .. ": loadCode done & Ready")  
    else
        HOOK.writeDebugBase(ModuleName .. ": AutoATIS_inj.lua not found")
	end

end

HOOK.writeDebugBase(ModuleName .. ": local function loadCode loaded")
HOOK.writeDebugBase(ModuleName .. ": Loaded " .. MainVersion .. "." .. SubVersion .. "." .. Build .. ", released " .. Date)



--[[
        local convertedFreqList = IntegratedserializeWithCycles("AtisConfigFreq", AtisConfigFreq)
        HOOK.writeDebugBase("convertedFreqList: " .. convertedFreqList)  
]]--



--~=