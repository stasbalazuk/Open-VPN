unit HtmlParser;

interface

uses Classes, SysUtils, StrUtils, FonctionsChaine, UrlTools, Unit1;

TYPE
  tHtmlParser = Class(TMemoryStream)
    function BMSearchStr(const StrToFind: string; StartOfs:Integer): longint;
    procedure ParseHtml(UrlSite:String; Var Liens:TStringList);
  end;

implementation

function tHtmlParser.BMSearchStr(const StrToFind: string; StartOfs:Integer): longint;

 Var    BMHTable: array[0..255] of Byte;

procedure MakeBMHTable;
 Var    K   :Integer;
begin
 fillchar(BMHTable,Sizeof(BMHTable),Length(StrToFind));
 for K := 1 to Length(StrToFind)-1 do
    BMHTable[ord(StrToFind[K])] := length(StrToFind)-K;
end;

{
 Performs the Boyer-Moore-Horspool string searching algorithm, returning
  the offset in file where the string was found.  If not found, then
  -1 is returned.
}
Var StartPos, NewStartPos,
    BufPos, StrPos   :Integer;
    fMem    : Array of Char;
begin
  Result := -1;
  fMem:=Memory;
  MakeBMHTable;
  StartPos := StartOfs+Length(StrToFind);
  While (StartPos <= Size) do begin
    BufPos := StartPos;
    StrPos := length(StrToFind);
    while (StrPos >= 1) do begin
        NewStartPos:= BufPos + BMHTable[ ord(fMem[BufPos]) ];
        if (StartPos<NewStartPos) then StartPos:=NewStartPos;
        if fMem[BufPos] <> StrToFind[StrPos]
         then StrPos := -1
         else begin
            dec (StrPos);
            dec (BufPos);
         end;
    end;
    if (StrPos = 0) then begin
        Result := BufPos+1;
        exit
    end;
  end;
end;


procedure tHtmlParser.ParseHtml;
var
    i,j       : integer;
    host,path,nam,ext:String;

    Lien        : String;
    Guillemet   : Integer;
    StartOfs    : Integer;
    fMem        : Array of Char;

const
    BALISES : Array[0..3] of String = ( 'src="', 'href="', 'SRC="', 'HREF="' );

begin
  fMem:=Memory;
  for i:=0 to 3 do begin
    StartOfs:=BMSearchStr( BALISES[i], 0);
    while StartOfs<>-1 do begin
        Guillemet:=BMSearchStr( '"', StartOfs+Length(BALISES[i]) );
        if (Guillemet<>-1) and (Guillemet-Startofs<300) then begin
            SetLength(Lien,Guillemet-Startofs-Length(BALISES[i]) );
            Move(fMem[Startofs+Length(BALISES[i])], Lien[1],Length(Lien) );
            //
            if Trim(LeftStr( Lien, 4 ) ) <> 'http' then Lien := Trim( UrlAddSlash(UrlSite) + Lien );
            SplitFullURL(Lien, host,path,nam,ext);
            Lien:='http://'+host+path+nam+ext;
            if not Liens.Find(Lien,j) then Liens.Add( Lien );
            form1.lst1.Items.Add(Lien);
        end;
        StartOfs:=BMSearchStr( BALISES[i], StartOfs+Length(BALISES[i]) );
    end;
  end;
end;

end.

