unit sc1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics,
  Controls, Forms, Dialogs, AMixer, MMSystem,StdCtrls, ExtCtrls, ComCtrls;

type
  TForm1 = class(TForm)
    ScrollBox1: TScrollBox;
    Image2: TImage;
    StaticText1: TStaticText;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure TrackBar1Change(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
Form1: TForm1;
Mixer: TAudioMixer;
wR:boolean=false;//выполняется регулировка программой
y:  integer;     //высота списка

mt: array of record
  t:       tTrackBar;
  cb:      tCheckBox;
  ts,cs:   boolean;  //tTrackBar, CheckBox созданы
  Ar,Br,Cr:integer;
end;

q:     integer=0; //число trackBar;
add:   boolean;   //было добавление регулятора
s,name,cName: string;
A,B,C,rrr: integer;
maxR:  integer;//число выключателей Record;

implementation

{$R *.DFM}
{$R WindowsXP.res}

FUNCTION getR(nr:byte):integer;
var
MCD:TMixerControlDetails;
Cntrl:PMixerControl;
z:integer;
begin
//Получение значения регулятора
with mt[nr] do begin

  if Cr=-1 then Cntrl:=Mixer.Destinations[Br].Controls[Ar]
           else Cntrl:=Mixer.Destinations[Br].Connections[Cr].Controls[Ar];

  MCD.cbStruct:=SizeOf(TMixerControlDetails);
  MCD.dwControlID:=Cntrl.dwControlID;
  MCD.cChannels:=1;
  MCD.cMultipleItems:=0;
  MCD.cbDetails:=SizeOf(Integer);
  MCD.paDetails:=@z;
  mixerGetControlDetails (Mixer.MixerHandle,@MCD,MIXER_GETCONTROLDETAILSF_VALUE);
  result:=z;
end;
end;

PROCEDURE uq;
begin
inc(q);
if q>=length(mt) then setLength(mt,q+10);
with mt[q] do begin ts:=false; cs:=false end;
add:=true;
end;

PROCEDURE createTB(A,B,C:integer);
begin
uq;
mt[q].t:=tTrackBar.create(form1);
with form1,mt[q],mt[q].t do begin
  parent:=scrollBox1;
  width:=104;
  left:=0;
  height:=20;
  ThumbLength:=18;
  tickStyle:=tsNone;
  max:=65535;
  ts:=true;
  tag:=q;
  top:=y;
  Ar:=A; Br:=B; Cr:=C;
  onChange:=Form1.TrackBar1Change;
end
end;

PROCEDURE createCB(A,B,C:integer);
begin
mt[q].cb:=tCheckBox.create(form1);
with form1,mt[q],mt[q].cb do begin
  parent:=scrollBox1;
  width:=20;
  height:=20;
  left:=103;
  cs:=true;
  tag:=q;
  top:=y;
  Ar:=A; Br:=B; Cr:=C;
  onClick:=Form1.CheckBox1Click;
end;
end;

PROCEDURE getW;
var i,C:integer; ck:boolean;
begin
//получение выключателей
maxR:=0;
for i:=1 to q do with mt[i] do if Br=1 then if Cr>maxR then maxR:=Cr;
for i:=1 to q do with mt[i] do if cs then begin
  if Br=1 then c:=maxR-Cr else c:=Cr;
  if ts then mixer.GetMute(Br, c, ck,MIXERCONTROL_CONTROLTYPE_MUTE)
        else mixer.GetMute(Br, Cr, ck,MIXERCONTROL_CONTROLTYPE_ONOFF);
  cb.checked:=ck;
end;
end;

PROCEDURE getV;
var
i:integer;
begin
for i:=1 to q do with mt[i] do
  if ts then t.position:=getR(i);
end;

procedure showAll;
var
AM:TAudioMixer;

Procedure show(s:string);
begin
with form1.Image2.picture.bitmap.Canvas do begin
  textOut(119,y+4,s);
  inc(y,20);
end;
end;

procedure ProcessControls (B, C:Integer);
var
Cntrls:TMixerControls;
A:Integer;
nl:string;
begin
if C=-1 then Cntrls := AM.Destinations[B].Controls
        else Cntrls := AM.Destinations[B].Connections[C].Controls;
name:='';
For A:=0 to Cntrls.Count - 1 do begin
//создание регулятора
  s:=IntToHex (Cntrls[A].dwControlType, 1);
  name:=lowerCase(Cntrls[A].szName);
  add:=false;
  nl:=ansiLowerCase(name);
  if (copy(s,1,4)='5003') then begin
    createTB(A,B,C);
    createCB(A,B,C);
  end
  else
{ if copy(s,1,3)='500' then begin
    createTB(A,B,C);
  end
  else }
  if (copy(s,1,3)='200')and
     (pos('mute',nl)=0) and (pos('выкл',nl)=0) then begin
    uq;
    mt[q].cb:=tCheckBox.create(form1);
    createCB(A,B,C);
  end;

  if add then show(' '+cName+' '+name);
end;
end;


begin
y:=22;
AM := TAudioMixer.Create (form1);
A := 0;
cName:='';

while (A < AM.MixerCount) do begin
  form1.staticText1.caption:='  Mixer Id : '+IntToStr (AM.MixerId)+
       '  Product name : '+AM.ProductName+
       '  Number of lines : ' + IntToStr (AM.NumberOfLine);

  B:=0;
  while B<AM.Destinations.Count do begin

    form1.Image2.picture.bitmap.Canvas.Font.style:=[fsBold];
    show (IntToStr(B)+'.'+AM.Destinations[B].Data.szName);
    form1.Image2.picture.bitmap.Canvas.Font.style:=[];
    ProcessControls (B, -1);

    C:=0;
    while C<AM.Destinations[B].Connections.Count do begin
      cName:=IntToStr(C)+'. '+AM.Destinations[B].Connections[C].Data.szName;
      ProcessControls (B, C);
      inc(C);
    end;

    inc(B);
  end;

  inc (A);
  If (A < AM.MixerCount) then AM.MixerId := A;
end;
AM.Free;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
Mixer:=TAudioMixer.Create (Self);

if Mixer.MixerCount=0 then begin
  MessageDlg ('Не нашла тут звук!',mtError,[mbOK],0);
  halt;
end;

image2.width:=scrollBox1.width-130+118;
image2.left:=0;
image2.height:=2000;
image2.Picture.bitmap.canvas.brush.color:=clBtnFace;
image2.Picture.bitmap.height:=image2.height;
image2.Picture.bitmap.width:=image2.width;
showAll;
height:=y+50;
top :=(screen.height-height) div 2;
left:=(screen.width-width)   div 2;
scrollBox1.height:=clientHeight-4;

image2.height:=y+4;

//Установка регуляторов в текущее положение
wr:=true;
getW;
getV;
wr:=false;
end;

PROCEDURE setReg(nr:byte; z:integer);
var
MCD:TMixerControlDetails;
Cntrl:PMixerControl;
begin
//Установка звука по trackBarу
with mt[nr] do begin
  if Cr=-1 then Cntrl:=Mixer.Destinations[Br].Controls[Ar]
           else Cntrl:=Mixer.Destinations[Br].Connections[Cr].Controls[Ar];
  MCD.cbStruct:=SizeOf(TMixerControlDetails);
  MCD.dwControlID:=Cntrl.dwControlID;
  MCD.cChannels:=1;
  MCD.cMultipleItems:=0;
  MCD.cbDetails:=SizeOf(Integer);
  MCD.paDetails:=@z;
  mixerSetControlDetails (Mixer.MixerHandle,@MCD,MIXER_GETCONTROLDETAILSF_VALUE);
end;
end;

procedure TForm1.TrackBar1Change(Sender: TObject);
begin
if wR then exit;
wR:=true;
with sender as tTrackBar do
with mt[tag] do setReg(tag,t.Position);
wR:=false;
end;

procedure TForm1.CheckBox1Click(Sender: TObject);
var
c:integer;
begin
if wR then exit;
wR:=true;
with sender as tCheckBox do
with mt[tag] do begin
  if Br=1 then c:=maxR-Cr else c:=Cr;

  if ts then
    mixer.SetMute(Br, c, cb.checked,MIXERCONTROL_CONTROLTYPE_MUTE)
    else mixer.SetMute(Br, Cr, cb.checked,MIXERCONTROL_CONTROLTYPE_ONOFF);

  getW;
end;
wR:=false;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
mixer.free;
mixer:=nil;
end;

end.

