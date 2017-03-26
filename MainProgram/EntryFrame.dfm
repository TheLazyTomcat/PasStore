object frmEntryFrame: TfrmEntryFrame
  Left = 0
  Top = 0
  Width = 361
  Height = 457
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  ParentFont = False
  TabOrder = 0
  object pnlMainPanel: TPanel
    Left = 0
    Top = 0
    Width = 361
    Height = 457
    Align = alClient
    BevelOuter = bvNone
    ParentBackground = True
    TabOrder = 0
    object shpNameBackground: TShape
      Left = 0
      Top = 0
      Width = 361
      Height = 25
      Pen.Style = psClear
    end
    object lblName: TLabel
      Left = 0
      Top = 0
      Width = 361
      Height = 25
      Alignment = taCenter
      AutoSize = False
      Caption = 'lblName'
      Color = clBtnFace
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
      Transparent = True
      Layout = tlCenter
      OnDblClick = lblNameDblClick
    end
    object lblHistory: TLabel
      Left = 0
      Top = 344
      Width = 86
      Height = 13
      Caption = 'Password history:'
    end
    object lblNotes: TLabel
      Left = 0
      Top = 72
      Width = 91
      Height = 13
      Caption = 'Description, notes:'
    end
    object bvlHorSplit: TBevel
      Left = 0
      Top = 184
      Width = 361
      Height = 9
      Shape = bsTopLine
    end
    object meNotes: TMemo
      Left = 0
      Top = 88
      Width = 361
      Height = 84
      ScrollBars = ssVertical
      TabOrder = 2
    end
    object lvHistory: TListView
      Left = 0
      Top = 360
      Width = 361
      Height = 97
      Columns = <
        item
          Caption = 'Time of addition'
          Width = 100
        end
        item
          Caption = 'Password'
          Width = 235
        end>
      HideSelection = False
      ReadOnly = True
      RowSelect = True
      PopupMenu = pmHistoryMenu
      TabOrder = 6
      ViewStyle = vsReport
    end
    object lePassword: TLabeledEdit
      Left = 0
      Top = 288
      Width = 361
      Height = 21
      EditLabel.Width = 50
      EditLabel.Height = 13
      EditLabel.Caption = 'Password:'
      TabOrder = 3
    end
    object leAddress: TLabeledEdit
      Left = 0
      Top = 48
      Width = 336
      Height = 21
      EditLabel.Width = 66
      EditLabel.Height = 13
      EditLabel.Caption = 'Address/URL:'
      TabOrder = 0
    end
    object btnAddToHistory: TButton
      Left = 272
      Top = 315
      Width = 89
      Height = 25
      Caption = 'Add to history'
      TabOrder = 5
      OnClick = btnAddToHistoryClick
    end
    object btnGenerate: TButton
      Left = 176
      Top = 315
      Width = 89
      Height = 25
      Caption = 'Generate...'
      TabOrder = 4
      OnClick = btnGenerateClick
    end
    object btnOpen: TButton
      Left = 336
      Top = 48
      Width = 25
      Height = 21
      Hint = 'Open address/URL'
      Caption = '8'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Webdings'
      Font.Style = []
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 1
      OnClick = btnOpenClick
    end
    object leLogin: TLabeledEdit
      Left = 0
      Top = 208
      Width = 361
      Height = 21
      EditLabel.Width = 103
      EditLabel.Height = 13
      EditLabel.Caption = 'Login, account name:'
      TabOrder = 7
    end
    object leEmail: TLabeledEdit
      Left = 0
      Top = 248
      Width = 361
      Height = 21
      EditLabel.Width = 74
      EditLabel.Height = 13
      EditLabel.Caption = 'Account e-mail:'
      TabOrder = 8
    end
  end
  object pmHistoryMenu: TPopupMenu
    OnPopup = pmHistoryMenuPopup
    Top = 320
    object pm_hm_Remove: TMenuItem
      Caption = 'Remove'
      ShortCut = 46
      OnClick = pm_hm_RemoveClick
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object pm_hm_Copy: TMenuItem
      Caption = 'Copy password'
      ShortCut = 16451
      OnClick = pm_hm_CopyClick
    end
  end
end
