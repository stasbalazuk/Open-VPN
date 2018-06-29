unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, IdBaseComponent, IdComponent, IdTCPConnection,
  IdTCPClient, IdHTTP, URLMon, WinInet, Buttons, SyncObjs, ExtCtrls,
  IdAntiFreezeBase, IdAntiFreeze, IdIOHandler, IdIOHandlerSocket,
  ShellAPI,
  Masks,
  IniFiles,
  ShlObj,
  Tlhelp32,
  IdSSLOpenSSL, IdCookieManager, clDownLoader, clWinInet, clDC, clDCUtils, clMultiDC, clSingleDC,
  clProgressBar, XPMan;

const
  MY_MESS = WM_USER + 100;

type
  TForm1 = class(TForm)
    IdHTTP1: TIdHTTP;
    XPManifest1: TXPManifest;
    lst1: TListBox;
    pnl1: TPanel;
    lbl1: TLabel;
    btn1: TButton;
    btn2: TButton;
    btn3: TButton;
    tmr1: TTimer;
    lbl2: TLabel;
    edt1: TEdit;
    edt2: TEdit;
    lbl3: TLabel;
    chk1: TCheckBox;
    btn4: TButton;
    IdAntiFreeze1: TIdAntiFreeze;
    IdSSLIOHandlerSocket1: TIdSSLIOHandlerSocket;
    IdIOHandlerSocket1: TIdIOHandlerSocket;
    IdCookieManager1: TIdCookieManager;
    ProgressBar1: TProgressBar;
    udBufferSize: TUpDown;
    cbb1: TComboBox;
    btn5: TSpeedButton;
    clDownLoader1: TclDownLoader;    
    procedure FileSearch(const PathName, FileName: string; const InDir: boolean);
    procedure AddLog(const aStr: String; const aColor: TColor);
    procedure DeleteWord(var s:string;substr:string);
    procedure btn1Click(Sender: TObject);
    procedure btn2Click(Sender: TObject);
    procedure lst1Click(Sender: TObject);
    procedure btn3Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure lst1DrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure btn4Click(Sender: TObject);
    procedure IdHTTP1Work(Sender: TObject; AWorkMode: TWorkMode;
      const AWorkCount: Integer);
    procedure IdHTTP1WorkBegin(Sender: TObject; AWorkMode: TWorkMode;
      const AWorkCountMax: Integer);
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure chk1Click(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btn5Click(Sender: TObject);
    procedure cbb1Change(Sender: TObject);
    procedure clDownLoader1Changed(Sender: TObject);
    procedure clDownLoader1DataItemProceed(Sender: TObject;
      ResourceInfo: TclResourceInfo; AStateItem: TclResourceStateItem;
      CurrentData: PAnsiChar; CurrentDataSize: Integer);
    procedure clDownLoader1GetResourceInfo(Sender: TObject;
      ResourceInfo: TclResourceInfo);
    procedure clDownLoader1StatusChanged(Sender: TObject;
      Status: TclProcessStatus);
    procedure clDownLoader1UrlParsing(Sender: TObject;
      var URLComponents: URL_COMPONENTS);
  private
    FIsLoading: Boolean;
    procedure WMQueryEndSession(var Message: TMessage); message WM_QUERYENDSESSION;
  public
    { Public declarations }
    procedure thrTerminate(Sender:TObject);
    procedure MyProgress(var msg:TMessage);message MY_MESS;
  end;

const
  {$EXTERNALSYM CSIDL_COMMON_APPDATA}
  CSIDL_COMMON_APPDATA = $0023;
  sPf = 'c:\Program Files\OpenVPN\config\';
  OpenVPN = 'c:\Program Files\OpenVPN\VPN.exe';
  OpenVPNPrg = 'C:\Program Files\OpenVPN\bin\openvpn-gui.exe';

var
  Form1: TForm1;
  http:TIdHTTP;
  y: integer;
  fIniFile: TIniFile;
  TFiles: TStringList;
  UrlVPN,StrVPN,IPVPN: TStringList;
  n,nv,vpnf,strf: string;
  url1,urlf: string;
  FileHandle: Integer;
  Thr,Buf,gn: Integer;
  CountThr: integer; // глобальная переменная, индикатор количества потоков
  SectCounter: TCriticalSection; //TCriticalSection; // критическая секция для счетчика, иначе может возникнуть ошибка совместного доступа


implementation

{$R *.dfm}

uses HtmlParser, UrlTools, httpsend, ssl_openssl;

procedure TForm1.WMQueryEndSession(var Message: TMessage);
begin
  Message.Result := 1;
  Application.Terminate;
end;

type
  TDownLoader = class(TThread)
  private
    FToFolder: string;
    FURL: string;
    protected
      procedure Execute;override;
    public
      property URL:string read FURL write FURL;
      property ToFolder:string read FToFolder write FToFolder;
      procedure IdHTTP1Work(ASender: TObject; AWorkMode: TWorkMode;
      AWorkCount: Integer);
      procedure IdHTTP1WorkBegin(ASender: TObject; AWorkMode: TWorkMode;
      AWorkCountMax: Integer);
      procedure IdHTTP1WorkEnd(ASender: TObject; AWorkMode: TWorkMode);
  end;

procedure TDownLoader.IdHTTP1Work(ASender: TObject; AWorkMode: TWorkMode;
  AWorkCount: Integer);
begin
  Form1.ProgressBar1.Position := AWorkCount;
end;

function GetSpecialFolderPath(CSIDL : Integer) : String;
var
  Path : PChar;
begin
  Result := '';
  GetMem(Path,MAX_PATH);
  Try
    If Not SHGetSpecialFolderPath(0,Path,CSIDL,False) Then
      Raise Exception.Create('Shell function SHGetSpecialFolderPath fails.');
    Result := Trim(StrPas(Path));
    If Result = '' Then
      Raise Exception.Create('Shell function SHGetSpecialFolderPath return an empty string.');
    Result := IncludeTrailingPathDelimiter(Result);
  Finally
    FreeMem(Path,MAX_PATH);
  End;
end;
 
function GetTempFolderPath : String;
var
  Path : PChar;
begin
  Result := ExtractFilePath(ParamStr(0));
  GetMem(Path,MAX_PATH);
  Try
    If GetTempPath(MAX_PATH,Path) <> 0 Then
      Begin
        Result := Trim(StrPas(Path));
        Result := IncludeTrailingPathDelimiter(Result);
      End;
  Finally
    FreeMem(Path,MAX_PATH);
  End;
end;

function GetInetFile(const fileURL, FileName: string): boolean;
const
  BufferSize = 1024;
var
  hSession, hURL: HInternet;
  Buffer: array[1..BufferSize] of Byte;
  BufferLen: DWORD;
  f: file;
  sAppName: string;
begin
  //Result := False;
  sAppName := ExtractFileName(Application.ExeName);
  hSession := InternetOpen(PChar(sAppName),
  INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  try
    hURL := InternetOpenURL(hSession, PChar(fileURL), nil, 0, 0, 0);
    try
      AssignFile(f, FileName);
      Rewrite(f,1);
      repeat
        InternetReadFile(hURL, @Buffer, SizeOf(Buffer), BufferLen);
        BlockWrite(f, Buffer, BufferLen);
      until
        BufferLen = 0;
        CloseFile(f);
        Result := True;
        Form1.lbl1.Caption:='Load openvpn - OK';
    finally
      InternetCloseHandle(hURL);
    end;
  finally
    InternetCloseHandle(hSession);
  end;
end;
 
function GetWindowsFolerPath : String;
var
  Path : PChar;
begin
  Result := ExtractFilePath(ParamStr(0));
  GetMem(Path,MAX_PATH);
  Try
    If GetWindowsDirectory(Path, MAX_PATH) <> 0 Then
      Begin
        Result := Trim(StrPas(Path));
        Result := IncludeTrailingPathDelimiter(Result);
      End;
  Finally
    FreeMem(Path,MAX_PATH);
  End;
end;
 
function GetUserAppDataFolderPath : String;
begin
  Result := GetSpecialFolderPath(CSIDL_APPDATA);
end;

function GetUserMyDocumentsFolderPath : String;
begin
  Result := GetSpecialFolderPath(CSIDL_PERSONAL);
end;

function GetUserFavoritesFolderPath : String;
begin
  Result := GetSpecialFolderPath(CSIDL_FAVORITES);
end;

function GetCommonAppDataFolderPath : String;
begin
  Result := GetSpecialFolderPath(CSIDL_COMMON_APPDATA);
end;

procedure RestartP;
var
  FullProgPath: PChar;
begin
  FullProgPath := PChar(Application.ExeName);
  WinExec(FullProgPath, SW_SHOW); // Or better use the CreateProcess function
  Application.Terminate; // or: Close; 
end;

//Защита от отладчика
function DebuggerPresent:boolean;
type
  TDebugProc = function:boolean; stdcall;
var
   Kernel32:HMODULE;
   DebugProc:TDebugProc;
begin
   Result:=false;
   Kernel32:=GetModuleHandle('kernel32.dll');
   if kernel32 <> 0 then
    begin
      @DebugProc:=GetProcAddress(kernel32, 'IsDebuggerPresent');
      if Assigned(DebugProc) then
         Result:=DebugProc;
    end;                                  
end;

Procedure IniFileProc;
Var
  Ini : TIniFile;
  dt,dt1,dt2: string;
Begin
  dt:=Copy(DateToStr(Date),1,2);
  dt1:=Copy(DateToStr(Date),4,2);
  dt2:=Copy(DateToStr(Date),7,4);
  dt:=dt2+dt1+dt;
  Ini := TIniFile.Create(ExtractFilePath(ParamStr(0))+'settings.ini');
  Ini.WriteString('PROXY','IP',Form1.edt1.Text);
  Ini.WriteString('PROXY','PORT',Form1.edt2.Text);
  Ini.WriteString('DATE','NOW',dt);
  Ini.Free;
end;

Procedure IniFileLoad;
var
   Ini : TIniFile;
begin
  Ini := TIniFile.Create(ExtractFilePath(ParamStr(0))+'settings.ini');
  Form1.edt1.Text:=Ini.ReadString('PROXY','IP','');
  Form1.edt2.Text:=Ini.ReadString('PROXY','PORT','');
  Ini.Free;
end;

procedure CreateFormInRightBottomCorner;
var
 r : TRect;
begin
 SystemParametersInfo(SPI_GETWORKAREA, 0, Addr(r), 0);
 Form1.Left := r.Right-Form1.Width;
 Form1.Top := r.Bottom-Form1.Height;
end;

procedure FindFiles(StartFolder, Mask: string; List: TStrings;
  ScanSubFolders: Boolean = True);
var
  SearchRec: TSearchRec;
  FindResult: Integer;
begin
  List.BeginUpdate;
  try
    StartFolder := IncludeTrailingBackslash(StartFolder);
    FindResult := FindFirst(StartFolder + '*.*', faAnyFile, SearchRec);
    try
      while FindResult = 0 do
        with SearchRec do
        begin
          if (Attr and faDirectory) <> 0 then
          begin
            if ScanSubFolders and (Name <> '.') and (Name <> '..') then
              FindFiles(StartFolder + Name, Mask, List, ScanSubFolders);
          end
          else
          begin
            if MatchesMask(Name, Mask) then begin
               DeleteFile(StartFolder + Name);
               List.Add(StartFolder + Name);
            end;
          end;
          FindResult := FindNext(SearchRec);
        end;
    finally
      FindClose(SearchRec);
    end;
  finally
    List.EndUpdate;
  end;
end;

procedure TForm1.AddLog(const aStr: String; const aColor: TColor);
begin
  lst1.Items.AddObject(aStr, TObject(aColor));
end;

function ExtractText(const Str: string; const Delim1: char): string;
var
  pos1: integer;
begin
  result := '';
  pos1 := Pos(Delim1, Str);
  if (pos1 > 0) then
    result := Copy(Str, pos1 + 1, pos1 - 1);
end;

procedure TDownLoader.IdHTTP1WorkBegin(ASender: TObject; AWorkMode: TWorkMode;
  AWorkCountMax: Integer);
begin
  Form1.ProgressBar1.Position := 0;
  Form1.ProgressBar1.Max := AWorkcountMax;
end;

procedure TDownLoader.IdHTTP1WorkEnd(ASender: TObject; AWorkMode: TWorkMode);
begin
  Form1.ProgressBar1.Position := 0;
end;

{ TDownLoader }
procedure TDownLoader.execute;
var http: TIdHTTP;
    str: TFileStream;
begin
  //Создим класс для закачки
  http:=TIdHTTP.Create(nil);
  http.ProtocolVersion:=pv1_1;
  http.HandleRedirects:=true;
  http.ProxyParams.BasicAuthentication := true;
  if Form1.chk1.Checked then begin
     http.ProxyParams.ProxyServer:=Form1.edt1.Text;   //10.220.1.7
     http.ProxyParams.ProxyPort:=StrToInt(Form1.edt2.Text); //3129
  end;
if http.ProxyParams.BasicAuthentication then begin
  //каталог, куда файл положить
  ForceDirectories(ExtractFileDir(ToFolder));
  //Поток для сохранения
  str := TFileStream.Create(ToFolder, fmCreate);
  try
    //Качаем
    Form1.lbl1.Caption:='Ожидайте ... качаю файл ...';
    Form1.ProgressBar1.Position:=http.RecvBufferSize;
    Application.ProcessMessages;
    http.Get(url, str);
  finally
    //Нас учили чистить за собой
    http.Free;
    str.Free;
    SectCounter.Enter;
    Dec(CountThr);
    SectCounter.Leave;
    Form1.btn1.Enabled:=True;
    Form1.btn3.Enabled:=True;
    Form1.tmr1.Enabled:=False;
    Form1.ProgressBar1.Position:=100;
    Application.ProcessMessages;
  end;
end else Form1.lbl1.Caption:='PROXY - ERROR';
end;

function OpenInternet(Name: WideString): pointer;
begin
  result := InternetOpenW(@Name[1], INTERNET_OPEN_TYPE_PRECONFIG,
    nil, nil, 0);
end;

function Pars(T_, ForS, _T: string): string;
var
  a, b: integer;
begin
  Result := ''; // обнуляем результат
  if (T_ = '') or (ForS = '') or (_T = '') then
    Exit; // если параметры пусты, то выходим
  a := Pos(T_, ForS); // ищем заданный параметр T_ в строке ForS
  if a = 0 then // если не нашли, то
    Exit // выходим
  else // иначе
    a := a + Length(T_); // а=а+длина T_
  ForS := Copy(ForS, a, Length(ForS) - a + 1); // ForS = копируем из ForS начиная с символа а символов длина Fors - a + 1
  b := Pos(_T, ForS); // ищем 2ую часть
  if b > 0 then // если нашли, то
    Result := Copy(ForS, 1, b - 1); // результат функции равен копированию из ForS начиная с индекса 1 символов b - 1
// получается, что функция просто обрезает всё, что до параметра T_ и параметр T_, и параметр _T и всё, что после него
end;

//Поиск запущенного процесса
function FindTask(ExeFileName: string): integer;
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
begin
  result := 0;
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := Sizeof(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);
  while integer(ContinueLoop) <> 0 do
   begin
    if ((UpperCase(ExtractFileName(FProcessEntry32.szExeFile)) = UpperCase(ExeFileName))
      or (UpperCase(FProcessEntry32.szExeFile) = UpperCase(ExeFileName)))
      then Result := 1;
      ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
   end;
   CloseHandle(FSnapshotHandle);
end;

//функция который возвращает кол. массива.
function DCOUNT(str, Delimeter: string) : integer;
var
 StrL : TStringList;
 ParseStr : string;
begin
  try
    StrL := TStringList.Create;
    ParseStr:= StringReplace(str, Delimeter, #13, [rfReplaceAll]);
    StrL.Text := ParseStr;
    Result := StrL.Count;
  finally
    //StrL.Free;
  end;
end;

//Извелчь урл из строки
function ExtractUrlFileName(const AUrl: string): string;
var
  i: Integer;
begin
  i := LastDelimiter('/', AUrl);
  Result := Copy(AUrl, i + 1, Length(AUrl) - (i));
end;

function Parse(Char, S: string; Count: Integer): string;
var
   I: Integer;
   T: string;
begin
   if S[Length(S)] <> Char then
     S := S + Char;
   for I := 1 to Count do
   begin
     T := Copy(S, 0, Pos(Char, S) - 1);
     S := Copy(S, Pos(Char, S) + 1, Length(S));
   end;
   Result := T;
end;

procedure explode(const S, Delimeter : string; Parts : TStrings);
var
  CurPos: integer;
  CurStr: string;
begin
  Parts.clear;
  Parts.BeginUpdate();
  try
    CurStr:= S;
    repeat
      CurPos:= Pos(Delimeter, CurStr);
      if (CurPos>0) then
      begin
        Parts.Add(Copy(CurStr, 1, Pred(CurPos)));
        CurStr:= Copy(CurStr, CurPos+Length(Delimeter),
        Length(CurStr)-CurPos-Length(Delimeter)+1);
      end else
        Parts.Add(CurStr);
    until CurPos=0;
  finally
    Parts.EndUpdate();
  end;
end;

{-------------------------------------------------------------------------------
    Функция: ParseStr
    Автор:    ArhangeL
    Дата:  2011.01.11
    Входные параметры: str, sub1, sub2: string
    Результат:    string
    Описание: Парсер строки, вытаскивает текст из строки str между тегами sub1, sub2
    Stt входная строка.
    sub1 - открывающий тег.
    Sub2 - закрывающий тег.
-------------------------------------------------------------------------------}
function ParseStr(str, sub1, sub2: string): string;
var
 st, fin: Integer;
begin
 st := Pos(sub1, str);
if st = 0 then n:='';
if st > 0 then begin
 str := Copy(str, st + length(sub1), length(str) - 1);
 st := 1;
 fin := Pos(sub2, str);
 Result := Copy(str, st, fin - st);
 str := Copy(str, fin + length(sub2), length(str) - 1);
end;
end;

procedure TForm1.MyProgress(var msg: TMessage);
begin
  case msg.WParam of
  0:begin ProgressBar1.Max:=msg.LParam;ProgressBar1.Position:=0; end;
  1:ProgressBar1.Position:=msg.LParam;
  end;
end;

procedure TForm1.thrTerminate(Sender: TObject);
begin
  MessageBox(Handle,PChar('Файл успешно загружен!'),PChar('Внимание'),64);
end;

procedure TForm1.btn1Click(Sender: TObject);
var
  F :TFileStream;
  s: string;
  lHTTP: THTTPSend;
  fsz: Integer;
  i: Integer;
begin
   cbb1.Clear;
if not DirectoryExists(sPf) then
   ForceDirectories(sPf);
if not FileExists(OpenVPN) then
   CopyFile(PChar(Application.ExeName),PChar(OpenVPN),False);
if DirectoryExists(sPf) then begin
   lbl1.Caption:='Dir OpenVPN - OK';
if DirectoryExists(ExtractFilePath(ParamStr(0))+'config') then
   FindFiles(PChar(ExtractFilePath(ParamStr(0))+'config\'), '*.ovpn', TFiles, true);
   IPVPN.Clear;
   IPVPN.Text:=lst1.Items.Text;
   lst1.Items.Clear;
for i:=0 to UrlVPN.Count-1 do begin
try
   urlf:=UrlVPN.Strings[i];
   s:=IPVPN.Strings[i];
   ProgressBar1.Max:=UrlVPN.Count-1;
   ProgressBar1.Position:=i;
   Application.ProcessMessages;
   vpnf:=ExtractUrlFileName(UrlVPN.Strings[i]);
   url1:=ExtractUrlFileName(UrlVPN.Strings[i]);
   strf:=StrVPN.Strings[i];
   ProgressBar1.Position:=20;
if url1 <> '' then begin
   tmr1.Enabled:=true;
   btn1.Enabled:=False;
   btn3.Enabled:=False;
   btn4.Enabled:=False;
   chk1.Enabled:=False;
   edt1.Enabled:=False;
   edt2.Enabled:=False;
   OpenInternet('Mozilla Firefox');
   if chk1.Checked then begin
      lHTTP.ProxyHost:=Form1.edt1.Text;
      lHTTP.ProxyPort:=Form1.edt2.Text;
   end;
   ProgressBar1.Position:=50;
   lHTTP := THTTPSend.Create;
  try
    if lHTTP.HTTPMethod('GET', urlf) then
    if lHTTP.ResultCode = 200 then begin
       lHTTP.Document.SaveToFile(url1);
    end;
  finally
    lHTTP.Free;
  end;
  ProgressBar1.Position:=100;
  tmr1.Enabled:=False;
if not DirectoryExists(ExtractFilePath(ParamStr(0))+'config') then CreateDir(ExtractFilePath(ParamStr(0))+'config');
if FileExists(url1) then RenameFile(url1,'SERJ.WS_'+strf+'.ovpn');
if not FileExists('SERJ.WS_'+strf+'.ovpn') then Exit;
   F:=TFileStream.Create('SERJ.WS_'+strf+'.ovpn', fmOpenRead);
   fsz:=F.Size;
   F.Free;
if fsz < 200 then begin
if FileExists('SERJ.WS_'+strf+'.ovpn') then DeleteFile('SERJ.WS_'+strf+'.ovpn');
end else begin
if DirectoryExists(ExtractFilePath(ParamStr(0))+'config') then
if FileExists('SERJ.WS_'+strf+'.ovpn') then
MoveFile(PChar('SERJ.WS_'+strf+'.ovpn'),PChar(ExtractFilePath(ParamStr(0))+'config\'+'SERJ.WS_'+strf+'.ovpn'));
if FileExists('SERJ.WS_'+strf+'.ovpn') and FileExists(ExtractFilePath(ParamStr(0))+'config\'+'SERJ.WS_'+strf+'.ovpn') then
DeleteFile('SERJ.WS_'+strf+'.ovpn');
end;
end else lst1.Items.Add('Нет данных для загрузки ...');
except on e: Exception do
   ShowMessage(e.Message); // вот здесь получаем 'Operation aborted'
end;
if s <> '' then
AddLog(s+' - OK',RGB(Random(11) * 20 , Random(11) * 20, Random(11) * 20));
lbl1.Caption:=StrVPN.Strings[i]+' - OK';
Application.ProcessMessages;
end;
if ProgressBar1.Position <= 100 then lbl1.Caption:='Download - OK';
if FindTask(ExtractFileName(OpenVPNPrg)) <> 0 then
   lbl1.Caption:='Openvpn-gui - OK'
else begin
   lbl1.Caption:='Openvpn-gui - Error';
if FileExists(OpenVPNPrg) then ShellExecute(Handle, 'open',PChar(OpenVPNPrg), nil,PChar(ExtractFilePath(OpenVPNPrg)), SW_SHOWNORMAL)
else lbl1.Caption:='File not found Openvpn-gui.exe';
end;
if FindTask(ExtractFileName(OpenVPNPrg)) <> 0 then
   lbl1.Caption:='Openvpn-gui - OK'
else lbl1.Caption:='Openvpn-gui - Error';
btn1.Enabled:=True;
btn3.Enabled:=True;
btn4.Enabled:=True;
chk1.Enabled:=True;
edt1.Enabled:=True;
edt2.Enabled:=True;
end else begin
    lbl1.Caption:='Dir OpenVPN - ERROR';
    Exit;
end;
end;

procedure TForm1.btn2Click(Sender: TObject);
var
  i:integer;
  Source,Source1: TStringList;
  s,substr,substr1,ipv : string;
  UrlSite  : string;
  SrcPathCount: Integer;
  SrcHost, SrcPath, Srcfname, Srcfext:String;
  HTTP: THTTPSend;
  str: TStringList;
begin
  cbb1.Clear;
  lst1.Items.Clear;
  tmr1.Enabled:=True;
  OpenInternet('Mozilla Firefox');
  //Создим класс для закачки
  Source:=TStringList.Create;
  Source1:=TStringList.Create;
  Http:=THTTPSend.Create;
  str:= TStringList.Create;
  if chk1.Checked then begin
     HTTP.ProxyHost:=Form1.edt1.Text;
     HTTP.ProxyPort:=Form1.edt2.Text;
  end;
  //каталог, куда файл положить
  ForceDirectories(ExtractFileDir(ExtractFilePath(ParamStr(0))));
  //Поток для сохранения
  //str:=TFileStream.Create(ExtractFilePath(ParamStr(0))+'Log.txt', fmCreate);  //+Form1.urlf
  url1:='http://serj.ws/openvpn';
  SrcPathCount:=SplitFullURL(Trim(url1), Srchost,Srcpath,Srcfname,Srcfext);
if (SrcPathCount=-1) then Exit;
   UrlSite:='http://'+SrcHost+SrcPath+Srcfname+Srcfext;
try
   Application.ProcessMessages;
   HTTP.HTTPMethod('Get', 'http://serj.ws/openvpn');
   http.MimeType:='application/x-www-form-urlencoded';
   if Http.ResultCode = 200 then form1.lbl1.Caption:='PROXY - OK'
   else form1.lbl1.Caption:='PROXY - NO';
   str.LoadFromStream(HTTP.Document);
   // переводим в ansi(сайт на кодировке utf8), просто если не перевести, будут очень нехорошие символы
   str.Text:=utf8toansi(str.Text);
   Source.Text:=str.Text;
   {Source.SaveToFile('vpn.log'); //Для теста
   if FileExists('vpn.log') then Source.LoadFromFile('vpn.log'); // Для теста}
except on e: Exception do
   ShowMessage(e.Message); // вот здесь получаем 'Operation aborted'
end;
  for i:=0 to Source.Count-1 do begin
      n:=Source.Strings[i];
      //n:=Utf8ToAnsi(n);
   if Pars('<div class="ovpn"><font color=black><b>', n, '</b>') <> '' then
    begin
      Source1.Text:=Source.Strings[i];
      s := ParseStr(Source1.Text,'<font color=black><b>','</b>');
      StrVPN.Add(Trim(s));
      substr1:= Trim(s);
    end;
   if Pars('<div class="ovpn"><font color="#D40000"><b>', n, '</b>') <> '' then
    begin
      Source1.Text:=Source.Strings[i];
      s := ParseStr(Source1.Text,'<font color="#D40000"><b>','</b>');
      IPVPN.Add(Trim(s));
      ipv:=Trim(s);
    end;
   if Pars('<div class="ovpn"><b><a href=', n, 'title="Скачать"') <> '' then
    begin
      Source1.Text:=Source.Strings[i];
      s := ParseStr(Source1.Text,'href="','" title');
      substr:= Trim('http://serj.ws'+s+'='+substr1);
      UrlVPN.Add(Trim('http://serj.ws'+s));
      AddLog(Trim(substr1)+' -> '+ipv,RGB(Random(11) * 20 , Random(11) * 20, Random(11) * 20));
    end;
  end;
  if UrlVPN.Count <> StrVPN.Count then StrVPN.Add(StrVPN.Strings[Random(StrVPN.Count)]);
  if UrlVPN.Count <> StrVPN.Count then StrVPN.Add(StrVPN.Strings[Random(StrVPN.Count)]);
  if UrlVPN.Count <> StrVPN.Count then StrVPN.Add(StrVPN.Strings[Random(StrVPN.Count)]);
  if UrlVPN.Count <> StrVPN.Count then StrVPN.Add(StrVPN.Strings[Random(StrVPN.Count)]);
  if UrlVPN.Count <> StrVPN.Count then StrVPN.Add(StrVPN.Strings[Random(StrVPN.Count)]);
  {y:=UrlVPN.Count;
  UrlVPN.SaveToFile('UrlVPN.txt'); //Для теста
  y:=IPVPN.Count;
  IPVPN.SaveToFile('IPVPN.txt');
  y:=StrVPN.Count;
  StrVPN.SaveToFile('StrVPN.txt');}
  http.Free;
  str.Free;
  Source.Free;
  Source1.Free;
  DeleteFile('Log.txt');
  btn2.Enabled:=false;
  tmr1.Enabled:=false;
end;

procedure TForm1.lst1Click(Sender: TObject);
begin
  lst1.Repaint;
end;

procedure TForm1.btn3Click(Sender: TObject);
var otv:word;
begin
 IniFileProc;
 otv := MessageBox(handle,PChar('Выберите действие над программой?'+#13#10+'Да - Выход'+#13#10+'Нет - Перезапуск'), PChar('Внимание'), 36);
 if otv=IDYES then Application.Terminate;
 if otv=IDNO  then RestartP;
end;

procedure TForm1.DeleteWord(var s:string;substr:string);
begin
  Delete(s,Pos(substr,s),Length(substr));
end;

function GetUserFromWindows: string;
var
UserName : string;
UserNameLen : Dword;
begin
UserNameLen := 255;
SetLength(userName, UserNameLen);
if GetUserName(PChar(UserName), UserNameLen) then
   Result := Copy(UserName,1,UserNameLen - 1)
else
   Result := '';
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  Style: Longint;
begin
  urlf:='';
  y:=0;
  CreateFormInRightBottomCorner;
  TFiles:=TStringList.Create;
  UrlVPN:=TStringList.Create;
  StrVPN:=TStringList.Create;
  IPVPN:=TStringList.Create;
  url1:='http://serj.ws/openvpn';
  Style := GetWindowLong(Handle, GWL_STYLE);
  SetWindowLong(Handle, GWL_STYLE, Style and not WS_SYSMENU); //Скрыть значки на панели формы
  //=====Защита от отладчика===========
  //if DebuggerPresent then Application.Terminate;
  SectCounter:=TCriticalSection.Create;
  ExtractFilePath(ParamStr(0));
  if not DirectoryExists(ExtractFilePath(ParamStr(0))+'config') then CreateDir(ExtractFilePath(ParamStr(0))+'config');
  if not FileExists(ExtractFilePath(ParamStr(0))+'settings.ini') then IniFileProc;
  if FileExists(ExtractFilePath(ParamStr(0))+'settings.ini') then IniFileLoad;  
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  TFiles.Free;
  UrlVPN.Free;
  StrVPN.Free;
  IPVPN.Free;
  FileClose(FileHandle);
end;

procedure TForm1.lst1DrawItem(Control: TWinControl; Index: Integer;
  Rect: TRect; State: TOwnerDrawState);
var
  OldColor : TColor;
begin
  with lst1.Canvas do begin
    //Запоминаем действующий цвет шрифта.
    OldColor := Font.Color;
    //Извлекаем сведения о цвете шрифта и задаём для шрифта канвы этот цвет.
    Font.Color := TColor(lst1.Items.Objects[Index]);
    //Выводим текст строки.
    TextOut(Rect.Left, Rect.Top, lst1.Items[Index]);
    //Восстанавливаем прежний цвет шрифта.
    Font.Color := OldColor;
  end;
end;

procedure TForm1.btn4Click(Sender: TObject);
var
  HTTP: THTTPSend;
begin
  try
    cbb1.Clear;
    FIsLoading := False;
    lst1.Items.Clear();
    url1:='https://drive.google.com/uc?authuser=0&id=1AE13aVI4b1XHvpupOGyAJ5BK7n1dtC8K&export=download';
    if GetInetFile(url1,'openvpn-install-2.4.2-I601.exe') then begin
       lbl1.Caption:='Load openvpn - OK';
       clDownLoader1.GetResourceInfo(True);
       Application.ProcessMessages;
    end else begin
    lbl1.Caption:='Load openvpn ...';
    url1:='https://swupdate.openvpn.org/community/releases/openvpn-install-2.4.2-I601.exe';
    Http:=THTTPSend.Create;
    if chk1.Checked then begin
       HTTP.ProxyHost:=Form1.edt1.Text;
       HTTP.ProxyPort:=Form1.edt2.Text;
    end;
       ProgressBar1.Position := 50;
    if Http.HTTPMethod('GET', url1) then
    if Http.ResultCode = 200 then begin
       ProgressBar1.Position := 80;
       Http.Document.SaveToFile(ExtractFilePath(ParamStr(0))+'openvpn-install-2.4.2-I601.exe');
    end else begin
       lbl1.Caption:='Load openvpn - ERROR';
       Application.ProcessMessages;
       Exit;
    end;
       lbl1.Caption:='Load openvpn - OK';
       Application.ProcessMessages;
       Exit;
    end;
    ExtractFilePath(ParamStr(0));
  finally
    ProgressBar1.Position := 100;
    Application.ProcessMessages;
    if FileExists(ExtractFilePath(ParamStr(0))+'openvpn-install-2.4.2-I601.exe') then begin
       lbl1.Caption:='Load openvpn - OK';
       ShellExecute(Handle, 'open',PChar(ExtractFilePath(ParamStr(0))+'openvpn-install-2.4.2-I601.exe'), nil,PChar(ExtractFilePath(ParamStr(0))), SW_SHOWNORMAL);
    end else lbl1.Caption:='Load openvpn - ERROR';
    Application.ProcessMessages;
  end;
end;

procedure TForm1.IdHTTP1Work(Sender: TObject; AWorkMode: TWorkMode;
  const AWorkCount: Integer);
begin
   ProgressBar1.Position:=ProgressBar1.Position+AWorkCount;
end;

procedure TForm1.IdHTTP1WorkBegin(Sender: TObject; AWorkMode: TWorkMode;
  const AWorkCountMax: Integer);
begin
   ProgressBar1.Max:=AWorkCountMax;
end;

procedure TForm1.FormActivate(Sender: TObject);
begin
//=====Защита от отладчика===========
//if DebuggerPresent then Application.Terminate;
CreateFormInRightBottomCorner;   
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  IniFileProc;
end;

procedure TForm1.chk1Click(Sender: TObject);
begin
  if chk1.Checked then
     lbl1.Caption:='Proxy - Yes'
  else lbl1.Caption:='Proxy - No';
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
CanClose := False;
CanClose := not clDownLoader1.IsBusy;
end;

procedure TForm1.FileSearch(const PathName, FileName: string; const InDir: boolean);
var
 Rec: TSearchRec;
 Path: string;
begin
btn5.Enabled:=False;
lbl1.Caption:='Expect, Find files ...';
Application.ProcessMessages;
Path := IncludeTrailingBackslash(PathName);
if FindFirst(Path + FileName, faAnyFile - faDirectory, Rec) = 0 then
 try
   repeat
     cbb1.Items.Add(Rec.Name);
   until FindNext(Rec) <> 0;
 finally
   FindClose(Rec);
 end;
 if not InDir then Exit;
 if FindFirst(Path + FileName, faDirectory, Rec) = 0 then
 try
   repeat
     if ((Rec.Attr and faDirectory) <> 0) and (Rec.Name <> '.') and (Rec.Name <> '..') then
     FileSearch(Path + Rec.Name, FileName, True);
   until FindNext(Rec) <> 0;
 finally
   FindClose(Rec);
   btn5.Enabled:=True;
   lbl1.Caption:='Find files - OK!';
   Application.ProcessMessages;
 end;
end;

procedure TForm1.btn5Click(Sender: TObject);
var
  i: integer;
begin
{
  GetUserFromWindows
  GetUserAppDataFolderPath
  GetUserMyDocumentsFolderPath
  GetUserFavoritesFolderPath
  GetCommonAppDataFolderPath
}
  url1:=GetUserFavoritesFolderPath;
  i:=Pos('Favorites',url1);
  if i > 0 then
     Delete(url1,i,Length(url1));
     url1:=url1+'OpenVPN\log\';
  if DirectoryExists(url1) then begin
     lbl1.Caption:='Dir log - OK';
     FileSearch(url1,'*.log', True);
  end else lbl1.Caption:='Dir log - Error';
end;

procedure TForm1.cbb1Change(Sender: TObject);
var
  s: string;
begin
   s:=url1;
   Sendmessage(cbb1.Handle,352,100,cbb1.ItemIndex);
   s:=s+cbb1.Items.Strings[cbb1.ItemIndex];
if FileExists(s) then
   ShellExecute(Handle, 'open',PChar(s), nil,PChar(ExtractFilePath(s)), SW_SHOWNORMAL);
end;

procedure TForm1.clDownLoader1Changed(Sender: TObject);
begin
  if FIsLoading then Exit;
  FIsLoading := True;
  try
    lst1.Items.Add(clDownLoader1.URL);
    //lst1.Items.Add(clDownLoader1.UserName);
    //lst1.Items.Add(clDownLoader1.Password);
    lst1.Items.Add(clDownLoader1.LocalFile);
    //lst1.Items.Add(clDownLoader1.LocalFolder);
    lst1.Items.Add('Position '+IntToStr(clDownLoader1.ThreadCount));
    lst1.Items.Add('Size Position '+IntToStr(clDownLoader1.BatchSize));
  finally
    FIsLoading := False;
  end;
end;

procedure TForm1.clDownLoader1DataItemProceed(Sender: TObject;
  ResourceInfo: TclResourceInfo; AStateItem: TclResourceStateItem;
  CurrentData: PAnsiChar; CurrentDataSize: Integer);
var
  State: TclResourceStateList;
begin
  State := AStateItem.ResourceState;
  lst1.Items.Add(Format('%.2n of %.2n Kb proceed, speed %.2n Kb/sec, elapsed %.2n min, remains %.2n min',
    [State.BytesProceed / 1024, State.ResourceSize / 1024, State.Speed / 1024,
    State.ElapsedTime / 60, State.RemainingTime / 60]));
end;

procedure TForm1.clDownLoader1GetResourceInfo(Sender: TObject;
  ResourceInfo: TclResourceInfo);
var
  s: String;
begin
  if (ResourceInfo <> nil) then
  begin
    s := 'Resource ' + ResourceInfo.Name + '; Size ' + IntToStr(ResourceInfo.Size)
      + '; Date ' + DateTimeToStr(ResourceInfo.Date)
      + '; Type ' + ResourceInfo.ContentType;
    if ResourceInfo.Compressed then
    begin
      s := s + '; Compressed';
    end;
  end else
  begin
    s := 'There are no any info available.';
  end;
  lst1.Items.Add(s);
  Application.ProcessMessages;
  if not clDownLoader1.IsBusy then clDownLoader1.Start(True)
  else lbl1.Caption:='Load openvpn - ERROR';
end;

procedure TForm1.clDownLoader1StatusChanged(Sender: TObject;
  Status: TclProcessStatus);
var
  s: String;
begin
  case Status of
    psSuccess: lbl1.Caption:='Process successfully';
    psFailed:
      begin
        s := (Sender as TclDownLoader).Errors.Text;
        MessageBox(0, PChar(s), 'Error', 0);
      end;
    psTerminated: lbl1.Caption:='Process stopped';
    psErrors: lbl1.Caption:='Process warnings';
  end;
end;

procedure TForm1.clDownLoader1UrlParsing(Sender: TObject;
  var URLComponents: URL_COMPONENTS);
begin
  with URLComponents do
  begin
    lst1.Items.Add('Scheme: ' + lpszScheme);
    lst1.Items.Add('Host: ' + lpszHostName);
    lst1.Items.Add('User: ' + lpszUserName);
    lst1.Items.Add('Path: ' + lpszUrlPath);
    lst1.Items.Add('Extra: ' + lpszExtraInfo);
  end;
end;

end.
