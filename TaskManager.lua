-------------------------------------
-- PLAYERTASKCONTROLLER
-------------------------------------


local anvil = PLAYERTASKCONTROLLER:New("Anvil",coalition.side.BLUE,PLAYERTASKCONTROLLER.Type.A2GS)
anvil:SetMenuName("Anvil")
anvil:SetMenuOptions(true)
anvil:SetSRS({135,255},{radio.modulation.AM, radio.modulation.AM},mySRSPath,nil,nil,mySRSPort,MSRS.Voices.Google.Standard.en_GB_Standard_D,1,mySRSGKey,nil,AIRBASE:FindByName(AIRBASE.Sinai.Tel_Nof):GetCoordinate())
anvil:SetSRSBroadcast(243,radio.modulation.AM)
anvil:SetCallSignOptions(true,false)
anvil:SetEnableIlluminateTask()
anvil:SetTransmitOnlyWithPlayers(true)
anvil:SetEnableUseTypeNames()
anvil:EnableTaskInfoMenu()
anvil:EnableBuddyLasing(Recce)

-- Add a lasing drone for precision bombing tasks
local drone = SPAWN:New("Reaper")
:OnSpawnGroup(
  function(grp)
    grp:CommandSetUnlimitedFuel(true)
    grp:SetCommandImmortal(true)
    grp:SetCommandInvisible(true)
    grp:CommandSetUnlimitedFuel(true)
    local FlightGroup = FLIGHTGROUP:New(grp)
    FlightGroup:SetDefaultImmortal(true)
    FlightGroup:SetDefaultInvisible(true)
    --local mission = AUFTRAG:NewORBIT(ZONE:New("Rahat"):GetCoordinate(),10000,150,306,10)
    --FlightGroup:AddMission(mission)
    anvil:EnablePrecisionBombing(FlightGroup,1688,ZONE:New("Rahat"):GetCoordinate())
  end
)
:Spawn()

-- General Zone Target

local zonetarget = PhaseBorderZones[CurrentPhase]
local zoneset = SET_GROUP:New():FilterZones({zonetarget}):FilterCategoryGround():FilterCoalitions("red"):FilterOnce()
local ztarget = TARGET:New(zoneset)
local zonetask = PLAYERTASK:New(AUFTRAG.Type.BAI,ztarget,true,99,"Neutralize all REDFOR units in "..PhaseBorderNames[CurrentPhase].." Zone!")
zonetask:SetMenuName("Phase Objective")
zonetask:AddFreetext("Neutralize all REDFOR units in "..PhaseBorderNames[CurrentPhase].." Zone!")
zonetask:AddConditionSuccess(
  function(set)
    local Set = set -- Core.Set#SET_GROUP
    if Set:CountAlive() == 0 then
      return true
    else
      return false
    end
  end,
  zoneset
  )
anvil:AddPlayerTaskToQueue(zonetask)

function zonetask:OnAfterSuccess(From,Event,To)
  if CurrentPhase and CurrentPhase < 4 then
    MESSAGE:New("Well done! We have won this phase!",30,"Eisenhower",true):ToAll():ToLog()
    CurrentPhase = CurrentPhase + 1
  else
    MESSAGE:New("Well done! We have won the war!",30,"Eisenhower",true):ToAll():ToLog()
  end
end

-- Airbase targets

for _,_name in pairs(PhaseAirbases[CurrentPhase]) do
  local AB = AIRBASE:FindByName(_name)
  if AB:GetCoalition() ~= coalition.side.BLUE then
    local target = TARGET:New(AB)
    local task = PLAYERTASK:New(AUFTRAG.Type.CAS,target,true,99,"Conquer airbase ".._name.."!")
    task:SetMenuName("Conquer ".._name)
    task:AddFreetext("Conquer and fortify airbase ".._name..".")
    task:AddConditionSuccess(
      function(ab)
        local afb = ab -- Wrapper.Airbase#AIRBASE
        if afb:GetCoalition() == coalition.side.BLUE then
          return true
        else
          return false
        end
      end, AB
    )
    anvil:AddPlayerTaskToQueue(task)
  end
end

-- Single Ground Targets, groups, ships and statics

zoneset:ForEachGroup(
  function(grp)
    if grp and grp:IsAlive() then
      BASE:I("***** Adding target "..grp:GetName().." *****")
      anvil:AddTarget(grp)
    end
  end
)

local shipset = SET_GROUP:New():FilterCategoryShip():FilterCoalitions("red"):FilterZones({zonetarget}):FilterOnce()
shipset:ForEach(
  function(grp)
    if grp and grp:IsAlive() then
      BASE:I("***** Adding target "..grp:GetName().." *****")
      anvil:AddTarget(grp)
    end
  end
)


local StatSet = SET_STATIC:New():FilterCoalitions("red"):FilterZones({zonetarget}):FilterOnce()
StatSet:ForEach(
  function(grp)
    if grp and grp:IsAlive() then
      BASE:I("***** Adding target "..grp:GetName().." *****")
      anvil:AddTarget(grp)
    end
  end
)

-- Special tasks
if CurrentPhase == 1 then
  local TgtSetOne = SET_ZONE:New():FilterPrefixes("army_fuel_tank"):FilterOnce()
  local scensetone = SET_SCENERY:New(TgtSetOne)
  local ScenTask = PLAYERTASK:New(AUFTRAG.Type.PRECISIONBOMBING,TARGET:New(scensetone),true,99,"Destroy the fuel tanks at Nevatim Airbase!")
  ScenTask:SetMenuName("Bomb Fuel Tanks")
  ScenTask:AddFreetext("Destroy the fuel tanks at Nevatim Airbase!")
  ScenTask:AddFreetextTTS(("Destroy the fuel tanks at Nevatim Airbase!"))
  anvil:AddPlayerTaskToQueue(ScenTask)
  
  local TgtSettwo = SET_ZONE:New():FilterPrefixes("gaza"):FilterOnce()
  local scensettwo = SET_SCENERY:New(TgtSettwo)
  local ScenTask2 = PLAYERTASK:New(AUFTRAG.Type.PRECISIONBOMBING,TARGET:New(scensettwo),true,99,"Destroy the weapon factory in Gaza!")
  ScenTask2:SetMenuName("Bomb Factory")
  ScenTask2:AddFreetext("Destroy the weapon factory in Gaza!")
  ScenTask2:AddFreetextTTS(("Destroy the weapon factory in Gaza!"))
  anvil:AddPlayerTaskToQueue(ScenTask2)
end

-------------------------------------
-- PlayerRecce
-------------------------------------

local HeloPrefixes = { "UH", "SA342", "Mi.8", "Mi.24", "AH.64"}
local PlayerSet = SET_CLIENT:New():FilterCoalitions("blue"):FilterPrefixes(HeloPrefixes):FilterStart()
local HeloRecce = PLAYERRECCE:New("Blue HeloRecce",coalition.side.BLUE,PlayerSet)
HeloRecce:SetCallSignOptions(true,false)
HeloRecce:SetMenuName("Scouting")
HeloRecce:SetTransmitOnlyWithPlayers(true)
HeloRecce:SetSRS({140,240},{radio.modulation.AM,radio.modulation.AM},mySRSPath,"male","en-IR",mySRSPort,MSRS.Voices.Google.Standard.en_GB_Standard_F,1)
--HeloRecce.SRS:SetProvider(MSRS.Provider.WINDOWS)
--HeloRecce.SRS:SetVoice("Sean")
HeloRecce:SetPlayerTaskController(anvil)
anvil:EnableBuddyLasing(HeloRecce)

