Scriptname RS_ShelterSystemQuest extends Quest  

GetShelterTBScript Property CurrentShelter Auto Hidden
GlobalVariable Property RS_Debug Auto

Bool busy = false
Bool Property isBusy Hidden
	Bool Function get()
		return busy
	EndFunction
EndProperty



Function EnterTrigger(GetShelterTBScript tb, ObjectReference eP1, ObjectReference eP2)
	busy = true
	Float debugValue = RS_Debug.GetValue()
	If tb != CurrentShelter
		If CurrentShelter
			CurrentShelter.IsActiveShelter = false
		EndIf
		CurrentShelter = tb
		(GetAlias(0) as RS_TBAliasBase).SetShelter(tb, eP1, eP2, debugValue)
		(GetAlias(1) as RS_TBAliasBase).SetShelter(tb, eP1, eP2, debugValue)
		tb.IsActiveShelter = true
	EndIf
	busy = false
EndFunction

Function StartRegister(Int Index)
	RegisterForUpdateGameTime(index)
EndFunction

Function ShutDown()
	CurrentShelter = none
EndFunction