Scriptname RS_Main extends Quest  
{This is the script that will check the weather.  This will allow all tents to work. As it will send a modEvent when the weather changes}

Globalvariable Property RS_IsOn Auto
GlobalVariable Property RS_FFIsOn Auto
Actor Property PlayerREF Auto

Auto State FirstRun

  Event OnInit()
  GotoState("")
  Debug.Trace("Real Shelter: Checking For Real Shelter: Frostfall")
  If (Game.GetFormFromFile(0x00005399, "RealShelterFF.esp"))
    RS_FFISOn.SetValue(1)
  Else
    RS_FFISOn.SetValue(0)
  EndIf
  ToggleSystem((GetAlias(2) as ReferenceAlias), RS_FFIsOn.GetValue())
 ToggleSystem((GetAlias(1) as ReferenceAlias), 1.0)

  RegisterForSingleUpdate(5)
  EndEvent

  Event OnGameReset()

  EndEvent

EndState

Event OnInit()
  RegisterForSingleUpdate(5)
EndEvent

Event OnUpdate()
  ToggleSystem((GetAlias(1) as ReferenceAlias), RS_IsOn.GetValue())
  ToggleSystem((GetAlias(2) as ReferenceAlias), RS_FFISOn.GetValue())
EndEvent

Function OnGameReset()
  LocalChecks()

EndFunction

Function ToggleSystem(ReferenceAlias akPlayerRef, float num)
  If num != 0.0
    akPlayerRef.ForceRefIfEmpty(PlayerREF)
  Else
    akPlayerRef.Clear()
  EndIf
EndFunction

Function LocalChecks()
Debug.Trace("Real Shelter:  Checking For Real Shelter: Frostfall:")
If !(Game.GetFormFromFile(0x00005399, "RealShelterFF.esp"))
  RS_FFISOn.SetValue(0)
  Debug.Trace("Real Shelter: Frostfall Not Found")
Else
  Debug.Trace("Real Shelter: Frostfall Found!")
EndIf
EndFunction
