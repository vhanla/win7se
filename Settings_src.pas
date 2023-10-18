unit Settings_src;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, jpeg, StdCtrls, XPMan;

type
  TForm2 = class(TForm)
    Image1: TImage;
    Image2: TImage;
    Shape1: TShape;
    Shape2: TShape;
    Label1: TLabel;
    ComboBox1: TComboBox;
    ComboBox2: TComboBox;
    ComboBox3: TComboBox;
    ComboBox4: TComboBox;
    XPManifest1: TXPManifest;
    chkSmartSwitch: TCheckBox;
    chkBackground: TCheckBox;
    chkAeroPeek: TCheckBox;
    CheckBox1: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure chkAeroPeekMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    { Private declarations }
    procedure WMNCHitTest(var Message: TWMNCHitTest); message WM_NCHITTEST;
    procedure CreateParams(var Params: TCreateParams);override;
    procedure CloseApp(Sender: TObject);
    procedure UpdatePosition;
  public
    { Public declarations }
  end;

var
  Form2: TForm2;


    procedure SwitchToThisWindow(h1: hWnd; x: bool); stdcall;
  external user32 Name 'SwitchToThisWindow';
implementation
uses Win7se_src, CommCtrl, Registry;
{$R *.dfm}
procedure tForm2.UpdatePosition;
var
  Shell_TrayWnd: HWND; // la barra completa
//  TrayNotifyWnd: HWND; // la bandeja de sistema
  Shell_TrayWndRect: TRect;
  //TrayNotifyWndRect: TRect;
  // let's locate the taskbar position and according to that repos this form

begin
 Shell_TrayWnd:=FindWindow('Shell_TrayWnd',nil);
 if Shell_TrayWnd>0 then
 begin
//   TrayNotifyWnd:=FindWindowEx(Shell_TrayWnd,HWND(0),'TrayNotifyWnd',nil);
//   if TrayNotifyWnd>0 then
   begin
   GetWindowRect(Shell_TrayWnd,Shell_TrayWndRect);
//   GetWindowRect(TrayNotifyWnd,TrayNotifyWndRect);

//   ShowMessage('Left: '+inttostr(Shell_TrayWndRect.Left)+   ' Top: '+inttostr(Shell_TrayWndRect.Top)+   ' Right: '+inttostr(Shell_TrayWndRect.Right)+   ' Bottom: '+inttostr(Shell_TrayWndRect.Bottom)   +#13+'Screen.Width: '+inttostr(Screen.Width)+' Screen.Height: '+inttostr(Screen.Height));
      //bottom
      if (Shell_TrayWndRect.Left=0)
      and(Shell_TrayWndRect.Right=Screen.Width)
      and(Shell_TrayWndRect.Top>0)
      then
      begin
      //ShowMessage('está abajo')
      //posicionamos a la derecha en el systray
      Left:=Screen.Width-Width-10;
      if Left<1 then Left:=10;
      Top:=Screen.Height-Height-Shell_TrayWndRect.Bottom+Shell_TrayWndRect.Top-10;
      if Top<1 then Top:=10;
      end
      //arriba
      else if (Shell_TrayWndRect.Left=0)
      and(Shell_TrayWndRect.Right=Screen.Width)
      and(Shell_TrayWndRect.Top<1)
      then
      begin
      //ShowMessage('Está arriba');
      Left:=Screen.Width-Width-10;
      if Left<1 then Left:=10;
      Top:=Shell_TrayWndRect.Bottom+10;
      if Top<1 then Top:=10;
      end
      //izquierda
      else if (Shell_TrayWndRect.Left<1)
      and (Shell_TrayWndRect.Top=0)
      and(Shell_TrayWndRect.Bottom=Screen.Height)
      then
      begin
      //ShowMessage('Está a la izquierda')
      Left:=Shell_TrayWndRect.Right+10;
      if Left<1 then Left:=10;
      Top:=Screen.Height-Height-10;
      if Top<1 then Top:=10;
      end
      //derecha
      else if (Shell_TrayWndRect.Left>0)
      and(Shell_TrayWndRect.Top=0)
      and(Shell_TrayWndRect.Bottom=Screen.Height)
      then
      begin
      //ShowMessage('Está a la derecha');
      Left:=Shell_TrayWndRect.Left-Width-10;
      if Left<1 then Left:=10;
      Top:=Screen.Height-Height-10;
      if Top<1 then Top:=10;
      end;

 end;
end;
end;

procedure tform2.CloseApp(Sender: TObject);
begin
  close;
end;

function AeroPeekState:Boolean;
var
  reg: TRegistry;
begin
  Result:=False; //default disabled
  reg:=TRegistry.Create;
  try
    reg.RootKey:=HKEY_CURRENT_USER;
    if reg.OpenKeyReadOnly('SOFTWARE\Microsoft\Windows\DWM') then
    begin
      if reg.ReadInteger('EnableAeroPeek') = 1 then Result := True
      else Result:=false;
      reg.CloseKey;
    end;
  finally
    reg.free;
  end;
end;

procedure EnableAeroPeek;
var
  reg: TRegistry;
begin
  reg:=TRegistry.Create;
  try
    reg.RootKey:=HKEY_CURRENT_USER;
    if reg.OpenKey('SOFTWARE\Microsoft\Windows\DWM',True) then
    begin
      reg.WriteInteger('EnableAeroPeek',1);
      reg.CloseKey;
    end;
  finally
    reg.Free;
  end;
end;

procedure DisableAeroPeek;
var
  reg: TRegistry;
begin
  reg:=TRegistry.Create;
  try
    reg.RootKey:=HKEY_CURRENT_USER;
    if reg.OpenKey('SOFTWARE\Microsoft\Windows\DWM',True) then
    begin
      reg.WriteInteger('EnableAeroPeek',0);
      reg.CloseKey;
    end;
  finally
    reg.Free;
  end;
end;
procedure ShowBallonTip(Control: TWinControl; Icon: integer; Title: Pchar; text:pwidechar;
backcl, textcl: tcolor);
const
  TOOLTIPS_CLASS = 'tooltips_class32';
  TTS_ALWAYSTIP = $01;
  TTS_NOPREFIX = $02;
  TTS_BALLOON = $40;
  TTF_SUBCLASS = $0010;
  TTF_TRANSPARENT = $0100;
  TTF_CENTERTIP = $0002;
  TTM_ADDTOOL = $0400 + 50;
  TTM_SETTITLE = (WM_USER + 32);
  ICC_WIN95_CLASSES = $000000FF;
type
  TOOLINFO = packed record
    cbSize: Integer;
    uFlags: Integer;
    hwnd: THandle;
    uId: Integer;
    rect: TRect;
    hinst: THandle;
    lpszText: PWideChar;
    lParam: Integer;
    end;
var
  hWndTip: THandle;
  ti: TOOLINFO;
  hWnd: THandle;
begin
  hWnd:=Control.Handle;
  hWndTip:=CreateWindow(TOOLTIPS_CLASS,nil,
  WS_POPUP or TTS_NOPREFIX or TTS_BALLOON or TTS_ALWAYSTIP,
  0,0,0,0, hWnd,0,HInstance,nil);
  if hWndTip <> 0 then
  begin
    SetWindowPos(hWndTip,HWND_TOPMOST,0,0,0,0,
    SWP_NOACTIVATE or SWP_NOMOVE or SWP_NOSIZE);
    ti.cbSize:=SizeOf(ti);
    ti.uFlags:=TTF_CENTERTIP or TTF_TRANSPARENT or TTF_SUBCLASS;
    ti.hwnd:=hWnd;
    ti.lpszText:=Text;
    Windows.GetClientRect(hwnd,ti.rect);
    SendMessage(hWndTip, TTM_SETTIPBKCOLOR, backcl,0);
    SendMessage(hWndTip, TTM_SETTIPTEXTCOLOR, textcl,0);
    SendMessage(hWndTip,TTM_ADDTOOL, 1, Integer(@ti));
    SendMessage(hWndTip,TTM_SETTITLE,Icon mod 4, Integer(Title));
  end;
end;


procedure TForm2.WMNCHitTest(var Message: TWMNCHitTest);
begin
  inherited;
 if (message.Result = htbottom)
 or (message.Result = htbottomleft)
 or (message.Result = htbottomright)
 or (message.Result = htleft)
 or (message.Result = htright)
 or (message.Result = httop)
 or (message.Result = httopleft)
 or (message.Result = httopright)
 then message.Result := HTBORDER;

// if Message.Result = htclient then Message.Result:=HTCAPTION;
end;

procedure TForm2.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.Style:=Params.Style or WS_THICKFRAME;
end;
procedure TForm2.FormCreate(Sender: TObject);
var
  cursorpos: TPoint;
  i: integer;
begin
  Application.OnDeactivate:=CloseApp;
  try
    cursorpos:= mouse.CursorPos;
  except
  end;
        Form2.Left:=cursorpos.X;
        Form2.Top:=cursorpos.Y;
        if form2.Top + form2.Height > Screen.Height then
        Form2.Top:=Screen.Height-form2.Height-20;
        if Form2.Left + form2.Width > Screen.Width then
        Form2.Left:=Screen.Width-form2.Width-20;

//Embellecemos la ventana Win7 like

  BorderStyle:=bsNone;
Color:=clWhite;

// La forma de abajo celeste o parecido
Shape1.Brush.Color:=$FbF5F1;
Shape1.Pen.Color:=$FbF5F1;
Shape1.Height:=41;
Shape1.Align:=alBottom;

Shape2.Pen.Color:=$eaD9cc;
Shape2.Height:=1;
Shape2.Align:=alBottom;
//color chéver para el enlace about
  with Label1 do begin
    Font.Style:=[fsBold];
    Caption:='About Win7sé';
    AutoSize:=False;
    Width:=Form2.Width;
    Left:=0;
    Alignment:=taCenter;
    Cursor:=crHandPoint;
    font.Color:=$FF901E;
  end;
Image1.Top:=16;
Image1.Left:=Image2.Left;
Image2.Top:=16;
Image2.Visible:=False;

//opciones del combo box
ComboBox1.Items.Clear;ComboBox1.Text:='';ComboBox1.Style:=csDropDownList;
ComboBox2.Items.Clear;ComboBox2.Text:='';ComboBox2.Style:=csDropDownList;
ComboBox3.Items.Clear;ComboBox3.Text:='';ComboBox3.Style:=csDropDownList;
ComboBox4.Items.Clear;ComboBox4.Text:='';ComboBox4.Style:=csDropDownList;
for i:=0 to Length(Win7se_src.Actions)-1 do
begin
  ComboBox1.Items.Add(Win7se_src.Actions[i]);
  ComboBox2.Items.Add(Win7se_src.Actions[i]);
  ComboBox3.Items.Add(Win7se_src.Actions[i]);
  ComboBox4.Items.Add(Win7se_src.Actions[i]);
end;

  //hiding from taskbar
  ShowWindow(Application.Handle, SW_HIDE) ;
  SetWindowLong(Application.Handle, GWL_EXSTYLE, getWindowLong(Application.Handle, GWL_EXSTYLE) or WS_EX_TOOLWINDOW) ;
  ShowWindow(Application.Handle, SW_SHOW) ;
  FormStyle:=fsStayOnTop;
//it hides the app from alt tab
  SetWindowLong(Handle, GWL_EXSTYLE, GetWindowLong(Handle, GWL_EXSTYLE)  or WS_EX_TOOLWINDOW);

chkAeroPeek.Checked:=AeroPeekState;
//va después de la modificacion de estilo de ventana sino no funciona
ShowBallonTip(chkSmartSwitch,1,'Smart switch','Cycle to desired app with mousewheel and return to corner to switch, no click required!',clBlue,clRed);

end;

procedure TForm2.FormShow(Sender: TObject);
begin
SwitchToThisWindow(Form2.Handle,True);
Win7se_src.ToggleForm2:=true;
UpdatePosition;
end;

procedure TForm2.FormClose(Sender: TObject; var Action: TCloseAction);
begin
Win7se_src.ToggleForm2:=false;
end;

procedure TForm2.chkAeroPeekMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
if chkAeroPeek.Checked then EnableAeroPeek
    else DisableAeroPeek
end;

end.
