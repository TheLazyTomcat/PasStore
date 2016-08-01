{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
program PasStore;

uses
  Forms,
  
  MainForm      in '..\MainForm.pas' {fMainForm},
  EntryFrame    in '..\EntryFrame.pas' {frmEntryFrame: TFrame},
  PromptForm    in '..\PromptForm.pas' {fPromptForm},
  GeneratorForm in '..\GeneratorForm.pas' {fGeneratorForm},

  PST_Manager in '..\Source\PST_Manager.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'PasStore';
  Application.ShowMainForm := False;
  Application.CreateForm(TfMainForm, fMainForm);
  Application.CreateForm(TfPromptForm, fPromptForm);
  Application.CreateForm(TfGeneratorForm, fGeneratorForm);
  fMainForm.AskForMasterPassword;
  Application.Run;
end.
