local _, e = ...

if not AstralAffixes then 
	AstralAffixes = {}
end
--[[
	AstralAffixes[1] = 0
	AstralAffixes[2] = 0
	AstralAffixes[3] = 0
end
]]

local GRAY = 'ff9d9d9d'
local PURPLE = 'ffa335ee'

--local mapID, keyLevel, usable, a1, a2, a3, s, itemID, delink, link

local init = false

e.RegisterEvent('CHALLENGE_MODE_MAPS_UPDATE', function()
	if UnitLevel('player') ~= 110 then return end
	e.GetBestClear()
 	if not init then
 		e.UpdateGuildList()
 		e.FindKeyStone(true)
 		e.BuildMapTable()
 		SendAddonMessage('AstralKeys', 'request', 'GUILD')
 		init = true
 	end
 end)

e.RegisterEvent('CHALLENGE_MODE_START', function()
	--print('this shit started')
	e.RegisterEvent('BAG_UPDATE', function() 
		--STUFF
		end)

	end)

e.RegisterEvent('BAG_UPDATE', function(...)
	--e.FindKeyStone(true, true)
	end)

function e.CreateKeyLink(index)
	local s = '|c'
	local mapID, keyLevel, usable, a1, a2, a3 = AstralKeys[index].map, AstralKeys[index].level, AstralKeys[index].usable, AstralKeys[index].a1, AstralKeys[index].a2, AstralKeys[index].a3

	if tonumber(usable) == 1 then
		s = s .. PURPLE
	else
		s = s .. GRAY
	end

	s = s .. '|Hkeystone:' .. mapID .. ':' .. keyLevel .. ':' .. usable .. ':' .. a1 .. ':' .. a2 .. ':' .. a3 .. '|h[Keystone: ' .. e.GetMapName(mapID) .. ']|h|r'
	s = s:gsub('\124\124', '\124')

	return s, keyLevel
end

e.RegisterEvent('CHALLENGE_MODE_NEW_RECORD', function()
	e.GetBestClear()
	e.UpdateCharacterFrames()
	end)


function e.SetAffix(affixNumber, affixID)
	AstralAffixes[affixNumber] = affixID
end

function e.GetAffix(affixNumber)
	return AstralAffixes[affixNumber]
end

function e.FindKeyStone(sendUpdate, anounceKey)
	local s, itemID, delink, link
	local s = ''

	for bag = 0, NUM_BAG_SLOTS + 1 do
		for slot = 1, GetContainerNumSlots(bag) do
			itemID = GetContainerItemID(bag, slot)
			if (itemID and itemID == 138019) then
				link = GetContainerItemLink(bag, slot)
				delink = link:gsub('\124', '\124\124')
				local mapID, keyLevel, usable, a1, a2, a3 = delink:match(':(%d+):(%d+):(%d+):(%d+):(%d+):(%d+)')
				s = 'updateV1 ' .. e.PlayerName() .. ':' .. e.PlayerClass() .. ':' .. e.PlayerRealm() ..':' .. mapID .. ':' .. keyLevel .. ':' .. usable .. ':' .. a1 .. ':' .. a2 .. ':' .. a3
				--s = 'updateV1 CHARACTERSAZ:DEMONHUNTER:Bleeding Hollow:201:22:1:13:13:10'				
			end
		end
	end

	if not link then 
		e.RegisterEvent('CHAT_MSG_LOOT', function(...)
			--print('registering event to find key')

		local msg = ...
		local sender = select(5, ...) -- Should return unit that looted
		if not sender == e.PlayerName() then return end
		--if not msg:find('You') then return end

		if msg:find('Keystone') then
			--print('loot event fired to find it')
			e.FindKeyStone(true, true)
			e.UnregisterEvent('CHAT_MSG_LOOT')
		end

		end)
	end
--[[
	e.RegisterEvent('BAG_UPDATE', function()
		e.FindKeyStone(true, true)
		print('bag update fired to find it')
		end)
]]
	local oldMap, oldLevel, oldUsable = e.GetUnitKey(e.PlayerID())

	if tonumber(oldMap) == tonumber(mapID) and tonumber(oldLevel) == tonumber(keyLevel) and tonumber(oldUsable) == tonumber(usable) then return end

	if sendUpdate  and s ~= '' then
		if IsInGuild() then
			SendAddonMessage('AstralKeys', s, 'GUILD')
		else
			AstralKeys[#AstralKeys + 1] = {
			['name'] = e.PlayerName(),
			['class'] = e.PlayerClass(),
			['realm'] = e.PlayerRealm(),
			['map'] = tonumber(mapID),
			['level'] = tonumber(keyLevel),
			['usable'] = tonumber(usable),
			['a1'] = tonumber(a1),
			['a2'] = tonumber(a2),
			['a3'] = tonumber(a3),
			}
		end
	end

	if anounceKey and link then
		e.AnnounceNewKey(link, keyLevel)
	end

end

function e.GetKeyLevelByIndex(index)
	return AstralKeys[index].keyLevel
end

local function CreateKeyText(mapID, level, usable)
	if not isDepleted then
		return level .. ' ' .. C_ChallengeMode.GetMapInfo(mapID)
	else
		if tonumber(isDepleted) == 0 then
			return WrapTextInColorCode(level .. ' ' .. C_ChallengeMode.GetMapInfo(mapID), 'ff9d9d9d')
		else
			return level .. ' ' .. C_ChallengeMode.GetMapInfo(mapID)
		end
	end
end

function e.GetUnitKey(id)
	if not id then return '' end

	return AstralKeys[id]['map'], AstralKeys[id]['level'], AstralKeys[id]['usable']
end

function e.GetCharacterKey(unit)
	if not unit then return '' end

	for i = 1, #AstralKeys do
		if AstralKeys[i].name == unit then
			return CreateKeyText(AstralKeys[i].map, AstralKeys[i].level, AstralKeys[i].usable)
		end
	end

	return WrapTextInColorCode('No key found.', 'ff9d9d9d')

end

function e.GetBestKey(id)
	return AstralCharacters[id].level
end

function e.GetBestMap(unit)

	for i = 1, #AstralCharacters do
		if AstralCharacters[i].name == unit then
			if AstralCharacters[i].map ~= 0 then
				return e.GetMapName(AstralCharacters[i].map)
			end
		end
	end
	
	return 'No mythic+ ran this week.'
end

--Returns map ID and keystone level run for current week
local bestLevel, bestMap, weeklyBestLevel
function e.GetBestClear()
	if UnitLevel('player') ~= 110 then return end
	local bestLevel = 0
	local bestMap = 0
	for _, v in pairs(C_ChallengeMode.GetMapTable()) do
		_, _, weeklyBestLevel = C_ChallengeMode.GetMapPlayerStats(v)
		if weeklyBestLevel then
			if weeklyBestLevel > bestLevel then
				bestLevel = weeklyBestLevel
				bestMap = v
			end
		end
	end

	if #AstralCharacters == 0 then
		table.insert(AstralCharacters, {name = e.PlayerName(), class = e.PlayerClass(), realm = e.PlayerRealm(), map = bestMap, level = bestLevel, knowledge = e.GetAKBonus(e.ParseAKLevel())})
	end

	local index = -1
	for i = 1, #AstralCharacters do
		if AstralCharacters[i]['name'] == e.PlayerName() and AstralCharacters[i].realm == e.PlayerRealm() then
			AstralCharacters[i].map = bestMap
			AstralCharacters[i].level = bestLevel
			index = i
		end
	end

	if index == -1 then
		table.insert(AstralCharacters, {name = e.PlayerName(), class = e.PlayerClass(), realm = e.PlayerRealm(), map = bestMap, level = bestLevel, knowledge = e.GetAKBonus(e.ParseAKLevel())})
	end
end