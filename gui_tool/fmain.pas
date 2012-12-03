{ RX5USB tool

  Copyright (C) 2012 GliGli (gligli@sfxteam.org)

  This source is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License as published by the Free
  Software Foundation; either version 2 of the License, or (at your option)
  any later version.

  This code is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
  details.

  A copy of the GNU General Public License is available on the World Wide Web
  at <http://www.gnu.org/copyleft/gpl.html>. You can also obtain it by writing
  to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
  MA 02111-1307, USA.
}

unit FMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, TAGraph, TASeries, Forms,
  Controls, Graphics, Dialogs, StdCtrls, ComCtrls, ExtCtrls, rx5classes,
  LCLType, Buttons, Spin, math, jedi_sdl_sound, sdl;

type

  { TMainForm }

  TMainForm = class(TForm)
    btAddManySounds: TToolButton;
    btImportSample: TBitBtn;
    btStop: TBitBtn;
    btPlayAll: TBitBtn;
    btPlayLoop: TBitBtn;
    Button1: TButton;
    chartWave: TChart;
    chartWaveLoop: TAreaSeries;
    chartWaveData: TLineSeries;
    chLoop: TCheckBox;
    edName: TEdit;
    sePitch: TFloatSpinEdit;
    gbLoop: TGroupBox;
    gbQuality: TGroupBox;
    gbEnv: TGroupBox;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    llSampleRate: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label7: TLabel;
    Label9: TLabel;
    llBasics: TGroupBox;
    ilImages: TImageList;
    Label1: TLabel;
    Label2: TLabel;
    Label6: TLabel;
    Label8: TLabel;
    llChannel: TLabel;
    llSize: TLabel;
    llVolume: TLabel;
    lvSounds: TListView;
    odBank: TOpenDialog;
    odSample: TOpenDialog;
    pbSize: TProgressBar;
    pnDetails: TPanel;
    pnSize: TPanel;
    rb12: TRadioButton;
    rb8: TRadioButton;
    sdBank: TSaveDialog;
    seLoopEnd: TSpinEdit;
    seLoopStart: TSpinEdit;
    Splitter1: TSplitter;
    tbChannel: TTrackBar;
    tbTop: TToolBar;
    btNew: TToolButton;
    btOpen: TToolButton;
    btSave: TToolButton;
    tbVolume: TTrackBar;
    ToolButton1: TToolButton;
    btProgram: TToolButton;
    ToolButton2: TToolButton;
    btAbout: TToolButton;
    btAddSound: TToolButton;
    btRemoveSound: TToolButton;
    ToolButton5: TToolButton;
    tbEnvAR: TTrackBar;
    tbEnvD1R: TTrackBar;
    tbEnvGT: TTrackBar;
    tbEnvD1L: TTrackBar;
    tbEnvD2R: TTrackBar;
    tbEnvRR: TTrackBar;
    ttPreview: TTimer;
    procedure AudioOutDone(Sender: TComponent);
    procedure btAboutClick(Sender: TObject);
    procedure btAddManySoundsClick(Sender: TObject);
    procedure btAddSoundClick(Sender: TObject);
    procedure btImportSampleClick(Sender: TObject);
    procedure btNewClick(Sender: TObject);
    procedure btOpenClick(Sender: TObject);
    procedure btPlayAllClick(Sender: TObject);
    procedure btPlayLoopClick(Sender: TObject);
    procedure btRemoveSoundClick(Sender: TObject);
    procedure btSaveClick(Sender: TObject);
    procedure btStopClick(Sender: TObject);
    procedure chartWaveMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of String);
    procedure lvSoundsData(Sender: TObject; Item: TListItem);
    procedure lvSoundsSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure ttPreviewTimer(Sender: TObject);
    procedure UpdateCurrentSound(Sender: TObject);
  private
    { private declarations }
    FChanged:Boolean;
    FBank:TRX5Bank;
    FPCurrentSound:TRX5Sound;
    FFileName:String;
    FPanelLoading:Boolean;

    FPreviewAudioData:TMemoryStream;
    FPreviewAudioSpec:TSDL_AudioSpec;
    FPreviewContinue:Boolean;

    procedure UpdateList;
    procedure UpdatePanel(AUpdateChart:Boolean);
    procedure UpdateState;

    function AskSave:Boolean;

    procedure Load(AFileName:String);
    procedure Save(AFileName:String);
    procedure New;

    function ImportSample(AFileName:String):Boolean;
    procedure Play(ALoop:Boolean);
    procedure Stop;
  public
    { public declarations }
  end;

var
  MainForm: TMainForm;

implementation

const
    CMaxPreviewChartPoints=10000;

resourcestring
  SUnableToPlay='Unable to play sample';
  SUnableToImport='Unable to import %s: %s.';
  SSaveCurrent='Save current bank?';
  SUntitled='New bank';
  SMainTitle='%s - %s';
  SSizeCpation='%n%% (%n KB/%n KB)';
  SModified=' (modified)';
  SEmpty='(Nothing)';
  SBank='Sound bank';
  SSample='New sample';

  SAbout=
   'Yamaha RX5 waveform bank editor /'+sLineBreak+
   'RX5USB cartridge programmer'+sLineBreak+
   sLineBreak+
   'Version: 0.01 alpha'+sLineBreak+
   'Coder: gligli'+sLineBreak+
   'License: GNU GPL';

{$R *.lfm}

procedure playCallback( userdata: Pointer; stream: PUInt8; len: Integer ); cdecl;
var mf:TMainForm;
begin
  mf:=TMainForm(userdata);

  FillChar(stream^,len,0);

  if mf.FPreviewContinue then
  begin
    mf.FPreviewAudioData.Read(stream^,len);
    mf.FPreviewContinue:=mf.FPreviewAudioData.Position<mf.FPreviewAudioData.Size;
  end;
end;

{ TMainForm }


procedure TMainForm.FormCreate(Sender: TObject);
begin
  FormatSettings.ThousandSeparator:=' ';

  FPreviewAudioData:=TMemoryStream.Create;

  if SDL_Init(SDL_INIT_AUDIO)<>0 then
    raise ERX5Error.Create(SDL_GetError);

  if Sound_Init=0 then
    raise ERX5Error.Create(Sound_GetError);

  //HACK: this fixes importing MP3, don't ask me why...
  FPreviewContinue:=False;
  FPreviewAudioSpec.samples:=512;
  FPreviewAudioSpec.channels:=1;
  FPreviewAudioSpec.format:=AUDIO_S16;
  FPreviewAudioSpec.freq:=44100;
  FPreviewAudioSpec.userdata:=Self;
  FPreviewAudioSpec.callback:=@playCallback;
  SDL_OpenAudio(@FPreviewAudioSpec,nil);
  SDL_PauseAudio(0);

  FBank:=TRX5Bank.Create;

  if (Paramcount>=1) and FileExists(ParamStr(1)) then
    Load(ParamStr(1))
  else
    New;
end;

procedure TMainForm.btNewClick(Sender: TObject);
begin
  if not AskSave then Exit;
  New;
end;

procedure TMainForm.btOpenClick(Sender: TObject);
begin
  if not AskSave then Exit;

  if odBank.Execute then
    Load(odBank.FileName);
end;

procedure TMainForm.btPlayAllClick(Sender: TObject);
begin
  Play(False);
end;

procedure TMainForm.btPlayLoopClick(Sender: TObject);
begin
  Play(True);
end;

procedure TMainForm.btAddSoundClick(Sender: TObject);
begin
  FBank.Sounds.Add(TRX5Sound.Create);

  FChanged:=True;

  UpdateList;

  lvSounds.ItemIndex:=FBank.Sounds.Count-1;

  UpdateState;
end;

procedure TMainForm.btImportSampleClick(Sender: TObject);
begin
  if odSample.Execute then
  begin
    ImportSample(odSample.FileName);
    UpdateState;
  end;
end;

procedure TMainForm.AudioOutDone(Sender: TComponent);
begin
  UpdatePanel(False);
end;

procedure TMainForm.btAboutClick(Sender: TObject);
begin
  Application.MessageBox(PChar(SAbout),PChar(Application.Title),MB_ICONINFORMATION);
end;

procedure TMainForm.btAddManySoundsClick(Sender: TObject);
var i:Integer;
begin
  odSample.Options:=odSample.Options+[ofAllowMultiSelect];
  try
    if odSample.Execute then
    begin
      for i:=0 to odSample.Files.Count-1 do
      begin
        FPCurrentSound:=TRX5Sound.Create;

        if ImportSample(odSample.Files[i]) then
          FBank.Sounds.Add(FPCurrentSound)
        else
          FPCurrentSound.Free;
      end;

      UpdateList;

      lvSounds.ItemIndex:=FBank.Sounds.Count-1;

      UpdateState;
    end;
  finally
    odSample.Options:=odSample.Options-[ofAllowMultiSelect];
  end;
end;

procedure TMainForm.btRemoveSoundClick(Sender: TObject);
var ii:Integer;
begin
  Stop;
  while SDL_GetAudioStatus=SDL_AUDIO_PLAYING do
    CheckSynchronize(50);

  ii:=lvSounds.ItemIndex;

  if ii<0 then Exit;

  FBank.Sounds.Delete(ii);

  FChanged:=True;

  UpdateList;

  lvSounds.ItemIndex:=Min(ii,FBank.Sounds.Count-1);

  UpdateState;
end;

procedure TMainForm.btSaveClick(Sender: TObject);
begin
  if sdBank.Execute then
    Save(sdBank.FileName);
end;

procedure TMainForm.btStopClick(Sender: TObject);
begin
  Stop;
end;

procedure TMainForm.chartWaveMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var p:Integer;
begin
  if FPanelLoading or (FPCurrentSound=nil) then
    Exit;

  p:=GetPCMSize(chartWave.XImageToGraph(X)/SecsPerDay,FPCurrentSound.SampleRate,FPCurrentSound.BitsPerSample);

  if Button=mbLeft then
    seLoopStart.Value:=p
  else if Button=mbRight then
    seLoopEnd.Value:=p;

end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  Stop;

  CanClose:=AskSave;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FBank.Free;

  Sound_Quit;
  SDL_CloseAudio;
  SDL_Quit;

  FPreviewAudioData.Free;
end;

procedure TMainForm.FormDropFiles(Sender: TObject;
  const FileNames: array of String);
var i:Integer;
begin
  if (Length(FileNames)=1) and SameText(ExtractFileExt(FileNames[0]),odBank.DefaultExt) then
  begin
    if not AskSave then Exit;
    Load(FileNames[0]);
    Exit;
  end;

  for i:=0 to length(FileNames)-1 do
  begin
    FPCurrentSound:=TRX5Sound.Create;

    if ImportSample(FileNames[i]) then
      FBank.Sounds.Add(FPCurrentSound)
    else
      FPCurrentSound.Free;
  end;

  UpdateList;

  lvSounds.ItemIndex:=FBank.Sounds.Count-1;

  UpdateState;
end;

procedure TMainForm.lvSoundsData(Sender: TObject; Item: TListItem);
var s:TRX5Sound;
begin
  if (Item=nil) or (Item.Index<0) or (Item.Index>=FBank.Sounds.Count) then Exit;

  s:=FBank.Sounds[Item.Index];

  Item.Caption:=s.Name;

  if s.RawMode then
  begin
    if s.FinalPCMSize=0 then
      Item.SubItems.Add(SEmpty)
    else
      Item.SubItems.Add(SBank);
  end
  else
      Item.SubItems.Add(SSample);

  Item.SubItems.Add(Format('%d Bits',[CRX5SoundFormatBPS[s.Format]]));
  Item.SubItems.Add(Format('%n Khz',[s.SampleRate/1000.0]));
  Item.SubItems.Add(Format('%n s',[s.FinalLength*SecsPerDay]));
  Item.SubItems.Add(Format('%n KB',[s.FinalPCMSize/1024.0]));
  Item.SubItems.Add(IntToStr(s.Channel+1));
end;

procedure TMainForm.lvSoundsSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
begin
  UpdateState;
end;

procedure TMainForm.ttPreviewTimer(Sender: TObject);
begin
  if not FPreviewContinue then
  begin
    ttPreview.Enabled:=False;
    UpdatePanel(False);
  end;
end;

procedure TMainForm.UpdateCurrentSound(Sender: TObject);
begin
  if FPanelLoading or (FPCurrentSound=nil) then
    Exit;

  FPCurrentSound.Name:=edName.Text;
  if rb8.Checked then FPCurrentSound.Format:=rsfPCM8;
  if rb12.Checked then FPCurrentSound.Format:=rsfPCM12;

  FPCurrentSound.Pitch:=round(sePitch.Value*10);

  FPCurrentSound.LoopEnable:=chLoop.Checked;
  FPCurrentSound.LoopStart:=seLoopStart.Value;
  FPCurrentSound.LoopEnd:=seLoopEnd.Value;
  FPCurrentSound.LoopEnd:=Max(FPCurrentSound.LoopStart,FPCurrentSound.LoopEnd);

  FPCurrentSound.Level:=tbVolume.Position;
  FPCurrentSound.Channel:=tbChannel.Position-1;

  FPCurrentSound.EnvAttackRate:=tbEnvAR.Position;
  FPCurrentSound.EnvDecay1Rate:=tbEnvD1R.Position;
  FPCurrentSound.EnvDecay1Level:=tbEnvD1L.Position;
  FPCurrentSound.EnvDecay2Rate:=tbEnvD2R.Position;
  FPCurrentSound.EnvReleaseRate:=tbEnvRR.Position;
  FPCurrentSound.EnvGateTime:=tbEnvGT.Position;

  FChanged:=True;

  UpdateState;
end;

procedure TMainForm.UpdateList;
begin
  lvSounds.Items.Count:=FBank.Sounds.Count;
  lvSounds.Repaint;
end;

procedure TMainForm.UpdatePanel(AUpdateChart: Boolean);
var ms:TMemoryStream;
    w:Double;
    ls,le,t:TDateTime;
    skip:Integer;
begin
  if FPanelLoading or (FPCurrentSound=nil) then
    Exit;

  FPanelLoading:=true;
  try
    btPlayAll.Enabled:=not FPreviewContinue;
    btPlayLoop.Enabled:=btPlayAll.Enabled and FPCurrentSound.LoopEnable;

    if AUpdateChart then
    begin;
      chartWaveData.Clear;
      chartWaveLoop.Clear;

      if FPCurrentSound.LoopEnable then
      begin
        ls:=GetPCMLength(FPCurrentSound.LoopStart,FPCurrentSound.SampleRate,FPCurrentSound.BitsPerSample)*SecsPerDay;
        le:=GetPCMLength(FPCurrentSound.LoopEnd,FPCurrentSound.SampleRate,FPCurrentSound.BitsPerSample)*SecsPerDay;
        chartWaveLoop.AddXY(ls,0.5);
        chartWaveLoop.AddXY(le,0.5);
      end;

      ms:=TMemoryStream.Create;
      try
        FPCurrentSound.ExportPreviewPCMToStream(ms);
        ms.Seek(0,soFromBeginning);

        skip:=(ms.Size div (CMaxPreviewChartPoints * 2)) * 2;

        while ms.Position<ms.Size do
        begin
          w:=SmallInt(ms.ReadWord)/65536.0;
          t:=GetPCMLength(ms.Position,FPCurrentSound.SampleRate,16)*SecsPerDay;
          chartWaveData.AddXY(t,w);

          ms.Seek(skip,soFromCurrent);
        end;

      finally
        ms.Free;
      end;
    end;

    edName.Text:=FPCurrentSound.Name;
    rb8.Checked:=FPCurrentSound.Format=rsfPCM8;
    rb12.Checked:=FPCurrentSound.Format=rsfPCM12;
    rb8.Enabled:=not FPCurrentSound.RawMode;
    rb12.Enabled:=not FPCurrentSound.RawMode;
    sePitch.Value:=FPCurrentSound.Pitch/10;
    llSampleRate.Caption:=Format('%n Khz',[FPCurrentSound.SampleRate/1000.0]);

    chLoop.Checked:=FPCurrentSound.LoopEnable;
    seLoopStart.MaxValue:=FPCurrentSound.FinalPCMSize;
    seLoopStart.Value:=FPCurrentSound.LoopStart;
    seLoopEnd.MaxValue:=FPCurrentSound.FinalPCMSize;
    seLoopEnd.Value:=FPCurrentSound.LoopEnd;

    tbVolume.Position:=FPCurrentSound.Level;
    llVolume.Caption:=IntToStr(tbVolume.Position);
    tbChannel.Position:=FPCurrentSound.Channel+1;
    llChannel.Caption:=IntToStr(tbChannel.Position);

    tbEnvAR.Position:=FPCurrentSound.EnvAttackRate;
    tbEnvD1R.Position:=FPCurrentSound.EnvDecay1Rate;
    tbEnvD1L.Position:=FPCurrentSound.EnvDecay1Level;
    tbEnvD2R.Position:=FPCurrentSound.EnvDecay2Rate;
    tbEnvRR.Position:=FPCurrentSound.EnvReleaseRate;
    tbEnvGT.Position:=FPCurrentSound.EnvGateTime;

  finally
    FPanelLoading:=False;
  end;
end;

procedure TMainForm.UpdateState;
var overloaded:Boolean;
    projected:Integer;
begin
  UpdateList;

  btRemoveSound.Enabled:=(FBank.Sounds.Count>0) and (lvSounds.ItemIndex>=0);

  Caption:=Format(SMainTitle,[Application.Title,FFileName]);
  if FChanged then
    Caption:=Caption+SModified;

  projected:=FBank.ProjectedSize;
  overloaded:=projected>CRX5BankSize;

  pbSize.Max:=CRX5BankSize;
  pbSize.Position:=projected;

  llSize.Font.Color:=clDefault;
  if overloaded then llSize.Font.Color:=clRed;

  llSize.Caption:=Format(SSizeCpation,[100*projected/CRX5BankSize,projected/1024,CRX5BankSize/1024]);

  btSave.Enabled:=not overloaded;

  FPCurrentSound:=nil;
  if (lvSounds.ItemIndex>=0)  then
    FPCurrentSound:=FBank.Sounds[lvSounds.ItemIndex];

  pnDetails.Visible:=FPCurrentSound<>nil;

  UpdatePanel(True);
end;

function TMainForm.AskSave: Boolean;
var res:Integer;
begin
  Result:=True;

  if not FChanged then
    Exit;

  res:=Application.MessageBox(PChar(SSaveCurrent),PChar(Application.Title),MB_ICONQUESTION or MB_YESNOCANCEL);

  case res of
    IDYES: btSave.Click;
    IDCANCEL: Result:=False;
  end;
end;

procedure TMainForm.Load(AFileName: String);
begin
  FBank.ImportFromFile(AFileName);

  FFileName:=AFileName;
  FPCurrentSound:=nil;
  FChanged:=False;

  UpdateState;
end;

procedure TMainForm.Save(AFileName: String);
begin
  FBank.ExportToFile(AFileName);

  FFileName:=AFileName;
  FChanged:=False;

  UpdateState;
end;

procedure TMainForm.New;
begin
  FFileName:=SUntitled;

  FPCurrentSound:=nil;
  FBank.Clear;

  FChanged:=False;

  UpdateState;
end;

function TMainForm.ImportSample(AFileName: String):Boolean;
var c:TCursor;
begin
  Result:=False;

  if FPCurrentSound=nil then Exit;

  try
    c:=Screen.Cursor;;
    Screen.Cursor:=crHourGlass;
    try
      FPCurrentSound.ImportFromFile(AFileName);
    finally
      Screen.Cursor:=c;
    end;
    Result:=True;
  except
    on e:ERX5Error do
      Application.MessageBox(PChar(Format(SUnableToImport,[AFileName,e.Message])),PChar(Application.Title),MB_ICONERROR);
  end;

  FChanged:=True;
end;

procedure TMainForm.Play(ALoop: Boolean);
var ts,te:TDateTime;
    ps,pe,sz:Integer;
    ms:TMemoryStream;
begin
  if FPCurrentSound=nil then Exit;

  Stop;
  FPreviewAudioData.Clear;

  if ALoop then
  begin
    ms:=TMemoryStream.Create;
    try
      FPCurrentSound.ExportPreviewPCMToStream(ms);

      ts:=GetPCMLength(FPCurrentSound.LoopStart,FPCurrentSound.SampleRate,FPCurrentSound.BitsPerSample);
      te:=GetPCMLength(FPCurrentSound.LoopEnd,FPCurrentSound.SampleRate,FPCurrentSound.BitsPerSample);

      ps:=GetPCMSize(ts,FPCurrentSound.SampleRate,16);
      pe:=GetPCMSize(te,FPCurrentSound.SampleRate,16);

      ps:=(ps shr 1) shl 1;
      pe:=(pe shr 1) shl 1;

      sz:=pe-ps;

      if sz<=0 then
        Exit;

      while FPreviewAudioData.Position<(4*FPCurrentSound.FinalPCMSize*8 div FPCurrentSound.BitsPerSample) do
      begin
        ms.Seek(ps,soFromBeginning);
        FPreviewAudioData.CopyFrom(ms,Min(ms.Size-ps,sz));
      end;

    finally
      ms.Free;
    end;
  end
  else
    FPCurrentSound.ExportPreviewPCMToStream(FPreviewAudioData);

  FPreviewAudioData.Seek(0,soFromBeginning);

  FPreviewAudioSpec.samples:=2048;
  FPreviewAudioSpec.format:=AUDIO_S16;
  FPreviewAudioSpec.channels:=1;
  FPreviewAudioSpec.freq:=FPCurrentSound.SampleRate;
  FPreviewAudioSpec.userdata:=Self;
  FPreviewAudioSpec.callback:=@playCallback;

  FPreviewContinue:=True;
  ttPreview.Enabled:=True;

  if SDL_OpenAudio(@FPreviewAudioSpec,nil)<>0 then
    raise ERX5Error.Create(SUnableToPlay);

  SDL_PauseAudio(0);

  UpdateState;
end;

procedure TMainForm.Stop;
begin
  FPreviewContinue:=False;

  if SDL_GetAudioStatus=SDL_AUDIO_STOPPED then
    Exit;

  SDL_CloseAudio;

  UpdateState;
end;

end.

