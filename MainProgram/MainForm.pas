{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit MainForm;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  Windows, SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls, ExtCtrls, StdCtrls, EntryFrame, Menus, ActnList, {$IFNDEF FPC}XPMan,{$ENDIF}
  PST_Manager;

type

  { TfMainForm }

  TfMainForm = class(TForm)
    shpHeader: TShape;
    imgLogo: TImage;
    lblTitle: TLabel;
    lblTitleShadow: TLabel;
    lblVersion: TLabel;
    lblCopyright: TLabel;
    bvlHeader: TBevel;
    lbEntries: TListBox;
    gbEntryDetails: TGroupBox;
    lblEntries: TLabel;
    sbStatusBar: TStatusBar;
  {$IFNDEF FPC}
    oXPManifest: TXPManifest;
  {$ENDIF}
    leSearchFor: TLabeledEdit;
    btnFindPrev: TButton;
    btnFindNext: TButton;
    cbCaseSensitive: TCheckBox;    
    frmEntryFrame: TfrmEntryFrame;
    pmEntries: TPopupMenu;
    pm_entry_Add: TMenuItem;
    pm_entry_Remove: TMenuItem;
    N1: TMenuItem;
    pm_entry_Rename: TMenuItem;
    N2: TMenuItem;
    pm_entry_MoveUp: TMenuItem;
    pm_entry_MoveDown: TMenuItem;
    N3: TMenuItem;
    pm_entry_SortFwd: TMenuItem;
    pm_entry_SortRev: TMenuItem;
    N4: TMenuItem;
    pm_entry_FindNext: TMenuItem;
    N5: TMenuItem;
    pm_entry_SaveNow: TMenuItem;
    pm_entry_ChangePswd: TMenuItem;
    cbSearchHistory: TCheckBox;
    actlActionList: TActionList;
    actSearchShortcut: TAction;
    tmrAnimTimer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure lbEntriesClick(Sender: TObject);
    procedure lbEntriesMouseDown(Sender: TObject; {%H-}Button: TMouseButton; {%H-}Shift: TShiftState; X, Y: Integer);
    procedure FormDestroy(Sender: TObject);
    procedure pmEntriesPopup(Sender: TObject);
    procedure pm_entry_AddClick(Sender: TObject);
    procedure pm_entry_RemoveClick(Sender: TObject);
    procedure pm_entry_RenameClick(Sender: TObject);
    procedure pm_entry_MoveUpClick(Sender: TObject);
    procedure pm_entry_MoveDownClick(Sender: TObject);
    procedure pm_entry_SortFwdClick(Sender: TObject);
    procedure pm_entry_SortRevClick(Sender: TObject);
    procedure pm_entry_FindNextClick(Sender: TObject);
    procedure pm_entry_SaveNowClick(Sender: TObject);    
    procedure pm_entry_ChangePswdClick(Sender: TObject);
    procedure leSearchForKeyPress(Sender: TObject; var Key: Char);
    procedure btnFindPrevClick(Sender: TObject);
    procedure btnFindNextClick(Sender: TObject);
    procedure actSearchShortcutExecute(Sender: TObject);
    procedure tmrAnimTimerTimer(Sender: TObject);
  private
    // animation counters
    acntNothingFound: Integer;
    acntSearching:    Integer;
  protected
    Unlocked: Boolean;
    Manager:  TPSTManager;
    procedure RunAnimation(ID: Integer);
  public
    { Public declarations }
    procedure AskForMasterPassword;
  end;

var
  fMainForm: TfMainForm;

implementation

uses
  WinFileInfo,
  PromptForm, GeneratorForm
{$IF Defined(FPC) and not Defined(Unicode) and (FPC_FULLVERSION < 20701)}
  , LazFileUtils, LazUTF8
{$IFEND};

{$IF defined(CPU64) or defined(CPU64BITS)}
  {$DEFINE 64bit}
{$ELSEIF defined(CPU16)}
  {$MESSAGE FATAL 'Unsupported CPU.'}
{$ELSE}
  {$DEFINE 32bit}
{$IFEND}

{$IFDEF FPC}
  {$R *.lfm}
{$ELSE}
  {$R *.dfm}
{$ENDIF}

const
  ANIM_NOTHINGFOUND = 1;
  ANIM_SEARCHING    = 2;

procedure TfMainForm.RunAnimation(ID: Integer);
begin
case ID of
  ANIM_NOTHINGFOUND:
      begin
        acntNothingFound := 20;
        leSearchFor.Color := clRed;
        sbStatusBar.Panels[1].Text := 'Nothing found';
        Beep;
      end;
  ANIM_SEARCHING:
      begin
        acntSearching := 5;
        leSearchFor.Color := clYellow;
      end;
end;
tmrAnimTimer.Enabled := True;
end;

//------------------------------------------------------------------------------

procedure TfMainForm.AskForMasterPassword;
var
  PromptPos:  TPosition;
  GenPos:     TPosition;
  Pswd:       String;
begin
PromptPos := fPromptForm.Position;
GenPos := fGeneratorForm.Position;
try
  fPromptForm.Position := poScreenCenter;
  fGeneratorForm.Position := poScreenCenter;
  If fPromptForm.ShowPrompt('Enter master password','Master password:','',Pswd,True) then
    begin
      Manager.MasterPassword := Pswd;
    {$IF Defined(FPC) and not Defined(Unicode) and (FPC_FULLVERSION < 20701)}
      If FileExistsUTF8(Manager.FileName) then
    {$ELSE}
      If FileExists(Manager.FileName) then
    {$IFEND}
        If not Manager.Load then
          begin
            MessageDlg('Wrong master password.',mtError,[mbOk],0);
            Close;
            Exit;
          end;
      Application.ShowMainForm := True;
      Unlocked := True;
    end
  else Close;
finally
  fGeneratorForm.Position := GenPos; 
  fPromptForm.Position := PromptPos;
end;
end;

//==============================================================================

procedure TfMainForm.FormCreate(Sender: TObject);
begin
sbStatusBar.DoubleBuffered := True;
Manager := TPSTManager.Create;
{$IF Defined(FPC) and not Defined(Unicode) and (FPC_FULLVERSION < 20701)}
Manager.FileName := ExtractFilePath(SysToUTF8(ParamStr(0))) + 'PasStore.dat';
{$ELSE}
Manager.FileName := ExtractFilePath(ParamStr(0)) + 'PasStore.dat';
{$IFEND}
Manager.OnEntrySet := frmEntryFrame.SetEntry;
Manager.OnEntryGet := frmEntryFrame.GetEntry;
acntNothingFound := 0;
acntSearching := 0;
Unlocked := False;
// Load copyright info
with TWinFileInfo.Create(WFI_LS_VersionInfoAndFFI) do
try
  If VersionInfoTranslationCount > 0 then
    begin
      lblTitle.Caption := VersionInfoValues[VersionInfoTranslations[0].LanguageStr,'ProductName'];
      lblTitleShadow.Caption := lblTitle.Caption;
      with VersionInfoFixedFileInfoDecoded.FileVersionMembers do
        lblVersion.Caption := Format('Version of the program: %d.%d.%d %s%s #%d%s',[Major,Minor,Release,
                                     {$IFDEF FPC}'L'{$ELSE}'D'{$ENDIF},{$IFDEF 64bit}'64'{$ELSE}'32'{$ENDIF},
                                     Build,{$IFDEF Debug}' debug'{$ELSE}''{$ENDIF}]);
      lblCopyright.Caption := Format('%s, all rights reserved',[VersionInfoValues[VersionInfoTranslations[0].LanguageStr,'LegalCopyright']]);
    end;
finally
  Free;
end;
pm_entry_MoveUp.ShortCut := ShortCut(VK_UP,[ssShift]);
pm_entry_MoveDown.ShortCut := ShortCut(VK_DOWN,[ssShift]);
end;

//------------------------------------------------------------------------------

procedure TfMainForm.FormShow(Sender: TObject);
var
  i:  Integer;
begin
For i := 0 to Pred(Manager.EntryCount) do
  lbEntries.Items.Add(Manager[i].Name);
If lbEntries.Count > 0 then
  lbEntries.ItemIndex := 0
else
  lbEntries.ItemIndex := -1;
lbEntries.OnClick(nil);
end;

//------------------------------------------------------------------------------

procedure TfMainForm.FormDestroy(Sender: TObject);
begin
If Unlocked then
  begin
    Manager.CurrentEntryIdx := -2;
    Manager.Save;
  end;
Manager.Free;
end;

//------------------------------------------------------------------------------

procedure TfMainForm.lbEntriesClick(Sender: TObject);
begin
Manager.CurrentEntryIdx := lbEntries.ItemIndex;
If lbEntries.ItemIndex >= 0 then
  sbStatusBar.Panels[0].Text := Format('Entry %d/%d',[Manager.CurrentEntryIdx + 1,Manager.EntryCount])
else
  sbStatusBar.Panels[0].Text := 'No entry';
end;

//------------------------------------------------------------------------------

procedure TfMainForm.lbEntriesMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Index:  Integer;
begin
If (Button = mbRight) and (Shift = [ssRight]) then
  begin
    Index := lbEntries.ItemAtPos(Point(X,Y),True);
    If Index >= 0 then
      begin
        lbEntries.ItemIndex := Index;
        lbEntries.OnClick(nil);
      end;
  end;
end;

//------------------------------------------------------------------------------

procedure TfMainForm.pmEntriesPopup(Sender: TObject);
begin
pm_entry_Remove.Enabled := lbEntries.ItemIndex >= 0;
pm_entry_Rename.Enabled := lbEntries.ItemIndex >= 0;
pm_entry_MoveUp.Enabled := lbEntries.ItemIndex > 0;
pm_entry_MoveDown.Enabled := (lbEntries.ItemIndex < Pred(lbEntries.Count)) and (lbEntries.Count > 0);
pm_entry_SortFwd.Enabled := lbEntries.Count > 1;
pm_entry_SortRev.Enabled := lbEntries.Count > 1;
pm_entry_FindNext.Enabled := leSearchFor.Text <> '';
end;

//------------------------------------------------------------------------------

procedure TfMainForm.pm_entry_AddClick(Sender: TObject);
var
  OutStr: String;
begin
If fPromptForm.ShowPrompt('Add new entry','Entry name:','',OutStr) then
  begin
    lbEntries.Items.Add(OutStr);
    Manager.AddEntry(OutStr);
    lbEntries.ItemIndex := Pred(lbEntries.Count);
    lbEntries.OnClick(nil);
  end;
end;

//------------------------------------------------------------------------------

procedure TfMainForm.pm_entry_RemoveClick(Sender: TObject);
var
  OldIndex: Integer;
begin
If lbEntries.ItemIndex >= 0 then
  If MessageDlg(Format('Are you sure you want to delete entry "%s"?',[lbEntries.Items[lbEntries.ItemIndex]]),
                mtConfirmation,[mbYes,mbNo],0) = mrYes then
    begin
      OldIndex := lbEntries.ItemIndex;
      Manager.CurrentEntryIdx := -2;
      lbEntries.Items.Delete(OldIndex);
      Manager.DeleteEntry(OldIndex); 
      If OldIndex < lbEntries.Count then
        lbEntries.ItemIndex := OldIndex
      else
        begin
          If lbEntries.Count > 0 then
            lbEntries.ItemIndex := Pred(lbEntries.Count)
          else
            lbEntries.ItemIndex := -1;
        end;
      lbEntries.OnClick(nil);
    end;
end;
 
//------------------------------------------------------------------------------

procedure TfMainForm.pm_entry_RenameClick(Sender: TObject);
var
  OutStr: String;
begin
If lbEntries.ItemIndex >= 0 then
  If fPromptForm.ShowPrompt('Rename entry','New entry name:',Manager[lbEntries.ItemIndex].Name,OutStr) then
    begin
      Manager.EntriesPtr[lbEntries.ItemIndex]^.Name := OutStr;
      lbEntries.Items[lbEntries.ItemIndex] := OutStr;
      frmEntryFrame.LocalEntry.Name := OutStr;
      frmEntryFrame.lblName.Caption := OutStr;
    end;
end;
 
//------------------------------------------------------------------------------

procedure TfMainForm.pm_entry_MoveUpClick(Sender: TObject);
var
  OldIndex: Integer;
begin
If lbEntries.ItemIndex > 0 then
  begin
    OldIndex := lbEntries.ItemIndex;
    Manager.CurrentEntryIdx := -2;
    Manager.Exchange(OldIndex,OldIndex - 1);
    lbEntries.Items.Exchange(OldIndex,OldIndex - 1);
    lbEntries.ItemIndex := OldIndex - 1;
    lbEntries.OnClick(nil);
  end;
end;

//------------------------------------------------------------------------------

procedure TfMainForm.pm_entry_MoveDownClick(Sender: TObject);
var
  OldIndex: Integer;
begin
If (lbEntries.ItemIndex < Pred(lbEntries.Count)) and (lbEntries.Count > 0) then
  begin
    OldIndex := lbEntries.ItemIndex;
    Manager.CurrentEntryIdx := -2;
    Manager.Exchange(OldIndex,OldIndex + 1);
    lbEntries.Items.Exchange(OldIndex,OldIndex + 1);
    lbEntries.ItemIndex := OldIndex + 1;
    lbEntries.OnClick(nil);
  end;
end; 

//------------------------------------------------------------------------------

procedure TfMainForm.pm_entry_SortFwdClick(Sender: TObject);
var
  i:  Integer;
begin
If lbEntries.Count > 1 then
  begin
    Manager.CurrentEntryIdx := -2;
    Manager.Sort(False);
    For i := 0 to Pred(lbEntries.Count) do
      lbEntries.Items[i] := Manager[i].Name;
    lbEntries.ItemIndex := 0;
    lbEntries.OnClick(nil);
  end;
end;

//------------------------------------------------------------------------------

procedure TfMainForm.pm_entry_SortRevClick(Sender: TObject);
var
  i:  Integer;
begin
If lbEntries.Count > 1 then
  begin
    Manager.CurrentEntryIdx := -2;
    Manager.Sort(True);
    For i := 0 to Pred(lbEntries.Count) do
      lbEntries.Items[i] := Manager[i].Name;
    lbEntries.ItemIndex := 0;
    lbEntries.OnClick(nil);
  end;
end;

//------------------------------------------------------------------------------

procedure TfMainForm.pm_entry_FindNextClick(Sender: TObject);
begin
btnFindNext.OnClick(nil);
end;

//------------------------------------------------------------------------------

procedure TfMainForm.pm_entry_SaveNowClick(Sender: TObject);
var
  CurrentIndex: Integer;
begin
CurrentIndex := Manager.CurrentEntryIdx;
try
  Manager.CurrentEntryIdx := -2;
  Manager.Save;
finally
  Manager.CurrentEntryIdx := CurrentIndex;
end;
end;

//------------------------------------------------------------------------------

procedure TfMainForm.pm_entry_ChangePswdClick(Sender: TObject);
var
  OutStr: String;
begin
If fPromptForm.ShowPrompt('Master password','New master password:',Manager.MasterPassword,OutStr,True) then
  Manager.MasterPassword := OutStr;
end;

//------------------------------------------------------------------------------

procedure TfMainForm.leSearchForKeyPress(Sender: TObject; var Key: Char);
begin
If Key = #13 then
  begin
    btnFindNext.OnClick(nil);
    Key := #0;
  end;
end;

//------------------------------------------------------------------------------

procedure TfMainForm.btnFindPrevClick(Sender: TObject);
var
  Index:  Integer;
begin
If leSearchFor.Text <> '' then
  begin
    Index := Manager.Find(leSearchFor.Text,lbEntries.ItemIndex,True,cbCaseSensitive.Checked,cbSearchHistory.Checked);
    If Index >= 0 then
      begin
        lbEntries.ItemIndex := Index;
        lbEntries.OnClick(nil);
      end
    else RunAnimation(ANIM_NOTHINGFOUND);
  end;
end;

//------------------------------------------------------------------------------

procedure TfMainForm.btnFindNextClick(Sender: TObject);
var
  Index:  Integer;
begin
If leSearchFor.Text <> '' then
  begin
    Index := Manager.Find(leSearchFor.Text,lbEntries.ItemIndex,False,cbCaseSensitive.Checked,cbSearchHistory.Checked);
    If Index >= 0 then
      begin
        lbEntries.ItemIndex := Index;
        lbEntries.OnClick(nil);
      end
    else RunAnimation(ANIM_NOTHINGFOUND);
end;
end;

//------------------------------------------------------------------------------

procedure TfMainForm.actSearchShortcutExecute(Sender: TObject);
begin
If fMainForm.Visible and fMainForm.Active and not leSearchFor.Focused then
  begin
    leSearchFor.SetFocus;
    leSearchFor.SelectAll;
    RunAnimation(ANIM_SEARCHING);
  end;
end;

//------------------------------------------------------------------------------

procedure TfMainForm.tmrAnimTimerTimer(Sender: TObject);

  Function DecAndGet(var Value: Integer): Integer;
  begin
    Result := Value;
    If Value > 0 then
      Dec(Value);
  end;

begin
case DecAndGet(acntNothingFound) of
  14: leSearchFor.Color := clWindow;
   1: sbStatusBar.Panels[1].Text := '';
end;
If DecAndGet(acntSearching) = 1 then
  leSearchFor.Color := clWindow;
tmrAnimTimer.Enabled := (acntNothingFound + acntSearching) > 0;
end;

end.
