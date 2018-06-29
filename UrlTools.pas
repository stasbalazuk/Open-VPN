unit UrlTools;

interface
uses sysutils,strutils;
function UrlAddSlash( URL : string ) : string;
PROCEDURE SplitURL(Const Path:String;Var http:Boolean;Var Dir,Name,Ext:String);
function SplitFullURL(Const Url:String;Var host,path,fname,fext:String):integer;

    function  ExtractPathURLToCompleteURL ( URL : string ) : string;
    function  Slach    ( chemin : string ) : string;
    function TakeBeforeFolder( PathURL : string ) : string;

implementation


function UrlAddSlash( URL : string ) : string;
begin
 if ( Copy( URL, length(URL), 1 ) <> '/')
  then Result := Trim(URL) + '/'
  else Result := Trim(URL);
end;

PROCEDURE SplitURL(Const Path:String;Var http:Boolean;Var Dir,Name,Ext:String);
 Var i          : Integer;
     DirEndPos  : Integer;
     PointPos   : Integer;
     LastPos    : Integer;
Begin
 LastPos:= Length(Path);
 DirEndPos:=0;
 PointPos:=0;
 http:=False;
 For i:=1 To Length(Path) Do
  Case Path[I] of
   '\','/':
      Begin
        DirEndPos:=i;
        PointPos:=0;
      End;
   '.':PointPos:=i;
   ':':http:=True;
   '#','?':
        begin
            LastPos:=i-1;
            break;
        end;
  end;

 if DirEndPos>1 Then Dir:=Copy(Path,1,DirEndPos) Else Dir:='';
 if PointPos>1 Then
   Begin
     Name:=Copy(Path, DirEndPos+1,PointPos-DirEndPos-1);
     Ext:=Copy(Path, PointPos,LastPos-PointPos+1);
   End
   Else Begin
     Name:=Copy(Path, DirEndPos+1,LastPos-DirEndPos);
     Ext:='';
   End;
End;


function SplitFullURL(Const Url:String;Var host,path,fname,fext:String):integer;
 Var i          : Integer;
     StartPos  : Integer;
     S          : String;
     Paths  : Array[0..100] of String;
     PathsCount:Integer;
Begin
 Result:=-1;
 // Check for http://
 S:=UpperCase(Copy(Url,1,7));
 if S<>'HTTP://' then Exit;
 S:=Copy(Url,8,Length(Url)-7);

 // Decouper le lien en repertoires
 StartPos:=1;
 PathsCount:=0;
 for i:=1 to Length(s) do
    if (S[I]='/') then begin
        if (i-StartPos=0) then begin
            StartPos:=i+1;
            Continue;
        end;
        Inc(PathsCount);
        Paths[PathsCount]:=Copy(S,StartPos,i-StartPos);
        if Paths[PathsCount]='.' then Dec(PathsCount)
        else if Paths[PathsCount]='..' then Dec(PathsCount,2);
        StartPos:=i+1;
    end else if (S[I]='?') then Break
    else if (S[I]='#') then break;

 if (StartPos<i) then begin
    Inc(PathsCount);
    Paths[PathsCount]:=Copy(S,StartPos,i-StartPos);
 end;
 //
 Path:='/';
 fname:='';
 fext:='';
 if PathsCount=0 then Exit;
 Host:=Paths[1];
 if (PathsCount>1) then begin
    if PathsCount>2 then
        For i:=2 to PathsCount-1 do Path:=Path+Paths[i]+'/';
    i:=Pos('.',Paths[PathsCount]);
    if (i=0) then Path:=Path+Paths[PathsCount]+'/'
    else begin
        fname:= Copy(Paths[PathsCount],1,i-1);
        fext:= Copy(Paths[PathsCount],i,Length(Paths[PathsCount])-i+1);
        Dec(PathsCount);
    end;
 end;
  //for i:=1 to PathsCount do Writeln('=',Paths[i]);
 Result:=PathsCount;
End;



function  ExtractPathURLToCompleteURL ( URL : string ) : string;
var
    Temp : string;
    Position : Integer;
begin

    if RightStr( Trim(URL) , 1) = '/' then
        Temp := URL
    else begin

        Position := Length( URL );

        if Pos( '/', URL ) <> 0 then
        begin
            while ( Copy( URL, Position, 1 ) <> '/' ) do dec( Position );
            Temp := LeftStr( URL, Position  )
        end else
            Temp := Trim( URL );
    end;

    Result := Trim(Temp);

end;


function TakeBeforeFolder( PathURL : string ) : string;
var
    temp : string;
    Position : integer;
begin

    if RightStr( Trim(PathURL) , 1) = '/' then
        Temp := Copy( PathURL, 1, Length(PathURL) - 1 );


        Position := Length( Temp );

        if Pos( '/', Temp ) <> 0 then
        begin
            while ( Copy( Temp, Position, 1 ) <> '/' ) do dec( Position );
            Temp := LeftStr( Temp, Position  )
        end else
            Temp := Trim( Temp );

    Result := Trim(Temp);

end;

{ Ajoute '\' en fin de chemin s'il n'y est pas }
function Slach( chemin : string ) : string;
begin
  if ( Copy( chemin, length(chemin), 1 ) <> '\')
    then Result := Trim(chemin) + '\'
    else Result := Trim(chemin);
end;



end.
