{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
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
    btnGenerator: TButton;
    procedure FormShow(Sender: TObject);    
    procedure lePromptKeyPress(Sender: TObject; var Key: Char);
    procedure btnGeneratorClick(Sender: TObject);
    procedure btnAcceptClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
  private
    PromptResult: Boolean;
  public
    Function ShowPrompt(const Caption, Prompt, DefaultText: String; var Output: String; Generator: Boolean = False): Boolean;
  end;

var
  fPromptForm: TfPromptForm;

implementation

{$R *.dfm}

uses
  GeneratorForm;

Function TfPromptForm.ShowPrompt(const Caption, Prompt, DefaultText: String; var Output: String; Generator: Boolean = False): Boolean;
begin
Self.Caption := Caption;
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

procedure TfPromptForm.btnGeneratorClick(Sender: TObject);
var
  GeneratoedText: String;
begin
If fGeneratorForm.GeneratorPrompt(GeneratoedText) then
  lePrompt.Text := GeneratoedText;
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
