Scriptname GetShelterTBScript extends ObjectReference
;TBscript v1.4 - Full Release Version
;December 10 2014

import math
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

Actor Property PlayerREF auto
FormList Property RS_CurrentList Auto
FormList Property RS_RSList Auto
FormList Property RS_WSList Auto


Weather Property CurrentWeather Auto
Weather Property RSWeather Auto
ObjectReference property rainsoundfx1 auto
ObjectReference property rainsoundfx2 Auto

ObjectReference property fxOnEnter Auto hidden

Sound Property rainSound Auto
Sound Property snowSound Auto

Int prevWTHRIndx = 0
Bool dbRS = false
Bool infWTHR = false
Bool shelterTransf = false
Int db_indexThreshold = 2
Int happened = 0
Int rsWTHRIndx = -1
Int soundInstance = 0
Int wthrClassification = 0 

ObjectReference CheckLink
ObjectReference NewLink





State Stopped

Event OnBeginState()
  UnregisterForModEvent("RS_DisableSnowEvent")
  UnregisterForModEvent("RS_DisableRainEvent")
  DisableAll()
EndEvent

Event OnTrigger(ObjectReference akActionRef)
  RS_IsSheltered.SetValue(0.0) 
EndEvent

Event OnTriggerLeave(ObjectReference akActionRef)
  If akActionRef == PlayerREF
    GotoState("")
  EndIf
EndEvent

EndState

Event RS_StopChecking()
  If RS_Debug.GetValue() == 1
  Notification("Inside of RS_StopChecking")
  EndIf
  GotoState("Stopped")
EndEvent

Event OnTriggerEnter(ObjectReference akActionRef)
 ; Debug.MessageBox("RS_CurrentListgetsize  " +  RS_CurrentList.Getsize()  " RS_CurrentList.GetAt(2) " + RS_CurrentList.GetAt(5) )
  If akActionRef == PlayerREF
    ;This controls the ifelse statements
    SetLocalVar()
    If RS_ISOn.GetValue() == 1 && CurrentWeather.GetClassification() > 1
      If RS_Debug.GetValue() == 1.0
        Notification("Inside of OnTriggerEnter")
        Trace(self + "Inside of OnTriggerEnter")
      EndIf
      If RS_IsSheltered.GetValue() <= 1 
        ActivateSoundFX()
        UpdateFormLists()
      EndIf
      if infWTHR == false
      RegisterForModEvent("RS_DisableSnowEvent","RS_StopChecking")
      RegisterForModEvent("RS_DisableRainEvent","RS_StopChecking")
      EndIf
    EndIf
  EndIf
EndEvent



Event OnTrigger(ObjectReference akActionRef)
  If akActionRef == PlayerREF
    ;GotoState("Busy2")
    if happened == 0 
      RS_TimeUnderShelter.Mod(1.0)
      RS_IsSheltered.SetValue(1.0) 
    EndIf
  EndIf
EndEvent

Event OnTriggerLeave(ObjectReference akActionRef)
  If akActionRef == PlayerREF
    If RS_ISOn.GetValue() == 1.0 
      If CurrentWeather.GetClassification() > 1
        RS_IsSheltered.SetValue(0.0)
        Utility.Wait(0.3)
          If RS_IsSheltered.GetValue() > 1
            DisableFX(rainsoundfx1)
            DisableFX(rainsoundfx2)
            RS_Index.SetValue(rsWTHRIndx)
          Else 
             RevertWeather()
             happened = 0
          EndIf
        if infWTHR == false
        UnregisterForModEvent("RS_DisableSnowEvent")
        UnregisterForModEvent("RS_DisableRainEvent")
        EndIf
      Else
        if !rainsoundfx1.isDisabled()
          rainsoundfx1.Disable()
        EndIf
        if !rainsoundfx2.isDisabled()
          rainsoundfx2.Disable()
        EndIf
        UnregisterForModEvent("RS_DisableSnowEvent")
        UnregisterForModEvent("RS_DisableRainEvent")
      EndIF
    EndIf
  EndIf
EndEvent

Function DisableFX(ObjectReference fx, bool noWait = true)
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

int Function SetLocalVar()
    CurrentWeather = Weather.GetCurrentWeather()
    wthrClassification = CurrentWeather.GetClassification()
    happened = 0
    infWTHR = false
    If RS_Debug.GetValue() == 1.0
      Notification("Inside of SetLocalVar")
      Trace(self + "Inside of SetLocalVar")
    EndIf
    RS_TimeUnderShelter.SetValue(0.0)
    if RS_HasRegions.GetValue() == 0
      infWTHR = true
    EndIf
    
    Return  0
EndFunction

int Function RevertWeather()
    Form rsWeatherTemp
    Weather Temp = Weather.GetCurrentWeather()
    happened = 1
    If rsWTHRIndx != -1
      if RS_RSList.HasForm(Temp)
        RSWeatherTemp = RS_CurrentList.GetAt(rsWTHRIndx) 
        RSWeather = RSWeatherTemp as Weather
        RSWeather.ForceActive()
      EndIf
    EndIf
    DisableFX(rainsoundfx2, false)
    DisableFX(rainsoundfx1)
    ;Debug.MessageBox("rsWTHRIndx != -1" + (RS_CurrentList.GetAt(rsWTHRIndx) as Weather))  
Return 1
EndFunction

Function ActivateSoundFX()
  Form rsWeatherForm
  Form tempW = CurrentWeather as Form
  float soundVol = RS_RainSoundVolume.GetValue()
  float fluidTrans = RS_FluidTransitions.GetValue() 

  rsWTHRIndx = RS_Index.GetValue() As Int
 ; Notification("RSWTHRINDEX: " + rsWTHRIndx)
  RS_TimeUnderShelter.SetValue(0.0)
  rsWTHRIndx = RS_CurrentList.Find(tempW)
  Utility.Wait(0.1)
  If rsWTHRIndx == -1
    rsWTHRIndx = RS_RSList.Find(tempW)
  EndIF

  If rsWTHRIndx != -1
    RS_IsSheltered.SetValue(1)
    rsWeatherForm = RS_RSList.GetAt(rsWTHRIndx) 
    RSWeather = rsWeatherForm as Weather
    If (fluidTrans != 0.0)
      RSWeather.SetActive(infWTHR,true)
    Else
      RSWeather.ForceActive(infWTHR)
    EndIf
    Utility.Wait(0.1)
    EnableAll()
    If (wthrClassification == 2)
      soundInstance = rainSound.Play(rainsoundfx1)
      Sound.SetInstanceVolume(soundInstance, soundVol) 
    ElseIF (wthrClassification == 3)
      soundInstance = snowSound.Play(rainsoundfx1)
      Sound.SetInstanceVolume(soundInstance, soundVol) 
    EndIf
  EndIf
EndFunction 

Function UpdateFormLists()
  Form curList
  Form rssList
  Form wsList
  If rsWTHRIndx > 4
    curList = RS_CurrentList.GetAt(rsWTHRIndx)
    rssList = RS_RSList.GetAt(rsWTHRIndx)
    wsList = RS_WSList.GetAt(rsWTHRIndx)
    RS_CurrentList.AddForm(curList)
    RS_RSList.AddForm(rssList)
    RS_WSList.AddForm(wsList)
    RS_Index.SetValue(0.0)
    curList = none
    rssList = none
    wsList = none
  ElseIf rsWTHRIndx != -1
    RS_Index.SetValue(rsWTHRIndx as float)
  EndIf
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
 

;Depreciated as of 1.3
FormList Property CurrentList Auto hidden
FormList Property RSList Auto hidden

GlobalVariable Property IsSheltered Auto hidden
GlobalVariable Property ShelterSwitch Auto hidden
GlobalVariable Property flist Auto hidden

 ;Notification("Inside Activate: rsWTHRIndx" + rsWTHRIndx)
  {
  If (tempW != RS_CurrentList.GetAt(rsWTHRIndx))
    rsWTHRIndx = RS_CurrentList.Find(tempW)
    ;Notification("After Activate: rsWTHRIndx" + rsWTHRIndx)
  EndIf
  Utility.Wait(0.1)
  if rsWTHRIndx != -1
     RS_IsSheltered.SetValue(1)
     rsWeatherForm = RS_RSList.GetAt(rsWTHRIndx) 
     RSWeather = rsWeatherForm as Weather
     If (fluidTrans != 0.0)
      RSWeather.SetActive(infWTHR,true)
     Else
      RSWeather.ForceActive(infWTHR)
     EndIf
  Else
    rsWTHRIndx = RS_RSList.Find(tempW)
  EndIf
  If (rsWTHRIndx != -1)
   RS_Index.SetValue(rsWTHRIndx)
   EnableAll()
    If (wClass == 2)
    soundInstance = rainSound.Play(rainsoundfx1)
    Sound.SetInstanceVolume(soundInstance, soundVol) 
    ElseIF (wClass == 3)
    soundInstance = snowSound.Play(rainsoundfx1)
    Sound.SetInstanceVolume(soundInstance, soundVol) 
    EndIf
  EndIf
  }