program HC06;

uses
  System.StartUpCopy,
  FMX.Forms,
  form_Main in 'form_Main.pas' {FormMain};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
