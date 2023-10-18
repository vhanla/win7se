unit DashBoardBG_src;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs;

type
  TfrmDashboard = class(TForm)
    procedure FormClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormPaint(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmDashboard: TfrmDashboard;
  showGadgets: Boolean;

  DwmIsCompositionEnabled:function (pfEnabled: PBOOL):HRESULT;stdcall;
  DwmExtendFrameIntoClientArea:function (hWnd: HWND; Margins: PRect):HRESULT;stdcall;

    procedure SwitchToThisWindow(h1: hWnd; x: bool); stdcall;
  external user32 Name 'SwitchToThisWindow';
  
implementation
uses Registry;
{$R *.dfm}

function DWMExists:Boolean;
var
  reg: TRegistry;
  SystemRoot: string;
begin
  reg:= TRegistry.Create;
  try
    reg.RootKey:=HKEY_LOCAL_MACHINE;
    //HKEY_LOACL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion
    //SystemRoot RG_SZ c:\windows
    if reg.OpenKeyReadOnly('SOFTWARE\Microsoft\Windows NT\CurrentVersion')then
    begin
      SystemRoot:=reg.ReadString('SystemRoot');
    end;
    reg.CloseKey;
  finally
    reg.Free;
  end;
   Result:= FileExists(SystemRoot+'\System32\dwmapi.dll');
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
         if showGadgets then
         begin
           ShowWindow(gHandle,SW_SHOWNA);
         SwitchToThisWindow(gHandle,True);
         end
         else
//         ShowWindow(gHandle,SW_HIDE);
          SetWindowPos(gHandle,HWND_BOTTOM,0,0,0,0,SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE);

        end;
      end;
  end;

  result:=true;
end;

procedure TfrmDashboard.FormClick(Sender: TObject);
begin
  showGadgets:=False;
EnumWindows(@  EnumWindowsFunc,0);
close
end;

procedure TfrmDashboard.FormCreate(Sender: TObject);
var
  Aero:BOOL;
  Area:TRect;
  hDWM: THandle;
begin
  BorderStyle:=bsNone;
  Color:=clBlack;
  Left:=0;
  Top:=0;
  Width:=Screen.Width;
  Height:=Screen.Height;
//hiding from taskbar
  ShowWindow(Handle, SW_HIDE) ;
  SetWindowLong(Handle, GWL_EXSTYLE, getWindowLong(Application.Handle, GWL_EXSTYLE) or WS_EX_TOOLWINDOW) ;
//  ShowWindow(Handle, SW_SHOW) ;

//Aplicamos oscurecimiento
  //SetWindowLong(form1.Handle,GWL_EXSTYLE,GWL)
   SetWindowLong(Handle, GWL_EXSTYLE, GetWindowLong(Handle, GWL_EXSTYLE) Or WS_EX_LAYERED or WS_EX_TOOLWINDOW {and not WS_EX_APPWINDOW});
   SetLayeredWindowAttributes(Handle,0,200, LWA_ALPHA);

   SetWindowPos(Handle,HWND_TOPMOST,Left,Top,Width, Height,SWP_NOMOVE or SWP_NOACTIVATE or SWP_NOSIZE);

{//aero
    Area:=Rect(-1,-1,-1,-1);
    BorderStyle:=bsSingle;
    BorderIcons:=[];
    Position:=poScreenCenter;
    Caption:='';
    DoubleBuffered:=true;
  if DWMExists then
  begin
    hDWM:=LoadLibrary('dwmapi.dll');
    try
    @DwmIsCompositionEnabled:=GetProcAddress(hDWM,'DwmIsCompositionEnabled');
    if @DwmIsCompositionEnabled<>nil then
    DwmIsCompositionEnabled(@Aero);
    if Aero then begin
      Area:=Rect(-1,-1,-1,-1);
      Color:=clBlack;
      @DwmExtendFrameIntoClientArea:=GetProcAddress(hDWM,'DwmExtendFrameIntoClientArea');
      if @DwmExtendFrameIntoClientArea<>nil then
      DwmExtendFrameIntoClientArea(Handle,@Area);
    end;//    else ShowMessage('Aero Disabled');
    finally
      FreeLibrary(hDWM);
    end;
  end  ;//  else ShowMessage('DWM Api not present');
   SetWindowPos(Handle,HWND_TOPMOST,Left,Top,Width, Height,SWP_NOMOVE or SWP_NOACTIVATE or SWP_NOSIZE);}
end;

procedure TfrmDashboard.FormPaint(Sender: TObject);
begin
//  showGadgets:=True;
//EnumWindows(@EnumWindowsFunc,0);
end;

end.
