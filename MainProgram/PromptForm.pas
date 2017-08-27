{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit PromptForm;

{$INCLUDE '.\Source\PST_defs.inc'}

interface

uses
  SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs, StdCtrls,
  ExtCtrls;

type
  TfPromptForm = class(TForm)
    lePrompt: TLabeledEdit;
    cbShowPassword: TCheckBox;
    btnAccept: TButton;
    btnCancel: TButton;
    btnGenerator: TButton;
    procedure FormShow(Sender: TObject);    
    procedure lePromptKeyPress(Sender: TObject; var Key: Char);
    procedure cbShowPasswordClick(Sender: TObject);
    procedure btnGeneratorClick(Sender: TObject);
    procedure btnAcceptClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
  private
    PromptResult: Boolean;
  public
    Function ShowPrompt(const FormCaption, Prompt, DefaultText: String; out Output: String; Generator: Boolean = False): Boolean;
  end;

var
  fPromptForm: TfPromptForm;

implementation

{$IFDEF FPC}
  {$R *.lfm}
{$ELSE}
  {$R *.dfm}
{$ENDIF}

uses
  GeneratorForm;

Function TfPromptForm.ShowPrompt(const FormCaption, Prompt, DefaultText: String; out Output: String; Generator: Boolean = False): Boolean;
begin
Self.Caption := FormCaption;
lePrompt.EditLabel.Caption := Prompt;
lePrompt.Text := DefaultText;
btnGenerator.Visible := Generator;
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
cbShowPassword.Checked := False;
cbShowPassword.OnClick(nil);
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

procedure TfPromptForm.cbShowPasswordClick(Sender: TObject);
begin
If cbShowPassword.Checked then
  lePrompt.PasswordChar := #0
else
  lePrompt.PasswordChar := '*';
end;

//------------------------------------------------------------------------------

procedure TfPromptForm.btnGeneratorClick(Sender: TObject);
var
  GeneratedText:  String;
begin
If fGeneratorForm.GeneratorPrompt(GeneratedText) then
  lePrompt.Text := GeneratedText;
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
