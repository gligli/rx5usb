unit fprogram;

{$mode objfpc}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons, ComCtrls, filectrl, rx5classes;

type

  { TProgramForm }

  TProgramForm = class(TForm)
    btProgram: TBitBtn;
    btCancel: TBitBtn;
    cbTarget: TComboBox;
    gbSettings: TGroupBox;
    gbStatus: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    llStatus: TLabel;
    llSource: TLabel;
    pbProgress: TProgressBar;
    procedure btProgramClick(Sender: TObject);
    procedure cbTargetChange(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
    FPStream:TStream;
    FFileName:String;
    FCartridge:TRX5Cartridge;
    FCancel:Boolean;
    procedure UpdateState;
    function RX5Progress(APosition,AMax:Integer):Boolean;
  public
    { public declarations }
    class procedure Popup(APStream:TStream;AFileName:String);
  end;

implementation

{$R *.lfm}

resourcestring
  SCurrentBank='(Current bank)';

{ TProgramForm }

procedure TProgramForm.FormCreate(Sender: TObject);
begin
  FCartridge:=TRX5Cartridge.Create;
  FCartridge.OnProgress:=@RX5Progress;
  FCartridge.BankIndex:=rbiNone;
end;

procedure TProgramForm.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  FCancel:=True;
  CanClose:=not (FCartridge.Status in [rpsDownloading,rpsUploading]);
end;

procedure TProgramForm.btProgramClick(Sender: TObject);
begin
  FCartridge.Upload(FPStream);
  UpdateState;
end;

procedure TProgramForm.cbTargetChange(Sender: TObject);
begin
  FCartridge.BankIndex:=TRX5BankIndex(cbTarget.ItemIndex);
  UpdateState;
end;

procedure TProgramForm.FormDestroy(Sender: TObject);
begin
  FCartridge.Free;
end;

procedure TProgramForm.FormShow(Sender: TObject);
begin
  UpdateState;
end;

procedure TProgramForm.UpdateState;
begin
  cbTarget.Enabled:=FCartridge.Status=rpsIdle;
  btProgram.Enabled:=FCartridge.BankIndex<>rbiNone;

  llSource.Caption:=SCurrentBank;
  if FFileName<>'' then llSource.Caption:=MiniMizeName(FFileName,llSource.Canvas,llSource.Width);

  llStatus.Caption:=LoadResString(CRX5StatusText[FCartridge.Status]);
end;

function TProgramForm.RX5Progress(APosition, AMax: Integer): Boolean;
begin
  if (APosition=-1) and (AMax=-1) then
  begin
    pbProgress.Style:=pbstMarquee
  end
  else
  begin
    pbProgress.Style:=pbstNormal;
    pbProgress.Max:=AMax;
    pbProgress.Position:=APosition;
  end;

  UpdateState;

  Application.ProcessMessages;

  Result:=not FCancel;
end;

class procedure TProgramForm.Popup(APStream: TStream; AFileName: String);
var pf:TProgramForm;
begin
  pf:=TProgramForm.Create(Application.MainForm);
  try
    pf.FPStream:=APStream;
    pf.FFileName:=AFileName;
    pf.ShowModal;
  finally
    pf.Free;
  end;
end;

end.

