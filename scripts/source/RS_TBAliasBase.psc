Scriptname RS_TBAliasBase extends ReferenceAlias  
import Weather
import Debug

GlobalVariable Property RS_IsSheltered Auto
GlobalVariable Property RS_Index Auto


ObjectReference property EnableParent1 auto hidden
ObjectReference property EnableParent2 Auto hidden

Int Property AliasType Auto 
Float Property DebugLevel Auto



Function SetShelter(GetShelterTBScript tb, ObjectReference eP1, ObjectReference eP2, Float Db)
  GoToState("Startup")
  DebugLevel = Db
  ForceRefTo(tb)
  If AliasType == 0
    EnableParent1 = eP1
    EnableParent2 = eP2
  ElseIf AliasType == 1
    RS_IsSheltered.SetValue(1)
  EndIf
  RegisterForSingleUpdate(0.01)
EndFunction

Event OnUpdate()
  OnTrigger(none)  
EndEvent

State Startup
  Event OnTrigger(ObjectReference akActionRef)
    If GetCurrentWeather().GetClassification() > 1
      ActivateShelter()
    EndIf
    GoToState("Active")
  EndEvent
EndState

State Active
  Event OnTriggerEnter(ObjectReference akActionRef)
      Int WaitMax = 0
      While (GetOwningQuest() as RS_ShelterSystemQuest).isBusy && WaitMax < 5
        Utility.Wait(0.1)
        WaitMax+=1
      EndWhile
      GoToState("Startup")
  EndEvent
EndState

Event OnTriggerLeave(ObjectReference akActionRef)
      Int WaitMax = 0
      While (GetOwningQuest() as RS_ShelterSystemQuest).isBusy && WaitMax < 5
        Utility.Wait(0.1)
        WaitMax+=1
      EndWhile
      If AliasType == 0
        DisableFX(EnableParent2, false)
        DisableFX(EnableParent1, false)
      ElseIf AliasType == 1
        
        WeatherPlugin.SetPrecipitationDisabled(0)
        RS_IsSheltered.SetValue(0.0)
      EndIf
EndEvent

Event OnTriggerEnter(ObjectReference akActionRef)
  
EndEvent

Event OnTrigger(ObjectReference akActionRef)

EndEvent


Function ActivateShelter()
    If AliasType == 0
      DebugString("Alias1: Activating Shelter")
      EnableFX(EnableParent2, false)
      EnableFX(EnableParent1, true)
    ElseIf AliasType == 1

      WeatherPlugin.SetPrecipitationDisabled(1)
    EndIf
EndFunction


Function EnableFX(ObjectReference fx, bool noWait = false) global
  If noWait
    If fx
      fx.EnableNoWait()
    EndIf
  Else
    If fx
      fx.Enable()
    EndIf
  EndIf
EndFunction


Function DisableFX(ObjectReference fx, bool noWait = false) global
  If noWait
    If fx
      fx.DisableNoWait()
    EndIf
  Else
    If fx
      fx.Disable()
    EndIf
  EndIf
EndFunction

Function DebugString(String s, Int dType = 0)
  If DebugLevel == 1.0
    If dType >= 0
      Trace(s)
    EndIf
    If dType == 1
      Notification(s)
    EndIf
  EndIf
EndFunction

Function DebugForm(String s, Form frm) 
  If DebugLevel == 1.0 
      Trace(s+" "+frm)
  EndIf
EndFunction

Function ShutDown()
  DisableFX(EnableParent2, false)
  DisableFX(EnableParent1, true)
  EnableParent1 = none
  EnableParent2 = none
EndFunction