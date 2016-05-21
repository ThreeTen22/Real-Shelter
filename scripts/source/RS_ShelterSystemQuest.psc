Scriptname RS_ShelterSystemQuest extends Quest  

GetShelterTBScript Property CurrentShelter Auto Hidden
GlobalVariable Property RS_Debug Auto

Function EnterTrigger(GetShelterTBScript tb, ObjectReference eP1, ObjectReference eP2)
	GoToState("Busy")
	Float debugValue = RS_Debug.GetValue()
	If tb != CurrentShelter
		If CurrentShelter
			CurrentShelter.IsActiveShelter = false
		EndIf
		CurrentShelter = tb
		(GetAlias(0) as RS_TBAliasBase).SetShelter(tb, eP1, eP2, debugValue)
		Utility.Wait(0.01)
		(GetAlias(1) as RS_TBAliasBase).SetShelter(tb, eP1, eP2, debugValue)
		tb.IsActiveShelter = true
	EndIf
	GoToState("")
EndFunction

State Busy

EndState

Function StartRegister(Int Index)
	RegisterForUpdateGameTime(index)
EndFunction

Function ShutDown()
	CurrentShelter = none;
EndFunction