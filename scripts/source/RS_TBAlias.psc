Scriptname RS_TBAlias extends ReferenceAlias  
import Weather
import Debug

GlobalVariable Property RS_IsSheltered Auto
GlobalVariable Property RS_ISOn Auto
GlobalVariable Property RS_Debug Auto
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

ObjectReference property rainsoundfx1 auto
ObjectReference property rainsoundfx2 Auto

Sound Property rainSound Auto
Sound Property snowSound Auto

Bool SetUnderShelter = true
Int db_indexThreshold = 2


Function SetLocalVar()
    CurrentWeather = GetCurrentWeather()
    RSWeather = CurrentWeather
    RS_TimeUnderShelter.SetValue(0.0)
EndFunction

Function GrabEnableParents(ObjectReference tb,ObjectReference rsfx1, ObjectReference rsfx2)
TryToClear()
ForceRefTo(tb)
If rsfx1 
	rainsoundfx1 = rsfx1
EndIf
If rsfx2
	rainsoundfx2 = rsfx2
EndIf
SetLocalVar()
OnTriggerEnter(Game.GetPlayer())
EndFunction

Event OnTriggerEnter(ObjectReference akActionRef)
  RS_IsSheltered.SetValue(1.0) 
  If CurrentWeather.GetClassification() > 1
      GoToState("Active")
      DebugString("Inside of OnTriggerEnter", 1)
      ActivateShelter()
  EndIf
EndEvent

Event OnTriggerLeave(ObjectReference akActionRef)
    GoToState("")
    RSWeather = GetCurrentWeather()
    RS_IsSheltered.SetValue(0)
    If RSWeather.GetClassification() > 1
      If RS_IsSheltered.GetValue() > 0
        DisableFX(rainsoundfx1)
        DisableFX(rainsoundfx2)
      Else 
        RevertWeather()
      EndIf
    Else
      RS_TimeUnderShelter.SetValue(0.0)
      DisableFX(rainsoundfx1)
      DisableFX(rainsoundfx2)
    EndIf
EndEvent

Event OnTrigger(ObjectReference akActionRef)

EndEvent

State Active
  Event OnTrigger(ObjectReference akActionRef)
    GoToState("")
    RS_TimeUnderShelter.Mod(1.0)
    If GetCurrentWeather() != RSWeather && GetCurrentWeatherTransition() > 0.5
      If (GetCurrentWeather()).GetClassification() < 2
        DisableFX(rainsoundfx1)
        DisableFX(rainsoundfx2)
        DebugForm("OnTrigger: RSWeather:",RSWeather)
      Else
        SetLocalVar()
        DebugString("Inside of OnTriggerEnter", 1)
        ActivateShelter()
        GoToState("Active")
      EndIf
    ElseIf RS_IsSheltered.GetValue() == 1.0
        GoToState("Active")
    EndIf
  EndEvent
EndState



Function ActivateShelter()
  Int Indx = FindInFL(CurrentWeather,RS_CurrentList,RS_RSList)
  If Indx != -1
    ReplaceWeather(Indx)
    EnableFX(rainsoundfx2, false)
    EnableFX(rainsoundfx1, false)
    If (CurrentWeather.GetClassification() == 2)
      ActivateSound(rainSound,RS_RainSoundVolume.GetValue(),rainsoundfx1)
    Else
      ActivateSound(snowSound,RS_SnowSoundVolume.GetValue(), rainsoundfx1)
    EndIf
    UpdateFormLists(Indx)
  EndIf
EndFunction 

Function ActivateSound(Sound akSoundForm, float fVolume, ObjectReference akObjectRef)
  If fVolume > 0.0 && akObjectRef.Is3dLoaded()
    int soundInstance = akSoundForm.Play(akObjectRef)
    Sound.SetInstanceVolume(soundInstance, fVolume) 
  EndIf
EndFunction


Function RevertWeather()
  Int Indx = 0
  GoToState("")
    DebugString("Inside RevertWeather", 1)
    if RS_RSList.HasForm(GetCurrentWeather() as Form)
      Indx = RS_RSList.Find(GetCurrentWeather() as Form)
      RSWeather = RS_CurrentList.GetAt(Indx) as Weather
      RSWeather.ForceActive()
    EndIf
    DisableFX(rainsoundfx2, false)
    DisableFX(rainsoundfx1, false)
    ;Debug.MessageBox("rsWTHRIndx != -1" + (RS_CurrentList.GetAt(rsWTHRIndx) as Weather))  
EndFunction

Int Function FindInFL(Weather wthr, FormList list1, FormList list2)
  int i = list1.Find(wthr)
  If i == (-1)
    i = list2.Find(wthr)
  EndIf
  return i
EndFunction

Function ReplaceWeather(int Indx)
  DebugString("Inside ReplaceWeather", 1)
  RSWeather = RS_RSList.GetAt(Indx) as Weather
  If (RS_FluidTransitions.GetValue() != 0.0)
    RSWeather.SetActive(false,false)
  Else
    RSWeather.ForceActive(false)
  EndIf
EndFunction

Function UpdateFormLists(Int Indx)
  If Indx != -1
    TransferForm(RS_CurrentList.GetAt(Indx), RS_CurrentList)
    TransferForm(RS_RSList.GetAt(Indx), RS_RSList)
    TransferForm(RS_WSList.GetAt(Indx), RS_WSList)
    RS_Index.SetValue(Indx as float)
  EndIf
EndFunction

Function TransferForm(Form akSource, FormList akDestination) global
  akDestination.AddForm(akSource)
EndFunction

Function EnableAll()
  if rainsoundfx1
    rainsoundfx1.Enable()
  EndIf
  if rainsoundfx2
    rainsoundfx2.Enable()
  EndIf
EndFunction


Function DisableAll()
  if rainsoundfx1
    rainsoundfx1.Disable()
  EndIf
  if rainsoundfx2
    rainsoundfx2.Disable()
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


Function DisableFX(ObjectReference fx, bool noWait = false) 
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

Function DebugString(String s, Int dType) 
  If RS_Debug.GetValue() == 1.0 
    If dType > 0
      Trace(s)
    EndIf
    If dType > 1
      Notification(s)
    EndIf
  EndIf
EndFunction

Function DebugForm(String s, Form frm)
  If RS_Debug.GetValue() == 1.0 
      Trace(s+" "+frm)
  EndIf
EndFunction