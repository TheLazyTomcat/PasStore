object fGeneratorForm: TfGeneratorForm
  Left = 722
  Top = 114
  BorderStyle = bsDialog
  Caption = 'Password generator'
  ClientHeight = 220
  ClientWidth = 528
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
  object lblMethod: TLabel
    Left = 8
    Top = 56
    Width = 142
    Height = 13
    Caption = 'Method of generation (hash):'
  end
  object lblLength: TLabel
    Left = 216
    Top = 56
    Width = 61
    Height = 13
    Caption = 'Hash length:'
  end
  object lblEncoding: TLabel
    Left = 320
    Top = 56
    Width = 80
    Height = 13
    Caption = 'Result encoding:'
  end
  object leSeed: TLabeledEdit
    Left = 8
    Top = 24
    Width = 513
    Height = 21
    EditLabel.Width = 28
    EditLabel.Height = 13
    EditLabel.Caption = 'Seed:'
    TabOrder = 0
  end
  object cbMethod: TComboBox
    Left = 8
    Top = 72
    Width = 201
    Height = 21
    Style = csDropDownList
    ItemHeight = 13
    ItemIndex = 6
    TabOrder = 1
    Text = 'SHA-256'
    OnChange = cbMethodChange
    Items.Strings = (
      'MD2'
      'MD4'
      'MD5'
      'SHA0'
      'SHA1'
      'SHA-224'
      'SHA-256'
      'SHA-384'
      'SHA-512'
      'SHA-512/224'
      'SHA-512/256'
      'Keccak224'
      'Keccak256'
      'Keccak384'
      'Keccak512'
      'Keccak[]'
      'SHA3-224'
      'SHA3-256'
      'SHA3-384'
      'SHA3-512'
      'SHAKE128'
      'SHAKE256'
      'Random')
  end
  object seLength: TSpinEdit
    Left = 216
    Top = 72
    Width = 97
    Height = 22
    Increment = 8
    MaxValue = 2048
    MinValue = 8
    TabOrder = 2
    Value = 512
  end
  object cbEncoding: TComboBox
    Left = 320
    Top = 72
    Width = 201
    Height = 21
    Style = csDropDownList
    ItemHeight = 13
    ItemIndex = 9
    TabOrder = 3
    Text = 'ASCII 85'
    Items.Strings = (
      'Base 2'
      'Base 8'
      'Base 10'
      'Base 16'
      'Hexadecimal'
      'Base 32'
      'Base 32 - Extended Hexadecimal'
      'Base 64'
      'Base 85'
      'ASCII 85')
  end
  object btnGenerate: TButton
    Left = 8
    Top = 104
    Width = 513
    Height = 25
    Caption = 'Generate'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 4
    OnClick = btnGenerateClick
  end
  object leResult: TLabeledEdit
    Left = 8
    Top = 152
    Width = 513
    Height = 21
    EditLabel.Width = 34
    EditLabel.Height = 13
    EditLabel.Caption = 'Result:'
    TabOrder = 5
  end
  object btnAccept: TButton
    Left = 352
    Top = 184
    Width = 81
    Height = 25
    Caption = 'Accept'
    TabOrder = 6
    OnClick = btnAcceptClick
  end
  object btnCancel: TButton
    Left = 440
    Top = 184
    Width = 81
    Height = 25
    Caption = 'Cancel'
    TabOrder = 7
    OnClick = btnCancelClick
  end
end
