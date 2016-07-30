object fPromptForm: TfPromptForm
  Left = 812
  Top = 115
  BorderStyle = bsDialog
  Caption = 'fPromptForm'
  ClientHeight = 92
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
    Top = 56
    Width = 81
    Height = 25
    Caption = 'btnAccept'
    TabOrder = 1
    OnClick = btnAcceptClick
  end
  object btnCancel: TButton
    Left = 344
    Top = 56
    Width = 81
    Height = 25
    Caption = 'btnCancel'
    TabOrder = 2
    OnClick = btnCancelClick
  end
end
