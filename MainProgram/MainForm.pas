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
    Manager:  TPSTManager;
  public
    { Public declarations }
  end;

var
  fMainForm: TfMainForm;

implementation

uses PromptForm;

{$R *.dfm}

procedure TfMainForm.FormCreate(Sender: TObject);
var
  i:  Integer;
begin
sbStatusBar.DoubleBuffered := True;
Manager := TPSTManager.Create;
Manager.FileName := ExtractFilePath(ParamStr(0)) + 'PasStore.dat';
Manager.MasterPassword := 'password';
Manager.OnEntrySet := frmEntryFrame.SetEntry;
Manager.OnEntryGet := frmEntryFrame.GetEntry;
Manager.Load;
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
Manager.CurrentEntryIdx := -2;
Manager.Save;
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

procedure TfMainForm.pm_entry_AddClick(Sender: TObject);
var
  OutStr: String;
begin
If fPromptForm.ShowPrompt('Add new entry','Entry name:','','Accept','Cancel',OutStr) then
  begin
    lbEntries.Items.Add(OutStr);
    Manager.AddEntry(OutStr);
    lbEntries.ItemIndex := Pred(lbEntries.Count);
    lbEntries.OnClick(nil);
  end;
end;

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

procedure TfMainForm.pm_entry_RenameClick(Sender: TObject);
var
  OutStr: String;
begin
If lbEntries.ItemIndex >= 0 then
  If fPromptForm.ShowPrompt('Rename entry','New entry name:',Manager[lbEntries.ItemIndex].Name,'Accept','Cancel',OutStr) then
    begin
      Manager.EntriesPtr[lbEntries.ItemIndex]^.Name := OutStr;
      lbEntries.Items[lbEntries.ItemIndex] := OutStr;
      frmEntryFrame.LocalEntry.Name := OutStr;
      frmEntryFrame.lblName.Caption := OutStr;
    end;
end;

procedure TfMainForm.pm_entry_ChangePswdClick(Sender: TObject);
var
  OutStr: String;
begin
If fPromptForm.ShowPrompt('Master password','New master password:',Manager.MasterPassword,'Accept','Cancel',OutStr) then
  Manager.MasterPassword := OutStr;
end;

end.
