object Form1: TForm1
  Left = 1062
  Top = 336
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 
    'VPN (Virtual Private Network) Downloader v1.0.0.3               ' +
    '                                            -= StalkerSTS =- '
  ClientHeight = 349
  ClientWidth = 590
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  Position = poDesktopCenter
  OnActivate = FormActivate
  OnClose = FormClose
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object lst1: TListBox
    Left = 0
    Top = 73
    Width = 590
    Height = 276
    Style = lbOwnerDrawFixed
    Align = alClient
    Color = clBtnFace
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlue
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ImeName = 'Russian'
    ItemHeight = 13
    ParentFont = False
    TabOrder = 0
    OnClick = lst1Click
    OnDrawItem = lst1DrawItem
  end
  object pnl1: TPanel
    Left = 0
    Top = 0
    Width = 590
    Height = 73
    Align = alTop
    BorderStyle = bsSingle
    ParentBackground = False
    TabOrder = 1
    object lbl1: TLabel
      Left = 8
      Top = 8
      Width = 7
      Height = 13
      Caption = '0'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lbl2: TLabel
      Left = 384
      Top = 10
      Width = 43
      Height = 13
      Caption = 'Log files:'
    end
    object lbl3: TLabel
      Left = 332
      Top = -3
      Width = 9
      Height = 29
      Caption = ':'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -24
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object btn5: TSpeedButton
      Left = 528
      Top = 28
      Width = 48
      Height = 22
      Hint = #1055#1086#1080#1089#1082' '#1083#1086#1075' '#1092#1072#1081#1083#1086#1074' ...'
      Caption = '...'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      OnClick = btn5Click
    end
    object btn1: TButton
      Left = 120
      Top = 28
      Width = 113
      Height = 22
      Caption = #1057#1082#1072#1095#1072#1090#1100' '#1086#1073#1085#1086#1074#1083#1077#1085#1080#1077
      TabOrder = 0
      OnClick = btn1Click
    end
    object btn2: TButton
      Left = 8
      Top = 28
      Width = 105
      Height = 22
      Caption = #1055#1086#1080#1089#1082' '#1086#1073#1085#1086#1074#1083#1077#1085#1080#1081
      TabOrder = 1
      OnClick = btn2Click
    end
    object btn3: TButton
      Left = 528
      Top = 4
      Width = 49
      Height = 22
      Caption = #1042#1099#1093#1086#1076
      TabOrder = 2
      OnClick = btn3Click
    end
    object edt1: TEdit
      Left = 240
      Top = 5
      Width = 93
      Height = 19
      Ctl3D = False
      ImeName = 'Russian'
      ParentCtl3D = False
      TabOrder = 3
      Text = '127.0.0.1'
    end
    object edt2: TEdit
      Left = 341
      Top = 5
      Width = 34
      Height = 19
      Ctl3D = False
      ImeName = 'Russian'
      ParentCtl3D = False
      TabOrder = 4
      Text = '3128'
    end
    object chk1: TCheckBox
      Left = 164
      Top = 7
      Width = 72
      Height = 17
      Caption = 'Use proxy:'
      TabOrder = 5
      OnClick = chk1Click
    end
    object btn4: TButton
      Left = 240
      Top = 28
      Width = 137
      Height = 22
      Caption = #1057#1082#1072#1095#1072#1090#1100' OpenVPN'
      TabOrder = 6
      OnClick = btn4Click
    end
    object ProgressBar1: TProgressBar
      Left = 1
      Top = 58
      Width = 584
      Height = 10
      Align = alBottom
      TabOrder = 7
    end
    object cbb1: TComboBox
      Left = 383
      Top = 28
      Width = 138
      Height = 22
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Tahoma'
      Font.Style = []
      ItemHeight = 14
      ParentFont = False
      TabOrder = 8
      OnChange = cbb1Change
    end
  end
  object udBufferSize: TUpDown
    Left = 934
    Top = 103
    Width = 17
    Height = 21
    Max = 32767
    TabOrder = 2
  end
  object IdHTTP1: TIdHTTP
    IOHandler = IdIOHandlerSocket1
    MaxLineAction = maException
    OnWork = IdHTTP1Work
    OnWorkBegin = IdHTTP1WorkBegin
    AllowCookies = True
    ProxyParams.BasicAuthentication = False
    ProxyParams.ProxyPort = 0
    Request.ContentLength = -1
    Request.ContentRangeEnd = 0
    Request.ContentRangeStart = 0
    Request.ContentType = 'text/html'
    Request.Accept = 'text/html, */*'
    Request.BasicAuthentication = False
    Request.UserAgent = 'Mozilla/3.0 (compatible; Indy Library)'
    HTTPOptions = [hoForceEncodeParams]
    CookieManager = IdCookieManager1
    Left = 232
    Top = 192
  end
  object XPManifest1: TXPManifest
    Left = 200
    Top = 192
  end
  object tmr1: TTimer
    Enabled = False
    Left = 232
    Top = 256
  end
  object IdAntiFreeze1: TIdAntiFreeze
    Left = 264
    Top = 192
  end
  object IdSSLIOHandlerSocket1: TIdSSLIOHandlerSocket
    SSLOptions.Method = sslvSSLv2
    SSLOptions.Mode = sslmUnassigned
    SSLOptions.VerifyMode = []
    SSLOptions.VerifyDepth = 0
    Left = 232
    Top = 160
  end
  object IdIOHandlerSocket1: TIdIOHandlerSocket
    Left = 232
    Top = 224
  end
  object IdCookieManager1: TIdCookieManager
    Left = 232
    Top = 128
  end
  object clDownLoader1: TclDownLoader
    BatchSize = 4096
    InternetAgent = 'Mozilla/4.0 (compatible; Clever Internet Suite)'
    ThreadCount = 2
    URL = 
      'https://swupdate.openvpn.org/community/releases/openvpn-install-' +
      '2.4.2-I601.exe'
    LocalFile = 'c:\openvpn-install-2.4.2-I601.exe'
    OnStatusChanged = clDownLoader1StatusChanged
    OnGetResourceInfo = clDownLoader1GetResourceInfo
    OnDataItemProceed = clDownLoader1DataItemProceed
    OnUrlParsing = clDownLoader1UrlParsing
    OnChanged = clDownLoader1Changed
    LocalFolder = 'c:\'
    Left = 370
    Top = 153
  end
end
