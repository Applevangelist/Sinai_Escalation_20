-------------------------------------
-- Configuration
-------------------------------------

if BASE.ServerName and BASE.ServerName ~= "DCS Server" then
  mySRSPath = "C:\\Users\\jgf\\Desktop\\srs\\srs-private"
  mySRSPort = 5004
  mySRSGKey = "C:\\Users\\jgf\\Desktop\\srs\\srs-training2\\theta-mile-349308-0ca2eeb17600.json"
  SavePath = "C:\\Users\\jgf\\Saved Games\\DCS.openbeta_server_private\\persistent-data"
else
  MSRS.LoadConfigFile()
  GRPC.debug = true
  GRPC.integrityCheckDisabled = true
  GRPC.load()
  mySRSPath = "E:\\Program Files\\DCS-SimpleRadio-Standalone"
  mySRSPort = 5002
  mySRSGKey = "E:\\Program Files\\DCS-SimpleRadio-Standalone\\theta-mile-349308-0ca2eeb17600.json"
  SavePath = "C:\\Users\\post\\Saved Games\\DCS\\Missions\\Sinai\\Escalation\\Persistenz"
end

_SETTINGS:SetPlayerMenuOn()
_SETTINGS:SetA2G_MGRS()
_SETTINGS:SetMGRS_Accuracy(3)
_SETTINGS:SetImperial()

PhaseAirbases = {
  [1] = {AIRBASE.Sinai.Kedem,AIRBASE.Sinai.Hatzerim,AIRBASE.Sinai.Nevatim,AIRBASE.Sinai.Ramon_Airbase,AIRBASE.Sinai.Ovda},
  [2] = {AIRBASE.Sinai.El_Arish,AIRBASE.Sinai.El_Gora,AIRBASE.Sinai.Melez,AIRBASE.Sinai.Bir_Hasanah,AIRBASE.Sinai.Abu_Rudeis,AIRBASE.Sinai.St_Catherine},
  [3] = {AIRBASE.Sinai.Baluza,AIRBASE.Sinai.As_Salihiyah,AIRBASE.Sinai.Al_Ismailiyah,AIRBASE.Sinai.Abu_Suwayr,AIRBASE.Sinai.Difarsuwar_Airfield,AIRBASE.Sinai.Fayed,AIRBASE.Sinai.Kibrit_Air_Base},
  [4] = {AIRBASE.Sinai.Al_Mansurah,AIRBASE.Sinai.Cairo_International_Airport,AIRBASE.Sinai.Cairo_West,AIRBASE.Sinai.AzZaqaziq,AIRBASE.Sinai.Bilbeis_Air_Base,AIRBASE.Sinai.Inshas_Airbase,AIRBASE.Sinai.Wadi_al_Jandali},
}

PhaseBorderNames = {}
PhaseBorderZones = {}
for i=1,4 do
  PhaseBorderNames[i] = "Phase "..i.." Border"
  PhaseBorderZones[i] = ZONE:New(PhaseBorderNames[i])
end

UseAirboss = false

--- TODO Load/Save Phase State

CurrentPhase = 2

---
AIRBASE:FindByName(AIRBASE.Sinai.Ramon_Airbase):SetParkingSpotWhitelist({31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,37,48,49,50,51,52,61,62,63,64,65,66,99,100,101,102,103,104,105,106,107})
AIRBASE:FindByName(AIRBASE.Sinai.Ovda):SetParkingSpotWhitelist({4,5,6,7,8,9,30,31,32,33,34,35,36,37,38,39,40,41,42,43,48,49,50,51,52,53,72,73,74,75,76,77,78,79,80,81,82,83,84,85})

-------------------------------------
-- Remove non-phase ground units
-------------------------------------

for Phase = 1,4 do

    -- Filter out SAM groups
   local function FilterOut(grp)
    if grp and grp:IsAlive() then
      local name = grp:GetName()
      if string.find(name,"SAM",1,true) or string.find(name,"EW",1,true) then
        return false
      else
        return true
      end
    end
    return false
   end
  
  --[[
  if Phase ~= CurrentPhase then
  

  
     local set = SET_GROUP:New():FilterCategoryGround():FilterCoalitions("red"):FilterPrefixes({"Ph"..Phase}):FilterFunction(FilterOut):FilterOnce()
     set:ForEach(
      function(grp)
        if grp and grp:IsAlive() then
          grp:Destroy()
        end
      end
     )
     
  end
  --]]
  
  if Phase ~= CurrentPhase then
     local set
     if Phase < CurrentPhase then
      set = SET_GROUP:New():FilterCategoryGround():FilterCoalitions("red"):FilterPrefixes({"Ph"..Phase}):FilterOnce()
     else
      set = SET_GROUP:New():FilterCategoryGround():FilterCoalitions("red"):FilterPrefixes({"Ph"..Phase}):FilterFunction(FilterOut):FilterOnce()
     end    
     set:ForEach(
      function(grp)
        if grp and grp:IsAlive() then
          grp:Destroy()
        end
      end
     )
     local set = SET_STATIC:New():FilterCoalitions("red"):FilterPrefixes({"Ph"..Phase}):FilterFunction(StaticFilter):FilterOnce()
     set:ForEach(
      function(grp)
        if grp and grp:IsAlive() and string.find(grp:GetName(),"FARP",1,true)==nil then
          grp:Destroy()
        end
      end
     )
     local set = SET_GROUP:New():FilterCategoryShip():FilterCoalitions("red"):FilterPrefixes({"Ph"..Phase}):FilterOnce()
     set:ForEach(
      function(grp)
        if grp and grp:IsAlive() then
          grp:Destroy()
        end
      end
     )
   end
end

-------------------------------------
-- Persistenz
-------------------------------------

local redgroundfilename = "RedGround_"..CurrentPhase..".csv"
local redshipsfilename = "RedShips_"..CurrentPhase..".csv"
local redspawnedgroundfilename = "RedGroundSpawned_"..CurrentPhase..".csv"
local bluegroundfilename = "BlueGroundSpawned_"..CurrentPhase..".csv"
local redstaticsfilename = "RedStatics_"..CurrentPhase..".csv"

local reddynamic = SET_GROUP:New():FilterCoalitions("red"):FilterCategoryGround():FilterPrefixes({"Spetznatz","Grouse"}):FilterStart()
local bluedynamic = SET_GROUP:New():FilterCoalitions("blue"):FilterCategoryGround():FilterPrefixes({"Marines","ADStinger"}):FilterStart()

local redgroups = SET_GROUP:New():FilterCoalitions("red"):FilterCategoryGround():FilterPrefixes({"Ph"..CurrentPhase}):FilterOnce()
local redstatics = SET_STATIC:New():FilterCoalitions("red"):FilterOnce()
local redships = SET_GROUP:New():FilterCoalitions("red"):FilterCategoryShip():FilterPrefixes({"Ph"..CurrentPhase}):FilterOnce()

function SaveGround()
  BASE:I("***** Save Ground Troops *****")
  local names = redgroups:GetSetNames()
  UTILS.SaveStationaryListOfGroups(names,SavePath,redgroundfilename,true)
  local snames = redstatics:GetSetNames()
  UTILS.SaveStationaryListOfStatics(snames,SavePath,redstaticsfilename)
  local shipnames = redships:GetSetNames()
  UTILS.SaveStationaryListOfGroups(shipnames,SavePath,redshipsfilename)
  UTILS.SaveSetOfGroups(reddynamic,SavePath,redspawnedgroundfilename,true)
  UTILS.SaveSetOfGroups(bluedynamic,SavePath,bluegroundfilename,true)
end

function RunAround(Set)
  local set = Set -- Core.Set#SET_GROUP
  if set then
    set:ForEachGroupAlive(
        function(grp)
          local group = grp -- Wrapper.Group#GROUP
          group:RelocateGroundRandomInRadius(10,750,false,shortcut,"Vee",true)
        end
    )
  end
end

function LoadGround()
  BASE:I("***** Load Ground Troops *****")
  UTILS.LoadStationaryListOfGroups(SavePath,redgroundfilename,true,true,false)
  UTILS.LoadStationaryListOfGroups(SavePath,redshipsfilename,true,true,false)
  UTILS.LoadStationaryListOfStatics(SavePath,redstaticsfilename,true,true,false)
  local redset = UTILS.LoadSetOfGroups(SavePath,redspawnedgroundfilename,true,true,false)
  local blueset = UTILS.LoadSetOfGroups(SavePath,bluegroundfilename,true,true,false)
  local redsettimer = TIMER:New(RunAround,redset)
  redsettimer:Start(5)
  local bluesettimer = TIMER:New(RunAround,blueset)
  bluesettimer:Start(6)
end

local SaveTimer = TIMER:New(SaveGround)
 SaveTimer:Start(120,120)

local LoadTimer = TIMER:New(LoadGround)
LoadTimer:Start(5)


------------------------------------------------------
-- Blocker
------------------------------------------------------
--BASE:TraceOn()
--BASE:TraceClass("NET")
local blocker = NET:New()

function blocker:OnAfterPlayerJoined(From,Event,To,Client,Name)
 -- BASE:I({Name,Client})
  local client = CLIENT:FindByPlayerName(Name)
  if client then
    local location = client:GetCoordinate()
    local ab = location:GetClosestAirbase()
    local coa = ab:GetCoalition()
    local abname = ab:GetName()
    local grp = Client:GetGroup()
    if coa ~= coalition.side.BLUE then
      -- kick player
      blocker:BlockPlayer(client,Name,60, abname.." has not yet been conquered by blue!")
      MESSAGE:New(abname.." has not yet been conquered by blue!",15,"ALERT"):ToClient(client)
      if not blocker:ForceSlot(client,0,SlotID) then -- works on server only IIRC
        if grp and grp:IsAlive() then grp:Destroy() end
      end
    end
  end
end


------------------------------------------------------
-- TIRESIAS
------------------------------------------------------
--[[
function ActivateTiresias()
  local tiresias = TIRESIAS:New()
  tiresias:SetActivationRanges(15,40)
end

local TTimer = TIMER:New(ActivateTiresias)
TTimer:Start(30)
--]]
