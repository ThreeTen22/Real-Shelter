Scriptname RealShelterConfigScript extends SKI_ConfigBase  

; RS 1.5
; 05/20/2016

;===============================================================


Globalvariable Property RS_IsOn Auto
GlobalVariable Property RS_FFIsOn Auto
GlobalVariable Property RS_Debug Auto


Globalvariable Property RS_FluidTransitions Auto

GlobalVariable Property RS_HasFF Auto
GlobalVariable Property RS_FFSnowAmount Auto
GlobalVariable Property RS_FFRainAmount Auto

GlobalVariable Property RS_RainMeshIndex Auto
GlobalVariable Property RS_RainMeshIndexFF Auto
GlobalVariable Property RS_SnowMeshIndex Auto
GlobalVariable Property RS_SnowMeshIndexFF Auto

GlobalVariable Property RS_RainSoundVolume Auto
GlobalVariable Property RS_SnowSoundVolume Auto

FormList Property RS_SnowOverrides Auto
FormList Property RS_RainOverrides Auto
FormList Property RS_PrecipStatic Auto

int firstTime = 0

int aOID ;toggle RS
int bOID ;Fluid Transitions
int cOID ;Toggle FF
int dOID ;FF Rain Emitters - Constant as GV is Called
int eOID ;FF Snow Emitters 
int fOID ;RS Rain Texture Override
int gOID ;RS Snow Texture Override
int hOID ;RS Rain Sound Override
int iOID ;RS Snow Sound Override
int debugID ;Debug Mode

Bool hasFrostfall = false


bool aVal = True  ;toggle RS
bool bVal = True ;Fluid Transitions
bool cVal = True  ;Toggle FF
bool bDebug = False ; Toggle Debug Information

float dVal = 20.0 ;FF Rain Emitters - Constant as GV is Called
float eVal = 23.0 ;FF Snow Emitters 
float fVal = 2.0  ;RS Rain Texture Override
float gVal = 1.0  ;RS Snow Texture Override
float hVal = 60.0  ;RS Rain Sound Volume
float iVal = 100.0  ;RS Snow Sound Volume


;===============================================================

Event OnConfigInit()
    Pages = New String[6]
    Pages[0] = "Options"
    Pages[1] = "Textures"
    Pages[2] = "Debug"
    RS_RainMeshIndex.SetValue(2.0)
EndEvent

;===============================================================

Event OnPageReset(string page)
  If (page == "")
    LoadCustomContent("RS_logo_static.dds")
    Return
  Else
    UnloadCustomContent()
  EndIf
  If Page == "Options"
    SetCursorFillMode(TOP_TO_BOTTOM)
    AddHeaderOption("Main:")
    MainOptions()
    SetCursorPosition(1)
    AddHeaderOption("Frostfall:")
    FFOptions()
  EndIf
  If Page == "Textures"
    SetCursorFillMode(TOP_TO_BOTTOM)
    AddHeaderOption("R.S. Texture Overrides")
    AddHeaderOption("Rain Override")
    fOID = AddSliderOption("Override #", fVal,"{0}")
    AddEmptyOption()
    AddHeaderOption("Snow Override")
    gOID = AddSliderOption("Override #", gVal,"{0}")
  EndIf
  If Page == "Debug"
    SetCursorFillMode(Top_To_BOTTOM)
    AddHeaderOption("Toggle Debug Mode")
    debugID = AddToggleOption("Enable:", bDebug)
  EndIf
  If Page == "#0"
    SetCursorFillMode(TOP_TO_BOTTOM)
    AddHeaderOption("Saving Slot For Later")
  EndIf
   If Page == "#1:"
    SetCursorFillMode(TOP_TO_BOTTOM)
    AddHeaderOption("Saving Slot For Later")
  EndIf
  If Page == "#2:"
    SetCursorFillMode(TOP_TO_BOTTOM)
    AddHeaderOption("Saving Slot For Later")
  EndIf
  If Page == "#3:"
    SetCursorFillMode(TOP_TO_BOTTOM)
    AddHeaderOption("Saving Slot For Later")
  EndIf
EndEvent

Function MainOptions()
  AddHeaderOption("Toggle Real Shelter")
  aOID = AddToggleOption("Enable", aVal)
  AddEmptyOption()
  AddHeaderOption("Toggle Fluid Transitions")
  bOID = AddToggleOption("Enable", bVal)
  AddEmptyOption()
  AddHeaderOption("Sheltered Rain Volume")
  hOID = AddSliderOption("Sheltered Rain Volume", hVal,"{0}%")
  AddEmptyOption()
  AddHeaderOption("Sheltered Snow Volume")
  iOID = AddSliderOption("Sheltered Snow Volume", iVal,"{0}%")
EndFunction

Function FFOptions()
  int flags = 0 
  If hasFrostfall
    flags = OPTION_FLAG_NONE
  Else
    flags = OPTION_FLAG_DISABLED
    AddHeaderOption("Cannot Detect Real Shelter: FrostFall")
    AddEmptyOption()
    AddEmptyOption()
  EndIf
  AddHeaderOption("Toggle FrostFall Shelter", flags)
  cOID = AddToggleOption("Enable", cVal, flags)
  AddEmptyOption()
  AddHeaderOption("Sheltered Rain Density",flags)
  dOID = AddSliderOption("Number of Emitters", dVal,"{0} Emitters",flags)
  AddEmptyOption()
  AddHeaderOption("Sheltered Snow Denisity", flags)
  eOID = AddSliderOption("Number of Emitters", eVal,"{0} Emitters",flags)
EndFunction
;===============================================================

Event OnOptionSliderOpen(int Option)
  If (Option == dOID)
    SetSliderDialogRange(4.0,128.0)
    SetSliderDialogInterval(2.0)
    SetSliderDialogDefaultValue(20)
    If RS_FFRainAmount
      SetSliderDialogStartValue(RS_FFRainAmount.GetValue())
    EndIf
  ElseIf (Option == eOID)
    SetSliderDialogRange(4.0,128.0)
    SetSliderDialogInterval(2.0)
    SetSliderDialogDefaultValue(20)
    If RS_FFSnowAmount
      SetSliderDialogStartValue(RS_FFSnowAmount.GetValue())
    EndIf
  ElseIf (Option == fOID)
    SetSliderDialogRange(0.0,3.0)
    SetSliderDialogInterval(1.0)
    SetSliderDialogDefaultValue(2.0)
    If RS_RainMeshIndex
      SetSliderDialogStartValue(RS_RainMeshIndex.GetValue())
    EndIf
  ElseIf (Option == gOID)
    SetSliderDialogRange(0.0,1.0)
    SetSliderDialogInterval(1.0)
    SetSliderDialogDefaultValue(1.0)
    If RS_SnowMeshIndex
      SetSliderDialogStartValue(RS_SnowMeshIndex.GetValue())
    EndIf
  ElseIf (Option == hOID)
    SetSliderDialogRange(0.0,100.0)
    SetSliderDialogInterval(1.0)
    SetSliderDialogDefaultValue(60.0)
    If RS_RainSoundVolume
      SetSliderDialogStartValue(hVal)
    EndIf
  ElseIf (Option == iOID)
    SetSliderDialogRange(0.0,100.0)
    SetSliderDialogInterval(1.0)
    SetSliderDialogDefaultValue(100.0)
    If RS_SnowSoundVolume
      SetSliderDialogStartValue(iVal)
    EndIf
  EndIf
EndEvent

Event OnOptionSliderAccept(int option, float value)
  if (option == dOID)
    dVal = value
    RS_FFRainAmount.SetValue(value)
  ElseIf (option == eOID)
    eVal = value
    RS_FFSnowAmount.SetValue(value)
  ElseIf (option == fOID)
    fVal = value
    RS_RainMeshIndex.SetValue(value)
    RainToRain(value as Int)
  ElseIf (option == gOID)
    gVal = value
    RS_SnowMeshIndex.SetValue(value)
    SnowToSnow(value as Int)
  ElseIf (option == hOID)
    hVal = value
    RS_RainSoundVolume.SetValue(value/100.0)
  ElseIf (option == iOID)
    iVal = value
    RS_SnowSoundVolume.SetValue(value/100.0)
  EndIf
  forcepagereset()
EndEvent

Event OnOptionSelect(int option)
  If (option == aOID)
    aVal = !aVal
    SetToggleOptionValue(aOID, aVal)
    If aVal    
      RS_IsOn.SetValue(1)
    Else
      RS_IsOn.SetValue(0)
    EndIf
  ElseIf (option == bOID)
    bVal = !bVal
    SetToggleOptionValue(bOID, bVal)
    If bVal    
      RS_FluidTransitions.SetValue(1)
    Else
      RS_FluidTransitions.SetValue(0)
    EndIf
  ElseIf (option == cOID)
    cVal = !cVal
    SetToggleOptionValue(cOID, cVal)
    If bVal    
      RS_FFISOn.SetValue(1)
    Else
      RS_FFISOn.SetValue(0)
    EndIf
  ElseIf (option == debugID)
    bDebug = !bDebug
    SetToggleOptionValue(debugID, bDebug)
    If bDebug
      RS_Debug.SetValue(1)
    Else
      RS_Debug.SetValue(0)
    EndIf
  EndIf
EndEvent

;===============================================================

Event OnOptionHighlight(int option)
  If (option == aOID)
    SetInfoText("Toggles Real Shelter on or off.\nDefault: Enabled")
  ElseIf (option == bOID)
    SetInfoText("Toggles Fluid Shelter Transitions (The quick fading effect when entering shelter) On or Off.\nDefault: Enabled")
  ElseIf (option == cOID)
    SetInfoText("Toggles Frostfall Tent's on or off.\nDefault: Enabled")
  ElseIf (option == dOID)
    SetInfoText("Sets the amount of rain particle emitters that are created for each tent.\nTurn down amount if its melting your graphics card")
  ElseIf (option == eOID)
    SetInfoText("Sets the amount of snow particle emitters that are created for each tent.\nTurn down amount if its melting your graphics card")
  ElseIf (option == fOID)
    SetInfoText("Select your Rain texture/model here.  \nReEnter your shelter to see the results.")
  ElseIf (option == gOID)
    SetInfoText("Select your Snow texture/model here.  \nReEnter your shelter to see the results.")
  ElseIf (option == hOID)
    SetInfoText("Enter a range from 0 to 100  \nDefault: 60")
  ElseIf (option == iOID)
    SetInfoText("Enter a range from 0 to 100  \nDefault: 100")
  ElseIf (option == debugID)
    SetInfoText("Toggles the display of debug notifications and traces")
  EndIf
EndEvent

;===============================================================

Event OnOptionDefault(int option)
  If (option == aOID)
    aVal = true
    SetToggleOptionValue(aOID, aVal)
    RS_IsOn.SetValue(1)
  ElseIf (option == bOID)
    bVal = True
    SetToggleOptionValue(bOID, bVal)
    RS_Debug.SetValue(0)
  ElseIf (option == cOID)
    if hasFrostfall
      cVal = True
      SetToggleOptionValue(cOID, cVal)
      RS_FFISOn.SetValue(1)
    Else
      cVal = False
      SetToggleOptionValue(cOID, cVal)
      RS_FFISOn.SetValue(0)
    EndIf
  ElseIf (option == debugID)
    bDebug = False
    SetToggleOptionValue(debugID, bDebug)
    RS_Debug.SetValue(0)
  EndIf
EndEvent

Event OnVersionUpdate(int a_version)
  If a_version == 141
    Debug.Notification("Updating Real Shelter MCM to 1.5")
    Pages = New String[3]
    Pages[0] = "Options"
    Pages[1] = "Textures"
    Pages[2] = "Debug"
  EndIf
endEvent

int function GetVersion()
  return 141
endFunction

Event OnGameReload()
LocalChecks()
RevertFormLists()
Parent.OnGameReload()
EndEvent

Function RevertFormLists() Global
FormList RSList
FormList CurrentList

RSList = Game.GetFormFromFile(0x0004CCAD, "RealShelter.esp") as FormList
CurrentList = Game.GetFormFromFile(0x0004CCAE, "RealShelter.esp") as FormList
If RSList != none
RSList.Revert()
EndIf
If CurrentList != none
CurrentList.Revert()
EndIf

EndFunction

Function LocalChecks()
Debug.Trace("Real Shelter Config:  Checking For Real Shelter: Frostfall")
hasFrostfall = Game.GetFormFromFile(0x00005399, "RealShelterFF.esp")
cVal = hasFrostfall
Debug.Trace("Real Shelter: Frostfall Found? " + cVal)
if !(cVal)
  RS_FFISOn.SetValue(0)
Else
  RS_FFISOn.SetValue(1)
EndIf
EndFunction


Bool Function RainToRain(int index = 0)
  string worldPath
  string floorSplashDefault = "effects/fxfloorsplash01.nif"
  Form temp2 = RS_RainOverrides.GetAt(index)
  worldPath = temp2.GetWorldModelPath()

  if RS_Debug.GetValue() != 0
  Debug.Notification("RainToRain:"+worldPath)
  Debug.Trace("RainToRain:"+worldPath)
  EndIf

  RS_PrecipStatic.GetAt(5).SetWorldModelPath(worldPath)
  RS_PrecipStatic.GetAt(6).SetWorldModelPath(floorSplashDefault)
  
  temp2 = none
  Return true
EndFunction

Bool Function SnowToSnow(int index = 0)
  string worldPath = "effects/ambient/fxambgentlyfallingsnow00.nif"
  Form tempForm
  If index == 1
  tempForm = RS_SnowOverrides.GetAt(index)
  worldPath = tempForm.GetWorldModelPath()
  EndIf

  If index != 0
    RS_PrecipStatic.GetAt(4).SetWorldModelPath(worldPath)
    tempForm = none
  EndIf
  Return true
EndFunction


;Depreciated as of 1.3.1
Globalvariable Property ShelterSwitch Auto hidden
Globalvariable Property DebugMode Auto hidden