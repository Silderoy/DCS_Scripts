--[[
Script created by Silderoy.
Version: 1.1
Forum post: https://forum.dcs.world/topic/365777-dynamic-ai-interceptors-script/

Changelog:
	added:
		check for combat ineffective units and remove landed or retreating units from the count.
		The option to activate the script on either coalition.
		Auto-recognition of editor groups based on name format so you don't have to give it all of the groups.

improvements:
	Auto-creation of groups from random/defined coalition bases, with preset/custom unit types.
--]]

local numAirborneJets = 0 -- Counter for active jets (or total active aircraft if not differentiating)
local numAirborneHelicopters = 0 -- Counter for active helicopters
local activeUnits = {}
local badGroups = {}
local events = {}
local debug = false
removeFromList = {}

-- Default values
local DEFAULT_RAND_MIN = 60 -- 1 minute
local DEFAULT_RAND_MAX = 300 -- 5 minutes
local DEFAULT_FIRST_SPAWN = 300 -- 5 minutes
local checkInterval = 60

local function make_set(array)
    local set = {}
    for _, val in ipairs(array) do
        set[val] = true
    end
    return set
end

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

local function CombatEffective()
	if debug then trigger.action.outText('RandomReds: checking combat effectiveness', 10) end
	if #activeUnits > 0 then
		for i,unit in pairs(activeUnits) do
			local real = false
			if unit then
				if not (unit:getController():hasTask() or unit:getGroup():getController():hasTask()) then
					if debug then trigger.action.outText('RandomReds: '..unit:getName()..' has no task.', 10) end
					real = true
				else
					if debug then trigger.action.outText('RandomReds: '..unit:getName()..' has a task.', 10) end
				end
			end
			if real then
				if unit:getCategoryEx() == 1 then
					numAirborneHelicopters = numAirborneHelicopters - 1
				else
					numAirborneJets = numAirborneJets - 1
				end
				table.remove(activeUnits,i)
				if debug then trigger.action.outText('RandomReds: '..unit:getName()..' is retreating\nThere are '..numAirborneHelicopters..' Helicopters and '..numAirborneJets..' Jets airborne', 10) end
			end
		end
		timer.scheduleFunction(function()
			CombatEffective()
			end,{}, timer.getTime() + checkInterval)
	elseif #badGroups > 0 then
		if debug then trigger.action.outText('RandomReds: No active units remaining but there are alert groups. skipping test.', 10) end
		timer.scheduleFunction(function()
			CombatEffective()
			end,{}, timer.getTime() + checkInterval)
	else
		if debug then trigger.action.outText('RandomReds: No groups remaining, shutting down.', 10) end
	end
end

-- Remove the activated group from the list and add to activeUnits
local function updateTables(actGroup, index)
	for i, unit in pairs(actGroup:getUnits()) do
		table.insert(activeUnits, unit)
		local name = unit:getName()
		if debug then trigger.action.outText('RandomReds: '..name..' changed to active status', 10) end
	end
	table.remove(badGroups, index)
	local grpName = actGroup:getName()
	if debug then trigger.action.outText('RandomReds: '..grpName..' removed from alert status', 10) end
end

-- Function to activate a group
function activateGroup(group, maxJets, maxHelicopters, index, relative)
    if group and group:isExist() then
		local comp = groupComp(group)
		if relative[1] ~= '' then
			-- calculate amount of players online
			local redPlayers = coalition.getPlayers(1)
			local bluePlayers = coalition.getPlayers(2)
			local playerCount = #bluePlayers - #redPlayers
			if playerCount < 0 then
				playerCount = -playerCount
			end
			if relative[1] == 'percent' then
				maxJets = relative[2] * playerCount
			else
				maxJets = relative[2] + playerCount
			end
		end
		if debug then trigger.action.outText('RandomReds: maxJets: '..maxJets..', maxHelicopters: '..maxHelicopters..'\nThere are '..numAirborneJets..' Jets and '..numAirborneHelicopters..' Helicopters airborne\nSelected group contains '..comp[1]..' Jets and '..comp[2]..' Helicopters', 10) end
		if maxHelicopters ~= 0 then
            -- Differentiated mode
			if ((numAirborneHelicopters + comp[2]) > maxHelicopters) or ((numAirborneJets + comp[1]) > maxJets) then
				if debug then trigger.action.outText('RandomReds: There are too many airborne aircraft, spawn canceled <Differentiated>', 10) end
				return
            end
        else
            -- Non-differentiated mode
			if (numAirborneJets + numAirborneHelicopters + comp[1] + comp[2]) > maxJets then
				if debug then trigger.action.outText('RandomReds: There are too many airborne aircraft, spawn canceled <Non-differentiated>', 10) end
				return
            end
		end
		group:activate()
		numAirborneJets = numAirborneJets + comp[1]
		numAirborneHelicopters = numAirborneHelicopters + comp[2]
		updateTables(group, index)
		if debug then trigger.action.outText('RandomReds: group '..group:getName()..' activated!', 10) end
	else
		if debug then trigger.action.outText('RandomReds: error activating group', 10) end
    end
end

-- Recursive function to schedule spawns
function scheduleSpawn(badGroups, maxJets, maxHelicopters, randMin, randMax, relative)
    -- Check if there are groups left to activate
    if #badGroups > 0 then
		if debug then trigger.action.outText('RandomReds: There are '..#badGroups..' groups on alert!', 10) end
        -- Select a random group from the list
        local randomIndex = math.random(#badGroups)
        local selectedGroup = Group.getByName(badGroups[randomIndex])
		if debug then trigger.action.outText('RandomReds: Activating group: '..badGroups[randomIndex], 10) end
        -- Activate the group if constraints allow
        activateGroup(selectedGroup, maxJets, maxHelicopters, randomIndex, relative)
    end

    -- If there are still groups left, schedule the next spawn
    if #badGroups > 0 then
        local nextInterval = math.random(randMin, randMax)
		if debug then trigger.action.outText('RandomReds: Next group activated in '..nextInterval..' seconds', 10) end
        timer.scheduleFunction(function()
			scheduleSpawn(badGroups, maxJets, maxHelicopters, randMin, randMax, relative)
			end, {}, timer.getTime() + nextInterval)
    else
		world.removeEventHandler(removeFromList)
		if debug then trigger.action.outText('RandomReds: No alert groups remaining!', 10) end
		return
	end
end

function removeFromList:onEvent(event)
	local id = event.id
	if events[id] then
		for i,unit in pairs(activeUnits) do
			local name = unit:getName()
			if unit == event.initiator then
				if unit:getCategoryEx() == 1 then
					numAirborneHelicopters = numAirborneHelicopters - 1
				else
					numAirborneJets = numAirborneJets - 1
				end
				table.remove(activeUnits,i)
				if debug then
					if event.id == 38 then
						trigger.action.outText('RandomReds: '..name..' aborted mission', 10)
					elseif (event.id == 4) or (event.id == 55) then
						trigger.action.outText('RandomReds: '..name..' landed', 10)
					elseif (event.id == 5) or (event.id == 6) or (event.id == 8) or (event.id == 30)or (event.id == 9) then
						trigger.action.outText('RandomReds: '..name..' died', 10)
					end
					trigger.action.outText('RandomReds: There are '..numAirborneHelicopters..' Helicopters and '..numAirborneJets..' Jets airborne', 10)
				end
			end
		end
	end
end

-- Main function
function randomReds(groups, maxJets, maxHelicopters,firstSpawn, randMin, randMax)
	if debug then trigger.action.outText('RandomReds Called', 10) end
	env.info("RandomReds Called")
	-- Apply defaults
	randMin = randMin or DEFAULT_RAND_MIN
	randMax = randMax or DEFAULT_RAND_MAX
	firstSpawn = firstSpawn or DEFAULT_FIRST_SPAWN
	
	-- Validate input
	local relative = {'',1}
	local playerCount = 0
	if (not maxJets) or maxJets == 0 or type(maxJets) ~= 'number' then
		local redPlayers = coalition.getPlayers(1)
		local bluePlayers = coalition.getPlayers(2)
		local playerCount = #bluePlayers - #redPlayers
		if playerCount < 0 then
			playerCount = -playerCount
		end
		if type(maxJets) == 'string' then
			if string.find(maxJets,'%%') then
				env.info("randomReds: maxJets using relative percentage")
				relative = {'percent',(string.gsub(maxJets,'%%','') / 100 + 1)}
				maxJets = relative[2] * playerCount
			elseif string.find(maxJets,'%-') then
				env.info("randomReds: maxJets using negative relative linear")
				relative = {'linear',(-(string.gsub(maxJets,'%-','')))}
				maxJets = relative[2] + playerCount
			elseif string.find(maxJets,'%+') then
				env.info("randomReds: maxJets using positive relative linear")
				relative = {'linear',(string.gsub(maxJets,'%+','') + 0)}
				maxJets = relative[2] + playerCount
			else
				maxJets = maxJets + 0
			end
		else
			env.error("randomReds: maxJets invalid, using player count")
			maxJets = playerCount
		end
	end
	if (not maxHelicopters) or type(maxHelicopters) ~= "number" then
		maxHelicopters = 0
	elseif maxHelicopters < 0 then
		maxHelicopters = -maxHelicopters
	end
	if randMin > randMax then
		env.error("RandomReds: randMin must be less than or equal to randMax")
		if debug then trigger.action.outText('RandomReds: randMin must be less than or equal to randMax', 10) end
		randMin = DEFAULT_RAND_MIN
		randMax = DEFAULT_RAND_MAX
	end
	if (type(groups) == "table" and #groups > 0) then
		badGroups = groups
		if debug then trigger.action.outText('RandomReds: provided group list recognized. Number of groups: '..#badGroups, 10) end
	elseif (type(groups) == "string" and groups ~= '') then
		for id=0,2 do
			for _, grp in pairs(coalition.getGroups(id)) do
				local name = Group.getName(grp)
				if string.find(name, groups) then
					table.insert(badGroups, name)
				end
			end
		end
		if debug then trigger.action.outText('RandomReds: group prefix recognized, Number of groups: '..#badGroups, 10) end
	else
		env.error("RandomReds: groups must be a non-empty table or a string")
		if debug then trigger.action.outText('RandomReds: groups must be a non-empty table or a string', 10) end
		return
	end
	if debug then trigger.action.outText('Number of groups: '..#groups..'\nmaxJets = '..maxJets..'\nmaxHelicopters = '..maxHelicopters..'\nFirst spawn in = '..firstSpawn..'\nMin interval = '..randMin..'\nMax interval = '..randMax, 20) end
	
	-- Start the spawning process
	timer.scheduleFunction(function()
		scheduleSpawn(badGroups, maxJets, maxHelicopters, randMin, randMax, relative, playerCount)
		end,{}, timer.getTime() + firstSpawn)
		
	-- Start checking combat effectiveness
	events = make_set{4, 5, 6, 8, 30, 38, 55, 9}
	world.addEventHandler(removeFromList)
	timer.scheduleFunction(function()
		CombatEffective()
		end,{}, timer.getTime() + checkInterval)
end

function randomRedsDebug(groups, maxJets, maxHelicopters,firstSpawn, randMin, randMax)
	debug = true
	randomReds(groups, maxJets, maxHelicopters,firstSpawn, randMin, randMax)
end

env.info("RandomReds Initiated")
