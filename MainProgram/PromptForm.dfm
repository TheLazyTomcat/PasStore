object fPromptForm: TfPromptForm
  Left = 812
  Top = 115
  BorderStyle = bsDialog
  Caption = 'fPromptForm'
  ClientHeight = 84
  ClientWidth = 432
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object lePrompt: TLabeledEdit
    Left = 8
    Top = 24
    Width = 417
    Height = 21
    EditLabel.Width = 42
    EditLabel.Height = 13
    EditLabel.Caption = 'lePrompt'
    TabOrder = 0
    OnKeyPress = lePromptKeyPress
  end
  object btnAccept: TButton
    Left = 256
    Top = 52
    Width = 81
    Height = 25
    Caption = 'Accept'
    TabOrder = 3
    OnClick = btnAcceptClick
  end
  object btnCancel: TButton
    Left = 344
    Top = 52
    Width = 81
    Height = 25
    Caption = 'Cancel'
    TabOrder = 4
    OnClick = btnCancelClick
  end
  object btnGenerator: TButton
    Left = 168
    Top = 52
    Width = 81
    Height = 25
    Caption = 'Generate...'
    TabOrder = 2
    OnClick = btnGeneratorClick
  end
  object cbShowPassword: TCheckBox
    Left = 8
    Top = 56
    Width = 97
    Height = 17
    Caption = 'Show password'
    TabOrder = 1
    OnClick = cbShowPasswordClick
  end
end
