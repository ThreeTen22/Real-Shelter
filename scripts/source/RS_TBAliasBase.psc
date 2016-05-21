Scriptname RS_TBAliasBase extends ReferenceAlias  
import Weather
import Debug

GlobalVariable Property RS_IsSheltered Auto
GlobalVariable Property RS_Index Auto

GlobalVariable Property RS_TimeUnderShelter Auto
GlobalVariable Property RS_FluidTransitions Auto
GlobalVariable Property RS_HasRegions Auto
GlobalVariable Property RS_RainSoundVolume Auto
GlobalVariable Property RS_SnowSoundVolume Auto

FormList Property RS_CurrentList Auto
FormList Property RS_RSList Auto
FormList Property RS_WSList Auto

Weather Property CurrentWeather Auto hidden
Weather Property RSWeather Auto hidden

ObjectReference property EnableParent1 auto hidden
ObjectReference property EnableParent2 Auto hidden

Sound Property rainSound Auto
Sound Property snowSound Auto

Int Property AliasType Auto 
Int Property WTHRType Auto
Float Property DebugLevel Auto


Function SetShelter(GetShelterTBScript tb, ObjectReference eP1, ObjectReference eP2, Float Db)
  GoToState("")
  DebugLevel = Db
  ForceRefTo(tb)
  If AliasType == 0
    EnableParent1 = eP1
    EnableParent2 = eP2
  ElseIf AliasType == 1
    RS_IsSheltered.SetValue(1)
  EndIf
  GoToState("Startup")
  RegisterForSingleUpdate(0.01)
EndFunction

State Startup
  Event OnUpdate()
    CurrentWeather = GetCurrentWeather()
    WTHRType = CurrentWeather.GetClassification()
    If WTHRType > 1
      ActivateShelter()
      GotoState("Active")
    EndIf
  EndEvent
EndState

Event OnTriggerLeave(ObjectReference akActionRef)
      Int WaitMax = 0
      While GetOwningQuest().GetState() == "Busy" && WaitMax < 5
        Utility.Wait(0.1)
        WaitMax+=1
      EndWhile
      If AliasType == 0
        DisableFX(EnableParent2, false)
        DisableFX(EnableParent1, false)
        RS_IsSheltered.SetValue(0.0)
      ElseIf AliasType == 1
          If GetSkyMode() > 1
            RevertWeather(RSWeather)
          EndIf
      EndIf
EndEvent


Event OnTrigger(ObjectReference akActionRef)

EndEvent

;Function ActivateShelter()
;   DebugString("I Should Never Hit This Activate Shelter!")
;EndFunction 

Event OnTriggerEnter(ObjectReference akActionRef)
    Int WaitMax = 0
    While GetOwningQuest().GetState() == "Busy" && WaitMax < 5
      Utility.Wait(0.1)
      WaitMax+=1
    EndWhile
    GoToState("Startup")
    RegisterForSingleUpdate(0.01)
EndEvent


State Active
  Event OnTrigger(ObjectReference akActionRef)
    RSWeather = GetCurrentWeather()
    WTHRType = RSWeather.GetClassification()
      GoToState("ShutDown")
      Trace("Entered Shutdown State")
  EndEvent
EndState


State ShutDown
  Event OnTrigger(ObjectReference akActionRef)
    If GetOwningQuest().GetCurrentStageID() > 1
        RegisterForSingleUpdate(0.1)
        Trace("Left ShutdownState")
    EndIf
  EndEvent
EndState


Function ActivateShelter()
    Int Indx = FindInFL(CurrentWeather)
    If Indx != -1
      RSWeather = RS_RSList.GetAt(Indx) as Weather
      If AliasType == 0
        DebugString("Alias1: Activating Shelter")
        EnableFX(EnableParent2, false)
        EnableFX(EnableParent1, true)
        If (WTHRType == 2)
          ActivateSound(rainSound,RS_RainSoundVolume.GetValue(),EnableParent1, EnableParent2)
        Else
          ActivateSound(snowSound,RS_SnowSoundVolume.GetValue(),EnableParent1, EnableParent2)
        EndIf
      ElseIf AliasType == 1
        DebugString("Alias2: Activating Shelter")
        ReplaceWeather(RS_FluidTransitions.GetValue())
        UpdateFormLists(Indx)
      EndIf
    EndIf 
EndFunction 

Function ActivateSounds()
  If (WTHRType == 2)
      ActivateSound(rainSound,RS_RainSoundVolume.GetValue(),EnableParent1, EnableParent2)
  Else
      ActivateSound(snowSound,RS_SnowSoundVolume.GetValue(),EnableParent1, EnableParent2)
  EndIf
EndFunction

Function ActivateSound(Sound akSoundForm, float fVolume, ObjectReference akObjectRef1, ObjectReference akObjectRef2)
    If fVolume > 0.0
      If akObjectRef1 && akObjectRef1.Is3dLoaded()
        int soundInstance = akSoundForm.Play(akObjectRef1)
        Sound.SetInstanceVolume(soundInstance, fVolume)
      ElseIf akObjectRef2 && akObjectRef2.Is3dLoaded()
        int soundInstance = akSoundForm.Play(akObjectRef2)
        Sound.SetInstanceVolume(soundInstance, fVolume)
      EndIf
    EndIf
EndFunction

Function RevertWeather(Form wthrForm)
    ;DebugString("Inside RevertWeather", 1)
    if RS_RSList.HasForm(wthrForm)
      Int Indx = RS_RSList.Find(wthrForm)
      CurrentWeather = RS_CurrentList.GetAt(Indx) as Weather
      CurrentWeather.ForceActive()
    EndIf
    ;Debug.MessageBox("rsWTHRIndx != -1" + (RS_CurrentList.GetAt(rsWTHRIndx) as Weather))  
EndFunction


Function ReplaceWeather(float fluid)
  ;DebugString("Inside ReplaceWeather", 1)
  If fluid == 1.0
    RSWeather.SetActive(false,false)
  Else
    RSWeather.ForceActive(false)
  EndIf
EndFunction

Function UpdateFormLists(Int Indx)
  If Indx != -1 && Indx > 5
    TransferForm(RS_CurrentList.GetAt(Indx), RS_CurrentList)
    TransferForm(RS_RSList.GetAt(Indx), RS_RSList)
    TransferForm(RS_WSList.GetAt(Indx), RS_WSList)
  EndIf
  ;RS_Index.SetValue(Indx as float)
EndFunction


Int Function FindInFL(Form wthr, bool deepCheck = true)
  int i = RS_CurrentList.Find(wthr)
  If deepCheck && i == (-1)
    i = RS_RSList.Find(wthr)
  EndIf
  return i
EndFunction

Function TransferForm(Form akSource, FormList akDestination) global
  akDestination.AddForm(akSource)
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