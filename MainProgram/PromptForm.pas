unit PromptForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TfPromptForm = class(TForm)
    lePrompt: TLabeledEdit;
    btnAccept: TButton;
    btnCancel: TButton;
    procedure FormShow(Sender: TObject);    
    procedure lePromptKeyPress(Sender: TObject; var Key: Char);    
    procedure btnAcceptClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
  private
    PromptResult: Boolean;
  public
    Function ShowPrompt(const Caption, Prompt, DefaultText, AcceptBtn, CancelBtn: String; var Output: String): Boolean;
  end;

var
  fPromptForm: TfPromptForm;

implementation

{$R *.dfm}

Function TfPromptForm.ShowPrompt(const Caption, Prompt, DefaultText, AcceptBtn, CancelBtn: String; var Output: String): Boolean;
begin
Self.Caption := Caption;
lePrompt.EditLabel.Caption := Prompt;
lePrompt.Text := DefaultText;
btnAccept.Caption := AcceptBtn;
btnCancel.Caption := CancelBtn;
PromptResult := False;
ShowModal;
Result := PromptResult;
If Result then
  Output := lePrompt.Text
else
  Output := '';
end;

//==============================================================================

procedure TfPromptForm.FormShow(Sender: TObject);
begin
lePrompt.SetFocus;
end;

//------------------------------------------------------------------------------

procedure TfPromptForm.lePromptKeyPress(Sender: TObject; var Key: Char);
begin
If Key = #13 then
  begin
    btnAccept.OnClick(nil);
    Key := #0;
  end;
end;

//------------------------------------------------------------------------------

procedure TfPromptForm.btnAcceptClick(Sender: TObject);
begin
If lePrompt.Text <> '' then
  begin
    PromptResult := True;
    Close;
  end
else MessageDlg('Empty text not allowed.',mtError,[mbOk],0)
end;

//------------------------------------------------------------------------------

procedure TfPromptForm.btnCancelClick(Sender: TObject);
begin
Close;
end;

end.
