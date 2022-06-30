local Argparse = require('argparse')
local json = require('dkjson')

local parser = Argparse('rotate', 'Automatically rotate the weekly dealer')
parser:flag('-d --dry-run', "Don't upload")
parser:option('-s --seed', 'Set the seed for the RNG')
local args = parser:parse({ ... })

local seed = args.seed and tonumber(args.seed) or tonumber(os.date('%Y%m%d'))
math.randomseed(seed)

print(string.format('---\nSEED    : %s\nDRY RUN : %s\n--', seed, args.dry_run and 'Yes' or 'No'))

local function discount(multi, ships)
  for _, ship in ipairs(ships) do
    ship[2] = math.ceil((ship[2] * multi) / 1000) * 1000
  end
  return ships
end

local prices = {}

prices.Battlecruiser = discount(.7, {
  { 'Tengu', 8401 },
  { 'Vansnova', 8928 },
  { 'Marauder', 12010 },
  { 'Valiant', 13686 },
  { 'Vigilance', 14671 },
  { 'Razor Wing', 14840 },
  { 'Belvat', 14950 },
  { 'Radiance', 16584 },
  { 'Mjolnheimr', 17904 },
  { 'MRLS Launcher', 18170 },
  { 'Black Flare', 20678 },
  { 'Bastion', 23815 },
  { 'Absolution', 23917 },
  { 'Dire Wolf', 24188 },
  { 'Sturm', 24725 },
  { 'Grievion', 25487 },
  { 'Hyron', 26725 }
})

prices.Battleship = discount(.7, {
  { 'Prowler', 17850 },
  { 'Warden', 23101 },
  { 'Legionnaire', 33341 },
  { 'Hasatan', 33525 },
  { 'Sovereign', 33889 },
  { 'Hawklight', 33917 },
  { 'Cutlass', 35396 },
  { 'Katana', 35799 },
  { 'Witch', 43047 },
  { 'Genesis', 45089 },
  { 'Warlock', 47915 },
  { 'Carvainir', 49067 },
  { 'Jackal', 51436 },
  { 'Nisos', 52152 },
  { 'Consul', 53871 },
  { 'Ampharos', 56222 },
  { 'Loyalist', 59840 },
  { 'Aegis', 65022 },
  { 'Archeon', 66268 }
})

prices.Dreadnought = discount(.7, {
  { 'Armageddon', 88136 },
  { 'Nemesis', 95916 },
  { 'Tennhausen', 101549 },
  { 'Retribution', 110695 },
  { 'Catalyst', 118478 },
  { 'Apocalypse', 121712 },
  { 'Behemoth', 121881 },
  { 'Ridgebreaker', 129576 },
  { 'Sagittarius', 132319 },
  { 'Avalon', 136393 },
  { 'Cyclops', 153664 },
  { 'Judgement', 185058 },
  { 'Zeus', 186271 },
  { 'Naglfar', 190731 },
  { 'Leviathan', 192148 },
  { 'Tempest', 211037 }
})

prices.Carrier = discount(.7, {
  { 'Hevnetier', 233005 },
  { 'Stormbringer', 239396 },
  { 'Vanguard', 241213 },
  { 'Borealis', 241819 },
  { 'Nyx', 266906 },
  { 'Nimitz', 272119 },
  { 'Rapture', 273104 },
  { 'Executioner', 287746 },
  { 'Prometheus', 293933 }
})

local assetId = require('folders').quests

local questsFolder = remodel.readModelAsset(assetId)[1]

-- https://devforum.roblox.com/t/why-does-this-format-thousands-function-not-format-correctly-with-millions/267812/2
local function comma_value(n) -- credit http://richard.warburton.it
	local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
	return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
end

local function pluralize(noun)
  local lastLetter = string.lower(string.sub(noun, #noun))
  if lastLetter == 's' or lastLetter == 'h' then
    return noun .. 'es'
  else
    return noun .. 's'
  end
end

local function wait(sec)
  local start = os.clock()
  while os.clock() - start <= sec do end
end

local randomMessagesUsed = {}
local function isUsed(message)
  for _, used in ipairs(randomMessagesUsed) do
    if message == used then return true end
  end
  return false
end
local function randomMessage(messages)
  return function(...)
    local rawArgs = {...}
    local processedArgs = {}
    local message
    while true do
      message = messages[math.random(1, #messages)]
      if not isUsed(message) then break end
    end

    for i, arg in ipairs(rawArgs) do
      if message[i + 1] then
        table.insert(processedArgs, pluralize(arg))
      else
        table.insert(processedArgs, arg)
      end
    end

    return string.format(message[1], table.unpack(processedArgs))
  end
end

local function makeQuest(id, ship, price)
  local quest = questsFolder[id]

  local thisWeekMessage = randomMessage({
    {'This week, I have %s available.', true},
    {'This week, I\'m selling %s.', true},
    {'I have %s this week.', true},
    {'I can get you a %s this week.'}
  })

  local priceMessage = randomMessage({
    {'It will cost you %s credits.'},
    {'%s credits.'},
    {'I\'ll give it to you for %s credits.'},
    {'You can have it for %s credits.'}
  })

  local thisWeek = thisWeekMessage(ship)
  local priceText = priceMessage(comma_value(price))

  print(id, thisWeek, priceText)

  remodel.setRawProperty(quest.Rewards.Ship, 'Value', 'String', ship)
  remodel.setRawProperty(quest.Objectives.Credits, 'Value', 'Int64', price)
  remodel.setRawProperty(quest.Dialog.DialogChoice, 'ResponseDialog', 'String', thisWeek)
  remodel.setRawProperty(quest.Dialog.DialogChoice.DialogChoice, 'ResponseDialog', 'String', priceText)
  remodel.setRawProperty(quest.Dialog.DialogChoice.DialogChoice.Accept, 'ResponseDialog', 'String', string.format('Make sure you don\'t have a %s already, or I will take your credits without compensation.', ship))
  remodel.setRawProperty(quest.Description, 'Value', 'String', string.format('Give the Weekly Dealer %s credits to obtain the discounted %s. Do not complete this quest if you already have a %s.', comma_value(price), ship, ship))
  remodel.setRawProperty(quest.Accept.CreateDialog.Dialog, 'InitialPrompt', 'String', string.format('Ready to receive your %s?', ship))
end

local carrier = prices.Carrier[math.random(1, #prices.Carrier)]
local dreadnought = prices.Dreadnought[math.random(1, #prices.Dreadnought)]
local battleship = prices.Battleship[math.random(1, #prices.Battleship)]
local battlecruiser = prices.Battlecruiser[math.random(1, #prices.Battlecruiser)]
makeQuest('77', table.unpack(carrier))
makeQuest('79', table.unpack(dreadnought))
makeQuest('78', table.unpack(battleship))
makeQuest('76', table.unpack(battlecruiser))

if args.dry_run then return end

local uploadDelay = 15
while true do
  local success, e = pcall(function()
    remodel.writeExistingModelAsset(questsFolder, assetId)
  end)
  if success then break end
  uploadDelay = uploadDelay * 2
  print('Quests upload failed. Waiting ' .. tostring(uploadDelay) .. ' seconds.', e)
  wait(uploadDelay)
end
local worked = pcall(function()
  remodel.readModelAsset(assetId)
end)
if not worked then
  print('Quests corrupted')
  return
end
print('Uploaded Quests')
print('wh!' .. json.encode({
  username = 'Weekly Dealer',
  content = string.format('-- Updated Weekly Dealer inventory.\n\nCarrier: %s\nDreadnought: %s\nBattleship: %s\nBattlecruiser: %s', carrier[1], dreadnought[1], battleship[1], battlecruiser[1])
}))
