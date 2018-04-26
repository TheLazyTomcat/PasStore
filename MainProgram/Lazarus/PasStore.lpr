{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
program PasStore;

{$INCLUDE '..\Source\PST_defs.inc'}

uses
  Interfaces,
  Forms,

  MainForm,
  PromptForm,
  GeneratorForm;

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Initialize;
  Application.ShowMainForm := False;
  Application.CreateForm(TfMainForm, fMainForm);
  Application.CreateForm(TfPromptForm, fPromptForm);
  Application.CreateForm(TfGeneratorForm, fGeneratorForm);
  fMainForm.AskForMasterPassword;
  Application.Run;
end.

