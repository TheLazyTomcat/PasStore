object fMainForm: TfMainForm
  Left = 671
  Top = 179
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'PasStore'
  ClientHeight = 515
  ClientWidth = 584
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object lblEntries: TLabel
    Left = 8
    Top = 8
    Width = 37
    Height = 13
    Caption = 'Entries:'
  end
  object lbEntries: TListBox
    Left = 8
    Top = 24
    Width = 185
    Height = 465
    ItemHeight = 13
    PopupMenu = pmEntries
    TabOrder = 0
    OnClick = lbEntriesClick
  end
  object gbEntryDetails: TGroupBox
    Left = 200
    Top = 8
    Width = 377
    Height = 481
    Caption = 'Entry details'
    TabOrder = 1
    inline frmEntryFrame: TfrmEntryFrame
      Left = 8
      Top = 16
      Width = 361
      Height = 457
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
  end
  object sbStatusBar: TStatusBar
    Left = 0
    Top = 496
    Width = 584
    Height = 19
    Panels = <
      item
        Alignment = taCenter
        Width = 100
      end
      item
        Width = 50
      end>
  end
  object oXPManifest: TXPManifest
    Left = 168
  end
  object pmEntries: TPopupMenu
    OnPopup = pmEntriesPopup
    Left = 136
    object pm_entry_Add: TMenuItem
      Caption = 'Add new...'
      ShortCut = 45
      OnClick = pm_entry_AddClick
    end
    object pm_entry_Remove: TMenuItem
      Caption = 'Remove selected'
      ShortCut = 46
      OnClick = pm_entry_RemoveClick
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object pm_entry_Rename: TMenuItem
      Caption = 'Rename...'
      ShortCut = 113
      OnClick = pm_entry_RenameClick
    end
    object N2: TMenuItem
      Caption = '-'
    end
    object pm_entry_ChangePswd: TMenuItem
      Caption = 'Change master password...'
      OnClick = pm_entry_ChangePswdClick
    end
  end
end
