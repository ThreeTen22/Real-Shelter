Scriptname GetShelterTBScript Extends ObjectReference
import Weather
import Debug

ObjectReference property rainsoundfx1 auto
ObjectReference property rainsoundfx2 Auto
ReferenceAlias Property RS_Alias Auto Hidden
RS_ShelterSystemQuest Property RS_ShelterSystem Auto
Bool Property IsActiveShelter = false Auto Hidden


Event OnTriggerEnter(ObjectReference akActionRef)
  If IsActiveShelter == false
    RS_ShelterSystem.EnterTrigger(self as GetShelterTBScript, rainsoundfx1, rainsoundfx2)
  EndIf
EndEvent

Event OnTrigger(ObjectReference akActionRef)

EndEvent

State Active
  Event OnTrigger(ObjectReference akActionRef)
  
  EndEvent
EndState


Event OnTriggerLeave(ObjectReference akActionRef)
  Int WaitMax = 0
  While RS_ShelterSystem.GetState() == "Busy" && WaitMax < 5
    Utility.Wait(0.1)
    WaitMax+=1
  EndWhile
  If IsActiveShelter == false
    GetShelterTBScript tb = RS_ShelterSystem.CurrentShelter
    If tb
      If (tb.rainsoundfx1 != rainsoundfx1)  
        DisableFX(rainsoundfx1)
      EndIf
      If (tb.rainsoundfx2 != rainsoundfx2)
        DisableFX(rainsoundfx2)
      EndIf
    EndIf
    tb = none
  EndIf
EndEvent

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