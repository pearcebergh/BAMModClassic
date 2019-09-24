-- BÄM Mod Classic by Sneep <Goon Squad> Herod

local BamModClassic_DefaultConfig = {
  EnableBamMod = true,
  CritString = "BÄM!! [{action} - {damage}]",
  OutputChannel = "YELL",
  OutputChannelNumber = 1,
  MeleeReplaceString = "Melee"
}

BamModClassic_Config = nil

BamModClassic_Events = {
  EventHandlers = {}
}

BamModClassic_SlashFunctions = {
  SlashFunctions = {},
  SlashHelp = {
    enable = {
      desc = "Enables BÄM Mod crit announces.",
      help = "",
      usage = ""
    },
    disable = {
      desc = "Disables BÄM Mod crit announces.",
      help = "",
      usage = ""
    },
    toggle = {
      desc = "Toggles on/off BÄM Mod crit announces.",
      help = "",
      usage = ""
    },
    message = {
      desc = "Sets the message to send on BÄM Mod crit announces.",
      help = "Enter your entire message to send out on a crit. Use the {specifiers} from '/bam specifiers' to swap in data from the attack.",
      usage = "..."
    },
    channel = {
      desc = "Sets channel to output BÄM Mod crit announces.",
      help = "A valid channel either one of the following: SAY YELL PARTY RAID or CHANNEL followed by the channel #. frame is also an option to output to the chatframe instead of a chat channel.",
      usage = "[SAY YELL PARTY RAID CHANNEL frame] [[Channel #]]"
    },
    specifiers = {
      desc = "Lists the string specifiers you can use in your /bam message string to swap in data from the attack.",
      help = "",
      usage = ""
    },
  }
}

local BamModClassic_OutputChannels = {
  "SAY",
  "YELL",
  "PARTY",
  "RAID"
}

local BamModClassic_MessageSpecifiers = {
  "{target}",
  "{action}",
  "{damage}", 
  "{overkill}", 
  "{school}", 
  "{resisted}", 
  "{blocked}", 
  "{absorbed}"
}

local BAMEvents = BamModClassic_Events
local BAMSlash = BamModClassic_SlashFunctions
local playerGUID = UnitGUID("player")

function BAMGenerateMessage(...)
  local arg = {...}
  local generatedMsg = BamModClassic_Config["CritString"]
  -- Replace our message specifiers in our crit strig with our argument values
  for i = 1, #arg do
       generatedMsg = generatedMsg:gsub(BamModClassic_MessageSpecifiers[i], arg[i])
  end
  return generatedMsg
end

function BAMEvents:OnEvent(_, event, ...)
  if self.EventHandlers[event] then
    self.EventHandlers[event](self, ...)
  end
end

function BAMEvents.EventHandlers.ADDON_LOADED(self, addonName, ...)
  if addonName ~= "BamModClassic" then return end

  -- Check if we already have a table saved globally
  if type(_G["BAMMODCLASSIC_CONFIG"]) ~= "table" then
    _G["BAMMODCLASSIC_CONFIG"] = BamModClassic_DefaultConfig
  end

  BamModClassic_Config = _G["BAMMODCLASSIC_CONFIG"]

  -- Add arguments from default config we're missing in our config
  for i,v in pairs(BamModClassic_DefaultConfig) do
    if BamModClassic_Config[i] == nil then
      BamModClassic_Config[i] = BamModClassic_DefaultConfig[i]
    end
  end

  -- Remove arguments from our config that no longer exists in the default config
  for i,v in pairs(BamModClassic_Config) do
    if BamModClassic_DefaultConfig[i] == nil then
      BamModClassic_Config[i] = nil
    end
  end

  BamModClassic_OptionsWindow:Initialize()
end

function BAMEvents.EventHandlers.COMBAT_LOG_EVENT_UNFILTERED(self, ...)
  if (BamModClassic_Config["EnableBamMod"] == true) then
    local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo()
    local spellId, spellName, spellSchool
    local amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, offhand

    if subevent == "SWING_DAMAGE" then
      amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, offhand = select(12, ...)
    elseif subevent == "SPELL_DAMAGE" then
      spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, offhand = select(12, ...)
    end

    if critical then
      if sourceGUID == playerGUID then
        local action = (spellName) or BamModClassic_Config["MeleeReplaceString"]
        chatMessage = BAMGenerateMessage(destName, action, amount, overkill, school, resisted, blocked, absorbed)
        if (BamModClassic_Config["OutputChannel"] == "FRAME") then
          print("BÄM Mod Crit Announce: " .. chatMessage)
        elseif (BamModClassic_Config["OutputChannel"] == "CHANNEL") then
          SendChatMessage(chatMessage, BamModClassic_Config["OutputChannel"], nil, BamModClassic_Config["OutputChannelNumber"])
        else
          SendChatMessage(chatMessage, BamModClassic_Config["OutputChannel"], nil)
        end
      end
    end
  end 
end

function BAMSlash.SlashFunctions.enable(splitCmds)
  print("BÄM Mod Classic Enable")
  BamModClassic_Config["EnableBamMod"] = true
end

function BAMSlash.SlashFunctions.disable(splitCmds)
  print("BÄM Mod Classic Disable")
  BamModClassic_Config["EnableBamMod"] = false
end

function BAMSlash.SlashFunctions.toggle(splitCmds)
  if (BamModClassic_Config["EnableBamMod"] == true) then
    BAMSlash.SlashFunctions.disable(splitCmds)
  else
    BAMSlash.SlashFunctions.enable(splitCmds)
  end
end

function BAMSlash.SlashFunctions.message(splitCmds)
  if (#splitCmds == 1) then
    print("BÄM Mod current crit message: " .. BamModClassic_Config["CritString"])
    return
  end

  local assembledString = ""

  for i,v in pairs(splitCmds) do
    if (i ~= 1) then
      assembledString = assembledString .. " " .. v
    end
  end

  print("Setting BÄM Mod Classic crit announce message to \'" .. assembledString .. '\'')
  BamModClassic_Config["CritString"] = assembledString
end

function BAMSlash.SlashFunctions.channel(splitCmds)
  if (#splitCmds < 2 or (splitCmds[2] == "channel" and #splitCmds < 3)) then
    print("BÄM Mod Classic Error: missing channel argument")
    print("    /bam channel " .. BamModClassic_SlashFunctions.SlashHelp.channel.usage)
    print(BamModClassic_SlashFunctions.SlashHelp.channel.desc)
    print(BamModClassic_SlashFunctions.SlashHelp.channel.help)
    return
  end

  local channelStr = ""
  BamModClassic_Config["OutputChannel"] = splitCmds[2]:upper()
  if (splitCmds[2] == "channel") then
    BamModClassic_Config["OutputChannelNumber"] = splitCmds[3]
    channelStr = splitCmds[3]
  end
  print("BÄM Mod Classic output channel set to " .. BamModClassic_Config["OutputChannel"] .. " " .. channelStr)
end

function BAMSlash.SlashFunctions.specifiers(splitCmds)
  specifierStr = ""
  for i, v in pairs(BamModClassic_MessageSpecifiers) do
    specifierStr = specifierStr .. v .. " "
  end
  print("List of string specifiers: " .. specifierStr)
end

function BAMSlash.SlashFunctions.help(splitCmds)
  print("BÄM Mod Classic list of slash commands:")
  for i, v in pairs(BamModClassic_SlashFunctions.SlashHelp) do
    print("  /bam " .. i .. " " .. v.usage .. "  " .. v.desc)
  end
end

function BAMSlash.SlashFunctions.test(splitCmds)
  print("BÄM Message test:")
  print("    [" .. BamModClassic_Config["OutputChannel"] .. "]: " .. BAMGenerateMessage("Sneep", "Melee", "250", "0", "Melee", "0", "0", "0"))
end

-- Register each event for which we have an event handler.
BAMEvents.Frame = CreateFrame("Frame")
for eventName,_ in pairs(BAMEvents.EventHandlers) do
  BAMEvents.Frame:RegisterEvent(eventName)
end
BAMEvents.Frame:SetScript("OnEvent", function(_, event, ...) BAMEvents:OnEvent(_, event, ...) end)

SLASH_BAM1 = "/bam"
SlashCmdList["BAM"] = function(inArgs)
  if (inArgs:len() ~= 0) then

    splitCmds = {}
    local subStrCount = 0
    local isMessageCommand = false
    -- Split commands by whitespace
    for substring in inArgs:gmatch("%S+") do
      if (subStrCount == 0) then
        if (substring:lower() == "message") then
          isMessageCommand = true
        end
      end

      -- Make every argument lowercase unless we're looking at a message command
      if (isMessageCommand == false and subStrCount > 0) then
        table.insert(splitCmds, substring:lower())
      else
        table.insert(splitCmds, substring)
      end
    end

    -- Call function that matches first argument and pass the split command arguments
    for i,v in pairs(splitCmds) do
      if (BAMSlash.SlashFunctions[v] ~= nil) then
        BAMSlash.SlashFunctions[v](splitCmds)
        return
      end
    end
    print("No command matches \'/bam " .. inArgs .. "\'")
  end
  print("BÄM Mod Classic slash commands:")
end