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
    end
    object lblHistory: TLabel
      Left = 0
      Top = 304
      Width = 38
      Height = 13
      Caption = 'History:'
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
      Top = 224
      Width = 361
      Height = 9
      Shape = bsTopLine
    end
    object meNotes: TMemo
      Left = 0
      Top = 88
      Width = 361
      Height = 129
      ScrollBars = ssVertical
      TabOrder = 2
    end
    object lvHistory: TListView
      Left = 0
      Top = 320
      Width = 361
      Height = 137
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
      Top = 248
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
      Top = 275
      Width = 89
      Height = 25
      Caption = 'Add to history'
      TabOrder = 5
      OnClick = btnAddToHistoryClick
    end
    object btnGenerate: TButton
      Left = 176
      Top = 275
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
      Caption = '>>'
      TabOrder = 1
      OnClick = btnOpenClick
    end
  end
  object pmHistoryMenu: TPopupMenu
    OnPopup = pmHistoryMenuPopup
    Top = 272
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
