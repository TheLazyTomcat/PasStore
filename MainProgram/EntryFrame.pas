{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit EntryFrame;

{$INCLUDE '.\Source\PST_defs.inc'}

interface

uses
  SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs, ExtCtrls,
  StdCtrls, ComCtrls, Menus,
  PST_Manager;

const
  EF_ACTREQ_RENAME = 1;

type
  TEntryFrameActionRequiredEvent = procedure(Sender: TObject; Action: Integer) of object;

  TfrmEntryFrame = class(TFrame)
    pnlMainPanel: TPanel;
    shpNameBackground: TShape;
    lblName: TLabel;
    leAddress: TLabeledEdit;
    btnOpen: TButton;
    lblNotes: TLabel;
    meNotes: TMemo;
    bvlHorSplit: TBevel;
    leLogin: TLabeledEdit;
    leEmail: TLabeledEdit;        
    lePassword: TLabeledEdit;
    btnGenerate: TButton;
    btnAddToHistory: TButton;
    lblHistory: TLabel;
    lvHistory: TListView;
    pmHistoryMenu: TPopupMenu;
    pm_hm_Remove: TMenuItem;
    N1: TMenuItem;
    pm_hm_Copy: TMenuItem;
    procedure lblNameDblClick(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
    procedure btnGenerateClick(Sender: TObject);
    procedure btnAddToHistoryClick(Sender: TObject);
    procedure pmHistoryMenuPopup(Sender: TObject);
    procedure pm_hm_RemoveClick(Sender: TObject);
    procedure pm_hm_CopyClick(Sender: TObject);
  private
    { Private declarations }
  protected
    fOnActionRequired:  TEntryFrameActionRequiredEvent;
    procedure ListHistory;
  public
    LocalEntry: TPSTEntry;
    procedure SetEntry(Sender: TObject; Entry: PPSTEntry);
    procedure GetEntry(Sender: TObject; Entry: PPSTEntry);
    property OnActionRequired: TEntryFrameActionRequiredEvent read fOnActionRequired write fOnActionRequired;
  end;

implementation

{$IFDEF FPC}
  {$R *.lfm}
{$ELSE}
  {$R *.dfm}
{$ENDIF}

uses
  Windows, ShellAPI, ClipBrd, GeneratorForm, StrRect;

{$IFDEF FPC_DisableWarns}
  {$WARN 5024 OFF} // Parameter "$1" not used
{$ENDIF}

procedure TfrmEntryFrame.ListHistory;
var
  i:  Integer;
begin
lvHistory.Items.BeginUpdate;
try
  lvHistory.Clear;
  For i := High(LocalEntry.History) downto Low(LocalEntry.History) do
    with lvHistory.Items.Add do
      begin
        Caption := FormatDateTime('YYYY-MM-DD HH:NN',LocalEntry.History[i].Time);
        SubItems.Add(LocalEntry.History[i].Password);
      end;
finally
  lvHistory.Items.EndUpdate;
end;
end;

//==============================================================================

procedure TfrmEntryFrame.SetEntry(Sender: TObject; Entry: PPSTEntry);
begin
pnlMainPanel.Visible := Assigned(Entry);
If Assigned(Entry) then
  begin
    LocalEntry := Entry^;
    lblName.Caption := LocalEntry.Name;
    leAddress.Text := LocalEntry.Address;
    meNotes.Text := LocalEntry.Notes;
    leLogin.Text := LocalEntry.Login;
    leEmail.Text := LocalEntry.Email;
    lePassword.Text := LocalEntry.Password;
    ListHistory;
  end;
end;

//------------------------------------------------------------------------------

procedure TfrmEntryFrame.GetEntry(Sender: TObject; Entry: PPSTEntry);
begin
If Assigned(Entry) then
  begin
    LocalEntry.Address := leAddress.Text;
    LocalEntry.Notes := meNotes.Text;
    LocalEntry.Login := leLogin.Text;
    LocalEntry.Email := leEmail.Text;
    LocalEntry.Password := lePassword.Text;
    Entry^ := LocalEntry;
  end;
end;

//==============================================================================

procedure TfrmEntryFrame.lblNameDblClick(Sender: TObject);
begin
If Assigned(fOnActionRequired) then
  fOnActionRequired(Self,EF_ACTREQ_RENAME);
end;

//------------------------------------------------------------------------------

procedure TfrmEntryFrame.btnOpenClick(Sender: TObject);
begin
If leAddress.Text <> '' then
  ShellExecute(0,'open',PChar(StrToWin(leAddress.Text)),nil,nil,SW_SHOWNORMAL);
end;

//------------------------------------------------------------------------------

procedure TfrmEntryFrame.btnGenerateClick(Sender: TObject);
var
  NewPassword:  String;
  InHistory:    Boolean;
begin
LocalEntry.Password := lePassword.Text;
If fGeneratorForm.GeneratorPrompt(NewPassword) then
  begin
    If Length(LocalEntry.History) > 0 then
      InHistory := AnsiSameStr(LocalEntry.History[High(LocalEntry.History)].Password,LocalEntry.Password)
    else
      InHistory := False;
    If not AnsiSameStr(LocalEntry.Password,NewPassword) and (Length(LocalEntry.Password) > 0) and not InHistory then
      begin
        case MessageDlg('New password will rewrite the currently stored one.' + sLineBreak +
           'Save current password to history?',mtWarning,[mbYes,mbNo,mbCancel],0) of
          mrYes:    begin
                      SetLength(LocalEntry.History,Length(LocalEntry.History) + 1);
                      LocalEntry.History[High(LocalEntry.History)].Time := Now;
                      LocalEntry.History[High(LocalEntry.History)].Password := LocalEntry.Password;
                      ListHistory;
                    end;
          mrNo:;    // no action
          mrCancel: Exit;
        end;
      end;
    LocalEntry.Password := NewPassword;
    lePassword.Text := NewPassword;
  end;
end;

//------------------------------------------------------------------------------

procedure TfrmEntryFrame.btnAddToHistoryClick(Sender: TObject);
begin
If lePassword.Text <> '' then
  begin
    SetLength(LocalEntry.History,Length(LocalEntry.History) + 1);
    LocalEntry.History[High(LocalEntry.History)].Time := Now;
    LocalEntry.History[High(LocalEntry.History)].Password := lePassword.Text;
    ListHistory;
  end
else MessageDlg('Cannot add empty password to history.',mtError,[mbOk],0);
end;
 
//------------------------------------------------------------------------------

procedure TfrmEntryFrame.pmHistoryMenuPopup(Sender: TObject);
begin
pm_hm_Remove.Enabled := lvHistory.ItemIndex >= 0;
pm_hm_Copy.Enabled := lvHistory.ItemIndex >= 0;
end;
 
//------------------------------------------------------------------------------

procedure TfrmEntryFrame.pm_hm_RemoveClick(Sender: TObject);
var
  i:  Integer;
begin
If lvHistory.ItemIndex >= 0 then
  If MessageDlg('Are you sure you want to remove this password from history?',mtConfirmation,[mbYes,mbNo],0) = mrYes then
    begin
      For i := (Pred(lvHistory.Items.Count) - lvHistory.ItemIndex) to Pred(High(LocalEntry.History)) do
        LocalEntry.History[i] := LocalEntry.History[i + 1];
      SetLength(LocalEntry.History,Length(LocalEntry.History) - 1);
      ListHistory;  
    end;
end;
 
//------------------------------------------------------------------------------

procedure TfrmEntryFrame.pm_hm_CopyClick(Sender: TObject);
begin
If lvHistory.ItemIndex >= 0 then
  Clipboard.AsText := LocalEntry.History[Pred(lvHistory.Items.Count) - lvHistory.ItemIndex].Password;
end;

end.
