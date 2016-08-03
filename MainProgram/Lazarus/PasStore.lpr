program PasStore;

{$mode objfpc}{$H+}

uses
  Interfaces,
  Forms,

  MainForm,
  EntryFrame,
  PromptForm,
  GeneratorForm,

  PST_Manager;

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

