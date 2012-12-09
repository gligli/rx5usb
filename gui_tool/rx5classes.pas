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

unit rx5classes;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, contnrs, math, sdl, jedi_sdl_sound, rawhid;

type
  TBassErrorString=record
    Code:Integer;
    Text:String;
  end;

  TRX5ProgressStatus=(rpsIdle=0,rpsConnecting=1,rpsAwaitingResponse=2,rpsUploading=3,rpsDownloading=4,rpsError=5,rpsDone=6,rpsInterrupted=7);
  TRX5BankIndex=(rbiNone=0,rbiSide1BankA=1,rbiSide1BankB=2,rbiSide2BankA=3,rbiSide2BankB=4);
  TRX5SoundFormat=(rsfNone=0,rsfPCM8=1,rsfPCM12=2);

  TRX5ProgressEvent=function(APosition,AMax:Integer):Boolean of object;

  ERX5Error = class(Exception);

  { TRX5Sound }

  TRX5Sound = class
  private
    FName:String;
    FFormat:TRX5SoundFormat;
    FOctave:Byte;
    FNote:Byte; // in octave, note in 1/20th tone
    FRawMode:Boolean;

    FLoopEnable:Boolean;
    FLoopStart:Integer;
    FLoopEnd:Integer;

    FEnvAttackRate:Byte;
    FEnvDecay1Rate:Byte;
    FEnvDecay1Level:Byte;
    FEnvDecay2Rate:Byte;
    FEnvReleaseRate:Byte;
    FEnvGateTime:Byte;

    FBendRate:Byte;
    FBendRange:Byte;

    FUnk:Byte;

    FLevel:Byte;
    FChannel:Byte;

    FFinalPCM:array of Byte;

    FSourceChannels:Integer;
    FSourceFormat:Integer;
    FSourceSampleRate:Integer;
    FSourcePCM:array of Byte;

    procedure FreeData;
    function GetBitsPerSample: Integer;

    function GetFinalPCMSize: Integer;
    function GetFinalLength: TDateTime;
    function GetPitch: Integer;
    function GetSampleRate: Integer;
    function GetSourceBitsPerSample: Integer;
    function GetSourceLength: TDateTime;
    function GetSourcePCMSize: Integer;
    procedure SetPitch(AValue: Integer);
    procedure SetRawMode(AValue: Boolean);
  public
    constructor Create;
    destructor Destroy;override;

    procedure ImportFromBankData(AStream:TStream;AHeaderEntryOffset:Integer);
    procedure ImportFromFile(AFileName:String);

    procedure ExportHeaderToStream(AStream:TStream;APCMDataOffset:Integer);
    procedure ExportRawPCMToStream(AStream:TStream);
    procedure ExportPreviewPCMToStream(AStream:TStream);

    property Name:String read FName write FName;
    property Format:TRX5SoundFormat read FFormat write FFormat;
    property BitsPerSample:Integer read GetBitsPerSample;
    property RawMode:Boolean read FRawMode write SetRawMode;

    property Pitch:Integer read GetPitch write SetPitch; // relative 1/20th tones
    property SampleRate:Integer read GetSampleRate;

    property LoopEnable:Boolean read FLoopEnable write FLoopEnable;
    property LoopStart:Integer read FLoopStart write FLoopStart;
    property LoopEnd:Integer read FLoopEnd write FLoopEnd;

    property EnvAttackRate:Byte read FEnvAttackRate write FEnvAttackRate;
    property EnvDecay1Rate:Byte read FEnvDecay1Rate write FEnvDecay1Rate;
    property EnvDecay1Level:Byte read FEnvDecay1Level write FEnvDecay1Level;
    property EnvDecay2Rate:Byte read FEnvDecay2Rate write FEnvDecay2Rate;
    property EnvReleaseRate:Byte read FEnvReleaseRate write FEnvReleaseRate;
    property EnvGateTime:Byte read FEnvGateTime write FEnvGateTime;

    property BendRate:Byte read FBendRate write FBendRate;
    property BendRange:Byte read FBendRange write FBendRange;

    property Level:Byte read FLevel write FLevel;
    property Channel:Byte read FChannel write FChannel;

    property SourcePCMSize:Integer read GetSourcePCMSize;
    property SourceLength:TDateTime read GetSourceLength;
    property SourceSampleRate:Integer read FSourceSampleRate;
    property SourceChannels:Integer read FSourceChannels;
    property SourceBitsPerSample:Integer read GetSourceBitsPerSample;

    property FinalPCMSize:Integer read GetFinalPCMSize;
    property FinalLength:TDateTime read GetFinalLength;
  end;

  { TRX5Sounds }

  TRX5Sounds = class(TObjectList)
  private
    function GetItem(Index: Integer): TRX5Sound;
  public
    property Items[Index: Integer]: TRX5Sound read GetItem; default;
  end;

  { TRX5Bank }

  TRX5Bank = class
  private
    FSounds:TRX5Sounds;
    FBankID:Byte;
    FGenerateBankID:Boolean;
    function GetProjectedSize: Integer;
  public
    constructor Create;
    destructor Destroy;override;

    procedure Clear;
    procedure ImportFromFile(AFileName:String);
    procedure ExportToFile(AFileName:String);
    procedure ExportToStream(AStream:TStream);

    property BankId:Byte read FBankID write FBankID;
    property GenerateBankId:Boolean read FGenerateBankId write FGenerateBankId;

    property ProjectedSize:Integer read GetProjectedSize;

    property Sounds:TRX5Sounds read FSounds;
  end;

  { TRX5Banks }

  TRX5Banks = class(TObjectList)
  private
    function GetItem(Index: Integer): TRX5Bank;
  public
    property Items[Index: Integer]: TRX5Bank read GetItem; default;
  end;

  { TRX5Cartridge }

  TRX5Cartridge = class
  private
    FBankIndex:TRX5BankIndex;
    FStatus:TRX5ProgressStatus;
    FOnprogress:TRX5ProgressEvent;
    function Progress(AStatus:TRX5ProgressStatus;APosition,AMax:Integer):Boolean;
  public
    procedure Upload(APStream:TStream);

    property BankIndex:TRX5BankIndex read FBankIndex write FBankIndex;
    property Status:TRX5ProgressStatus read FStatus;

    property OnProgress:TRX5ProgressEvent read FOnprogress write FOnprogress;
  end;

  { TRX5Library }

  TRX5Library = class
  private
    FBanks:TRX5Banks;
    FName:String;
  public
    constructor Create;
    destructor Destroy;override;

    property Banks: TRX5Banks read FBanks;
    property Name: String read FName write FName;
  end;

resourcestring
  SNotABankFile = 'Not a valid RX5 bank file';
  SUnknownFormat = 'Unknown format';
  SPCMConvertError = 'PCM convert error';

  SIdle = '(Idle)';
  SConnecting = 'Connecting...';
  SAwaitingResponse = 'Awaiting response...';
  SUploading = 'Uploading...';
  SDownloading = 'Downloading...';
  SError = 'Error!';
  SDone = 'Done!';
  SInterrupted = 'Interrupted!';
  SSound='Sound';

const
  CAudioBufferSize=64*1024;

  CRX5BankSize=128*1024;
  CRX5BankHeaderSize=1024;
  CRX5SoundEntrySize=32;
  CRX5MaxNumSoundEntries=30;

  CRX5SoundFormatBPS:array[TRX5SoundFormat] of Integer = (0,8,12);

  CRX5BasePitch=360;
  CRX5BaseSampleRate=25000;

  CRX5BankToAddress:array[TRX5BankIndex] of Integer = (-1,0*CRX5BankSize,1*CRX5BankSize,2*CRX5BankSize,3*CRX5BankSize);
  CRX5StatusText:array[TRX5ProgressStatus] of PResStringRec = (@SIdle,@SConnecting,@SAwaitingResponse,@SUploading,@SDownloading,@SError,@SDone,@SInterrupted);

function GetPCMLength(ASize,ASampleRate,ABitsPerSample:Integer):TDateTime;
function GetPCMSize(ALength:TDateTime;ASampleRate,ABitsPerSample:Integer):Integer;

function RX5_8To16Bit(AData:Byte):Word;
procedure RX5_12To16Bit(AData1,AData2,AData3:Byte; out AOut1,AOut2:Word);

function RX5_16To8Bit(AData:Word):Byte;
procedure RX5_16To12Bit(AData1,AData2:Word; out AOut1,AOut2,AOut3:Byte);

function RX5_Checksum(APtr:PByte;ASize:Integer):Word;

implementation

function GetPCMLength(ASize, ASampleRate, ABitsPerSample: Integer): TDateTime;
begin
  Result:=0;
  if (ASize=0) or (ASampleRate=0) or (ABitsPerSample=0) then
    Exit;

  Result:=abs(ASize/((ABitsPerSample/8.0)*ASampleRate*SecsPerDay));
end;

function GetPCMSize(ALength: TDateTime; ASampleRate, ABitsPerSample: Integer
  ): Integer;
begin
  Result:=ceil(ALength*SecsPerDay*ASampleRate*(ABitsPerSample/8.0));
end;

function RX5_8To16Bit(AData: Byte): Word;
var si:ShortInt absolute AData;
    so:SmallInt absolute Result;
begin
  so:=si*256;
end;

procedure RX5_12To16Bit(AData1,AData2,AData3:Byte; out AOut1,AOut2:Word);
var si1:SmallInt absolute AOut1;
    si2:SmallInt absolute AOut2;
begin
  si1:=(AData2 shl 8) or ((AData1 and $0f) shl 4);
  si2:=(AData3 shl 8) or ((AData1 shr 4) shl 4);
end;

function RX5_16To8Bit(AData: Word): Byte;
var so:ShortInt absolute Result;
begin
  so:=AData div 256;
end;

procedure RX5_16To12Bit(AData1, AData2: Word; out AOut1, AOut2, AOut3: Byte);
begin
  AOut2:=(AData1 shr 8) and $ff;
  AOut3:=(AData2 shr 8) and $ff;
  AOut1:=(((AData2 shr 4) and $0f) shl 4) or ((AData1 shr 4) and $0f);
end;

function RX5_Checksum(APtr: PByte; ASize: Integer): Word;
var i:Integer;
begin
  Result:=0;
  for i:=0 to ASize-1 do
  begin
    Result:=Result+APtr^;
    inc(APtr);
  end;
  Result:=((Result shr 8) and $ff) or (Result shl 8);
end;

{ TRX5Sound }

function TRX5Sound.GetFinalPCMSize: Integer;
begin
  if RawMode then
    Result:=Length(FFinalPCM)
  else
    Result:=GetPCMSize(GetSourceLength,SampleRate,BitsPerSample);
end;

function TRX5Sound.GetFinalLength: TDateTime;
begin
  Result:=GetPCMLength(FinalPCMSize,SampleRate,BitsPerSample);
end;

function TRX5Sound.GetPitch: Integer;
begin
  Result:=FOctave * 120 + FNote - CRX5BasePitch;
end;

function TRX5Sound.GetSampleRate: Integer;
begin
  Result:=round(power(2.0,Pitch/120.0)*CRX5BaseSampleRate);
end;

function TRX5Sound.GetSourceBitsPerSample: Integer;
begin
  Result:=FSourceFormat and $1f;
end;

function TRX5Sound.GetSourceLength: TDateTime;
begin
  Result:=GetPCMLength(SourcePCMSize,SourceSampleRate,SourceBitsPerSample);
end;

function TRX5Sound.GetSourcePCMSize: Integer;
begin
  Result:=Length(FSourcePCM);
end;

procedure TRX5Sound.SetPitch(AValue: Integer);
begin
  AValue:=AValue+CRX5BasePitch;

  FOctave:=AValue div 120;
  FNote:=AValue mod 120;
end;

procedure TRX5Sound.SetRawMode(AValue: Boolean);
begin
  if FRawMode=AValue then Exit;

  if not AValue then
    SetLength(FFinalPCM,0);

  FRawMode:=AValue;
end;

procedure TRX5Sound.FreeData;
begin
  SetLength(FSourcePCM,0);
  SetLength(FFinalPCM,0);
end;

function TRX5Sound.GetBitsPerSample: Integer;
begin
  Result:=CRX5SoundFormatBPS[Format];
end;

constructor TRX5Sound.Create;
begin
  FRawMode:=True;

  FOctave:=2;
  FNote:=120;

  FFormat:=rsfPCM8;
  FLevel:=27;

  FEnvAttackRate:=$63;
  FEnvDecay1Rate:=$02;
  FEnvReleaseRate:=$3c;
  FEnvDecay2Rate:=$63;
  FEnvDecay1Level:=$3b;
  FEnvGateTime:=$5c;

  FUnk:=$63;

  FName:=SSound;
end;

destructor TRX5Sound.Destroy;
begin
  FreeData;

  inherited Destroy;
end;

procedure TRX5Sound.ImportFromBankData(AStream: TStream;
  AHeaderEntryOffset: Integer);
var pcmStart,pcmSize:Cardinal;
    b1,b2,b3:Byte;
    n:array[0..5] of char;
begin
  FreeData;

  AStream.Seek(AHeaderEntryOffset,soFromBeginning);

  FOctave:=AStream.ReadByte;
  FNote:=AStream.ReadByte;

  FFormat:=rsfPCM8;
  if AStream.ReadByte=$01 then FFormat:=rsfPCM12;

  b1:=AStream.ReadByte;
  b2:=AStream.ReadByte;

  FLoopEnable:=(b1 and $40)=0;

  pcmStart:=((b1 and $01) shl 16) or (b2 shl 8);

  b1:=AStream.ReadByte;
  b2:=AStream.ReadByte;
  b3:=AStream.ReadByte;

  FLoopStart:=(((b1 and $01) shl 16) or (b2 shl 8) or b3) - pcmStart;

  b1:=AStream.ReadByte;
  b2:=AStream.ReadByte;
  b3:=AStream.ReadByte;

  FLoopEnd:=(((b1 and $01) shl 16) or (b2 shl 8) or b3) - pcmStart;

  b1:=AStream.ReadByte;
  b2:=AStream.ReadByte;
  b3:=AStream.ReadByte;

  pcmSize:=(((b1 and $01) shl 16) or (b2 shl 8) or b3) - pcmStart;

  FEnvAttackRate:=AStream.ReadByte;
  FEnvDecay1Rate:=AStream.ReadByte; // TODO: format?
  FEnvReleaseRate:=AStream.ReadByte;
  FEnvDecay2Rate:=AStream.ReadByte; // TODO: format?
  FEnvDecay1Level:=AStream.ReadByte;
  FEnvGateTime:=AStream.ReadByte; // TODO: index in an array

  FBendRate:=AStream.ReadByte; // TODO: just a supposition...
  FBendRange:=AStream.ReadByte; // TODO: just a supposition...

  FUnk:=AStream.ReadByte; // TODO: pitch maybe?

  FLevel:=AStream.ReadByte;
  FChannel:=AStream.ReadByte;

  b1:=AStream.ReadByte;

  Assert(b1=$00);

  n[0]:=#0;

  AStream.ReadBuffer(n,length(n));

  SetLength(FFinalPCM,pcmSize);

  AStream.Seek(pcmStart,soFromBeginning);

  AStream.ReadBuffer(FFinalPCM[0],pcmSize);

  FName:=TrimRight(n);
  FRawMode:=True;
end;

procedure TRX5Sound.ImportFromFile(AFileName: String);
var pss:PSound_Sample;
    pos,sz:Integer;
begin
  pss:=Sound_NewSampleFromFile(PChar(AFileName),nil,CAudioBufferSize);
  if pss=nil then
    raise ERX5Error.Create(Sound_GetError);

  pos:=0;
  while true do
  begin
    sz:=Sound_Decode(pss);
    if sz<=0  then
      Break;

    SetLength(FSourcePCM,pos+sz);
    Move(pss^.buffer^,FSourcePCM[pos],sz);

    pos:=pos+sz;
  end;

  FSourceSampleRate:=pss^.actual.rate;
  FSourceFormat:=pss^.actual.format;
  FSourceChannels:=pss^.actual.channels;

  FRawMode:=False;
  FName:=Copy(ChangeFileExt(ExtractFileName(AFileName),''),1,6);

  Sound_FreeSample(pss);
end;

procedure TRX5Sound.ExportHeaderToStream(AStream: TStream;
  APCMDataOffset: Integer);
var b1,b2,b3:Byte;
    start,off:Integer;
    n:array[0..5] of AnsiChar;
begin
  start:=AStream.Position;

  AStream.WriteByte(FOctave);
  AStream.WriteByte(FNote);
  AStream.WriteByte(ifthen(Format=rsfPCM12,$01,$00));

  Assert(APCMDataOffset and $ff = 0);

  b1:=ifthen(LoopEnable,$00,$40);
  b1:=b1 or ((APCMDataOffset shr 16) and 1);
  b2:=APCMDataOffset shr 8;

  AStream.WriteByte(b1);
  AStream.WriteByte(b2);

  off:=LoopStart+APCMDataOffset;

  b1:=((off shr 16) and 1);
  b2:=off shr 8;
  b3:=off;

  AStream.WriteByte(b1);
  AStream.WriteByte(b2);
  AStream.WriteByte(b3);

  off:=LoopEnd+APCMDataOffset;

  b1:=((off shr 16) and 1);
  b2:=off shr 8;
  b3:=off;

  AStream.WriteByte(b1);
  AStream.WriteByte(b2);
  AStream.WriteByte(b3);

  off:=FinalPCMSize+APCMDataOffset;

  b1:=((off shr 16) and 1);
  b2:=off shr 8;
  b3:=off;

  AStream.WriteByte(b1);
  AStream.WriteByte(b2);
  AStream.WriteByte(b3);

  AStream.WriteByte(FEnvAttackRate);
  AStream.WriteByte(FEnvDecay1Rate);
  AStream.WriteByte(FEnvReleaseRate);
  AStream.WriteByte(FEnvDecay2Rate);
  AStream.WriteByte(FEnvDecay1Level);
  AStream.WriteByte(FEnvGateTime);

  AStream.WriteByte(FBendRate);
  AStream.WriteByte(FBendRange);

  AStream.WriteByte(FUnk);

  AStream.WriteByte(FLevel);
  AStream.WriteByte(FChannel);

  AStream.WriteByte(0);

  n:='      ';
  Move(Name[1],n[0],Length(Name));

  AStream.WriteBuffer(n[0],6);

  Assert(AStream.Position-start=CRX5SoundEntrySize);
end;

procedure TRX5Sound.ExportPreviewPCMToStream(AStream: TStream);
var b1,b2,b3:Byte;
    w1,w2:Word;

    ms:TMemoryStream;
begin
  ms:=TMemoryStream.Create;
  try
    ExportRawPCMToStream(ms);

    ms.Seek(0,soFromBeginning);

    if Format=rsfPCM8 then
    begin
      while ms.Position<ms.Size do
      begin
        b1:=ms.ReadByte;

        w1:=RX5_8To16Bit(b1);

        AStream.WriteWord(w1);
      end;
    end
    else if Format=rsfPCM12 then
    begin
      ms.ReadByte; // 12bit mode has a 1 byte latency

      while ms.Position<ms.Size do
      begin
        b1:=ms.ReadByte;
        b2:=0;
        if ms.Position<ms.Size then
          b2:=ms.ReadByte;
        b3:=0;
        if ms.Position<ms.Size then
          b3:=ms.ReadByte;

        RX5_12To16Bit(b1,b2,b3,w1,w2);

        AStream.WriteWord(w1);
        AStream.WriteWord(w2);
      end;
    end
    else
      raise ERX5Error.Create(SUnknownFormat);

  finally
    ms.Free;
  end;
end;

procedure TRX5Sound.ExportRawPCMToStream(AStream: TStream);
var cvt:TSDL_AudioCVT;
    dstFmt:Integer;
    buf:PByte;

    b1,b2,b3:Byte;
    w1,w2:Word;

    pw,pwe:PWord;
    pb,pbe:PByte;
begin
  if RawMode then
  begin
    if FinalPCMSize=0 then
      Exit;

    AStream.Write(FFinalPCM[0],FinalPCMSize);

    Exit;
  end;

  dstFmt:=AUDIO_U8;
  if Format=rsfPCM12 then
    dstFmt:=AUDIO_S16;

  cvt.buf:=nil;
  FillChar(cvt,sizeof(cvt),0);

  if SDL_BuildAudioCVT(@cvt,FSourceFormat,FSourceChannels,FSourceSampleRate,dstFmt,1,SampleRate)<0 then
    raise ERX5Error.Create(SPCMConvertError);

  cvt.len:=SourcePCMSize;
  buf:=GetMemory(max(cvt.len,cvt.len*cvt.len_mult));
  try
    cvt.buf:=buf;
    Move(FSourcePCM[0],buf^,cvt.len);

    if SDL_ConvertAudio(@cvt)<0 then
      raise ERX5Error.Create(SPCMConvertError);

    if Format=rsfPCM12 then
    begin
      AStream.WriteByte(0); // 12bit mode has a 1 byte latency

      pw:=PWord(buf);
      pwe:=PWord(@buf[cvt.len_cvt]);
      while pw<pwe do
      begin
        w1:=pw^;
        Inc(pw);

        w2:=0;
        if pw<pwe then
        begin
          w2:=pw^;
          Inc(pw);
        end;

        RX5_16To12Bit(w1,w2,b1,b2,b3);

        AStream.WriteByte(b1);
        AStream.WriteByte(b2);
        AStream.WriteByte(b3);
      end;
    end
    else
    begin
      pb:=PByte(buf);
      pbe:=PByte(@buf[cvt.len_cvt]);
      while pb<pbe do
      begin
        b1:=pb^;
        Inc(pb);
        AStream.WriteByte(b1-128);
      end;
    end;
  finally
    Freememory(buf);
  end;
end;

{ TRX5Sounds }

function TRX5Sounds.GetItem(Index: Integer): TRX5Sound;
begin
  Result:=(inherited Items[Index]) as TRX5Sound;
end;

{ TRX5Bank }

function TRX5Bank.GetProjectedSize: Integer;
var i:Integer;
begin
  Result:=CRX5BankHeaderSize;

  for i:=0 to Sounds.Count-1 do
  begin
    Result:=Result+Sounds[i].FinalPCMSize;
    Result:=((Result+255) shr 8) shl 8;
  end;
end;

constructor TRX5Bank.Create;
begin
  FSounds:=TRX5Sounds.create(True);
  Clear;
end;

destructor TRX5Bank.Destroy;
begin
  FSounds.Free;

  inherited Destroy;
end;

procedure TRX5Bank.Clear;
begin
  FGenerateBankID:=True;
  FBankID:=$10;
  Sounds.Clear;
end;

procedure TRX5Bank.ImportFromFile(AFileName: String);
var fs:TFileStream;
    s:TRX5Sound;
    i,cnt:Integer;
begin
  Clear;

  fs:=TFileStream.Create(AFileName,fmOpenRead or fmShareDenyWrite);
  try
    cnt:=fs.Size;
    if (cnt<>CRX5BankSize) or (fs.ReadDWord<>$00000000) then
      raise ERX5Error.Create(SNotABankFile);

    FBankID:=fs.ReadByte;

    cnt:=fs.ReadByte;

    for i:=0 to cnt-1 do
    begin
      s:=TRX5Sound.Create;
      s.ImportFromBankData(fs,i*CRX5SoundEntrySize+6);
      Sounds.Add(s);
    end;

  finally
    fs.Free;
  end;
end;

procedure TRX5Bank.ExportToFile(AFileName: String);
var fs:TFileStream;
begin
  fs:=TFileStream.Create(AFileName,fmCreate or fmShareDenyWrite);
  try
    ExportToStream(fs);
  finally
    fs.Free;
  end;
end;

procedure TRX5Bank.ExportToStream(AStream: TStream);
var hms:TMemoryStream;
    i,cnt:Integer;
    header:array[0..CRX5BankHeaderSize-3] of Byte;
    cs:Word;
begin
  hms:=TMemoryStream.Create;
  try
    hms.WriteDWord($00000000);
    hms.WriteByte(FBankId);
    hms.WriteByte(Sounds.Count);

    while AStream.Size<CRX5BankHeaderSize do
      AStream.WriteQWord(0);

    for i:=0 to Sounds.Count-1 do
    begin
      Sounds[i].ExportHeaderToStream(hms,AStream.Position);
      Sounds[i].ExportRawPCMToStream(AStream);
      cnt:=((AStream.Size+255) shr 8) shl 8;
      while AStream.Size<cnt do
        AStream.WriteByte(0);
    end;

    while AStream.Size<CRX5BankSize do
      AStream.WriteByte(0);

    header[0]:=0;
    FillChar(header,Length(header),0);
    hms.Seek(0,soFromBeginning);
    hms.ReadBuffer(header,Min(Length(header),hms.Size));
    cs:=RX5_Checksum(@header[0],Length(header));

    if GenerateBankId then
    begin
      header[4]:=(cs and $ff) xor ((cs shr 8) and $ff); // hash of header checksum
      cs:=RX5_Checksum(@header[0],Length(header));
    end;

    AStream.Seek(0,soFromBeginning);
    AStream.WriteBuffer(header,Length(header));
    AStream.WriteWord(cs);
  finally
    hms.Free;
  end;
end;


{ TRX5Banks }

function TRX5Banks.GetItem(Index: Integer): TRX5Bank;
begin
  Result:=(inherited Items[Index]) as TRX5Bank;
end;

{ TRX5Cartridge }

type
  TRX5HIDHeader=packed record
    ID:array[0..2] of AnsiChar;
    Version:Byte;
    Address:Cardinal;
    Size:Cardinal;
    Response:array[0..1] of AnsiChar;
    Padding:array[14..63] of Byte;
  end;

function TRX5Cartridge.Progress(AStatus: TRX5ProgressStatus; APosition,
  AMax: Integer): Boolean;
begin
  Result:=True;
  FStatus:=AStatus;
  if Assigned(OnProgress) then Result:=OnProgress(APosition,AMax);
end;

procedure TRX5Cartridge.Upload(APStream: TStream);
const
  CRX5HIDTimeout=1000; //ms
  CRX5HIDWaitLoop=50; //ms

var res:Integer;
    hdr:TRX5HIDHeader;
    sendBuf,recvBuf:array[0..63] of Byte;
begin
  Assert(SizeOf(recvBuf)=SizeOf(hdr));

  sendBuf[0]:=0;

  // try to connect until it succeeds

  repeat
    if not Progress(rpsConnecting,-1,-1) then
    begin
      FStatus:=rpsInterrupted;
      Exit;
    end;
    res:=rawhid_open(1, $6112, $5550, $FFAB, $0200);
    Sleep(CRX5HIDWaitLoop);
  until res>0;

  try
    // send header

    hdr.ID[0]:='R';
    hdr.ID[1]:='X';
    hdr.ID[2]:='5';

    hdr.Version:=1;

    hdr.Response[0]:='?';
    hdr.Response[1]:='?';

    hdr.Address:=CRX5BankToAddress[BankIndex];
    hdr.Size:=APStream.Size;

    res:=rawhid_send(0,@hdr,SizeOf(hdr),CRX5HIDTimeout);

    if res<=0 then
    begin
      Progress(rpsError,1,1);
      Exit;
    end;

    // await ack (header sent back)

    hdr.Response[0]:='O';
    hdr.Response[1]:='K';

    repeat
      if not Progress(rpsAwaitingResponse,-1,-1) then
      begin
        FStatus:=rpsInterrupted;
        Exit;
      end;
      res:=rawhid_recv(0,@recvBuf,SizeOf(recvBuf),CRX5HIDWaitLoop);
    until res>0;

    if not CompareMem(@recvBuf,@hdr,sizeof(hdr)) then
    begin
      Progress(rpsError,1,1);
      Exit;
    end;

    // program loop

    repeat

      // send packet

      APStream.Read(sendBuf,SizeOf(sendBuf));
      res:=rawhid_send(0,@sendBuf,SizeOf(sendBuf),CRX5HIDTimeout);

      if res<=0 then
      begin
        Progress(rpsError,1,1);
        Exit;
      end;

      // recv packet

      res:=rawhid_recv(0,@recvBuf,SizeOf(recvBuf),CRX5HIDTimeout);

      if (res<=0) or not CompareMem(@recvBuf,@sendBuf,sizeof(sendBuf)) then
      begin
        Progress(rpsError,1,1);
        Exit;
      end;

      if (APStream.Position and 1023)=0 then
        if not Progress(rpsUploading,APStream.Position,hdr.Size) then
        begin
          FStatus:=rpsInterrupted;
          Exit;
        end;

    until APStream.Position>=hdr.Size;

    Progress(rpsDone,1,1);
  finally
    rawhid_close(0);
  end;
end;

{ TRX5Library }

constructor TRX5Library.Create;
begin
  FBanks:=TRX5Banks.create(True);
end;

destructor TRX5Library.Destroy;
begin
  FBanks.Free;

  inherited Destroy;
end;

end.



