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

-- The intervall in which the live map JSON data is exported
LiveMap.ExportMapInterval = 5
LiveMap.LiveMapBaseDirectory = "C:\\DCS-WebMap\\Serious Uglies\\02 Maps Missions Server\\98 Server Admin\\Syria-Livemap\\"
LiveMap.liveMapUnitsPosFile = LiveMap.LiveMapBaseDirectory .. "mapdata\\Syria247.json" --edit this to represent your own (DCS cant write to different disks)

LiveMap.exportRedUnits = true
LiveMap.exportBlueStatics = true
--LiveMap.maxDeadPilots = 20

-----------------------------------------------------------------------------------------
-- Helper

LiveMap.writemission = function (_data, _fileName)--Function for saving to file (commonly found)
    local File = io.open(_fileName, "w")
  
    if File ~= nil then
      File:write(_data)
      File:close()
    else
      env.info("Ugly.writemission: Cannot access or write - " .. _fileName)
    end
  end
  
LiveMap.writeDataset = function (_desc, _icon, _lon, _lat)

	local descString = _desc:gsub("%\n", "<br>")

	local newMarkerStr = "\t\t{\n"
	newMarkerStr = newMarkerStr.."\t\t\"d\": \""..descString.."\",\n"
	newMarkerStr = newMarkerStr.."\t\t\"i\": \"".._icon.."\",\n"
	newMarkerStr = newMarkerStr.."\t\t\"x\": ".._lon..",\n"
	newMarkerStr = newMarkerStr.."\t\t\"y\": ".._lat.."\n"
	newMarkerStr = newMarkerStr.."\t\t}" 
	return newMarkerStr
end

LiveMap.getCoordFromGroup = function (_grp)
	local _x = 0 
	local _y = 0 
	local _z = 0 

	for i = 1, #_grp:GetUnits() do
		_x = _x + _grp:GetUnit(i):GetCoordinate().x
		_y = _y + _grp:GetUnit(i):GetCoordinate().y
		_z = _z + _grp:GetUnit(i):GetCoordinate().z
	end

	if #_grp:GetUnits() ~= 0 then
		_x = _x / #_grp:GetUnits()
		_y = _y / #_grp:GetUnits()
		_z = _z / #_grp:GetUnits()
	end

	local newCoord = COORDINATE:New(_x, _y, _z)
	return newCoord
end

LiveMap.startsWith = function (_toCheckString, _toFindString)
    return _toCheckString:sub(1, #_toFindString) == _toFindString
end
  
  
-----------------------------------------------------------------------------------------
-- Check if unit is an specific type

LiveMap.awacsTypes = { "E-2C", "E-3A", "A-50" }
LiveMap.tankerTypes = { "KC130", "KC135MPRS", "KC-135", "S-3B Tanker", "IL-78M" }
LiveMap.cargoTypes = { "IL-76MD", "An-26B", "An-30M", "C-17A", "C-130" }

LiveMap.isOfType = function (_unit, _typeTable)

    local _typeName = _unit:GetTypeName()

    _typeName = string.lower(_typeName)

    for _key, _value in pairs(_typeTable) do
        if _typeName:lower() == _value:lower() then
            return true
        end
    end

    return false
end

LiveMap.isAwacs = function (_unit)
  return LiveMap.isOfType(_unit, LiveMap.awacsTypes)
end

LiveMap.isTanker = function (_unit)
  return LiveMap.isOfType(_unit, LiveMap.tankerTypes)
end

LiveMap.isCargo = function (_unit)
  return LiveMap.isOfType(_unit, LiveMap.cargoTypes)
end

LiveMap.isInfantry = function(_unit)
    return false
end
  

LiveMap.getIconForCategory = function(_category)
    local iconName
  
    if _category == 0 then
      iconName ="airfixed"
    elseif _category == 1 then
      iconName = "airrotary"
    elseif _category == 2 then
      iconName = "ground"
    elseif _category == 3 then
      iconName = "water"
    else
      iconName = "ground"
    end
  
    return iconName
end
  
LiveMap.getIconDriver = function(_unit)
    local iconName = "ai"
  
    if _unit:GetPlayerName() then
      iconName = "player"
    elseif LiveMap.isTanker(_unit) then
      iconName = "tanker"
    elseif LiveMap.isAwacs(_unit) then
      iconName = "awacs"
    elseif LiveMap.isCargo(_unit) then
      iconName = "cargo"
    end
  
    return iconName
end

LiveMap.writeObjectsToJson = function()
    --SCRIPT START
--	env.info("Store current groups to JSON!")

    -- HEADER
    local fileString = "{\n\t\"features\": [\n"

    ------------------------------------------------------------
    -- first write blue guys. all!
    local ExportGroups = SET_GROUP:New():FilterCoalitions( "blue" ):FilterActive(true):FilterStart()

    ExportGroups:ForEachGroupAlive(function (grp)
    
        local iconName = "blue" .. LiveMap.getIconForCategory(grp:GetCategory())

        -- The Ejected ones
        local checkMore = true
        if LiveMap.startsWith(grp:GetName(), "Downed Pilot") then
            iconName = "markerdownedpilot"
            local lat, lon = coord.LOtoLL(LiveMap.getCoordFromGroup(grp))

            local pilotName = "John Doe"
            local i, j = string.find(grp:GetName(), " -- ")

            if j ~= nil then
                pilotName = string.sub(grp:GetName(), j)
            end

            fileString = fileString..LiveMap.writeDataset("Mayday, Mayday, Mayday!<br>" .. pilotName .. " has ejected in this area and needs immediate rescue!" , iconName, lon, lat)
            fileString = fileString..",\n"
            checkMore = false
        end
    
        --- The Infantry
        if checkMore ~= false then
            for i = 1, #grp:GetUnits() do
    --	 			env.info("grp:GetUnit(i):GetTypeName() " .. grp:GetUnit(i):GetTypeName() )
                if checkMore ~= false then
                    local isInfantry = false;
                    if LiveMap.isInfantry(grp:GetUnit(i):GetDCSObject()) then
                        isInfantry = true;
    --						env.info(grp:GetUnit(i):GetTypeName() .. " is of type infantry." )
                    else
    --			 			env.info(grp:GetUnit(i):GetTypeName() .. " is NOT of type infantry." )
                    end

                    if isInfantry == true then
                        local finalIconName = iconName .. LiveMap.getIconDriver(grp:GetUnit(1))

                        local lat, lon = coord.LOtoLL(LiveMap.getCoordFromGroup(grp))
                        fileString = fileString..LiveMap.writeDataset("Group of " .. #grp:GetUnits() .. " Infantry" , finalIconName, lon, lat)
                        fileString = fileString..",\n"
                        checkMore = false
                    end
                end
            end
        end
    
        -- Statics and the rest
        if checkMore ~= false then
            -- If group starts with "S_" treat as one entity
            if LiveMap.startsWith(grp:GetName(), "S_") then
                -- collect as one entity
                local grpDesc = ""
                if #grp:GetUnits() > 1 then
                    grpDesc = "Group of Units:<br>"
                else
                    grpDesc = "Single Unit:<br>"
                end

                for i = 1, #grp:GetUnits() do
                    grpDesc = grpDesc .. grp:GetUnit(i):GetDesc().displayName
                    if i < #grp:GetUnits() then
                        grpDesc = grpDesc .. ", "
                    end
                end

                local finalIconName = iconName .. LiveMap.getIconDriver(grp:GetUnit(1))

                -- Calculate the center point from all units.
                local lat, lon = coord.LOtoLL(LiveMap.getCoordFromGroup(grp))
                fileString = fileString..LiveMap.writeDataset(grpDesc, finalIconName, lon, lat)
                fileString = fileString..",\n"
            else
                for i = 1, #grp:GetUnits() do
                    local lat, lon = coord.LOtoLL(grp:GetUnit(i):GetCoordinate())
                    
                    local playerName = grp:GetUnit(i):GetDesc().displayName
                    local finalIconName = iconName .. LiveMap.getIconDriver(grp:GetUnit(i))

                    if grp:GetUnit(i):GetPlayerName() ~= nil then
                        playerName = playerName .. " [" .. grp:GetUnit(i):GetPlayerName() .. "]"
                    else
                --            playerName = playerName .. "[AI]"
                    end

                    fileString = fileString..LiveMap.writeDataset("Single Unit:<br>" .. playerName, finalIconName, lon, lat)
                    fileString = fileString..",\n"
                end
            end
        end
    end
    )
  
    ---------------------------------
    -- Now the statics
    if LiveMap.exportBlueStatics then
        local ExportStatics = SET_STATIC:New():FilterOnce()
  
        ExportStatics:ForEachStatic(function (stc)
            local _name = stc:GetName()
            local isAirbase = false
            if AIRBASE:FindByName(_name) ~= nil then
--          env.info(_name.." is a type of airbase, farp or oil rig")
            --avoid these types of static, they are really airbases
            isAirbase = true
            else
--            env.info(_name.." is a normal static to be destroyed")
            --do things here that you want to do on a static like Destroy()
            end
                       
            if stc:IsAlive() and isAirbase == false and stc:GetCoalition() == 2 then

--          env.info("LiveMap.exportBlueStatics: stc:GetName()" .. stc:GetName())
--          env.info("LiveMap.exportBlueStatics: stc:GetCoalition()" .. stc:GetCoalition())
--          env.info("LiveMap.exportBlueStatics: stc:GetCategory()" .. stc:GetCategory())
--          env.info("LiveMap.exportBlueStatics: UTILS.GetCoalitionName(stc:GetCoalition()) " .. UTILS.GetCoalitionName(stc:GetCoalition()))

            local iconName = UTILS.GetCoalitionName(stc:GetCoalition()):lower()

            iconName = iconName.."groundai"
            
            local stcDesc = stc:GetName():gsub("Static ", "")
            stcDesc = stcDesc .. ", "

            -- Calculate the center point from all units.
            local lat, lon = coord.LOtoLL(stc:GetCoordinate())
            fileString = fileString..LiveMap.writeDataset(stcDesc, iconName, lon, lat)
            fileString = fileString..",\n"
            end
        end
        )
    end
  
    ---------------------------------
    -- Now the red ones

    if LiveMap.exportRedUnits then
        local ExportGroups = SET_GROUP:New():FilterCoalitions( "red" ):FilterCategoryAirplane():FilterCategoryHelicopter():FilterActive(true):FilterStart()
  
        ExportGroups:ForEachGroupAlive(function (grp)
            if LiveMap.startsWith(grp:GetName(), "S_") ~= true then
  
                local iconName = "red" .. LiveMap.getIconForCategory(grp:GetCategory())
  
                local checkMore = true

                for i = 1, #grp:GetUnits() do
--					env.info("grp:GetUnit(i):GetTypeName() " .. grp:GetUnit(i):GetTypeName() )
                    if checkMore ~= false then
                        local isInfantry = false;
                        if LiveMap.isInfantry(grp:GetUnit(i):GetDCSObject()) then
                            isInfantry = true;
--							env.info(grp:GetUnit(i):GetTypeName() .. " is of type infantry." )
                        else
--							env.info(grp:GetUnit(i):GetTypeName() .. " is NOT of type infantry." )
                        end
  
                        if isInfantry == true then
                            local finalIconName = iconName .. LiveMap.getIconDriver(grp:GetUnit(1))
  
                            local lat, lon = coord.LOtoLL(LiveMap.getCoordFromGroup(grp))
                            fileString = fileString..LiveMap.writeDataset("Group of " .. #grp:GetUnits() .. " Infantry" , finalIconName, lon, lat)
                            fileString = fileString..",\n"
                            checkMore = false
                        end
                    end
                end
  
                if checkMore ~= false then
                    -- Collect rest. No single units
                    local grpDesc = ""
                    if #grp:GetUnits() > 1 then
                        grpDesc = "Group of Units:<br>"
                    else
                        grpDesc = "Single Unit:<br>"
                    end

                    for i = 1, #grp:GetUnits() do
                        grpDesc = grpDesc .. grp:GetUnit(i):GetDesc().displayName
                        if i < #grp:GetUnits() then
                            grpDesc = grpDesc .. ", "
                        end
                    end
  
                    -- Calculate the center point from all units.
                    local finalIconName = iconName .. LiveMap.getIconDriver(grp:GetUnit(1))
  
                    local lat, lon = coord.LOtoLL(LiveMap.getCoordFromGroup(grp))
                    fileString = fileString..LiveMap.writeDataset(grpDesc, finalIconName, lon, lat)
                    fileString = fileString..",\n"
                end

            end
        end
        )
    end
  
    ---------------------------------
    -- Now the neutral ones
    ExportGroups = SET_GROUP:New():FilterCoalitions( "neutral" ):FilterActive(true):FilterStart()

    ExportGroups:ForEachGroupAlive(function (grp)
        if LiveMap.startsWith(grp:GetName(), "S_") ~= true then
  
            local iconName = "neutral" .. LiveMap.getIconForCategory(grp:GetCategory())
  
            -- Collect everything. No single units
            local grpDesc = ""
            if #grp:GetUnits() > 1 then
                grpDesc = "Group of Units:<br>"
            else
                grpDesc = "Single Unit:<br>"
            end

            for i = 1, #grp:GetUnits() do
                grpDesc = grpDesc .. grp:GetUnit(i):GetDesc().displayName
                if i < #grp:GetUnits() then
                    grpDesc = grpDesc .. ", "
                end
            end
  
            -- Calculate the center point from all units.
            local finalIconName = iconName .. LiveMap.getIconDriver(grp:GetUnit(1))
            local lat, lon = coord.LOtoLL(LiveMap.getCoordFromGroup(grp))
            fileString = fileString..LiveMap.writeDataset(grpDesc, finalIconName, lon, lat)
            fileString = fileString..",\n"
        end
    end
    )
  
    -- Finalize everything
    -- remove last comma
    fileString = fileString:sub(1, -3)
    fileString = fileString.."\n"

    -- Close the file
    fileString = fileString.."\t]\n}"
  
    LiveMap.writemission(fileString, LiveMap.liveMapUnitsPosFile)
  
end -- writeObjectsToJson
  
  
LiveMap.InitLiveWeb = function()
    --THE SAVING SCHEDULE
    SCHEDULER:New( nil, function()
        LiveMap.writeObjectsToJson()
--        LiveMap.writeMarkerToJson();
        
    end, {}, 2, LiveMap.ExportMapInterval)
end

local frameNumber = 0

LiveMap.waitForMoose = function (argument, time)

    trigger.action.outText("Wait for Moose...", 2)

    if ENUMS == nil then
        trigger.action.outText("Moose is not loaded!", 3)
    else
        trigger.action.outText("Moose is loaded - Starting LiveMap", 5)
        LiveMap.InitLiveWeb()

        return 0
    end

    trigger.action.outText("debugTestPrint framenumber: "..frameNumber, 3)

    frameNumber = frameNumber + 1

    return time + 5
end

timer.scheduleFunction(LiveMap.waitForMoose, {}, timer.getTime() + 30)



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

