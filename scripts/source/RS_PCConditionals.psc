Scriptname RS_PCConditionals extends ActiveMagicEffect  
{Checks for player specific events like OnSleep And On 1st - 3rd person Switch.
Compiling a few conditional checks into one to save space}
import Debug
Int Property Type = 0 Auto 
FormList Property RS_ActiveTentList Auto
FormList Property RS_PrecipStatic Auto
FormList Property RS_SnowOverrides Auto
FormList Property RS_RainOverrides Auto
;FormList Property RS_CurrentList Auto hidden
;FormList Property RS_RSList Auto hidden

Weather Property cWeather Auto hidden
Weather Property newWeather Auto hidden

GlobalVariable Property GameHour Auto
GlobalVariable Property IsSheltered Auto
GlobalVariable Property RS_TimeUnderShelter Auto
GlobalVariable Property RS_WindSpeedMod Auto
GlobalVariable Property RS_Debug Auto
;GlobalVariable Property RS_Index Auto hidden

GlobalVariable Property RS_RainMeshIndex Auto
GlobalVariable Property RS_RainMeshIndexFF Auto
GlobalVariable Property RS_SnowMeshIndex Auto
GlobalVariable Property RS_SnowMeshIndexFF Auto

;ShaderParticleGeometry Property StormRain Auto hidden

float sleepStart = 0.0
float sleepFinish = 0.0
float sleepTotal = 0.0
Bool ChangedEffect = false

string rainDefault = "effects/fx_rainandmistbeamnoglow.nif"
string snowDefault = "effects/ambient/fxambgentlyfallingsnow00.nif"

int classification
Form rainbeam
Form snowBeam

Event OnEffectStart(Actor akTarget, Actor akCaster)
	If Type != 0
		If Type == 3
		   	RainBeamToSnow()
		   	if RS_Debug.GetValue() != 0
		   	Notification("I Have started To Snow")
		   	EndIf
		ElseIf Type == 4
		   	RainBeamToRain(RS_RainMeshIndex.GetValue() As Int)
		   	if RS_Debug.GetValue() != 0
		   	Notification("I Have started To Rain")
		   	EndIf
		EndIf
	EndIf
EndEvent
Event OnEffectFinish(Actor akTarget, Actor akCaster)
 	float shelterTime
 	float rsDebug
  	If Type != 0
  		shelterTime = RS_TimeUnderShelter.GetValue()
  		rsDebug = RS_Debug.GetValue()
  		If Type == 3
  	 		if shelterTime > 5.0
  	 			if rsDebug != 0
  	 			Notification("I Have Finished Snowing")
  	 			EndIf
  	 		RainBeamToRain(RS_RainMeshIndex.GetValue() As Int)
  	 		DisableSnowEvent()
  	 		EndIf
  	 	ElseIf Type == 4
  	 		if shelterTime > 5.0
  	 			if rsDebug != 0
  	 			Notification("I Have Finished Raining")
  	 			EndIf
  	 		DisableRainEvent()
  	 		EndIf
  		EndIf
  	EndIf
 EndEvent

Bool Function RainBeamToSnow(int index = 0)
	string worldPath
	Form temp = RS_SnowOverrides.GetAt(2)
	worldPath = temp.GetWorldModelPath()

	if RS_Debug.GetValue() != 0
	Notification("rainTOSnow: "+worldPath)
	Trace("rainTOSnow:"+worldPath)
	EndIf

	RS_PrecipStatic.GetAt(5).SetWorldModelPath(worldPath)
	RS_PrecipStatic.GetAt(6).SetWorldModelPath(" ")
	temp = none
	Return true
EndFunction


Bool Function RainBeamToRain(int index = 0)
	string worldPath
	string floorSplashDefault = "effects/fxfloorsplash01.nif"
	Form temp2 = RS_RainOverrides.GetAt(index)
	worldPath = temp2.GetWorldModelPath()

	if RS_Debug.GetValue() != 0
	Notification("RainToRain:"+worldPath)
	Trace("RainToRain:"+worldPath)
	EndIf

	RS_PrecipStatic.GetAt(5).SetWorldModelPath(worldPath)
	If RS_PrecipStatic.GetAt(6).GetWorldModelPath() != " "
		RS_PrecipStatic.GetAt(6).SetWorldModelPath(floorSplashDefault)
	EndIf
	temp2 = none
	Return true
EndFunction




 float Function UpdateShelterTime()
 	sleepFinish = GetRealHour()
 	sleepTotal = sleepFinish - sleepStart
 	If sleepTotal < 0 
 		sleepTotal += 24
 	EndIf
 	If IsSheltered.GetValue() == 1
 		RS_TimeUnderShelter.Mod(sleepTotal)
 	EndIf
 EndFunction

 float Function GetRealHour() 
	Float Time = GameHour.GetValue()
	Int Std = Math.Floor(Time)
	Time = Time - Std
	Time = ((Time / 5)*3)
	Time = Time + Std
	Return Time
EndFunction


Function DisableSnowEvent()
  int Handle = ModEvent.Create("RS_DisableSnowEvent")
    if (handle)
      ModEvent.Send(handle)
    EndIf
EndFunction

Function DisableRainEvent()
  int Handle = ModEvent.Create("RS_DisableRainEvent")
    if (handle)
      ModEvent.Send(handle)
    EndIf
EndFunction
;/
Saving Code For Possible Expansion
RS_CurrentList = Game.GetFormFromFile(0x0004CCAE, "RealShelter.esp") as FormList
RS_RSList = Game.GetFormFromFile(0x0004CCAD, "RealShelter.esp") as FormList
RS_Index = Game.GetFormFromFile(0x0004FEAA, "RealShelter.esp") as GlobalVariable
StormRain = Game.GetFormFromFile(0x0010780F, "Skyrim.esm") as ShaderParticleGeometry
/;