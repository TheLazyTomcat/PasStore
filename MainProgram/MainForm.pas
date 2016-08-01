{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit MainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, ExtCtrls, StdCtrls, XPMan, EntryFrame, Menus,
  PST_Manager;

type
  TfMainForm = class(TForm)
    lbEntries: TListBox;
    gbEntryDetails: TGroupBox;
    lblEntries: TLabel;
    sbStatusBar: TStatusBar;
    oXPManifest: TXPManifest;
    frmEntryFrame: TfrmEntryFrame;
    pmEntries: TPopupMenu;
    pm_entry_Add: TMenuItem;
    pm_entry_Remove: TMenuItem;
    N1: TMenuItem;
    pm_entry_Rename: TMenuItem;
    N2: TMenuItem;
    pm_entry_ChangePswd: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure lbEntriesClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure pmEntriesPopup(Sender: TObject);
    procedure pm_entry_AddClick(Sender: TObject);
    procedure pm_entry_RemoveClick(Sender: TObject);
    procedure pm_entry_RenameClick(Sender: TObject);
    procedure pm_entry_ChangePswdClick(Sender: TObject);
  private
    { Private declarations }
  protected
    Unlocked: Boolean;
    Manager:  TPSTManager;
  public
    { Public declarations }
    procedure AskForMasterPassword;
  end;

var
  fMainForm: TfMainForm;

implementation

uses
  WinFileInfo,
  PromptForm, GeneratorForm;

{$R *.dfm}

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
      If FileExists(Manager.FileName) then
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
Manager.FileName := ExtractFilePath(ParamStr(0)) + 'PasStore.dat';
Manager.OnEntrySet := frmEntryFrame.SetEntry;
Manager.OnEntryGet := frmEntryFrame.GetEntry;
Unlocked := False;
// copyright info
with TWinFileInfo.Create(WFI_LS_VersionInfoAndFFI) do
try
  If VersionInfoTranslationCount > 0 then
    sbStatusBar.Panels[1].Text := Format('%s %s, %s',
     [VersionInfoValues[VersionInfoTranslations[0].LanguageStr,'ProductName'],
      VersionInfoValues[VersionInfoTranslations[0].LanguageStr,'ProductVersion'],
      VersionInfoValues[VersionInfoTranslations[0].LanguageStr,'LegalCopyright']]);
finally
  Free;
end;
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

procedure TfMainForm.pmEntriesPopup(Sender: TObject);
begin
pm_entry_Remove.Enabled := lbEntries.ItemIndex >= 0;
pm_entry_Rename.Enabled := lbEntries.ItemIndex >= 0;
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
  OldIdx: Integer;
begin
If lbEntries.ItemIndex >= 0 then
  If MessageDlg(Format('Are you sure you want to delete entry "%s"?',[lbEntries.Items[lbEntries.ItemIndex]]),
                mtConfirmation,[mbYes,mbNo],0) = mrYes then
    begin
      OldIdx := lbEntries.ItemIndex;
      If lbEntries.ItemIndex < Pred(lbEntries.Count) then
        lbEntries.ItemIndex := lbEntries.ItemIndex + 1
      else
        begin
          If lbEntries.ItemIndex > 0 then
            lbEntries.ItemIndex := lbEntries.ItemIndex - 1
          else
            lbEntries.ItemIndex := -1;
        end;
      lbEntries.OnClick(nil);
      lbEntries.Items.Delete(OldIdx);
      Manager.DeleteEntry(OldIdx);
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

procedure TfMainForm.pm_entry_ChangePswdClick(Sender: TObject);
var
  OutStr: String;
begin
If fPromptForm.ShowPrompt('Master password','New master password:',Manager.MasterPassword,OutStr,True) then
  Manager.MasterPassword := OutStr;
end;

end.
