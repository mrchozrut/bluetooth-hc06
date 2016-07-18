unit form_Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  System.Bluetooth, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts,
  FMX.ListBox, System.Bluetooth.Components, System.SyncObjs, System.Rtti,
  System.Threading, FMX.Edit, FMX.ScrollBox, FMX.Memo;

type
  TFormMain = class(TForm)
    Bluetooth: TBluetooth;
    FreeListBox: TListBox;
    btnInfo: TButton;
    FreeLbl: TLabel;
    AniIndicator1: TAniIndicator;
    btnPair: TButton;
    PairedListBox: TListBox;
    Panel1: TPanel;
    ListBoxInfo: TListBox;
    btnCreateSocket: TButton;
    PairedLbl: TLabel;
    FreeBtnRefresh: TButton;
    PairedBtnRefresh: TButton;
    pnlFree: TPanel;
    pnlPaired: TPanel;
    pnlCommunication: TPanel;
    memoCommIncomming: TMemo;
    lblCommunication: TLabel;
    edtSend: TEdit;
    btnSend: TButton;
    pnlSend: TPanel;
    btnFreeSocket: TButton;
    Timer: TTimer;
    btnUnpair: TButton;
    Button1: TButton;
    Button2: TButton;
    memoCommOutgoing: TMemo;
    Panel2: TPanel;
    procedure btnInfoClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure BluetoothDiscoveryEnd(const Sender: TObject;
      const ADeviceList: TBluetoothDeviceList);
    procedure PairedBtnRefreshClick(Sender: TObject);
    procedure FreeBtnRefreshClick(Sender: TObject);
    procedure btnCreateSocketClick(Sender: TObject);
    procedure PairedListBoxChange(Sender: TObject);
    procedure btnSendClick(Sender: TObject);
    procedure btnFreeSocketClick(Sender: TObject);
    procedure btnUnpairClick(Sender: TObject);
    procedure btnPairClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
//  BTClient: Array of TBluetoothDevice;
  BTClient: TBluetoothDevice;
  FormMain: TFormMain;
  BTManager: TBluetoothManager;
  BTAdapter: TBluetoothAdapter;
  BTSocket: TBluetoothSocket;

  ReceiverLoop: ITask;

  RecCount: Integer;


implementation

const
  DiscoveryTime = 20000;
  BTPortPooling = 100;

// HC-06 Serial port service info

  ServiceName = 'Dev B';
  ServiceGUI = '{00001101-0000-1000-8000-00805F9B34FB}';
{$R *.fmx}

// Functions Declaration
function GetServiceName(GUID: string): string;
var
  LServices: TBluetoothServiceList;
  LDevice: TBluetoothDevice;
  I: Integer;
begin
//  LDevice := FPairedDevices[ComboboxPaired.ItemIndex] as TBluetoothDevice;
  LDevice:=BTClient;
  LServices := LDevice.GetServices;
  for I := 0 to LServices.Count - 1 do
  begin
    if StringToGUID(GUID) = LServices[I].UUID then
    begin
      Result := LServices[I].Name;
      break;
    end;
  end;
end;



// Procedures Declaration

procedure TFormMain.btnUnpairClick(Sender: TObject);
begin
Bluetooth.UnPair(Bluetooth.CurrentManager.LastPairedDevices.Items[PairedListBox.ItemIndex]);
end;

procedure TFormMain.Button1Click(Sender: TObject);
var
  DiscoveryLoop: ITask;
begin
DiscoveryLoop := TTask.Create( procedure()
  var
    i,j: integer;
  begin
  FormMain.Button1.Enabled:=False;
  RecCount:=0;
  Timer.Enabled:=True;
  for j := 0 to 10000 do
  begin
  BTSocket.SendData( TEncoding.ASCII.GetBytes(edtSend.Text+#10) );
  inc(RecCount);
//  Tinterlocked.Increment(RecCount);
  end;
  FormMain.Button1.Enabled:=True;
  Timer.Enabled:=False;
  end);
DiscoveryLoop.Start;
end;

procedure TFormMain.btnPairClick(Sender: TObject);
begin
Bluetooth.Pair(Bluetooth.CurrentManager.LastDiscoveredDevices.Items[FreeListBox.ItemIndex]);
end;

procedure TFormMain.btnInfoClick(Sender: TObject);
begin
  ListBoxInfo.Clear;
  ListBoxInfo.Items.Add(BTClient.DeviceName);
  ListBoxInfo.Items.Add(BTClient.Address);
//  ListBoxInfo.Items.Add('BT State: '+inttostr(BTClient.State));
//  ListBoxInfo.Items.Add('BT Type: '+inttostr(BTClient.BluetoothType));
  ListBoxInfo.Items.Add('BT Type: '+inttostr(BTClient.ClassDeviceMajor)+'.'+inttostr(BTClient.ClassDevice));
end;

procedure TFormMain.btnCreateSocketClick(Sender: TObject);
var
  ToSend: TBytes;
begin
  if (BTSocket = nil) then
  try
    memoCommOutgoing.Lines.Add(GetServiceName(ServiceGUI)+' '+ServiceGUI);
    memoCommOutgoing.GoToTextEnd;
    BTSocket := BTClient.CreateClientSocket(StringToGUID(ServiceGUI), False);
    BTSocket.Connect;
    Bluetooth.CurrentManager.SocketTimeout:=BTPortPooling;

    if BTSocket <> nil then
    begin
      ToSend := TEncoding.ASCII.GetBytes('Init: '+FormatDateTime('c',now)+#10);
      memoCommOutgoing.Lines.Add('Init: '+FormatDateTime('c',now));
      memoCommOutgoing.GoToTextEnd;

    if ReceiverLoop=nil then
    begin
    ReceiverLoop := TTask.Create( procedure()
      var
        ToRead, SubBytes: TBytes;
        Temp: String;
        I: Integer;
      begin
      while BTSocket.Connected do
      begin
      ToRead:=BTSocket.ReadData;
      SubBytes:=SubBytes+ToRead;

      for I := 0 to length(SubBytes)-1 do
      begin
      if SubBytes[i]=10 then
        begin

          SetString(Temp, PAnsiChar(@SubBytes[0]), i);
          memoCommIncomming.Lines.Add('<--: '+trim(Temp));
          memoCommIncomming.GoToTextEnd;
          SetLength(ToRead, length(SubBytes)-i-1);
          move(SubBytes[i+1],ToRead[0],length(SubBytes)-i-1);
          SetLength(SubBytes, length(ToRead));
          move(ToRead[0],SubBytes[0],length(ToRead));
//          exit;
          break;

        end;
      end;


      end;
      end);
    end;

    end;
    btnCreateSocket.Enabled:=False;
    btnFreeSocket.Enabled:=True;
    PairedListBox.Enabled:=False;

    if ReceiverLoop<>nil then ReceiverLoop.Start;

  except
  on E : Exception do
    begin
    memoCommOutgoing.Lines.Add('Error: '+E.Message);
    memoCommOutgoing.GoToTextEnd;
    end;
  end;
end;

procedure TFormMain.btnFreeSocketClick(Sender: TObject);
begin

  memoCommOutgoing.Lines.Clear;
  memoCommIncomming.Lines.Clear;

  IF BTSocket<>nil then
  begin
  FreeAndNil(BTSocket);
  end;

  // Parallel task should end becasue socket is destroyed and there is while condition
  if ReceiverLoop<>nil then
  begin
  try
  FreeAndNil(ReceiverLoop);
  except
  end;
  end;

  btnCreateSocket.Enabled:=True;
  btnFreeSocket.Enabled:=False;
  PairedListBox.Enabled:=True;
end;

procedure TFormMain.btnSendClick(Sender: TObject);
var
  ToSend: TBytes;
begin
  if (BTSocket <> nil) and (BTSocket.Connected) then
  try
  ToSend := TEncoding.ASCII.GetBytes(edtSend.Text+#10);
  BTSocket.SendData(ToSend);
  memoCommOutgoing.Lines.Add('-->: '+edtSend.Text);
  memoCommOutgoing.GoToTextEnd;
  except
  on E : Exception do
    begin
    memoCommOutgoing.Lines.Add('Error: '+E.Message);
    memoCommOutgoing.GoToTextEnd;
    end;
  end;
end;

procedure TFormMain.FormCreate(Sender: TObject);
var
  I:Integer;
begin
Bluetooth.Enabled:=True;

// Add paired list
PairedListBox.Clear;
for I := 0 to Bluetooth.PairedDevices.Count-1 do PairedListBox.Items.Add(Bluetooth.PairedDevices.Items[i].DeviceName);

// Add free list

end;

procedure TFormMain.FreeBtnRefreshClick(Sender: TObject);
begin
Bluetooth.CurrentManager.StartDiscovery(DiscoveryTime);
AniIndicator1.Enabled:=True;
AniIndicator1.Visible:=True;
end;

procedure TFormMain.BluetoothDiscoveryEnd(const Sender: TObject;
  const ADeviceList: TBluetoothDeviceList);
var
  i: integer;
begin
AniIndicator1.Enabled:=False;
AniIndicator1.Visible:=False;
  for I := 0 to Bluetooth.CurrentManager.LastDiscoveredDevices.Count-1 do
    begin
      FreeListBox.Items.Add(Bluetooth.CurrentManager.LastDiscoveredDevices.Items[i].DeviceName);
    end;
end;

procedure TFormMain.PairedBtnRefreshClick(Sender: TObject);
var
  I: integer;
begin
PairedListBox.Clear;
for I := 0 to Bluetooth.PairedDevices.Count-1 do PairedListBox.Items.Add(Bluetooth.PairedDevices.Items[i].DeviceName);
end;

procedure TFormMain.PairedListBoxChange(Sender: TObject);
begin
if PairedListBox.Count<>0 then BTClient:=Bluetooth.PairedDevices.Items[PairedListBox.Selected.Index];
btnInfoClick(nil);
btnCreateSocket.Enabled:=True;
end;

end.
