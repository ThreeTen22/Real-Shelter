Scriptname RS_ShelterAlias extends ReferenceAlias  
 

Event OnPlayerLoadGame()
	(GetOwningQuest() as RS_Updater).OnGameReset()
EndEvent