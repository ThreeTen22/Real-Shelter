{
  RSFunctions

  These are most of the functions that do not require Globals from RSPatcher.
  Used to keep the code from getting rediculously long.    
}

unit RSFunctions;

uses mteFunctions;


procedure ChangeModelPath(localID, newPath: string; sFile,dFile: IInterface);
var
	tRecord: IInterface;
begin
	tRecord := GrabFormByLocalID(localID, sFile);
	if Assigned(dFile) then begin
		AddRequiredElementMasters(tRecord, dFile, false);
		tRecord := wbCopyElementToFile(tRecord, dFile, false, true);
	end;
	seev(tRecord, 'Model\MODL', newPath);
end;


procedure GetFormListIDs(localID: string; sFile: IInterface; var tList: TStringList; bGrabOverride: boolean);
  var
  i: integer;
  fGroup, tForm: IInterface;
  output2 : String;
  begin
  	AddMessage('SFileName: '+ GetFileName(sFile));
    fGroup := GroupBySignature(sFile, 'FLST');
    //if not Assigned(fGroup) then Exit;
    AddMessage('FLST Count: '+ IntToStr(Pred(ElementCount(fGroup))));
    for i := 0 to Pred(ElementCount(fGroup)) do begin
      tForm := ElementByIndex(fGroup, i);
      AddMessage('HexIDs: '+ HexFormID(tForm));
      if Pos(localID, HexFormID(tForm)) > 0 then Break;
      tForm := nil;
    end;
   	if not Assigned(tForm) then Exit;
    if (OverrideCount(tForm) > 0) and bGrabOverride then begin
      tForm := MasterOrSelf(tForm);
      tForm := WinningOverride(tForm);
    end;
    tForm := ElementByIp(tForm, 'FormIDs');
    if not Assigned(tForm) then Exit;
    for i := 0 to Pred(ElementCount(tForm)) do begin
      output2 := geev(tForm, '['+IntToStr(i)+']');
      output2 := CopyFromTo(output2, length(output2)-8,length(output2)-1);
      tList.Append(output2);
      AddMessage('-Adding '+output2+' to List');
    end;
  end;


procedure SetFormListIDs(localID: String; sFile: IInterface; var dFile: IInterface; tSList: TStringList);
  var
    fileForm: IInterface;
  begin
  	AddMessage('tsList: '+ tSList.CommaText);
    while length(localID) < 6 do
      localID := '0'+localID;
    fileForm := GrabFormByLocalID(localID, sFile);
    if OverrideCount(MasterOrSelf(fileForm)) > 0 then
      fileForm := WinningOverride(MasterOrSelf(fileForm));
    AddRequiredElementMasters(fileForm, dFile, false);
    fileForm := wbCopyElementToFile(fileForm, dFile,false,true); 
    slev(fileForm, 'FormIDs', tsList);
  end;

procedure cleanGRUP(iiFile: IInterface; sGRUP, sMessage: string);
  var
    i: integer;
    bHasGroup: boolean;
    iiCheckGrp, e: IInterface;

  begin
    bHasGroup := HasGroup(iiFile, sGRUP);
    if bHasGroup then begin
      iiCheckGrp := GroupBySignature(iiFile, sGRUP);
      //RemoveNode(e);
      AddMessage(sMessage);
      for i := Pred(ElementCount(iiCheckGrp)) downto 0 do begin
        e := ElementByIndex(iiCheckGrp, i);
        Remove(e);
      end;
    end;
  end;

function CopyIniFile(sourceDir: string; newDir:string; bIsBackup:boolean): String;
	var
		iniCtrlb: TMemIniFile;
		updateIniStrings: TStringList;
	begin
	 	updateIniStrings := TStringList.Create;
	 	iniCtrlb := TMemIniFile.Create(sourceDir);
	 	iniCtrlb.getStrings(updateIniStrings);
	 	iniCtrlb.Free;
	 	iniCtrlb := TMemIniFile.Create(newDir);
	 	iniCtrlb.setStrings(updateIniStrings);
	 	iniCtrlb.UpdateFile;
	 	iniCtrlb.Free;
	 	updateIniStrings.Free;
	 	if bIsBackup then
	 	Result := ('Finished Creating Your Backup.  You can find it here: ' + newDir)
	 	else
	 	Result := 'Refreshing _WeatherList.ini';
	end;
//Useful for grabbing master records from hexformIDs
function LoadOrderFromHexID(hexID: string): IInterface;
	var
		i,fIndex: Integer;
		croppedHexID: String;
	begin
		while Length(hexID) < 8 do
			hexID := '0'+ hexID;
		if (pos('$',hexID) = 0) and (pos('x',hexID) = 0) then begin
			hexID := '$'+ hexID;
		end;
		i := (hexID shr 24)+1;
		if i < 2 then i := 0;
			Result := FileByIndex(i);
	end;

function ContainerSize(mRecord: IInterface; ipPath: String): integer;
	var
		contAmount, precpNative: Integer;
		eContainer: IInterface;
	begin
		Result := 0;
		eContainer := ElementByIp(mRecord, ipPath);
		contAmount := ElementCount(eContainer)-1;
		if Assigned(eContainer) then
		Result := contAmount;
	end;

function IsUsingSkyrimWeathers(iiFile: IInterface): boolean;
	var
      a,b,c,d: Integer;
       append: String;
      regionGrp, newelement, temp, region, iiContainer :IInterface;
      tempFormID : string;
    begin
    	Result := false;
    	AddMessage(' ');
    	AddMessage(' ');
    	AddMessage('------  Checking To See If The Supported Regions Uses Vanilla Records');
    	regionGrp := GroupBySignature(iiFile,'REGN');
    	for a := 0 to Pred(ElementCount(regionGrp)) do
    	begin
    		region := ElementByIndex(regionGrp, a);
    		iiContainer := ElementByIp(region,'Region Data Entries\Region Data Entry\[1]');
    		d := ElementCount(iiContainer);
    		for b := 0 to Pred(d) do
    		begin
    			append := '['+IntToStr(b)+']\[0]';
    			tempFormID := geev(iiContainer, append);
    			if pos('R:00',tempFormID) > 0 then 
    			begin
    				Result := true;
    				Exit;
    			end;
    		end;
    	end;
    end;

{
	AddToRegions


}

function AddToRegions(iiFile: IInterface; WTHRToAdd : cardinal ; FormIDToCompare : string ; nameOfWeather : String ; var regionWCount: TList): boolean;
    var
      a,b,c,d: Integer;
       append: String;
      wTypesArray, newelement, temp, region :IInterface;
      tempForm : String;

      regionGrp : IInterface;
    begin
    	Result := false;
    	AddMessage('------  Checking Regions For: '+'[WTHR:'+FormIDToCompare+']');
    	regionGrp := GroupBySignature(iiFile, 'REGN');
    	for a := 0 to Pred(ElementCount(regionGrp)) do
    	begin
    	  	region := ElementByIndex(regionGrp, a);
    	  	wTypesArray := ElementByIp(region,'Region Data Entries\Region Data Entry\[1]');
    	  	if not Assigned(iiFile) then begin 
    	  		AddMessage('ELementByIp is Broke' + regionData2[a]);
    	  	end;
    	  	d := ElementCount(wTypesArray);
    	  	for b := 0 to Pred(d) do
    	  	begin
    	    	append := '['+IntToStr(b)+']\[0]';
    	    	tempForm := geev(wTypesArray, append);
    	    	if Pos(FormIdToCompare, tempForm) > 0 then 
    	    	begin
    	    		AddMessage('--------  Weather Found Inside: '+ Name(region));
    	    		newelement := ElementAssign(wTypesArray,HighInteger,nil,false);
    	    		senv(newelement,'[0]\', WTHRToAdd);
    	    		Result := true;
    	    	end;
			end;
    	end;
    end;

function GrabFormByLocalID(sLocalFormID: string; iiFile: IInterface): IInterface;
	var
	sLoadOrderID: string;
	iiRecord: IInterface;
	begin
    sLoadOrderID := LocalIDToLoadOrderID(sLocalFormID, iiFile,true);
    iiRecord := RecordByFormID(iiFile, StrToInt64(sLoadOrderID), true);
    Result := iiRecord;
	end;

{
LocalIDToLoadOrderID
  Takes the local 6hex digit value and adds the appropriate load order prefix.

  localHex -  The local 6hex digit variable, do not add a $ or 0x.  MUST BE 6 DIGITS LONG!
  fileName - File you are grabbing the formID from as String
  addHex - This will add a '$' to the beginning.:
  Example: 
  hexString := LocalIdToLoadOrderID('024098','someMod.esp', true);
  f := RecordByFormID(IwbFile, StrToInt64(hexString), false);
}

function LocalIDToLoadOrderID(localHex: string ; iiFile: IInterface; addHex:boolean): String;
	var
	  z, fileIndx: integer;
	  indxName, properHex,prefHex: string;
	begin
		if (Pos('$', localHex) > 0) or (Pos('x', localHex) > 0) then begin
		localHex := IntToHex(localHex shl 0,6);
		end;
		while Length(localHex) < 6 do
		localHex := '0'+ localHex;
	  	prefHex := IntToHex(GetLoadOrder(iiFile),2);
	  	if addHex then begin
	  	properHex := ('$'+PrefHex+localHex);
	  	end
	  	else
	  	properHex := PrefHex + localHex;
	  	Result := properHex;
	end;

function getLocalHexID(e: IInterface; shortform:boolean): String;
   var
     i: integer;
     loadOrderString, cutOffStr, finalStr: String;
   begin
	   loadOrderString := HexFormID(e);
	   cutOffStr := CopyFromTo(loadOrderString, 3, 8);
	   finalStr := '0x'+ cutOffStr;
	   if shortform then
	   begin
	   	cutOffStr := StrToInt64(finalStr);
	   	finalStr := IntToHex(cutOffStr, 1);
	   end;
	   result := finalStr;
   end;


function Odd(num: integer): boolean;
   var 
   	roundNum: integer;
   begin
      roundNum := num mod 2;
      if roundNum = 0 then
      	Result := true
      else
      	Result := false;
   end;


// NOT A GLOBAL FUNCTION!
procedure createOverrideBox(var frm: TObject;var rg: TObject;var pnl: TObject;var iniInfo1: TMemo;var rb1: TCheckBox; var rb2: TCheckBox; var rb3: TCheckBox; var btnOk: TButton; var btnCancel: TButton);
	var
		height: Integer;

	begin
	   frm.Caption := '(OUTDATED) Override Module';
	   frm.Width := 374;
	   frm.Position := poScreenCenter;
	   height := 400;
	   
	   	
	   frm.Height := height;

	   rg := TGroupBox.Create(frm);
	   rg.Parent := frm;
	   rg.Left := 6;
	   rg.Height := 100;
	   rg.Top := 10;
	   rg.Width := 345;
	   rg.Caption := 'Ok then, What Do You Want To Do?:';
	   //rg.ClientHeight := 100;

	   pnl := TPanel.Create(frm);
	   pnl.Parent := frm;
	   pnl.BevelOuter := bvNone;
	   pnl.Align := alBottom;
	   pnl.Height := height-rg.Top-rg.Height-50;
	   iniInfo1 := TMemo.Create(pnl);
	   iniInfo1.Parent := pnl;
	   iniInfo1.ReadOnly := true;
	   iniInfo1.Left := 6;
	   iniInfo1.Top := 0;
	   iniInfo1.Width := 345;
	   iniInfo1.Height := 200;
	   iniInfo1.Scrollbars := ssVertical;
	   iniInfo1.WordWrap := true;
	   iniInfo1.Lines.Text := ('=========.Welcome to the Override Module.========='#13#13
	   'THIS IS CURRENTLY FUNCTIONAL BUT OUTDATED, EXPECT A MORE EXPANDED VERSION IN 2.0'#13#13
	   'Here you can force any and all parts of the script to run.   If you arrived here by accident, just click the Quit button and run the script again.'#13#13
	   'This is a final failsafe if somehow the automatic functions do not work correctly.  You should only use this tool if you are 100% certain that the automatic part of this script is making wrong decisions.'#13#13
	   'Normally you only run "Create RealShelter Patch if there are no weather(WTHR) forms found in your RSPatch.esp.  A manual removal of all weathers will allow the script to work correctly (I suggest right clicking the weather dropdown menu inside of RSPatch.esp and removing that)'#13#13
	   'If you dont know whether or not you use weathers for ENB,  dont select it and only select "backup WeatherList.ini"  If you run this script again and it still is telling you that it cant find _weatherlistBackup.ini then your enb does not use weathers.'#13#13
	   'If you Know you do use weathers and the script keeps saying it cannot find _weatherlistBackup.ini, then visit your enbseries folder.  Create a copy of _weatherlist.ini and rename it to "_weatherlistBackup.ini". Then rerun this script and select "Update Weather Inis" (and "Create RealShelter Patch" if you need to as well).'#13#13
	   'If you want more detail on what exactly is going on in the background when running this script send me a pm and I will gladly explain it to you.');


	   rb1 := TCheckBox.Create(rg);
	   rb1.Parent := rg;
	   rb1.Left := 24;
	   rb1.Top := 23;
	   rb1.Caption := 'Patch RSPatch.esp';
	   rb1.Width := 180;
	   rb1.State := cbUnchecked;
	   rb2 := TCheckBox.Create(rg);
	   rb2.Parent := rg;
	   rb2.Left := 24;
	   rb2.Top := rb1.Top + 25;
	   rb2.Caption := 'Update _Weatherlist.ini';
	   rb2.Width := 150;
	   rb2.State := cbUnchecked;
	   rb3 := TCheckBox.Create(rg);
	   rb3.Parent := rg;
	   rb3.Left := 24;
	   rb3.Top := rb2.Top + 25;
	   rb3.Caption := 'backup _weatherlist.ini';
	   rb3.Width := 180;	
	   rb3.State := cbUnchecked;
                
	   btnOk := TButton.Create(frm);
	   btnOk.Parent := frm;
	   btnOk.Caption := 'Patch';
	   btnOk.ModalResult := mrOk;
	   btnOk.Left := frm.Width - 150;
	   btnOk.Top := 28;
	   
	   btnCancel := TButton.Create(frm);
	   btnCancel.Parent := frm;
	   btnCancel.Caption := 'Quit';
	   btnCancel.ModalResult := mrCancel;
	   btnCancel.Left := btnOk.Left;
	   btnCancel.Top := btnOk.Top+45;
	end;


// NOT A GLOBAL FUNCTION!
procedure createResearchBox(var Form1: TObject;var DiagBox: TMemo;var pnl1: TObject;var rg:TGroupBox;var btnOk: TButton;var btnAbort: TButton;var btnCancel: TButton; var bQuitting: Boolean;
			    var bWillUpdateRegions:boolean;var bWillUpdateWarburg:boolean; var bWillUpdateFFLists:boolean; var bWillRemoveVE:boolean;var bWillUseBlankSPG:boolean;var bWillRemoveSnowSpread:boolean;var bWillRemoveRainWS:boolean;var bWillUpdateMlmList:boolean;var bWillTurnOffSplashes:boolean;
			    var boolList: TList; var results: TModalResult);

	//bCorrupt,bRegMod,bHasWeatherList,bHasBackupList,bFreshRSP: boolean;

	var
		bCorrupt,bRegMod,bHasWeatherList,bHasBackupList,bFreshRSP,bHasFF,bHasRSFF,bHasWOW,bHasCot,bHasWB,bHasRSRO,bHasMLM : Boolean;
		i : Integer;
		ffOutline, rsOutline, ffRSOutline, miscOutline, rsroOutline, mlmOutline, visOutline: TGroupBox;
		ff, ff2,rs,rs2, rs3, wb, rsro, mlm, spl: TCheckBox;
		ffLabel, ff2Label,rsLabel,rs2Label, rs3Label, wbLabel,rsroLabel, mlmLabel, splLabel: TLabel;
		
	begin
	 	i := 0;
	 	bCorrupt := boolList[i];
		Inc(i);
		bRegMod := boolList[i];
		Inc(i);
		bHasWeatherList := boolList[i];
		Inc(i);
		bHasBackupList := boolList[i];
		Inc(i);
		bFreshRSP := boolList[i];
		Inc(i);
		bHasWOW := boolList[i];
		Inc(i);
		bHasRSFF := boolList[i];
		Inc(i);
		bHasFF := boolList[i];
		Inc(i);
		bHasCot := boolList[i];
		Inc(i);
		bHasWB := boolList[i];
		Inc(i);
		bHasRSRO := boolList[i];
		Inc(i);
		bHasMLM := boolList[i];


		Form1.Height := 600;
		Form1.Width := 1200;
		Form1.Position := poScreenCenter;
		Form1.Caption := 'R.S.Patcher 1.5';
		Form1.ClientHeight := 600;
		Form1.ClientWidth := 1240;
		

		DiagBox := TMemo.Create(Form1);
		DiagBox.Parent := Form1;
		DiagBox.Width := 490;
		DiagBox.Height := 540;
		DiagBox.Left := 5;
		DiagBox.Top := 5;
		DiagBox.Alignment := taLeftJustify;
		DiagBox.ReadOnly := true;
		DiagBox.Scrollbars := ssVertical;

		pnl1 := TPanel.Create(Form1);
		pnl1.Parent := Form1;
		pnl1.Left := DiagBox.Left + (DiagBox.Width/2) - (pnl1.Width);
		pnl1.Width := 362;
		pnl1.Height := 36;
		pnl1.Top := DiagBox.Top + DiagBox.Height;

		btnOk := TButton.Create(Form1);
		btnOk.Parent := pnl1;
		btnOk.Caption := 'Create Patch';
		btnOk.ModalResult := mrYes;
		btnOk.Width := 100;
		btnOk.Left := 14;
		btnOk.Top := 5;

		btnAbort := TButton.Create(Form1);
		btnAbort.Parent := pnl1;
		btnAbort.Caption := 'Exit Script';
		btnAbort.ModalResult := mrCancel;
		btnAbort.Width := 100;
		btnAbort.Left := pnl1.Width - (btnAbort.Width + 14);
		btnAbort.Top := btnOk.Top;

		btnCancel := TButton.Create(Form1);
		btnCancel.Parent := pnl1;
		btnCancel.Caption := 'Override Decision';
		btnCancel.ModalResult := mrOk;
		btnCancel.Width := 110;
		btnCancel.Left := ((btnOk.Left+btnOk.Width) + ((btnAbort.Left-(btnOk.Left+btnOk.Width))/2)-(btnCancel.Width/2))-1;
		btnCancel.Top := btnOk.Top;	

	   	rg := TGroupBox.Create(Form1);
	   	rg.Parent := Form1;
	   	rg.Height := 550;
	   	rg.Width := 700;
	   	rg.Left := DiagBox.Width + 32;
	   	rg.Top := 20;

	    rsOutline := TGroupBox.Create(Form1);
	    rsOutline.Parent := rg;
	    rsOutline.Height := 374;
	    rsOutline.Width := rg.Width/2 - 10;
	    rsOutline.Left :=  7;
	    rsOutline.Top := 10;
	    rsOutline.Caption := 'Real Shelter Options';


	   	ffOutline := TGroupBox.Create(Form1);
	   	ffOutline.Parent := rg;
	   	ffOutline.Height := 100;
	   	ffOutline.Width := rg.Width/2 - 10;
	   	ffOutline.Left :=  rsOutline.Left+rsOutline.Width + 5;
	   	ffOutline.Top := rsOutline.Top;
	   	ffOutline.Caption := 'Frostfall Options';	

	    rsroOutline := TGroupBox.Create(Form1);
	    rsroOutline.Parent := rg;
	    rsroOutline.Height := 144;
	    rsroOutline.Width := rsOutline.Width;
	    rsroOutline.Left :=  rsOutline.Left;
	    rsroOutline.Top := rsOutline.Height +rsOutline.Top + 10;
	    rsroOutline.Caption := 'Real Shelter Rain Overhaul Options';

	   	ffRSOutline := TGroupBox.Create(Form1);
	   	ffRSOutline.Parent := rg;
	   	ffRSOutline.Height := 100;
	   	ffRSOutline.Width := ffOutline.Width;
	   	ffRSOutline.Left :=  ffOutline.Left;
	   	ffRSOutline.Top := ffOutline.Top + ffOutline.Height + 10;
	   	ffRSOutline.Caption := 'Real Shelter: Frostfall Tents';	  

	    mlmOutline := TGroupBox.Create(Form1);
	    mlmOutline.Parent := rg;
	    mlmOutline.Height := 100;
	    mlmOutline.Width := rg.Width/2 - 10;
	    mlmOutline.Left :=  ffOutline.Left;
	    mlmOutline.Top := ffRSOutline.Top+FFRSOutline.Height + 10;
	    mlmOutline.Caption := 'Misty''s Lightning Options';


	    miscOutline := TGroupBox.Create(Form1);
	    miscOutline.Parent := rg;
	    miscOutline.Height := 100;
	    miscOutline.Width := rg.Width/2 - 10;
	    miscOutline.Left :=  ffOutline.Left;
	    miscOutline.Top := mlmOutline.Top + mlmOutline.Height + 10;
	    miscOutline.Caption := 'Warburg Mod Options';


    	ff := ConstructCheckbox(Form1, ffOutline, 20, 20, ffOutline.Width - 30, 'Add Sheltered Weathers To Frostfall FormLists. ', cbChecked);
    	//NOTE:  These ConstructLabel and ConstructCheckBox are using mator's old function,  it is not using the one provided by the current mteFunctins.pas
    	ffLabel := ConstructLabel(Form1, ffOutline, ff.Top+20, ff.Left+30, 50, 0,'By selecting this, frostfall will be able to recognize'#13'sheltered weather, and therefore remove the extra'#13'survivability bonus when staying under shelter during a'#13'severe storm.');

    	ff2 := ConstructCheckBox(Form1, ffRSOutline,ff.Top, ff.Left, ff.Width, 'Remove Snow Spread', cbUnchecked);
    	ff2Label := ConstructLabel(Form1, ffRSOutline, ff2.Top+20, ff2.Left+30, 20, 500, 'Select this to remove the directional randomness'#13'for snowy weathers.  This will exponentially improve'#13'the directional accuracy of the snow emitters.'#13'The downside is more predictable wind directions.');

    	rs := ConstructCheckBox(Form1, rsOutline, 20,20,rsOutline.Width-30,'Create Regional Overrides', cbChecked);
    	rsLabel := ConstructLabel(Form1, rsOutline, rs.Top+20, rs.Left+30, 20, 500,'These overwrites are necessary in order to have'#13'weather changes while under shelter.  This is not a'#13'requirement, but if you decide not to then the same '#13'weather will persist indefinitely while under shelter.'#13'These changes DO NOT affect the actual weather');

    	rs2 := ConstructCheckBox(Form1, rsOutline, rsLabel.Top + 80, rs.Left, rs.Width,'Remove Sheltered Weather Visual Effects', cbUnchecked);
    	rs2Label := ConstructLabel(Form1, rsOutline, rs2.Top+20, rs2.Left+30, 20, 500,'Select this to also remove weather visual effects'#13'For example: selecting this will remove the fog'#13'from Supreme Storm rains while under shelter');

    	rs3 := ConstructCheckBox(Form1, rsOutline, rs2Label.Top + 54, rs2.Left, rs2.Width,'Use Invisible Precipitation', cbChecked);
    	rs3Label := ConstructLabel(Form1, rsOutline, rs3.Top+20, rs3.Left+30, 20, 500,'Select this to have sheltered weather activate invisible'#13'rain or snow rather than removing it'#13''#32'-Enables raindrop animation on large bodies of water'#13''#32'-Certain town and city lights will stay on'#13''#32'-Guards no longer use torches while raining'#13''#32#32'or snowing under shelter');
    	
    	spl := ConstructCheckBox(Form1, rsOutline, rs3Label.Top + 90, rs3.Left, rs3.Width, 'Remove R.S. Rain Splashes', cbUnchecked);
    	splLabel := ConstructLabel(Form1, rsOutline, spl.Top+20, spl.Left+30, 20, 500,'By selecting this, R.S. rain splashes will not appear.'#13'This option is meant for Wonders of Weather users, but'#13'anyone can apply this setting.');

    	rsro := ConstructCheckBox(Form1, rsroOutline, 20,20, rsroOutline.Width-30,'Reduce Rain Wind Speed', cbUnchecked);
    	rsroLabel := ConstructLabel(Form1, rsroOutline, rsro.Top+20, rsro.Left+30, 20, 500,'This will reduce the angle at which rain travels'#13'By doing so you will find that the difference between the'#13'outside rain and sheltered rain near perfect.'#13'-This will not affect tree swaying'#13'-This will slow down cloud movement a bit'#13'-I only modify the weathers which use my S.P.G.');																		  

    	wb := ConstructCheckBox(Form1, miscOutline, 20,20,miscOutline.Width-30,'Apply Warburg Fix', cbUnchecked);
    	wbLabel := ConstructLabel(Form1, miscOutline, wb.Top+20, wb.Left+30, 20, 500,'Select this to apply a semi-permanent fix for warburgs'#13'For More Information, please read the info on the left'#13'under the Warnings tab');

    	mlm := ConstructCheckBox(Form1, mlmOutline, 20, 20, mlmOutline.width-30, 'Add Sheltered Weather To Misty''s FormLists', cbUnchecked);
    	mlmLabel := ConstructLabel(Form1, mlmOutline, mlm.Top+20, mlm.Left+30, 50, 0,'By selecting this, Misty''s Lightning will be able to recognize'#13'sheltered weather, and spawn lightning while under shelter');

    	if not bHasRSRO then begin
 			rsro.Enabled := false;
			rsroLabel.Enabled := false;
			rsro.State := cbUnchecked;    		
    	end;
 		
 		if not bHasRSFF then begin
 			ff2.Enabled := false;
			ff2Label.Enabled := false;
			ff2.State := cbUnchecked;
 		end;

    	if not bHasWB then begin
    		wb.Enabled := false;
    		wbLabel.Enabled := false;
    		wb.State := cbUnchecked;
    	end;

    	if not bHasFF then begin
    		ff.Enabled := false;
			ffLabel.Enabled := false;
			ff.State := cbUnchecked;
    	end;

    	if not bHasMLM then begin
    		mlm.Enabled := false;
    		mlmLabel.Enabled := false;
    		mlm.State := cbUnchecked;
    	end else mlm.State := cbChecked;

    	if bHasWOW then begin
    		spl.State := cbChecked;
    	end;

    	if not bUpdatingPlugin then begin
    		ff.Enabled := false;
    		ffLabel.Enabled := false;
    		ff.State := cbUnchecked;

    		ff2.Enabled := false;
			ff2Label.Enabled := false;
			ff2.State := cbUnchecked;

    		rs.Enabled := false;
    		rsLabel.Enabled := false;
    		rs.State := cbUnchecked;

    		rs2.Enabled := false;
    		rs2Label.Enabled := false;
    		rs2.State := cbUnchecked;

    		rs3.Enabled := false;
    		rs3Label.Enabled := false;
    		rs3.State := cbUnchecked;

    		spl.Enabled := false;
    		splLabel.Enabled := false;
    		spl.State := cbUnchecked;

    		rsro.Enabled := false;
			rsroLabel.Enabled := false;
			rsro.State := cbUnchecked;  

    		wb.Enabled := false;
    		wbLabel.Enabled := false;
    		wb.State := cbUnchecked;

    		mlm.Enabled := false;
    		mlmLabel.Enabled := false;
    		mlm.State := cbUnchecked;
    	end;
    	

	//---------------------------------------------------------------------------------------

		DiagBox.Lines.Add(' ');
		Diagbox.Lines.Add('__________                             ');
		DiagBox.Lines.Add('WARNINGS  \_________________________________________________________________');
		
		if bCorrupt then begin
		DiagBox.Lines.Add(' ');
		DiagBox.Lines.Add('One or more the following files have been detected:');
		DiagBox.Lines.Add('SUM.esp');
		DiagBox.Lines.Add('ReProccer.esp');
		DiagBox.Lines.Add('SkyRe_Main.esp & Modules');
		DiagBox.Lines.Add('ASIS-Dependency.esp');
		DiagBox.Lines.Add(' ');
		DiagBox.Lines.Add('-----SkyRe and All SkyProc dependant mods have had a long history of corrupting files when you try to copy their records in Tes5Edit.  As I know of no mods that use skyproc to make weather records or regional data this shouldnt be an issue.'); 
		DiagBox.Lines.Add(' ');
		end;
		
		If bHasWB then begin
		DiagBox.Lines.Add('Warburgs 3D Map World Detected!');
		DiagBox.Lines.Add('   Some people have had complaints about it not working with real shelter.');
		DiagBox.Lines.Add(' ');
		DiagBox.Lines.Add('   I HIGHLY suggest not doing this fix until you know this is a problem for you');
		DiagBox.Lines.Add(' ');
		Diagbox.Lines.Add('   In order to fix this, RSPatcher will transfer the map weather from Warburgs into RSPatch.');
		DiagBox.Lines.Add('   Please make sure to save both RSPatch and Warburgs patch after this has happened.  ');
		DiagBox.Lines.Add('Before playing Skyrim place warburgs mod after RSPatch and you will be good to go!');
		DiagBox.Lines.Add('  If you ever need to uninstall Real Shelter, then reinstall Warburgs otherwise the colors may seem off on the map');
		DiagBox.Lines.Add(' ');
		DiagBox.Lines.Add('  If you wish for this fix then please select the coorisponding checkbox to the right.');
		DiagBox.Lines.Add(' ');
		end;

		Diagbox.Lines.Add('__________                           ');
		DiagBox.Lines.Add('NOTICE        \_________________________________________________________________');
		if bRegMod then begin
		DiagBox.Lines.Add(' ');
		DiagBox.Lines.Add('One or more of these esp files have been found in your modlist');
		DiagBox.Lines.Add('Tropical Skyrim.esp');
		Diagbox.Lines.Add('SummerSkies.esp');
		DiagBox.Lines.Add('---As Of now all snow-only regions do not support rain shelters, as those mods make skyrim a tropical place, it will start to snow if you go under a shelter regardless of what weather is occuring before entering.'); 
		end;
		DiagBox.Lines.Add(' ');
		if bHasRSFF then
		DiagBox.Lines.Add('Real Shelter: Frostfall Tents Detected');
		if bHasRSRO then
		DiagBox.Lines.Add('Real Shelter Rain Overhaul Detected');
		if bHasFF then
		DiagBox.Lines.Add('Frostfall Detected');

		Diagbox.Lines.Add('__________                             ');
		DiagBox.Lines.Add('NEXT STEPS \_________________________________________________________________');
		DiagBox.Lines.Add(' ');
		if bHasWeatherList then
		DiagBox.Lines.Add('-You use an ENB preset that uses weathers' )
		else
		DiagBox.Lines.Add('-Your ENB preset does not use weather inis or you do not use ENB' );
		
		DiagBox.Lines.Add(' ');
		if bHasBackupList then
		DiagBox.Lines.Add('-Your _backupWeatherlist.ini was found in your enbseries folder and it contained weather information')
		else
		DiagBox.Lines.Add('-No _backupWeatherlist.ini was found.');
		
		DiagBox.Lines.Add(' ');
		if bFreshRSP then
		begin
		DiagBox.Lines.Add('-Your loaded RSPatch.esp meets the right requirements for patching');
		DiagBox.Lines.Add('  [RSPatch.esp does not contain any weather records.]');
		DiagBox.Lines.Add(' ');
		end
		else
		begin
		DiagBox.Lines.Add('-Your loaded RSPatch.esp has already been patched ');
		DiagBox.Lines.Add('  [There are weather records inside of RSPatch.esp]');
		DiagBox.Lines.Add(' ');	
		end;

		Diagbox.Lines.Add('-----------------------------------------------------');
		DiagBox.Lines.Add('Based on the factors above I am going to:    ');  
		Diagbox.Lines.Add('-----------------------------------------------------');                                                            
		DiagBox.Lines.Add(' ');
		if bIsBackingUpIni then begin
		DiagBox.Lines.Add('-Backup your _weatherlist.ini file and save it here:');
		DiagBox.Lines.Add('  '+ bDir);
		DiagBox.Lines.Add(' ');
		end
		else if bUpdatingWeatherIni then begin
		DiagBox.Lines.Add('-Leave your already created _weatherlistBackup.ini alone');
		DiagBox.Lines.Add(' ');
		end
		else begin
		DiagBox.Lines.Add('-Not do anything involving ENBs');
		DiagBox.Lines.Add(' ');
		end;
		
		if bUpdatingPlugin then begin
		DiagBox.Lines.Add('-Create your RSPatch');
		DiagBox.Lines.Add(' ');
		end
		else begin
		DiagBox.Lines.Add('-Leave your RSPatch.esp alone');
		DiagBox.Lines.Add(' ');
		end;
		if bUpdatingWeatherIni then begin
		DiagBox.Lines.Add('-Update your _weatherlist.ini file');
		DiagBox.Lines.Add(' ');	
		end;

		if bFreshRSP or not bIsBackingUpIni then begin
		DiagBox.Lines.Add(' ');	
		DiagBox.Lines.Add(' ');	
		DiagBox.Lines.Add(' ');	
		DiagBox.Lines.Add(' ');	
		DiagBox.Lines.Add(' ');	
		DiagBox.Lines.Add(' ');	
		DiagBox.Lines.Add(' ');		
		end;
		DiagBox.Lines.Add(' ');	
		DiagBox.Lines.Add(' ');	
		DiagBox.Lines.Add(' ');	
		Diagbox.Lines.Add('__________                            ');
		DiagBox.Lines.Add('Q & A           \_________________________________________________________________');
		DiagBox.Lines.Add(' ');
		if not bFreshRSP then
		begin
		DiagBox.Lines.Add('Q: I cant create a new RSPatch! / It doesnt seem to do anything.   What do I do?');
		DiagBox.Lines.Add(' ');
		DiagBox.Lines.Add('    -If you wish to create a new patch all you need to to is to replace your RSPatch.esp with a fresh copy, you can do that by reinstalling RSPatch.esp through NMM or MO');
		DiagBox.Lines.Add('    -If you are familiar with Tes5Edit then an alternative to reinstalling is to manually remove all weather and regional records(if applicable) from your loaded RSPatch.esp then run the script again.');
		end;
		if bIsBackingUpIni then
		begin
		DiagBox.Lines.Add('Q: Why are you backing up my ini file?');
		DiagBox.Lines.Add(' ');
		DiagBox.Lines.Add('    -Because new weather records are created everytime you run the realshelterpatch script,  I needed to come up with a way to keep your weatherlist.ini clean.  If I didnt then after 4-5 patches your weatherlist will be full of unused and possibly conflicting formIDs of previous RS records.  Rather than trying to keep track of the FormIDs of previoous patches, which would have been extremely tedious,  I instead chose a much easier solution');
		DiagBox.Lines.Add(' ');
		DiagBox.Lines.Add('    -By backing up your weatherlist before filling it up with RS weather ids I can then use it in the same manner that you would use a backup to restore your computer or phone.  I would grab a copy of your _weatherlistBackup file, add in all the newly created FormIDs, and fully replace the real _weatherlist with our new version');
		DiagBox.Lines.Add(' ');
		end;

		if bUpdatingWeatherIni and not bIsBackingUpIni then
		begin
		DiagBox.Lines.Add('Q: I Used your script and my weather transitions still seem off.');
		DiagBox.Lines.Add('    -If you are upgrading from Beta:, check your current _weatherlist.ini and see if there are any RealShelter weathers in there');
		DiagBox.Lines.Add('    -If you want to make sure there is no RS weathers in both your _weatherlist.ini and _weatherlistBackup.ini files, then delete your enbseries folder and reinstall your ENB preset');
		DiagBox.Lines.Add('    -Try disabling your weather');
		DiagBox.Lines.Add(' ');
		end;
		DiagBox.Lines.Add('Q. I have upgraded from 1.2 to 1.3.1 and it is not working!');
		DiagBox.Lines.Add('There could be a range of reasons, but first try this, load up your save and put in the console command "set RealShelter_ShelterSwitch to 1" as the mod may have been deactivated. If not then make a post and I will try to solve it asap!  This should not affect those who are upgrading to 1.4.');
		DiagBox.Lines.Add(' ');
		DiagBox.Lines.Add('Q. RSPatch has ITM records, can I clean it?');
		DiagBox.Lines.Add('I have had mixed results from people who cleaned it so I cannot give a definitive answer.  I would stick on the safe side.');
		DiagBox.Lines.Add(' ');
		DiagBox.Lines.Add('Q. Does 1.3+ still have the sheltered weather bug, where weather gets stuck?');
		DiagBox.Lines.Add('Yes, but it happens very rarely.  I have set it up so that if it does occur then all you need to do is reenter a shelter and walk back out again and it should fix itself!');
		DiagBox.Lines.Add(' ');
		DiagBox.Lines.Add('Q. I have a more up to date MteFunctions.pas? Which version do I use?');
		DiagBox.Lines.Add('Use the up to date version');
		DiagBox.Lines.Add(' ');
		DiagBox.Lines.Add('Q. Can I merge real shelter and RSPatch or merge any other weather mod?');
		DiagBox.Lines.Add('No.');
		DiagBox.Lines.Add(' ');

	results := Form1.ShowModal;
	//bQuitting := true;

    	if ff.State = cbChecked then 
    	begin
    		bWillUpdateFFLists := true;
    	end;

    	if ff2.State = cbChecked then begin
    		bWillRemoveSnowSpread := true;
    	end;

    	if rs.State = cbUnchecked then begin
    		bWillUpdateRegions := false;
    	end;

    	if rs2.State = cbChecked then begin
    		bWillRemoveVE := true;
    	end;

    	if rs3.State = cbChecked then begin
    		bWillUseBlankSPG := true;
    	end;

    	if rsro.State = cbChecked then begin
    		bWillRemoveRainWS := true;
    	end;

    	if wb.State = cbChecked then begin
    	bWillUpdateWarburg := true;
    		if not wb.Enabled then 
    		bWillUpdateWarburg := false;
    	end;


    	if mlm.State = cbChecked then bWillUpdateMlmList := true;
    	if spl.State = cbChecked then bWillTurnOffSplashes := true;
	end; 

	//THIS IS FOUND IN THE "CHECK FOR ERRORS" SCRIPT FOUND IN THE -EDIT SCRIPTS- FOLDER
	//MODIFIED TO SUIT REAL SHELTER
function CheckForErrors(aIndent: Integer; aElement: IInterface): Boolean;
	var
	  Error : string;
	  i     : Integer;
	begin
	  Error := Check(aElement);
	  Result := Error <> '';
	  if Result then begin
	    Error := Check(aElement);
	    AddMessage(StringOfChar(' ', aIndent * 2) + Name(aElement) + ' -> ' + Error);
	  end;
	
	  for i := ElementCount(aElement) - 1 downto 0 do
	    Result := CheckForErrors(aIndent + 1, ElementByIndex(aElement, i)) or Result;
	
	  if Result and (Error = '') then
	    AddMessage(StringOfChar(' ', aIndent * 2) + 'Above errors were found in :' + Name(aElement));
	end;

	//THESE HAVE BEEN PORTED OVER FROM AN OLD VERSION OF mteFunctions.pas 
	//AS MY SETUP IS BASED ON HIS OLD CALCULATIONS
function ConstructCheckbox(h: TObject; p: TObject; top: Integer; left: Integer; width: Integer; s: String; state: TCheckBoxState): TCheckBox;
	var
	  cb: TCheckBox;
	begin
	  cb := TCheckBox.Create(h);
	  cb.Parent := p;
	  cb.Top := top;
	  cb.Left := left;
	  cb.Width := width;
	  cb.Caption := s;
	  cb.State := state;
	  
	  Result := cb;
	end;
	
	{
	  ConstructLabel:
	  A function which can be used to make a label.  Used to make code more compact.
	  
	  Example usage:
	  lbl3 := ConstructLabel(frm, pnlBottom, 65, 8, 360, 'Reference removal options:');
	}
function ConstructLabel(h: TObject; p: TObject; top: Integer; left: Integer; width: Integer; height: Integer; s: String): TLabel;
	var
	  lb: TLabel;
	begin
	  lb := TLabel.Create(h);
	  lb.Parent := p;
	  lb.Top := top;
	  lb.Left := left;
	  lb.Width := width;
	  if (height > 0) then
	    lb.Height := height;
	  lb.Caption := s;
	  
	  Result := lb;
	end;
	
	{
	  ConstructButton:
	  A function which can be used to make a button.  Used to make code more compact.
	  
	  Example usage:
	  cb1 := ConstructButton(frm, pnlBottom, 8, 8, 160, 'OK');
	}
function ConstructButton(h: TObject; p: TObject; top: Integer; left: Integer; width: Integer; s: String): TButton;
	var
	  btn: TButton;
	begin
	  btn := TButton.Create(h);
	  btn.Parent := p;
	  btn.Top := top;
	  btn.Left := left;
	  if (width > 0) then
	    btn.Width := width;
	  btn.Caption := s;
	  
	  Result := btn;
	end;
	
	{
	  ConstructOkCancelButtons:
	  A procedure which makes the standard OK and Cancel buttons on a form.
	  
	  Example usage:
	  ConstructOkCancelButtons(frm, pnlBottom, frm.Height - 80);
	}
procedure ConstructOkCancelButtons(h: TObject; p: TObject; top: Integer);
	var
	  btnOk: TButton;
	  btnCancel: TButton;
	begin
	  btnOk := TButton.Create(h);
	  btnOk.Parent := p;
	  btnOk.Caption := 'OK';
	  btnOk.ModalResult := mrOk;
	  btnOk.Left := h.Width div 2 - btnOk.Width - 8;
	  btnOk.Top := top;
	  
	  btnCancel := TButton.Create(h);
	  btnCancel.Parent := p;
	  btnCancel.Caption := 'Cancel';
	  btnCancel.ModalResult := mrCancel;
	  btnCancel.Left := btnOk.Left + btnOk.Width + 16;
	  btnCancel.Top := btnOk.Top;
	end;
//Ported over from mteFunctions to support 3.1.0 and shorted for easier version comparison
function GetVersionStringRS(v: integer): string;
	begin
  	  Result := Format('%d.%d.%d', [
  	    Int(v) shr 24,
  	    Int(v) shr 16 and $FF,
  	    Int(v) shr 8 and $FF
  	  ]);
	end;


end.
