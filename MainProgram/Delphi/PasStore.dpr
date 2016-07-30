program PasStore;

uses
  Forms,
  MainForm in '..\MainForm.pas' {fMainForm},
  EntryFrame in '..\EntryFrame.pas' {frmEntryFrame: TFrame},
  PST_Manager in '..\Source\PST_Manager.pas',
  PromptForm in '..\PromptForm.pas' {fPromptForm},
  GeneratorForm in '..\GeneratorForm.pas' {fGeneratorForm};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'PasStore';
  Application.CreateForm(TfMainForm, fMainForm);
  Application.CreateForm(TfPromptForm, fPromptForm);
  Application.CreateForm(TfGeneratorForm, fGeneratorForm);
  Application.Run;
end.
