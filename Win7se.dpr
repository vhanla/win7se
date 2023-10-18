program Win7se;

uses
  Forms,
  Windows,
  Win7se_src in 'Win7se_src.pas' {Form1},
  Settings_src in 'Settings_src.pas' {Form2},
  DashBoardBG_src in 'DashBoardBG_src.pas' {frmDashboard};

{$R *.res}

var
  RvHandle: HWND;

begin
  //let's avoid double instance
  RvHandle:=FindWindow('Win7se',nil);
  if RvHandle > 0 then
  exit;
  Application.Initialize;
  Application.ShowMainForm:=False;
  Application.Title := 'Win7sé';
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TForm2, Form2);
  Application.CreateForm(TfrmDashboard, frmDashboard);
  Application.Run;
end.
