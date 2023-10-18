unit Win7se_src;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Menus, ShellAPI, Registry, ComObj;

type
  TForm1 = class(TForm)
    Timer1: TTimer;
    PopupMenu1: TPopupMenu;
    StartwithWindows1: TMenuItem;
    N1: TMenuItem;
    About1: TMenuItem;
    N2: TMenuItem;
    Exit1: TMenuItem;
    Settings1: TMenuItem;
    Disable1: TMenuItem;
    procedure Timer1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Exit1Click(Sender: TObject);
    procedure About1Click(Sender: TObject);
    procedure StartwithWindows1Click(Sender: TObject);
    procedure Settings1Click(Sender: TObject);
  private
    { Private declarations }
    IconData: TNotifyIconData;
    procedure Iconito(var Msg: TMessage);message WM_USER+1;
    //para evitar minimizar
    procedure WMShowWindow(var msg: TWMShowWindow);
  public
    { Public declarations }
     procedure CreateParams(var params: TCreateParams); override;
  end;

var
  Form1: TForm1;
  ToggleForm2: Boolean; //to control showing and hiding this form with clicking on systray's icon

  toggleBG: Boolean;
  toggleGadget: Boolean;

  originalAeroPeekState: DWORD; //from registry HKCU\Software\Microsoft\Windows\DWM\EnableAeroPeek 0=disabled, 1=enabled - funciona en tiempo real el cambio


  currentWND: HWND;
  taskswnd: THandle;
  task3dwnd: THandle;

  AltTabItems: Integer;
  // options available
  Actions: array[0..9] of string;

function GetWindowLongPtr(hWnd: HWND; nIndex: Integer): longint; stdcall;
    procedure SwitchToThisWindow(h1: hWnd; x: bool); stdcall;
  external user32 Name 'SwitchToThisWindow';


implementation


uses Settings_src, DashBoardBG_src;
{$R *.dfm}

function GetWindowLongPtr; external user32 name 'GetWindowLongA';
function ShellWindow: HWND;
type
  TGetShellWindow = function(): HWND; stdcall;
var
  hUser32: THandle;
  GetShellWindow: TGetShellWindow;
begin
  Result := 0;
  hUser32 := GetModuleHandle('user32.dll');
  if (hUser32 > 0) then
  begin
    @GetShellWindow := GetProcAddress(hUser32, 'GetShellWindow');
    if Assigned(GetShellWindow) then
    begin
      Result := GetShellWindow;
    end;
  end;
end;

{procedure PerformCtrlAltTab;
var
  shelll: OleVariant;
begin
  shelll:=CreateOleObject('WScript.Shell');}
 // shelll.SendKeys('^(%{TAB})');
{end;

procedure PerformAltTab;
var
  shelll: OleVariant;
begin
  shelll:=CreateOleObject('WScript.Shell');   }
//  shelll.SendKeys('%{TAB}');
{end;

procedure PerformShiftTab;
var
  shelll: OleVariant;
begin
  shelll:=CreateOleObject('WScript.Shell');    }
//  shelll.SendKeys('+{TAB}');
///end;

function AltTabCount(gHandle: HWND; lowparam: pointer):Boolean stdcall;
var
  caption: array[0..256]of char;
  dwStyle,dwexStyle: longint;
begin
   dwStyle:=GetWindowLongPtr(gHandle,GWL_STYLE);
   dwexStyle:=GetWindowLongPtr(gHandle,GWL_EXSTYLE);
   if (dwStyle and WS_VISIBLE = WS_VISIBLE)
   and (GetWindowText(gHandle,caption,sizeof(caption)-1)<>0)
   and (GetParent(gHandle)=0)
   and (ghandle<>application.Handle){exclude me}
   then
   begin
    if ((dwexStyle and WS_EX_APPWINDOW=WS_EX_APPWINDOW)
    and (GetWindow(gHandle,GW_OWNER)=ghandle))
    or
    ( (dwexStyle and WS_EX_TOOLWINDOW =0 )
    and (GetWindow(gHandle,GW_OWNER)=0)) //* Escondido cuando se quiere mostrar todos las ventanas
       then Inc(alttabitems);
    end;
  result:=True;
end;

procedure AutoStartState;
var key: string;
     Reg: TRegIniFile;
begin
  key := '\Software\Microsoft\Windows\CurrentVersion\Run';
  Reg:=TRegIniFile.Create;
try
  Reg.RootKey:=HKEY_CURRENT_USER;
  if reg.ReadString(key,'Win7se','')<>'' then
  form1.StartwithWindows1.Checked:=true;
  finally
  Reg.Free;
  end;
end;

procedure RegAutoStart;
var
key: string;
reg: TRegIniFile;
begin
key:='\Software\Microsoft\Windows\CurrentVersion\Run';
reg:=TRegIniFile.Create;
try
  reg.RootKey:=HKEY_CURRENT_USER;
  reg.CreateKey(key);
  if reg.OpenKey(Key,False) then reg.WriteString(key,'Win7se',pchar(Application.exename));
finally
  reg.Free;
end;
end;

procedure UnRegAutoStart;
var key: string;
     Reg: TRegIniFile;
begin
  key := '\Software\Microsoft\Windows\CurrentVersion\Run';
  Reg:=TRegIniFile.Create;
try
  Reg.RootKey:=HKEY_CURRENT_USER;
  if Reg.OpenKey(Key,False) then Reg.DeleteValue('Win7se');
  finally
  Reg.Free;
  end;
end;

{procedure PostKeyEx32(key: Word; const shift: TShiftState; specialkey: Boolean);
//************************************************************
//* Procedure PostKeyEx32
//*
//* Parameters:
//*  key    : virtual keycode of the key to send. For printable
//*           keys this is simply the ANSI code (Ord(character)).
//*  shift  : state of the modifier keys. This is a set, so you
//*           can set several of these keys (shift, control, alt,
//*           mouse buttons) in tandem. The TShiftState type is
//*           declared in the Classes Unit.
//*  specialkey: normally this should be False. Set it to True to
//*           specify a key on the numeric keypad, for example.
//* Description:
//*  Uses keybd_event to manufacture a series of key events matching
//*  the passed parameters. The events go to the control with focus.
//*  Note that for characters key is always the upper-case version of
//*  the character. Sending without any modifier keys will result in
//*  a lower-case character, sending it with [ssShift] will result
//*  in an upper-case character!
//************************************************************
type
  TShiftKeyInfo = record
    shift: Byte;
    vkey: Byte;
  end;
  byteset = set of 0..7;
const
  shiftkeys: array [1..3] of TShiftKeyInfo =
    ((shift: Ord(ssCtrl); vkey: VK_CONTROL),
    (shift: Ord(ssShift); vkey: VK_SHIFT),
    (shift: Ord(ssAlt); vkey: VK_MENU));
var
  flag: DWORD;
  bShift: ByteSet absolute shift;
  i: Integer;
begin
  for i := 1 to 3 do
  begin
    if shiftkeys[i].shift in bShift then
      keybd_event(shiftkeys[i].vkey, MapVirtualKey(shiftkeys[i].vkey, 0), 0, 0);
  end; // For
  if specialkey then
    flag := KEYEVENTF_EXTENDEDKEY
  else
    flag := 0;
  keybd_event(key, MapvirtualKey(key, 0), flag, 0);
  flag := flag or KEYEVENTF_KEYUP;
  keybd_event(key, MapvirtualKey(key, 0), flag, 0);
  for i := 3 downto 1 do
  begin
    if shiftkeys[i].shift in bShift then
      keybd_event(shiftkeys[i].vkey, MapVirtualKey(shiftkeys[i].vkey, 0),
        KEYEVENTF_KEYUP, 0);
  end; // For
end; //PostKeyEx32 }
function GetAKey(KeyPressed: byte): boolean;
begin
  GetAKey := GetAsyncKeyState(KeyPressed) <> 0;
end;

procedure TaskBarSwitcher;
begin
    keybd_event(VK_CONTROL,MapVirtualKey(VK_CONTROL,0),0,0);
    Sleep(10);
    keybd_event(VK_MENU,MapVirtualKey(VK_MENU,0),0,0);
    Sleep(10);
    keybd_event(VK_TAB,MapVirtualKey(VK_TAB,0),0,0);
    Sleep(10);
    keybd_event(VK_TAB,MapVirtualKey(VK_TAB,0),KEYEVENTF_KEYUP,0);
    Sleep(100);
    keybd_event(VK_MENU,MapVirtualKey(VK_MENU,0),KEYEVENTF_KEYUP,0);
    Sleep(100);
    keybd_event(VK_CONTROL,MapVirtualKey(VK_CONTROL,0),KEYEVENTF_KEYUP,0);
//    PerformCtrlAltTab;
    Sleep(100);
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

//** Set the Alt Tab Switcher Thumbnail Size **//
procedure AutomaticSize;
var
  reg: TRegistry;
begin
  reg:=TRegistry.Create;
  try
    reg.RootKey:=HKEY_CURRENT_USER;
    reg.CreateKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AltTab');
    if reg.OpenKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AltTab',True) then
    begin
      AltTabItems:=0;
      EnumWindows(@AltTabCount,0);
//      Screen.Width div AltTabItems - 24
      if AltTabItems > 6 then AltTabItems := 6;

      reg.WriteInteger('MinThumbSizePcent',100);
      reg.WriteInteger('MaxThumbSizePx',Screen.Width div (AltTabItems+1) - 24);
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

procedure Flip3DSwitcher;
begin
    keybd_event(VK_CONTROL,MapVirtualKey(VK_CONTROL,0),0,0);
    Sleep(10);          //usar 10 para presionar
    keybd_event(VK_LWIN,MapVirtualKey(VK_LWIN,0),0,0);
    Sleep(10);
    keybd_event(VK_TAB,MapVirtualKey(VK_TAB,0),0,0);
    Sleep(10);
    keybd_event(VK_TAB,MapVirtualKey(VK_TAB,0),KEYEVENTF_KEYUP,0);
    Sleep(100);         //usar 100 para soltar
    keybd_event(VK_LWIN,MapVirtualKey(VK_LWIN,0),KEYEVENTF_KEYUP,0);
    Sleep(100);
    keybd_event(VK_CONTROL,MapVirtualKey(VK_CONTROL,0),KEYEVENTF_KEYUP,0);
    Sleep(100);
end;

procedure AltTab;
begin
    keybd_event(VK_MENU,MapVirtualKey(VK_MENU,0),0,0);
    Sleep(10);
    keybd_event(VK_TAB,MapVirtualKey(VK_TAB,0),0,0);
    Sleep(10);
    keybd_event(VK_TAB,MapVirtualKey(VK_TAB,0),KEYEVENTF_KEYUP,0);
    Sleep(100);
    keybd_event(VK_MENU,MapVirtualKey(VK_MENU,0),KEYEVENTF_KEYUP,0);
    Sleep(100);    
end;

procedure TaskBarSwitcherStatic;
begin
  //PerformCtrlAltTab; <~this is buggy
    keybd_event(VK_CONTROL,MapVirtualKey(VK_CONTROL,0),0,0);
//    Sleep(10);
    keybd_event(VK_MENU,MapVirtualKey(VK_MENU,0),0,0);
//    Sleep(10);
    keybd_event(VK_TAB,MapVirtualKey(VK_TAB,0),0,0);
    Sleep(10);
    keybd_event(VK_TAB,MapVirtualKey(VK_TAB,0),KEYEVENTF_KEYUP,0);
//    Sleep(100);
    keybd_event(VK_MENU,MapVirtualKey(VK_MENU,0),KEYEVENTF_KEYUP,0);
//    Sleep(100);
    keybd_event(VK_CONTROL,MapVirtualKey(VK_CONTROL,0),KEYEVENTF_KEYUP,0);
    Sleep(10);
    //let's see if were on TaskSwitch
    if FindWindow('TaskSwitcherWnd',nil)<>GetForegroundWindow then
     SwitchToThisWindow(form1.handle,true);
// back
    keybd_event(VK_SHIFT,MapVirtualKey(VK_SHIFT,0),0,0);
//    Sleep(10);
    keybd_event(VK_TAB,MapVirtualKey(VK_TAB,0),0,0);
    Sleep(5);
    keybd_event(VK_TAB,MapVirtualKey(VK_TAB,0),KEYEVENTF_KEYUP,0);
//    Sleep(100);
    keybd_event(VK_SHIFT,MapVirtualKey(VK_SHIFT,0),KEYEVENTF_KEYUP,0);
//    PerformShiftTab;
    Sleep(100);
end;
function EnumWindowsFunc(gHandle: HWND; lowparam: pointer ):boolean stdcall;
var
  buf: array[0..1024] of char;

caption: array[0..256]of char;

begin
   if (GetWindowText(gHandle,caption,sizeof(caption)-1)<>0)
   and (GetParent(gHandle)=0)
   and (ghandle<>application.Handle){exclude me}
   then
   begin
{    if ((dwexStyle and WS_EX_APPWINDOW=WS_EX_APPWINDOW)
    and (GetWindow(gHandle,GW_OWNER)=ghandle))
    or
    ( (dwexStyle and WS_EX_TOOLWINDOW =0 )
    and (GetWindow(gHandle,GW_OWNER)=0)) //* Escondido cuando se quiere mostrar todos las ventanas
       then}
       begin
        GetClassName(gHandle,@buf,sizeof(buf));
        if (StrPas(buf)='BasicWindow')and(caption<>'SidebarBroadcastWatcher') then
        begin
{         if toggleGadget then //escondemos
         begin
          ShowWindow(gHandle,SW_HIDE)
         end
         else}
         begin
           ShowWindow(gHandle,SW_SHOWNA);
         SwitchToThisWindow(gHandle,True);
         end;

        end;
      end;
  end;

  result:=true;
end;
procedure TForm1.Iconito(var Msg: TMessage);
var
p:TPoint;
begin
  if Msg.LParam = WM_RBUTTONDOWN then begin
    GetCursorPos(p);
    PopupMenu1.Popup(p.X,p.Y);
    PostMessage(handle,WM_NULL,0,0);
  end
  else if Msg.LParam = WM_LBUTTONDOWN then
  begin
{  if not form1.Visible then
  begin
    Form1.Show;
  end
  else begin
    Form1.Hide;
  end;}
  //if click on icon let's show the taskbar exposed
    if not ToggleForm2 then
       Form2.Show;
  Exit;
  if not IsWindowVisible(FindWindow('TaskSwitcherWnd',nil)) then
  begin
      show;
      toggleBG:=False;
      //PostKeyEx32(VK_TAB,[ssCtrl, ssAlt],false);
      TaskBarSwitcher;
  end;
  end;
end;

procedure TForm1.CreateParams(var params: TCreateParams);
begin
  inherited CreateParams(params);
  params.WinClassName:='Win7se';
end;

procedure TForm1.WMShowWindow(var Msg: TWMShowWindow);
begin
  if not msg.Show then
  msg.Result:=0
  else  inherited
end;


procedure ActionSwitch;
begin
  if not IsWindowVisible(taskswnd) then
  begin
      if originalAeroPeekState = 1 then
      DisableAeroPeek; //si aero peek está habilitado entonces lo deshabilitamos por un momento
      if Form2.chkBackground.Checked then
      Form1.show;
      //esto corrige que no se pueda hacer ctrl+alt+tab en programas de sistema
      SwitchToThisWindow(Form1.Handle,True);
      toggleBG:=False;
      AutomaticSize;
      if Form2.chkSmartSwitch.Checked then
      TaskBarSwitcherStatic
      else TaskBarSwitcher;
  end;

end;



procedure TForm1.Timer1Timer(Sender: TObject);
var
mousepos:TPoint;
begin
{   if (GetWindowLong(FindWindow('QWidget',''),GWL_EXSTYLE)and WS_EX_TOPMOST)<>WS_EX_TOPMOST then
   begin
      ShowWindow(FindWindow('QWidget',nil),SW_HIDE);
      UpdateWindow(FindWindow('QWidget',nil));
   end;

   if IsWindowVisible(FindWindow('QWidget',''))then
   begin
   ShowWindow(FindWindow('QWidget',nil),SW_SHOWNA);
   UpdateWindow(FindWindow('QWidget',nil));
   end;}

  try
    //si hago Win+L falla por tanto exception catch :P
    mousepos:=mouse.CursorPos;
  except
  end;
taskswnd:=FindWindow('TaskSwitcherWnd',nil);
//los botoncitos son de clase : TaskSwitcherOverlayWnd
task3dwnd:=FindWindow('Flip3D',nil);

if (mousepos.X=0) and (mousepos.y=0) then
begin
 if (Form2.ComboBox1.Text=Actions[1]) then
 begin
    ActionSwitch; //lanzamos el switch smart :P
 end
 //dashoboard
 else if (Form2.ComboBox1.Text=Actions[4])then
 begin
      //windows 7 gadgets
 if not IsWindowVisible(frmDashboard.Handle)then
 begin
   frmDashboard.Show;
   EnumWindows(@EnumWindowsFunc,0);
 end;exit;
   keybd_event(VK_F11,MapVirtualKey(VK_F11,0),0,0);
   Sleep(10);
   keybd_event(VK_F11,MapVirtualKey(VK_F11,0),KEYEVENTF_KEYUP,0);
   Sleep(100);
 end;
end

else if ((mousepos.X=screen.Width-1) and (mousepos.y=0))then
begin
  if (Form2.ComboBox2.Text=Actions[1])then
  begin
    ActionSwitch;
  end
 //dashoboard
 else if (Form2.ComboBox2.Text=Actions[4])then
 begin
      //windows 7 gadgets
 if not IsWindowVisible(frmDashboard.Handle)then
 begin
   frmDashboard.Show;
   EnumWindows(@EnumWindowsFunc,0);
 end;exit;
   keybd_event(VK_F11,MapVirtualKey(VK_F11,0),0,0);
   Sleep(10);
   keybd_event(VK_F11,MapVirtualKey(VK_F11,0),KEYEVENTF_KEYUP,0);
   Sleep(100);
 end;
end

else if ((mousepos.X=0) and (mousepos.y=screen.Height-1))then
begin
 if (Form2.ComboBox3.Text=Actions[1])then
 begin
    ActionSwitch;
 end //dashoboard
 else if (Form2.ComboBox3.Text=Actions[4])then
 begin
 if not IsWindowVisible(frmDashboard.Handle)then
 begin
   frmDashboard.Show;
   EnumWindows(@EnumWindowsFunc,0);
 end;
 Exit;
   keybd_event(VK_F11,MapVirtualKey(VK_F11,0),0,0);
   Sleep(10);
   keybd_event(VK_F11,MapVirtualKey(VK_F11,0),KEYEVENTF_KEYUP,0);
   Sleep(100);
 end;
end
else if((mousepos.X=screen.Width-1) and (mousepos.y=screen.Height-1)) then
begin
  if (Form2.ComboBox4.Text=Actions[1]) then
  begin
    ActionSwitch;
  end //dashoboard
 else if (Form2.ComboBox4.Text=Actions[4])then
 begin
   //windows 7 gadgets
 if not IsWindowVisible(frmDashboard.Handle)then
 begin
   frmDashboard.Show;
   if IsWindowVisible(frmDashboard.Handle) then
   EnumWindows(@EnumWindowsFunc,0);
 end;
   //support for Kludgets
{   if (FindWindow('QWidget',nil)>0)and((GetWindowLong(FindWindow('QWidget',''),GWL_EXSTYLE)and WS_EX_TOPMOST)<>WS_EX_TOPMOST) then
   begin
   keybd_event(VK_F11,MapVirtualKey(VK_F11,0),0,0);
   Sleep(10);
   keybd_event(VK_F11,MapVirtualKey(VK_F11,0),KEYEVENTF_KEYUP,0);
   Sleep(100);
   end;
   //support for Konfabulator (Yahoo Widgets)
   if FindWindow('KFWindow','_Backdrop_')=0 then
   begin
     SwitchToThisWindow(Handle,true);
   keybd_event(VK_F8,MapVirtualKey(VK_F8,0),0,0);
   Sleep(10);
   keybd_event(VK_F8,MapVirtualKey(VK_F8,0),KEYEVENTF_KEYUP,0);
   Sleep(100);
   end;}
 end;

end;
////**TERMINA LOS BORDES***/

if IsWindowVisible(taskswnd)then
begin
//  BringWindowToTop(handle);
//  Show;
//   SetLayeredWindowAttributes(taskswnd,0,200, LWA_ALPHA);
//   SetLayeredWindowAttributes(FindWindow('TaskSwitcherOverlayWnd',nil),0,150,LWA_ALPHA); oscurece todo :P
// esto modifica el tamaño del switch
//  SetWindowPos(taskswnd,HWND_TOPMOST, 0,0,Screen.Width,Screen.Height,SWP_NOZORDER or SWP_SHOWWINDOW);
end
else
begin
  if toggleBG then
  begin
    hide;
    if originalAeroPeekState = 1 then
    EnableAeroPeek;

//        if GetAKey(VK_CONTROL)then keybd_event(VK_CONTROL,MapVirtualKey(VK_CONTROL,0),KEYEVENTF_KEYUP,0);
  end
  else begin
    toggleBG:=True;
  end;
end;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
a:integer;
begin

SetPriorityClass(GetCurrentProcess,$4000);
//AeroPeek State
 if AeroPeekState then originalAeroPeekState := 1
 else originalAeroPeekState:=0;
//--------------
  toggleBG:=true;
  BorderStyle:=bsNone;
//  AlphaBlend:=true;
//  AlphaBlendValue:=128;
  Color:=clBlack;
  Left:=0;
  Width:=Screen.Width;
  Top:=0;
  Height:=Screen.Height;

// The available options are:
Actions[0]:='';
Actions[1]:='All Windows';
Actions[2]:='Fast Switch';
Actions[3]:='Desktop';
Actions[4]:='Dashboard';
Actions[5]:='';
Actions[6]:='Start Screen Saver';
Actions[7]:='Disable Screen Saver';
Actions[8]:='';
Actions[9]:='Put Display to Sleep';




//hiding from taskbar
  ShowWindow(Application.Handle, SW_HIDE) ;
  SetWindowLong(Application.Handle, GWL_EXSTYLE, getWindowLong(Application.Handle, GWL_EXSTYLE) or WS_EX_TOOLWINDOW) ;
  ShowWindow(Application.Handle, SW_SHOW) ;

//Aplicamos oscurecimiento
  //SetWindowLong(form1.Handle,GWL_EXSTYLE,GWL)
   SetWindowLong(Handle, GWL_EXSTYLE, GetWindowLong(Handle, GWL_EXSTYLE) Or WS_EX_LAYERED or WS_EX_TRANSPARENT or WS_EX_TOOLWINDOW {and not WS_EX_APPWINDOW});
   SetLayeredWindowAttributes(Handle,0,200, LWA_ALPHA);

   SetWindowPos(Handle,HWND_TOPMOST,Left,Top,Width, Height,SWP_NOMOVE or SWP_NOACTIVATE or SWP_NOSIZE);

   AutoStartState;

{creamos el icono del programa}
with IconData do
begin
cbSize:=sizeof(IconData);
Wnd:=Handle;
uID:=100;
uFlags:=NIF_MESSAGE+NIF_ICON+NIF_TIP;
uCallbackMessage:= WM_USER+1;
hIcon:=Application.Icon.Handle;
StrPCopy(szTip,'Win7sé');
end;

Shell_NotifyIcon(NIM_ADD,@Icondata);

end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
if IconData.Wnd <> 0 then Shell_NotifyIcon(NIM_DELETE, @IconData);
end;

procedure TForm1.Exit1Click(Sender: TObject);
begin
close
end;

procedure TForm1.About1Click(Sender: TObject);
begin
if MessageDlg('Win7sé v0.1 5/14/11'+#13
+'Author: Victor Alberto Gil a.k.a vhanla'+#13
+'http://apps.codigobit.info/'+#13
+#13
+'All rights reserved 2011.',mtInformation,[mbOk],0)=mrOk then
begin
hide;
end;
end;

procedure TForm1.StartwithWindows1Click(Sender: TObject);
begin
 if StartwithWindows1.Checked then
 begin
   UnRegAutoStart;
   StartwithWindows1.Checked:=False;
 end
 else
 begin
   RegAutoStart;
   StartwithWindows1.Checked:=True;
 end;
end;

procedure TForm1.Settings1Click(Sender: TObject);
begin
form2.show
end;

end.
