-- Ugly Server Mods - AutoATIS injected module

local ModuleName  	= "AutoATIS"
local MainVersion 	= "1"
local SubVersion 	= "0"
local Build 		= "0100"
local Date			= "23/01/2021"

--## MAIN TABLE
AutoATIS             = {}

--## LOCAL VARIABLES
local base 		    = _G
local USM_io 	    = base.io  	-- check if io is available in mission environment
local USM_lfs 	    = base.lfs		-- check if lfs is available in mission environment

-- The intervall in which the live map JSON data is exported

-----------------------------------------------------------------------------------------
-- Format of injected data
--[[

AtisStaticsPos:
AtisStaticsPos["ATIS Mozdok"] = {} ---Caucasus
AtisStaticsPos["ATIS Mozdok"]["shape_name"] = "UH-1H"
AtisStaticsPos["ATIS Mozdok"]["CountryID"] = 2
AtisStaticsPos["ATIS Mozdok"]["y"] = 835129.25
AtisStaticsPos["ATIS Mozdok"]["x"] = -83958.40625
AtisStaticsPos["ATIS Mozdok"]["CategoryID"] = 3
AtisStaticsPos["ATIS Mozdok"]["heading"] = 4.555309243523
AtisStaticsPos["ATIS Mozdok"]["type"] = "UH-1H"
AtisStaticsPos["ATIS Mozdok"]["name"] = "ATIS Mozdok"
AtisStaticsPos["ATIS Mozdok"]["CoalitionID"] = 2
AtisStaticsPos["ATIS Mozdok"]["dead"] = false


AtisConfigFreq:
  "Abu Al-Duhur 09": {
    "Map-Spezifisch": "Syria",
    "TACAN": "´",
    "I(C)LS": "´",
    "Primär": 136200,
    "Sekundär": 230800,
    "ATIS": 230850,
    "Runway": "09",
    "DCS-AirfieldName": "Abu al-Duhur",
    "MagVar": 5,
    "Comments": "",
    "KI ATC UHF": 250350,
    "KI ATC VHF": 122200,
    "Land": "Syrien"
  }
]]--

-----------------------------------------------------------------------------------------
-- Configuration

local coalitions = {}
coalitions[1] = coalition.side.RED
coalitions[2] = coalition.side.BLUE
--coalitions[3] = coalition.side.NEUTRAL
	

local atisUnits = {}
atisUnits[1] = {}
atisUnits[1]["type"] = "Ka-27" -- Red ATIS unit
atisUnits[1]["CountryID"] = 0 -- Red ATIS country

atisUnits[2] = {}
atisUnits[2]["type"] = "UH-1H" -- Blue ATIS unit
atisUnits[2]["CountryID"] = 2 -- Blue ATIS country

local AutoAtisConf = {}

-----------------------------------------------------------------------------------------
-- Debug code

function IntegratedbasicSerialize(s)
	if s == nil then
		return "\"\""
	else
		if ((type(s) == 'number') or (type(s) == 'boolean') or (type(s) == 'function') or (type(s) == 'table') or (type(s) == 'userdata') ) then
			return tostring(s)
		elseif type(s) == 'string' then
			return string.format('%q', s)
		end
	end
end

function Integratedserialize(name, value, level)
	-----Based on ED's serialize_simple2
	local basicSerialize = function (o)
	  if type(o) == "number" then
		return tostring(o)
	  elseif type(o) == "boolean" then
		return tostring(o)
	  else -- assume it is a string
		return IntegratedbasicSerialize(o)
	  end
	end

	local serialize_to_t = function (name, value, level)
	----Based on ED's serialize_simple2


	  local var_str_tbl = {}
	  if level == nil then level = "" end
	  if level ~= "" then level = level.."  " end

	  table.insert(var_str_tbl, level .. name .. " = ")

	  if type(value) == "number" or type(value) == "string" or type(value) == "boolean" then
		table.insert(var_str_tbl, basicSerialize(value) ..  ",\n")
	  elseif type(value) == "table" then
		  table.insert(var_str_tbl, "\n"..level.."{\n")

		  for k,v in pairs(value) do -- serialize its fields
			local key
			if type(k) == "number" then
			  key = string.format("[%s]", k)
			else
			  key = string.format("[%q]", k)
			end

			table.insert(var_str_tbl, Integratedserialize(key, v, level.."  "))

		  end
		  if level == "" then
			table.insert(var_str_tbl, level.."} -- end of "..name.."\n")

		  else
			table.insert(var_str_tbl, level.."}, -- end of "..name.."\n")

		  end
	  else
		print("Cannot serialize a "..type(value))
	  end
	  return var_str_tbl
	end

	local t_str = serialize_to_t(name, value, level)

	return table.concat(t_str)
end

function IntegratedserializeWithCycles(name, value, saved)
	local basicSerialize = function (o)
		if type(o) == "number" then
			return tostring(o)
		elseif type(o) == "boolean" then
			return tostring(o)
		else -- assume it is a string
			return IntegratedbasicSerialize(o)
		end
	end

	local t_str = {}
	saved = saved or {}       -- initial value
	if ((type(value) == 'string') or (type(value) == 'number') or (type(value) == 'table') or (type(value) == 'boolean')) then
		table.insert(t_str, name .. " = ")
		if type(value) == "number" or type(value) == "string" or type(value) == "boolean" then
			table.insert(t_str, basicSerialize(value) ..  "\n")
		else

			if saved[value] then    -- value already saved?
				table.insert(t_str, saved[value] .. "\n")
			else
				saved[value] = name   -- save name for next time
				table.insert(t_str, "{}\n")
				for k,v in pairs(value) do      -- save its fields
					local fieldname = string.format("%s[%s]", name, basicSerialize(k))
					table.insert(t_str, IntegratedserializeWithCycles(fieldname, v, saved))
				end
			end
		end
		return table.concat(t_str)
	else
		return ""
	end
end

-----------------------------------------------------------------------------------------
-- Main code

-- add atis to airport
AutoATIS.AddAtis = function (_name, _atisConf)  
    local newAtis=ATIS:New(_name, _atisConf["ATISFreq"])
    newAtis:SetRadioRelayUnitName("ATIS " .. _name)
    newAtis:SetTowerFrequencies({_atisConf["TowerFreqA"], _atisConf["TowerFreqB"]})
    newAtis:SetImperialUnits()
    if _atisConf["Tacan"] ~= "" then
        newAtis:SetTACAN(_atisConf["Tacan"])
    end
    newAtis:Start()
end

-- place unit at predefined position depended of coalition
AutoATIS.CreateAtisObjectForAirbase = function (_name, _coalition)
    local configName = "ATIS " .. _name
    local _conf = AtisStaticsPos[configName]

    if _conf ~= nil then
        local tmpGrp = {}
        tmpGrp["visible"] = true
        tmpGrp["x"] = _conf["x"]
        tmpGrp["y"] = _conf["y"]
        tmpGrp["CountryID"] = atisUnits[_coalition]["CountryID"]
        tmpGrp["CategoryID"] = 1 -- heli hardcoded
        tmpGrp["name"] = _conf["name"]
        tmpGrp["CoalitionID"] = _coalition
        tmpGrp["uncontrolled"] = true
        tmpGrp["tasks"] = {}
        tmpGrp["task"] = "transport"
        tmpGrp["units"] = {}
        tmpGrp["units"][1] = {}
        tmpGrp["units"][1]["x"] = _conf["x"]
        tmpGrp["units"][1]["y"] = _conf["y"]
        tmpGrp["units"][1]["type"] = atisUnits[_coalition]["type"]
        tmpGrp["units"][1]["name"] = _conf["name"]
        tmpGrp["units"][1]["shape_name"] = atisUnits[_coalition]["type"]
        tmpGrp["units"][1]["heading"] = _conf["heading"]

        coalition.addGroup(tmpGrp["CountryID"], tmpGrp["CategoryID"], tmpGrp)
        env.info("UGLY: Adding group as ATIS to: " .. tostring(_coalition))
    end
end

AutoATIS.injectAtisToMap = function ()
    if AtisStaticsPos ~= nil then -- Data has been injected properly
        env.info("AtisStaticsPos injected - contains no. of elements: " .. tostring(#AtisStaticsPos))

--[[
        for k,v in pairs(AtisStaticsPos) do
            local AtisStaticsPosString = IntegratedserializeWithCycles("AtisStaticsPos - " .. k, AtisStaticsPos[k])
            env.info("AtisStaticsPos - \n" .. AtisStaticsPosString)
        end
]]
    else
        env.info("AtisStaticsPos not injected")
    end

    if AtisConfigFreq ~= nil then -- Data has been injected properly
        env.info("UGLY: Existing database, using given atis conf.")

        -- Convert to more usable format
        for k,v in pairs(AtisConfigFreq) do
            local nextAirfieldConf = AtisConfigFreq[k]
            
            local nextAirfieldName = AtisConfigFreq[k]["DCS-AirfieldName"]
            env.info("UGLY: Checking config for: " .. nextAirfieldName)

            local currentAtisConf = AutoAtisConf[nextAirfieldName]
            if currentAtisConf == nil then
                env.info("UGLY: Adding new config for: " .. nextAirfieldName)

                local airfieldConf = {}

                local atisFreq = 0
                if tonumber(nextAirfieldConf ["ATIS"]) ~= nil then
                    atisFreq = tonumber(nextAirfieldConf ["ATIS"]) / 1000
                end
                local towerAFreq = 0
                if tonumber(nextAirfieldConf ["Primär"]) ~= nil then
                    towerAFreq = tonumber(nextAirfieldConf ["Primär"]) / 1000
                end
                local towerBFreq = 0
                if tonumber(nextAirfieldConf ["Sekundär"]) ~= nil then
                    towerBFreq = tonumber(nextAirfieldConf ["Sekundär"]) / 1000
                end

                local tacanFreq = ""
                if nextAirfieldConf ["TACAN"] ~= nil then
                    tacanFreq = string.gsub(nextAirfieldConf ["TACAN"], "X", "")
                end

                airfieldConf["ATISFreq"] = atisFreq
                env.info("UGLY: ATISFreq: " .. tostring(atisFreq))
                airfieldConf["TowerFreqA"] = towerAFreq
                env.info("UGLY: TowerFreqA: " .. tostring(towerAFreq))
                airfieldConf["TowerFreqB"] = towerBFreq
                env.info("UGLY: TowerFreqB: " .. tostring(towerBFreq))
                airfieldConf["Tacan"] = tacanFreq
                env.info("UGLY: Tacan: " .. tacanFreq)

                AutoAtisConf[nextAirfieldName] = airfieldConf
            end

            -- TODO: Check for new runway with different ILS
        end

        for k = 1, #coalitions do
            local airbaseMap = coalition.getAirbases(coalitions[k])
            for i=1, #airbaseMap do
                env.info("UGLY: Adding objects to coalition: " .. coalitions[k])

                if AutoAtisConf[airbaseMap[i]:getName()] ~= nil then
                    env.info("UGLY: Adding object to airfield: " .. airbaseMap[i]:getName())

                    local GroupObject = GROUP:FindByName( "ATIS " .. airbaseMap[i]:getName() )
                    if GroupObject == nil then
                        AutoATIS.CreateAtisObjectForAirbase(airbaseMap[i]:getName(), coalitions[k])
                    else
                        env.info("UGLY: Group exists - reusing: " .. airbaseMap[i]:getName())
                    end
                    
                    AutoATIS.AddAtis(airbaseMap[i]:getName(), AutoAtisConf[airbaseMap[i]:getName()])
                else
                    env.info("UGLY: No frequencies for: " .. airbaseMap[i]:getName())
                end
            end
        end
    else
        env.info("Atis data not injected")
    end
end  
  
--local checkNumber = 0
AutoATIS.startMapAfterMoose = function (argument, time)

--    trigger.action.outText("AutoATIS is waiting for Moose to be loaded...", 2)
    if UglyStartAtis == nil then
        env.info("AutoATIS is configured to be off...")
        return 0
    else
        env.info("AutoATIS is configured to be on, so wating for Moose to be loaded...")
    end


    if ENUMS == nil then
--        trigger.action.outText("AutoATIS is waiting for Moose to be loaded...", 1)
        env.info("AutoATIS is waiting for Moose to be loaded...")
    else
        trigger.action.outText("Moose is loaded - Starting AutoATIS", 5)
        env.info("Moose is loaded - Starting AutoATIS")
        AutoATIS.injectAtisToMap()

        return 0
    end

--    trigger.action.outText("debugTestPrint checkNumber: "..checkNumber, 3)
--    checkNumber = checkNumber + 1

    return time + 5
end

timer.scheduleFunction(AutoATIS.startMapAfterMoose, {}, timer.getTime() + 10)


-----------------------------------------------------------------------------------------
-- Leftovers

--[[
if env.mission.theatre == "Caucasus" then
    local tTbl = {}
    for tName, tData in pairs(CaucasusTowns) do
        tTbl[#tTbl+1] = tData
    end
    AutoATIS.TerrainDb["towns"] = tTbl
    CaucasusTowns = nil
elseif env.mission.theatre == "Nevada" then
    local tTbl = {}
    for tName, tData in pairs(NevadaTowns) do
        tTbl[#tTbl+1] = tData
    end
    AutoATIS.TerrainDb["towns"] = tTbl
    NevadaTowns = nil
elseif env.mission.theatre == "Normandy" then
    local tTbl = {}
    for tName, tData in pairs(NormandyTowns) do
        tTbl[#tTbl+1] = tData
    end
    AutoATIS.TerrainDb["towns"] = tTbl
    NormandyTowns = nil
elseif env.mission.theatre == "PersianGulf" then
    local tTbl = {}
    for tName, tData in pairs(PersianGulfTowns) do
        tTbl[#tTbl+1] = tData
    end
    AutoATIS.TerrainDb["towns"] = tTbl
    PersianGulfTowns = nil
elseif env.mission.theatre == "TheChannel" then
    local tTbl = {}
    for tName, tData in pairs(TheChannelTowns) do
        tTbl[#tTbl+1] = tData
    end
    AutoATIS.TerrainDb["towns"] = tTbl
    TheChannelTowns = nil
elseif env.mission.theatre == "Syria" then
    local tTbl = {}
    for tName, tData in pairs(SyriaTowns) do
        tTbl[#tTbl+1] = tData
    end
    AutoATIS.TerrainDb["towns"] = tTbl
    SyriaTowns = nil
else
    env.error(("AutoATIS, no theater identified: halting everything"))
    return
end
]]--


--[[
AutoATIS.AtisConf = {}
AutoATIS.AtisConf["Batumi"] = {}
AutoATIS.AtisConf["Batumi"]["ATISFreq"] = 260.15
AutoATIS.AtisConf["Batumi"]["TowerFreqA"] = 260.100
AutoATIS.AtisConf["Batumi"]["TowerFreqB"] = 131.100
AutoATIS.AtisConf["Batumi"]["Tacan"] = 16
AutoATIS.AtisConf["Batumi"]["Runway"] = {}
AutoATIS.AtisConf["Batumi"]["Runway"]["9"]["Heading"] = 9
AutoATIS.AtisConf["Batumi"]["Runway"]["9"]["ILS"] = 123.4
AutoATIS.AtisConf["Batumi"]["Runway"]["27"]["Heading"] = 27
AutoATIS.AtisConf["Batumi"]["Runway"]["27"]["ILS"] = 123.5


AtisConfigFreq:
  "Abu Al-Duhur 09": {
    "Map-Spezifisch": "Syria",
    "TACAN": "´",
    "I(C)LS": "´",
    "Primär": 136200,
    "Sekundär": 230800,
    "ATIS": 230850,
    "Runway": "09",
    "DCS-AirfieldName": "Abu al-Duhur",
    "MagVar": 5,
    "Comments": "",
    "KI ATC UHF": 250350,
    "KI ATC VHF": 122200,
    "Land": "Syrien"
  }

]]
