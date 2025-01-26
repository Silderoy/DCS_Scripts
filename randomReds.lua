--[[
Script created by Silderoy.
Version: 1
Forum post: https://forum.dcs.world/topic/365777-dynamic-ai-interceptors-script/
--]]

local numAirborneJets = 0 -- Counter for active jets (or total active aircraft if not differentiating)
local numAirborneHelicopters = 0 -- Counter for active helicopters
local activeUnits = {}
local redGroups = {}

removeFromList = {}

-- Default values
local DEFAULT_RAND_MIN = 60 -- 1 minute
local DEFAULT_RAND_MAX = 300 -- 5 minutes
local DEFAULT_FIRST_SPAWN = 300 -- 5 minutes

local function groupComp(group)
	local jetNum = 0
	local HeloNum = 0
	for i, unit in pairs(group:getUnits()) do
        if unit:getCategoryEx() == 1 then
			HeloNum = HeloNum + 1
		else
			jetNum = jetNum + 1
		end
	end
	return {jetNum, HeloNum}
end

-- Remove the activated group from the list and add to activeUnits
local function updateTables(actGroup, index)
	for i, unit in pairs(actGroup:getUnits()) do
		table.insert(activeUnits, unit)
	end
	table.remove(redGroups, index)
end

-- Function to activate a group
function activateGroup(group, maxJets, maxHelicopters, index)
    if group and group:isExist() then
		-- calculate amount of players online
		local redPlayers = coalition.getPlayers(1)
		local bluePlayers = coalition.getPlayers(2)
		maxJets = maxJets or (#bluePlayers - #redPlayers)
        if maxHelicopters then
            -- Differentiated mode
			local comp = groupComp(group)
			if ((numAirborneHelicopters + comp[2]) <= maxHelicopters) and ((numAirborneJets + comp[1]) <= maxJets) then
				group:activate()
				numAirborneJets = numAirborneJets + comp[1]
                numAirborneHelicopters = numAirborneHelicopters + comp[2]
				updateTables(group, index)
				return
            end
        else
            -- Non-differentiated mode
            local size = group:getSize()
			if numAirborneJets + size <= maxJets then
                group:activate()
                numAirborneJets = numAirborneJets + size
				updateTables(group, index)
				return
            end
		end
    end
end

-- Recursive function to schedule spawns
function scheduleSpawn(redGroups, maxJets, maxHelicopters, randMin, randMax)
    -- Check if there are groups left to activate
    if #redGroups > 0 then
        -- Select a random group from the list
        local randomIndex = math.random(#redGroups)
        local selectedGroup = Group.getByName(redGroups[randomIndex])
        -- Activate the group if constraints allow
        activateGroup(selectedGroup, maxJets, maxHelicopters, randomIndex)
    end

    -- If there are still groups left, schedule the next spawn
    if #redGroups > 0 then
        local nextInterval = math.random(randMin, randMax)
        timer.scheduleFunction(function()
			scheduleSpawn(redGroups, maxJets, maxHelicopters, randMin, randMax)
			end, {}, timer.getTime() + nextInterval)
    else
		return
	end
end

-- Main function
function randomReds(groups, maxJets, maxHelicopters,firstSpawn, randMin, randMax)
    -- Apply defaults if randMin or randMax are not provided
	randMin = randMin or DEFAULT_RAND_MIN
    randMax = randMax or DEFAULT_RAND_MAX
	firstSpawn = firstSpawn or DEFAULT_FIRST_SPAWN
	redGroups = groups

    -- Validate input
    if type(groups) ~= "table" or #groups == 0 then
        env.error("randomReds: groups must be a non-empty table")
        return
    end
    if maxJets and maxJets ~= '' and (type(maxJets) ~= "number" or maxJets <= 0) then
        env.error("randomReds: maxJets must be a number greater than 0")
        return
    end
    if randMin > randMax then
        env.error("randomReds: randMin must be less than or equal to randMax")
		randMin = DEFAULT_RAND_MIN
		randMax = DEFAULT_RAND_MAX
    end
	world.addEventHandler(removeFromList) -- start counting airborne reds
    -- Start the spawning process
	timer.scheduleFunction(function()
		scheduleSpawn(redGroups, maxJets, maxHelicopters, randMin, randMax)
        end,{}, timer.getTime() + firstSpawn)
end

function removeFromList:onEvent(event)
	if event.id == 8 or event.id == 30 then
		for i,unit in pairs(activeUnits) do
			if unit == event.initiator then
				if unit:getCategoryEx() == 1 then
					numAirborneHelicopters = numAirborneHelicopters - 1
				else
					numAirborneJets = numAirborneJets - 1
				end
				table.remove(activeUnits,i)
			end
		end
	end
end

env.info("RandomReds Initiated")