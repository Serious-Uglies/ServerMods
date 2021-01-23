-- Ugly Server Mods - Live Map injected module

local ModuleName  	= "LiveMap"
local MainVersion 	= "1"
local SubVersion 	= "0"
local Build 		= "0100"
local Date			= "23/01/2021"

--## MAIN TABLE
LiveMap             = {}

--## LOCAL VARIABLES
local base 		    = _G
local USM_io 	    = base.io  	-- check if io is available in mission environment
local USM_lfs 	    = base.lfs		-- check if lfs is available in mission environment

local frameNumber = 0

function debugTestPrint(argument, time)

    trigger.action.outText("Check for Moose...", 3)

    if ENUMS == nil then
        trigger.action.outText("Moose is not loaded!", 3)
    else
        trigger.action.outText("Moose is loaded!", 3)
    end

    trigger.action.outText("debugTestPrint framenumber: "..frameNumber, 3)

    frameNumber = frameNumber + 1

    return time + 5
end

timer.scheduleFunction(debugTestPrint, {}, timer.getTime() + 1)

--[[
if env.mission.theatre == "Caucasus" then
    local tTbl = {}
    for tName, tData in pairs(CaucasusTowns) do
        tTbl[#tTbl+1] = tData
    end
    LiveMap.TerrainDb["towns"] = tTbl
    CaucasusTowns = nil
elseif env.mission.theatre == "Nevada" then
    local tTbl = {}
    for tName, tData in pairs(NevadaTowns) do
        tTbl[#tTbl+1] = tData
    end
    LiveMap.TerrainDb["towns"] = tTbl
    NevadaTowns = nil
elseif env.mission.theatre == "Normandy" then
    local tTbl = {}
    for tName, tData in pairs(NormandyTowns) do
        tTbl[#tTbl+1] = tData
    end
    LiveMap.TerrainDb["towns"] = tTbl
    NormandyTowns = nil
elseif env.mission.theatre == "PersianGulf" then
    local tTbl = {}
    for tName, tData in pairs(PersianGulfTowns) do
        tTbl[#tTbl+1] = tData
    end
    LiveMap.TerrainDb["towns"] = tTbl
    PersianGulfTowns = nil
elseif env.mission.theatre == "TheChannel" then
    local tTbl = {}
    for tName, tData in pairs(TheChannelTowns) do
        tTbl[#tTbl+1] = tData
    end
    LiveMap.TerrainDb["towns"] = tTbl
    TheChannelTowns = nil
elseif env.mission.theatre == "Syria" then
    local tTbl = {}
    for tName, tData in pairs(SyriaTowns) do
        tTbl[#tTbl+1] = tData
    end
    LiveMap.TerrainDb["towns"] = tTbl
    SyriaTowns = nil
else
    env.error(("LiveMap, no theater identified: halting everything"))
    return
end
]]--

