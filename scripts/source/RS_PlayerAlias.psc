Scriptname RS_PlayerAlias extends ReferenceAlias  
 

Event OnPlayerLoadGame()
	(GetOwningQuest() as RS_Main).OnGameReset()
EndEvent