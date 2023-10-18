object Form1: TForm1
  Left = 339
  Top = 144
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Win7s'#233' settings'
  ClientHeight = 350
  ClientWidth = 391
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PopupMenu = PopupMenu1
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Timer1: TTimer
    Interval = 100
    OnTimer = Timer1Timer
    Left = 200
    Top = 112
  end
  object PopupMenu1: TPopupMenu
    Left = 288
    Top = 168
    object Settings1: TMenuItem
      Caption = '&Settings'
      OnClick = Settings1Click
    end
    object StartwithWindows1: TMenuItem
      Caption = '&Start with Windows'
      OnClick = StartwithWindows1Click
    end
    object Disable1: TMenuItem
      Caption = '&Disable'
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object About1: TMenuItem
      Caption = '&About...'
      OnClick = About1Click
    end
    object N2: TMenuItem
      Caption = '-'
    end
    object Exit1: TMenuItem
      Caption = 'E&xit'
      OnClick = Exit1Click
    end
  end
end
