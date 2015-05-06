{
  RSPatcher

  Real Shelter auto patcher v1.5  by ThreeTen
  Feel free to use this code for your own purposes, and feel free to contact me if you have any questions.  
      }
unit RSPatcher;


//uses mteFunctions;
uses RSFunctions;
//Mod is split into three parts - 
{   1. Do some research on your modlist/aquire the appropriate assets and info/ show the outcome to the user with tweaking options
    2. Grab The Appropriate weather and regions as both copies and new records, and modify/store them according to the users tweaks.
    3. Take the list of the new sheltered weathers and correctly place them in the appropriate Weather section in their _Weatherlist.ini file
}
  const 
  regionChange = 'Tropical Skyrim.esp'#13'SummerSkies.esp'; 
  corruptESP = 'SUM.esp'#13'ReProccer.esp'#13'SkyRe_Main.esp'#13'ReProccer.esp'#13'ASIS-Dependency.esp';
  FFVanillaFormIDs = '000C8220,0010A23C,0010A23D,0010A241';
  FFCombinedFormIDs = '068A1A,06C559,04483A,044838,044836,044832,044831,00C8220,010A23C,010A23D,010A241';
  RSSupportedRegions = '$0002A72D,$0004D7FD,$00069E2B,$000703C2,$00070408,$0007042A,$0007042E,$0007042F,$000C5852,$000C5853,$000C5854,$000C5855,$000C5856,$000C5857,$000C5858,$0010474D,$0010474E,$00104AB3,$00106632,$00106634,$00106667,$00106668,$0010AFC5,$0010FDC6';
  
  var
//The 2 Main Bools - These determine if part 2 and part 3 will run or not.
    bUpdatingWeatherIni, bUpdatingPlugin: boolean; 
//These bools decide if a backup is needed for ini modification and if ini modification is possible
    bHasBackupList, bIsBackingUpIni, bIsUsingBackupData, bHasWeatherList: boolean;
//Bool used to determine if RSPatch.esp needs to be cleaned before patching
    bFreshRSP: boolean; 
//These are the records that I need to constantly reference
    RSFile, RSPFile, RSFFFile, WBFile, WSList, RSPList, CurrentList, oldWeathers, wthrMR, globalVariable : IInterface;
    SPGR, SPGS : IInterface;
//These are the stringlists which usually hold formids
    slText, idToAdd, idToSearch, idToRemove, idCurrents, idRSs, FFOWlist, WSStringList, rspMasters : TStringList;
    regionData, FFSevereList : TStringList;
    regionWTHRCount :TList;
//Ini-Modification
//--Holds Directory Info
    directory, eDir, bDir, skyDir: string;
//--Houses the Actual ini files we want to modify
    iniCtrl, iniCrtlb: TMemIniFile;
//Specific Mod checks (in order: Real Shelter:Frostfall Tents, Frostfall 2.6, Pure Weather, Climates of Tamriel, Warburg 3d paper world map, Real Shelter Rain Overhaul)
    bHasRSFF, bHasFF, bHasPW, bHasCoT, bHasWB, bHasRSRO: boolean;
//File Index's that I reference constantly 
    RSPFIndex, RSFIndex, CoTIndex, PWIndex, FFIndex: integer;
//Real Shelter Modification Bools
    bWillUpdateRegions, bWillRemoveVE, bWillUseBlankSPG, bWillShelterFXRain, bWillRemoveSnowSpread, bWillRemoveRainWS : boolean;
//Frostfall Modification Bools
    bWillUpdateFFLists:boolean;
//Misc
    bWillUpdateWarburg, bUsingSkyrimWeathers: boolean;
    bDebugging, bQuitting: boolean;
    trueCheck,  falseCheck, bRegMod, bCorrupt: boolean;
    


// NOT A GLOBAL FUNCTION!
function GrabAllTextInfoAndSearch(splitSections:Boolean):  TStringList;
   var
      iniCtrls :TMemIniFile;
    e: TStringList;
    secStr, secDetails,sStr1, sStr2, fullString: String;
    properKey, usesZeroX, usesCommas:Boolean;
    i, p, wthrFormSize, hInt1, hInt2: integer;
   begin
      iniCtrls :=  TMemIniFile.Create(bDir);
      e := TStringList.Create;
      fullString := '';
      secStr := 'WEATHER003';
      usesZeroX := false;
      usesCommas := false;
      //
      if splitSections then begin
        secDetails := iniCtrls.readString(secStr, 'WeatherIDs', 'p');
        if Pos(',',secDetails) > 0 then
        usesCommas := true;
        if Pos('0x',secDetails) > 0 then
        usesZeroX := true;
      end;

      for i := 1 to 99 do begin
        
        if(i < 10) then
          secStr := 'WEATHER00' + IntToStr(i)
        else
          secStr := 'WEATHER0' + IntToStr(i);

        //function ReadString(const Section, Ident, Default: string): string; virtual; abstract;
        secDetails := iniCtrls.readString(secStr, 'WeatherIDs', 'p');

        if secDetails = 'p' then continue;
        if splitSections then begin
          if usesCommas then
          fullString := (fullString + ' ' + secDetails)
          else
          fullString := (fullString + ' ' + secDetails);
        end
        else
        e.Add(secDetails);
      end;

      if splitSections then begin
        if usesCommas then
         e.CommaText := fullString
        else
         e.DelimitedText := fullString;
      end;

      iniCtrls.Free;
      result := e;
   end;

function FixWarburg(var RSPFile: IInterface; var WBFile: IInterface): boolean;

  var
    WBGrpp, wMR, wthrGrpp : IInterface;
  begin
    if (HasGroup(WBFile, 'WTHR')) then 
      begin
        wthrGrpp := GroupBySignature(WBFile, 'WTHR');
        WBGrpp := ElementByIndex(wthrGrpp, 0);
        wMR := RecordByFormID(WBFile, FormID(WBGrpp), false);
        wbCopyElementToFile(wMR,RSPFile,false,true);
        RemoveNode(wMR);
        Result := true;
        end
      else
        begin
         MessageDlg('RSPatcher 1.5:   ERROR'#13#13'Warburgs has already been modified.'#13#13'First please quit Tes5Edit and reinstall Warburgs. Then relaunch Tes5Edit and run this patcher again',mtError, [mbOK], 0);
         Result := false;
        end;
  end;

function findAllTheFiles: integer;
  var
    Form1, Form2, Form3, checkForm1 : IInterface;
    a, ii: Integer;
    s1: string;
  begin
    // Find Files
    CoTIndex := 0;
    bRegMod := false;
    bCorrupt := false;
   
    bHasPW := false;
    bHasRSFF := false;
    bHasFF := false;
    bHasCot := false;
    bHasWB := false;
    bHasRSRO := false;
    bWillUpdateFFLists := false;
    bWillUpdateWarburg := false;
    bWillUpdateRegions := true;
    bWillRemoveVE := false;
    bWillUseBlankSPG := false;
    bWillShelterFXRain := false;
    bWillRemoveSnowSpread := false;
    for a := 0 to (FileCount - 1) do 
    begin
      s1 := GetFileName(FileByIndex(a));
      if bDebugging then
      begin
        AddMessage('s= ' + s1 + ' at i '+ IntToStr(a));
      end;

      if (Lowercase(s1) = 'realshelter.esp') then 
      begin
        RSFile := FileByIndex(a);
        RSFIndex := a;
      end
      else if(Lowercase(s1) = 'rspatch.esp') then 
      begin
        RSPFile := FileByIndex(a);
        RSPFIndex := a;
      end
      else if(Lowercase(s1) = 'pureweather.esp') then 
      begin
        bHasPW := true;
        PWIndex := a;
      end
      else if(Lowercase(s1) = 'realshelterff.esp') then 
      begin
        RSFFFile := FileByIndex(a);
        bHasRSFF := true;
      end
      else if(Lowercase(s1) = 'chesko_frostfall.esp') then 
      begin
        bHasFF := true;
        FFIndex := a;
      end
      else if(Lowercase(s1) = 'climatesoftamriel.esm') then 
      begin
        bHasCoT := true;
        CoTIndex := a;
      end
      else if Pos('3d paper world map',Lowercase(s1))  > 0 then
      begin
        if not Assigned(WBFile) then begin
        WBFile := FileByIndex(a);
        bHasWB := true;
        end;
      end
      else if (s1 = 'rsrain.esp') or (s1 = 'rsraincot.esp') then 
      begin
        bHasRSRO := true;
      end
      else if Pos(s1, regionChange) > 0 then
        bRegMod := true
      else if Pos(s1, corruptESP) > 0  then
        bCorrupt := true;
    end; 
    

    if Assigned(WBFile) then
      if not (HasGroup(WBFile, 'WTHR')) then
        bWillUpdateWarburg := false;

    if Assigned(RSFile) then begin
      Form1 := GrabFormByLocalID('4CCAD',RSFile);
      Form2 := GrabFormByLocalID('4CCAE',RSFile);
      Form3 := GrabFormByLocalID('508B7',RSFile);
    end;
    if not Assigned(RSPFile) and Assigned(RSFile) then begin
      AddMessage('=== Real Shelter Patch Not Found By Name ===');
      AddMessage('=== Checking For Real Shelter Overrides ===');
      if OverrideCount(Form1) > 0 then begin
      AddMessage('=== Real Shelter Patch Found! ===');
      RSPFile := GetFile(WinningOverride(Form1));
      RSPFIndex := GetLoadOrder(RSPFile)+1;
      end;
    end;
    //define important files
    if not Assigned(RSPFile) and Assigned(RSFile) then begin
      AddMessage('=== No Overrides Found ===');
      AddMessage('=== Create New RSPatch.esp ===');
      RSPFile := AddNewFile;
      seev(RSPFile, 'TES4/CNAM','Real Shelter Patch - Please Do Not Modify This Text');
      RSPFIndex := GetLoadOrder(RSPFile)+1;
    end;

    if Assigned(RSPFile) then begin
      AddMessage('=== Preparing ESP For Patching ===');
      AddRequiredElementMasters(Form1, RSPFile,false);
      AddRequiredElementMasters(Form2, RSPFile,false);
      AddRequiredElementMasters(Form3, RSPFile,false);
      RSPList := wbCopyElementToFile(Form1, RSPFile, false, true);
      CurrentList := wbCopyElementToFile(Form2, RSPFile, false, true);
      WSList := wbCopyElementToFile(Form3, RSPFile, false, true);
      Add(WSList, 'FormIDs', true);
    end;
    

    if Assigned(RSFile) then begin
      SPGR := GrabFormByLocalID('59A91',RSFile);
      SPGS := GrabFormByLocalID('59A92',RSFile);
    end;
    Result := 0;
  end;



function CleanPatch(checkGrp:IInterface; bCleanup:integer): boolean;
  var
    j,k,l,m: Integer;
    tempList1, tempList2, tempList3 : IInterface;
  begin
    //Cleanup code for multiple patching in one session
    if bCleanup = mrYes then begin   

      cleanGRUP(checkGrp, 'KYWD','=== Removing Depreciated Information ===');
      cleanGRUP(checkGrp, 'WTHR','=== Removing Weathers ===');
      cleanGRUP(checkGrp, 'GLOB','=== Removing GlobalVariables ===');
      cleanGRUP(checkGrp, 'REGN','=== Removing Regions ===');
      

      tempList1 := MasterOrSelf(RSPList);
      tempList2 := MasterOrSelf(CurrentList);
      tempList3 := MasterOrSelf(WSList);
      cleanGRUP(checkGrp,'FLST','=== Reverting FormLists ===');

      RSPList := wbCopyElementToFile(tempList1, RSPFile, false, true);
      CurrentList := wbCopyElementToFile(tempList2, RSPFile, false, true);
      WSList := wbCopyElementToFile(tempList3, RSPFile, false, true);
      Add(WSList, 'FormIDs', true);
      AddMessage('=== Resetting Object ==='); 
      AddMessage('=== Cleaning Completed ==='); 
      bFreshRSP := true;
    end
    else if bCleanup = mrNo then begin
      bFreshRSP := false;
      AddMessage('=== Skipped Cleaning ===');
    end;
  end;

function GatherIniInfo: integer;
  var 
    iniWL, iniWLB: TMemIniFile;
    i,a,a1: integer;
    s1: string;
    s2: string;
    buttonSelected : Integer;
    wLInfo, wLBInfo: TStringList;
    message1: string;
    Form1: TForm;
    rg: TGroupBox;
    DiagBox: TMemo;
    pnl1: TPanel;
    btnOk: TButton;
    btnCancel: TButton;
    btnAbort: TButton;
    boolList : TList;
    results: TModalResult;
  begin
    Result := 0;
    bUpdatingPlugin := false;
    bUpdatingWeatherIni := false;
    bIsUsingBackupData := false;
    bHasWeatherList:= false;
    bHasBackupList:= false;
    boolList := TList.Create;
    s1 := DataPath;
    i := Length(s1);
    i := i - 5;
    skyDir := CopyFromTo(s1, 1, i);
    eDir := skyDir + 'enbseries\_weatherlist.ini';
    bDir := skyDir + 'enbseries\_weatherlistBackup.ini';
    directory := eDir;
    iniWL := TMemIniFile.Create(eDir);
    wLInfo := TStringList.Create;
    if iniWL.SectionExists('WEATHER001') then
    begin
      iniWL.ReadSection('WEATHER001',wLInfo);
      if wLInfo.Count > 1   then
        bHasWeatherList := true;
    end;
    wLInfo.Free;
    iniWL.Free;
    iniWLB := TMemIniFile.Create(bDir);
    if iniWLB.SectionExists('WEATHER001') then
    begin
      bHasBackupList := true;
    end;
    iniWLB.Free;
    if bHasWeatherList then 
    begin
      bUpdatingWeatherIni := true;
      bIsBackingUpIni := true;
      if bHasBackupList then
      begin
        bIsUsingBackupData := true;
        bIsBackingUpIni := false;
      end;
    end
    else
    begin
      bUpdatingWeatherIni := false;
      bIsBackingUpIni := false;
      bIsUsingBackupData := false;
    end;

    if bFreshRSP then 
      bUpdatingPlugin := true;
    try
      Form1 := TForm.Create(nil);
      boolList.Add(bCorrupt);
      boolList.Add(bRegMod);
      boolList.Add(bHasWeatherList);
      boolList.Add(bHasBackupList);
      boolList.Add(bFreshRSP);
      boolList.Add(bHasPW);
      boolList.Add(bHasRSFF);
      boolList.Add(bHasFF);
      boolList.Add(bHasCot);
      boolList.Add(bHasWB);
      boolList.Add(bHasRSRO);
      createResearchBox(Form1,DiagBox,pnl1,rg,btnOk,btnAbort,btnCancel, 
                          bQuitting, bWillUpdateRegions, bWillUpdateWarburg, bWillUpdateFFLists, bWillRemoveVE,bWillUseBlankSPG,bWillRemoveSnowSpread,bWillRemoveRainWS,
                          boolList, results);
    if results = mrOk then 
      Result := -1
    else if results = mrCancel then 
      bQuitting := true;
    finally
      Form1.Free;
      boolList.Free;
    end;
  end;

function OverrideModule(Var bUpdatingPlugin: boolean): boolean;
  var
    frm: TForm;
    btnOk, btnCancel: TButton;
    rb1, rb2, rb3, rb4, rb5: TCheckBox;
    rg, rg2: TGroupBox;
    lb1, lb2: TLabel;
    ed1, ed2: TEdit;
    pnl: TPanel;
    sb: TScrollBox;
    iniInfo1: TMemo;
    i, j, k, m, more: integer;
    holder: TObject;
    masters, e, f: IInterface;
    s: string;
    isIniModding: boolean;
  begin
    bIsBackingUpIni := false;
    more := 0;
    frm := TForm.Create(nil);
    bQuitting := true;
    try
      createOverrideBox(frm,rg,pnl,iniInfo1,rb1,rb2,rb3,btnOk,btnCancel);
      frm.ActiveControl := btnOk;
      if frm.ShowModal = mrOk then
      begin
        bQuitting := false;
        if rb1.State = cbChecked then begin
        bUpdatingPlugin := true;
        end;
        if rb2.State = cbChecked then begin
        bUpdatingPlugin := true;
        end;
        if rb3.State = cbChecked then begin
        bIsBackingUpIni := true;
        end;
      end;
    finally
      begin
      Result := isIniModding;
      frm.Free;
      end;
    end;
  end;

function GrabNonErrorRecord(badRecord: IInterface): IInterface;
  var
    i: Integer;
    tempRecord: IInterface;
  begin
    for i := OverrideCount(badRecord)-1 downto 0 do begin
      tempRecord := OverrideByIndex(badRecord,i);
       AddMessage('-  Adding '+Name(tempRecord)+'        From File:' + GetFileName(GetFile(tempRecord)));
      if CheckForErrors(0,tempRecord) then  begin
        AddMessage('---ERROR FOUND, PLEASE NOTIFY THE MOD AUTHOR OF THIS FILE: '+ GetFileName(tempRecord));
        AddMessage('---Could not add record from this file!');
        continue;
      end;
      Result := tempRecord;
      break;
    end;
    if not Assigned(tempRecord) then begin
      Result := badRecord;
    end;
  end;
{
  AddRSWeatherToRegion
    This procedure takes in a MR and looks at all of its referenced by,
    Then it filters it by Signature and WinningOverride.
}

procedure AddRegionsToRSPatch;
  var
    e, f, winningOverride,RSPatch, Skyrim, temp, copiedRecord: IInterface;
    i,a: Integer;
    messedRegions: TStringList;
  begin
    Skyrim := FileByName('Skyrim.esm');
    regionData := TStringList.Create;
    regionData.CommaText := RSSupportedRegions;

    for a := regionData.Count-1 downto 0 do begin
      temp := RecordByFormID(Skyrim, StrToInt64(regionData[a]), false);
      f := MasterOrSelf(temp);
      e := GrabNonErrorRecord(f);
      AddRequiredElementMasters(e,RSPFile,false);
      wbCopyElementToFile(e,RSPFile,false,true);
    end;
  end;



function ProcessIt: integer;
  var
      gV, spg  :IInterface;
      i, WindSpeed, isRain: integer;
      letIn: integer;
      st, localString, hexStr, spgType: string;
      AddedIndex,precipNum: integer; //used to sort RS list from auto sorted currentlist
      new_override, oFormId, oLoadOrderFormID: IInterface; //used to search
      new_record: IInterface;
      newelement: IInterface;
      IDAppend: IInterface;
      test : variant;
    begin
      if(bUpdatingPlugin) then
      begin
        //checking to see if it is the winning override and has precipitation, will exit if not
        if not IsWinningOverride(wthrMR) then exit;
        st := geev(wthrMR,'MNAM - Precipitation Type');
        if st = '' then exit;
        if st = 'NULL - Null Reference [00000000]' then exit;
        st := geev(wthrMR,'EDID - Editor ID');
        
        if Pos('FXMagic', st) > 0 then exit;
        if bHasCoT then
          if Pos('CoTAsh', st) > 0 then exit;
        if Pos('DLC', Uppercase(st)) = 1 then exit;
        
        //Copies the selected record as both an override and a new record.
        //Modifies the new record to not have any precip or to use a dummy precipitation.
        //If Selected, will also add the new records into any regions that has their override brother.
        //If frostfall is installed and the option selected it will add sheltered weather into the appropriate formlists.
        try
          AddRequiredElementMasters(wthrMR, RSPFile, false);
          AddMessage(' ');
          AddMessage('--  Grabbing: '+ Name(wthrMR));
          new_override := wbCopyElementToFile(wthrMR, RSPFile, False, True);
          new_record := wbCopyElementToFile(wthrMR, RSPFile, True, True);
        except
          On E : Exception do begin
          AddMessage('--  Grabbing: '+ Name(wthrMR) + ' FAILED! Most Likely due to containing errenous weather info. Please contact the mod author regarding this record!');
          Remove(new_override);
          Remove(new_record);
          Exit;
          end;
        end;
        seev(new_record, 'EDID - Editor ID', ('RSP_' + geev(new_record,'EDID - Editor ID')));
        seev(new_record, 'DATA\Trans Delta', 4);
        AddMessage('----  Created: '+Name(new_record));
        //This tests whether the weather is rain or not
        //There will be a bool to see if the player wants to turn off wind speed for rain to match RS
        precipNum := genv(wthrMR,'MNAM - Precipitation Type');
        spg := RecordByFormID(GetFile(wthrMR), precipNum, false);
        spgType := geev(spg,'DATA\[9]');
        if bWillUseBlankSPG then 
        begin
          if spgType = 'Rain' then
          seev(new_record, 'MNAM - Precipitation Type', HexFormID(SPGR))
          else
          seev(new_record, 'MNAM - Precipitation Type', HexFormID(SPGS));
        end
        else begin
        seev(new_record, 'MNAM - Precipitation Type', '0');
        end;
        //removes wind variation for snow - allows for more accurate snow direction for Frostfall Tents
        if bWillRemoveSnowSpread then begin
          if spgType ='Snow' then begin
          seev(new_override,'DATA - Data\Wind Direction Range', 0);
          seev(new_record,'DATA - Data\Wind Direction Range', 0);
          end;
        end;
        //Removes wind speed for rain, rain will only fall vertically
        if bWillRemoveRainWS then begin
          if (spgType ='Rain') then begin
          seev(new_override,'DATA - Data\Wind Speed', 0);
          seev(new_record,'DATA - Data\Wind Speed', 0); 
          end;
        end;
        //removes the visual effects, like fog and in-your-face snowflakes from weather while under shelter
        if bWillRemoveVE then 
        begin
          seev(new_record,'NNAM - Visual Effect', '0')
        end;
        //Add RS weathers to all regions supported by real shelter
        if bWillUpdateRegions then 
        begin
          if bUsingSkyrimWeathers or not(Pos('00',HexFormID(new_override)) = 1) then begin
            AddToRegions(RSPFile,FormID(new_record), HexFormID(new_override), Name(new_record), regionWTHRCount);
            AddMessage('--Added ' + Name(new_record) +' To All Appropriate Regions');
          end else begin
            AddMessage('---Skipping: This Weather Is Not Used In Any Region');
          end;
        end;

         //Will update frostfall's Formlists to recognize Real Shelter's weather.
        if bWillUpdateFFLists then 
        begin 
            if Pos(getLocalHexID(new_override, true), FFCombinedFormIDs) > 0 then begin
              FFSevereList.Append(HexFormID(new_record));
            end;
            if Pos(getLocalHexID(new_override, true), FFVanillaFormIDs) > 0 then begin
            FFSevereList.Append(HexFormID(new_override));
            end;
        end;
        //creates a constant Global Variable that houses the current weather's wind speed,  
        //this is used to calculate particle emitter rotation for Frostfall Tents
        WindSpeed := geev(new_record,'DATA - Data\Wind Speed');
        gV := wbCopyElementToFile(globalVariable, RSPFile, True, True);
        seev(gV , 'EDID - Editor ID', 'WS_'+IntToStr(WindSpeed));
        seev(gV, 'FLTV - Value', WindSpeed);
        AddMessage('WindSpeed GV: '+Name(gV));
        
        //Adding both override and new weather records into stringlists that are used for updating the _weatherlist.ini file
        AddedIndex := idCurrents.Add(HexFormID(new_override));
        idRSs.Insert(AddedIndex, HexFormID(new_record));
        WSStringList.Insert(AddedIndex,HexFormID(gV));
        localString := getLocalHexID(new_override, true);
        idToSearch.Append(localString);
        localString := getLocalHexID(new_record, true);
        idToAdd.Add(localString);
        Result := 0;
      end;
    end;

procedure GrabFFListsAndAddForms;
  var
      FFFile,FFFList, FFFListOverride : IInterface;
      Frostfall : TStringList;
      temp1  : String;

      begin
          AddMessage('--Adding RealShelter Weathers to Frostfalls Severe WeatherList');
          FFFile := FileByName('Chesko_Frostfall.esp');
          temp1 := LocalIdToLoadOrderID('024098',FFFile, true);
          FFFList :=  RecordByFormID(FFFile, StrToInt64(temp1), false);
          AddRequiredElementMasters(FFFList, RSPFile, false);
          FFFListOverride := wbCopyElementToFile(FFFList, RSPFile, false, true);
          Slev(FFFListOverride, 'FormIDs',FFSevereList);
          AddMessage('----  Complete');
      end;

procedure AddPatchedWeathersToStringLists(var fIdToAdd: TStringList; var fIdToSearch: TStringList);
  var 
      i, wGroupSize: integer;
      e, f: IInterface;
      begin
        if (fIdToAdd.Count) < 1 then
        begin
        e := GroupBySignature(RSPFile, 'WTHR');
        wGroupSize := ElementCount(e);
          for i := 0 to wGroupSize-1 do
          begin
          f := ElementByIndex(e, i);
            if Odd(i) then
            fidToSearch.Add(getLocalHexID(f, true))
            else
            fidToAdd.Add(getLocalHexID(f, true));
          end;
        end;
      end;

procedure ReserveLocalFormIDs();
  var
    i,ii: integer;
    loadOrderID, fileFormID, finalID: cardinal;
    sGMSTTemplate, fileformS: string;
    hasXZeros: boolean;
    weatherRecords: TStringList;
    skyrimESM, iiGMST, iiNewGMST: IInterface;
  begin
    hasXZeros := falseCheck;
    sGMSTTemplate := 'EDF';
    skyrimESM := FileByName('Skyrim.esm');
    loadOrderID := 0;
    iiGMST := GrabFormByLocalID(sGMSTTemplate, skyrimESM);
    weatherRecords := TStringList.Create;
    weatherRecords := GrabAllTextInfoAndSearch(trueCheck);

    if Pos('0x', weatherRecords[0]) > 0 then
      hasXZeros := trueCheck;

    for ii := 0 to GetLoadOrder(RSPFile)-1 do begin
      loadOrderID := loadOrderID + 16777216;
    end;

    for i := 0 to weatherRecords.Count-1 do begin
      AddRequiredElementMasters(iiGMST, RSPFile, true);
      iiNewGMST := wbCopyElementToFile(iiGMST,RSPFile,true,true);
      seev(iiNewGMST, 'EDID', 'RS_FormIDPlaceholder Please Ignore');
      fileformS :='$'+ weatherRecords[i];
      try
        if hasXZeros then begin
          fileFormID := StrToInt(weatherRecords[i]);
        end
        else begin
          fileFormID := StrToInt(fileFormS);
        end;
        finalID := loadOrderID + fileFormID;
        SetLoadOrderFormID(iiNewGMST,finalID);
      except
        On E: Exception do begin
        AddMessage('--Supplied Incorrect FormID : Please Check Your _weatherlistBackup.ini For This Hex:');
        AddMessage('----Faulty Weather Form: '+ weatherRecords[i]);
        AddMessage('------Most likely you have more than one of the above record in your ini file!');
        end;
      end;
    end;
    weatherRecords.Free;
  end;

procedure RegionWeatherCount(iiFile: IInterface);
  var
    i, size: integer;
    regionList: TList;
    mRecord, mRecordGrp: IInterface;
  
  begin
    mRecordGrp := GroupBySignature(iiFile, 'REGN');
    for i := 0 to Pred(ElementCount(mRecordGrp)) do begin
      mRecord := ElementByIndex(mRecordGrp, i);
      size := ContainerSize(mRecord,'Region Data Entries\Region Data Entry\[1]');
      regionWTHRCount.Add(size);
    end;
  end;

procedure CreateTStringLists();
  begin
    idCurrents := TStringList.Create;
    idCurrents.Sorted := true;
    idCurrents.delimiter := ' ';
    idRSs := TStringList.Create;
    idRSs.Sorted := false;
    idRSs.delimiter := ' ';
    idToSearch := TStringList.Create;
    idToSearch.Sorted := false;
    idToSearch.delimiter := ' ';
    idToAdd := TStringList.Create;
    idToAdd.Sorted := false;
    idToAdd.delimiter := ' ';
    WSStringList := TStringList.Create;
    WSStringList.Sorted := false;
    WSStringList.delimiter := ' ';
    FFSevereList := TStringList.Create;
    FFSevereList.delimiter := ' ';
    FFSevereList.Sorted := false;
  end;


function finalize: integer;
  var
    z,zz, z1, ztest, sindex, listSize, oldListSize, fIndex, fIndex2, ii, bCleanUp, kwIndex: integer;
    strindex, tempStr, secStr2, sLocalFormID, sRSGFormID, kwdStr, s, st1,st2,st3, kwdOldStr, GlobFormID, kwdVal, rlResult, backupDirectory: string;
    fIdToSearch, fIdToAdd, fIniDB, fIdIndex: TStringList;
    newWeathers, indexedWeathers, flipElements, wthrGrp, wthrU, wthr, checkGlob, checkGrp, checkForm2, getGlobal: IInterface;
    noWeatherList, toDoResult: boolean;
    tempS : String;
  begin
    bFreshRSP := true;
    noWeatherList := false;
    Result := 0;
    trueCheck := true;
    falseCheck := false;
    bUpdatingPlugin := false;
    bUpdatingWeatherIni := false;
    bDebugging := false;
    bUsingSkyrimWeathers := false;
    tempS := GetVersionStringRS(wbVersionNumber);
    for z := 0 to 30 do
    AddMessage('');
    AddMessage('================================');
    AddMessage('========== R.S.Patcher 1.5.1 ========== ');
    AddMessage('================================');
    AddMessage('');
    AddMessage('=== Checking TES5EDIT Version ===');
    AddMessage('Using Version '+ tempS);
    if Pos('3.1.',tempS) = 0 then begin
      MessageDlg('RSPatcher 1.5:  TES5Edit Version Mismatch'#13#13'This Patcher Requires'#13'TES5Edit 3.1.0+'#13#13'You are currently using'#13'TES5Edit '+tempS+''#13#13'You can find the most up-to-date version on the nexus'#13'Patcher will now exit',mtError, [mbOK], 0);
      Result := -1;
      Exit;
    end;
    RemoveFilter();
    AddMessage('=== Gathering ModList Information === ');
    findAllTheFiles;

    if not Assigned(RSFile) or not Assigned(RSPFile) then 
    begin
      MessageDlg('RSPatcher 1.5:  ERROR'#13#13'Could Not Find RealShelter.esp or RSPatch.esp.'#13#13'Please make sure both RSPatch and RealShelter are selected when loading up Tes5Edit.'#13#13'Terminating Script',mtError, [mbOK], 0);
      Result := -1;
      Exit;
    end;

    checkGrp := GroupBySignature(RSPFile, 'WTHR');
    if ElementCount(checkGrp) > 0 then
    bCleanUp := MessageDlg('RSPatcher 1.5 Notice:'#13#13'This is not a fresh copy of RSPatch.esp'#13#13'Would you like to clean your patch?'#13#13'Select no if you installed a new enb and only want to update the _weatherlist.ini file',mtWarning, [mbYes,mbNo], 0);
    //Cleanup Code
    CleanPatch(RSPFile, bCleanup);
    globalVariable := GrabFormByLocalID('0574DF',RSFile);
    AddRequiredElementMasters(globalVariable, RSPFile,false);
    wbCopyElementToFile(globalVariable, RSPFile, false,true);
    //EndCleanupCode
    //GatherIniInfo is a function that displays the research outcome box and selections
    if GatherIniInfo = -1 then 
    begin
      bUpdatingWeatherIni := OverrideModule(bUpdatingPlugin);
      seev(WinningOverride(globalVariable),'FLTV - Value', '0.0');
    end;
    if bQuitting then
    begin
      AddMessage('User Has Quit');
      RemoveFilter();
      Result := -1;
      Exit;
    end;
    if bDebugging then
    begin
      AddMessage('The CurrentCheckboxes give you:  Update Plugin: '+ BoolToStr(bUpdatingPlugin)  + ' andUpdatingWeathers: '+ BoolToStr(bUpdatingWeatherIni));
    end;
    if not bUpdatingPlugin and not bUpdatingWeatherIni then
    begin
      Result := -1;
      AddMessage('Exiting...');
      RemoveFilter();
      Exit;
    end;
    if bDebugging then
    begin
      AddMessage('Made it through GetFileGamePath()');
      AddMessage('Initbegin value of s = '+ s);
    end;
    if bWillUpdateWarburg then begin
      if not FixWarburg(RSPFile, WBFile) then begin
        AddMessage('Warburg Fix already applied,  Quitting');
        Result := -1;
        Exit;
      end;
    end;

    CreateTStringLists();
    if bIsBackingUpIni then  
    begin
      CopyIniFile(eDir,bDir, true);
      bIsBackingUpIni := false;
    end;
    if bUpdatingWeatherIni and not bIsBackingUpIni then
    begin
      CopyIniFile(bDir,eDir, false);
    end;
    //Change that needs to be changing before doing whole loop
    if bUpdatingPlugin and bUpdatingWeatherIni then begin
      AddMessage(' ');
      AddMessage('=== Creating Temporary Records to Reserve Conflicting FormIDs ===');
      ReserveLocalFormIDs();
      AddMessage(' ');
    end;
    if bWillUpdateRegions then
    begin
      AddMessage(' ');
      AddMessage('=== Adding Regions ==='); 
      AddMessage(' ');
      AddRegionsToRSPatch;
      regionWTHRCount := TList.Create;
      RegionWeatherCount(RSPFile);
      AddMessage('=== Gathering Weather Data Inside of Regions ==='); 

      bUsingSkyrimWeathers := IsUsingSkyrimWeathers(RSPFile);
      if bUsingSkyrimWeathers then
        AddMessage('---Vanilla Weathers are Used')
      else
        AddMessage('---Vanilla Weathers are NOT Used');
      seev(WinningOverride(globalVariable),'FLTV - Value', '1.0');
      //Add RS weathers to all regions supported by real shelter
      //AddToRegions(regionData,HexFormID(new_record), HexFormID(new_override), Name(new_record));
    end
    else
    begin
      AddMessage(' ');
      AddMessage('=== Skipping Region Additions ==='); 
      AddMessage(' ');
      seev(WinningOverride(globalVariable),'FLTV - Value', '0.0');
    end;

    AddMessage(' ');
    if bUpdatingPlugin then
    AddMessage('=== Going Through Files And Grabbing Appropriate Weathers ===')
    else
    AddMessage('=== Skipping Weather Processes ===');
    for fIndex := RSPFIndex-1 downto 0 do 
    begin
      if Lowercase(GetFileName(FileByIndex(fIndex))) = Lowercase('RealShelter.esp') then continue;
      if not (HasGroup(FileByIndex(fIndex), 'WTHR')) then continue;
      if bUpdatingPlugin then begin
        AddMessage(' ');
        AddMessage('------------------------------------------------------------------- Checking File: '+ GetFileName(FileByIndex(fIndex)));
      end;
      wthrGrp := GroupBySignature(FileByIndex(fIndex), 'WTHR');
      for fIndex2 := 0 to (ElementCount(wthrGrp) - 1) do
      begin
        wthrU := ElementByIndex(wthrGrp, fIndex2);
        wthrMR := RecordByFormID(FileByIndex(fIndex), FormID(wthrU), false);
        ProcessIt;
      end;
    end;
    fIdToSearch := TStringList.Create;
    fIdToSearch.Sorted := false;
    fIdToAdd := TStringList.Create;
    fIdToAdd.Sorted := false;
    fIniDB := TStringList.Create;
    fIniDB.Sorted := false;
    fIniDB.Delimiter := ',';
    fIdIndex := TStringList.Create;
    if(bUpdatingPlugin) then
    begin
      AddMessage(' ');
      AddMessage('=== Adding Appropriate Weathers To FormLists ==='); 
      AddMessage(' ');
      Slev(CurrentList, 'FormIDs', idCurrents);
      AddMessage('Success!  Added All Your Precipitation Weathers To RS_CurrentList');
      Slev(RSPList, 'FormIDs', idRSs);
      AddMessage('Success!  Added All Your Sheltered Weathers To RS_RSList');
      Slev(WSList, 'FormIDs', WSStringList);
      AddMessage('Success!  Added All Wind Speed Global Variables to RS_WSList');
      if bHasCoT then
      begin
        ReverseElements(ElementByIp(CurrentList, 'FormIDs'));
        ReverseElements(ElementByIp(RSPList, 'FormIDs'));
        ReverseElements(ElementByIp(WSList, 'FormIDs'));  
      end;
    
      if bHasFF and bWillUpdateFFLists then begin
        AddMessage(' ');
        AddMessage('=== Frostfall/Campfire Modifications ===');
        AddMessage(' ');
        GrabFFListsAndAddForms;
      end
      else  begin
        AddMessage(' ');
        AddMessage('=== Skipping Frostfall/Campfire Modifications ===');
        AddMessage(' ');
      end;

      fIdToSearch.CommaText := idToSearch.CommaText;
      fIdToAdd.CommaText:= idToAdd.CommaText;

      if Assigned(regionData) then regionData.Free;
      //idToAdd.Free;
      idToSearch.Free;
      idRSs.Free;
      idCurrents.Free;
      WSStringList.Free;
      FFSevereList.Free;
    end;
    if (bUpdatingWeatherIni) and (not bUpdatingPlugin) then
    begin
      AddPatchedWeathersToStringLists(fIdToAdd, fIdToSearch);
    end;
    if bDebugging then 
    AddMessage('about to search through weathers');
    if (bUpdatingWeatherIni) then 
    begin
      AddMessage(' ');
      AddMessage('=== Adding Weathers To _WeatherList.ini ==='); 
      AddMessage(' ');
      AddMessage('_weatherlist.ini Directory : '+ eDir);
      AddMessage('_weatherlistBackup.ini Directory : ' + bDir);
      AddMessage(' ');
      fIniDB := GrabAllTextInfoAndSearch(falseCheck);
      iniCtrl := TMemIniFile.Create(directory);
      for z := 0 to fIniDB.Count-1 do
      begin
        if bDebugging then
        AddMessage('Inside of fIniDB with z at  '+IntToStr(z));
        for zz := 0 to fIdToSearch.Count-1 do
        begin
          tempStr := UpperCase(fIniDB[z]);
          if Pos(fIdToSearch[zz], tempStr) > 0 then
          begin
          AddMessage('Adding ' + fIdToAdd[zz] + ' to WEATHER0' + IntToStr(z+1)+ ' By Matching Hex Number: ' + fIdToSearch[zz]);
          fIniDB[z] := fIniDB[z] + ' ' + fIdToAdd[zz];  
          end;
        end;
      end;
      for z1 := 0 to fIniDB.Count-1 do
      begin
          if(z1 < 9) then
          secStr2 := 'WEATHER00' + IntToStr(z1+1)
          else
          secStr2 := 'WEATHER0' + IntToStr(z1+1);
        iniCtrl.WriteString(secStr2, 'WeatherIDs', fIniDB[z1]);
      end;
      iniCtrl.UpdateFile;
      iniCtrl.Free;
    end;
    if Assigned(fIdToSearch) then fIdToSearch.Free;
    if Assigned(fIdToAdd) then fIdToAdd.Free;
    if Assigned(fIniDB) then fIniDB.Free;
    if Assigned(fIniDB) then fIdIndex.Free;
    //idToAdd.Free;
    if Assigned(regionWTHRCount) then regionWTHRCount.Free;
    cleanGRUP(RSPFile, 'KYWD','=== Removing Temporary Records ===');
    //for some reason I am unable to call idToAdd.Free; as it gives me a pointer error.  I have no idea how to fix it .
    AddMessage('=== Cleaning And Sorting Masters ==='); 
    CleanMasters(RSPFile);
    SortMasters(RSPFile);
    RemoveFilter();
    AddMessage('=== =====================  ===');
    AddMessage('=== Successfully Created Your Patch! ===');
    AddMessage('=== =====================  ===');
  end;

end.
