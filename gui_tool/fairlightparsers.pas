unit fairlightparsers;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, strutils, types, contnrs, math;

type

  { TCMISample }

  TCMISample=class
  private
    FLoopEnable: Boolean;
    FLoopEnd: Integer;
    FLoopStart: Integer;
    FName: String;
    FPCMData: TByteDynArray;
    FSampleRate: Integer;
    function GetPCMLength: Integer;
  public
    property Name:String read FName write FName;
    property SampleRate:Integer read FSampleRate write FSampleRate;
    property PCMData:TByteDynArray read FPCMData write FPCMData;
    property PCMLength:Integer read GetPCMLength;
    property LoopEnable:Boolean read FLoopEnable write FLoopEnable;
    property LoopStart:Integer read FLoopStart write FLoopStart;
    property LoopEnd:Integer read FLoopEnd write FLoopEnd;
  end;

  { TCMISamples }

  TCMISamples = class(TObjectList)
  private
    function GetItem(Index: Integer): TCMISample;
  public
    property Items[Index: Integer]: TCMISample read GetItem; default;
  end;


  { TCMI2xDiskParser }

  TCMI2xDiskParser = class
  private
    FSamples: TCMISamples;

	public
    constructor Create;
    destructor Destroy;override;

    procedure ImportFromRawDiskData(AStream:TStream);
    procedure ImportFromIMDStream(AStream:TStream);
    procedure ImportFromIMDFile(AFilename:String);

    property Samples:TCMISamples read FSamples;
  end;


function ConvertIMDToBinary(ASource,ADest:TStream;var ADescription:string):Boolean;

implementation

const
  CCMI2xSectorSize=128;
  CCMI2xDiskSize=512512;

function ConvertIMDToBinary(ASource,ADest:TStream;var ADescription:string):Boolean;
var hdr:AnsiString;
    b1,b2:Byte;
    i,j,secCnt,start:Integer;
    secBuf:array[0..CCMI2xSectorSize-1] of Byte;
    secMap:array of Byte;
begin
  Result:=False;
  ADescription:='';

  hdr:='';
  b1:=0;
  secBuf[0]:=0;

  while ASource.Position<ASource.Size do
  begin
    b1:=ASource.ReadByte;
    if b1=$1a then
       Break;

    hdr:=hdr+chr(b1);
  end;

  if (b1<>$1a) or not AnsiStartsStr('IMD',hdr) then Exit;

  ADescription:=hdr;

  while ASource.Position<ASource.Size do
  begin
     ASource.ReadByte; // mode
     ASource.ReadByte; // cylinder
     b2:=ASource.ReadByte; // head
     secCnt:=ASource.ReadByte; // sector count
     b1:=ASource.ReadByte; // sector size

     Assert(b1=$00);

     SetLength(secMap,secCnt);

     ASource.ReadBuffer(secMap[0],secCnt);

     if (b2 and $40)<>0 then
     		ASource.Seek(secCnt,soFromCurrent);
     if (b2 and $80)<>0 then
     		ASource.Seek(secCnt,soFromCurrent);

     start:=ADest.Position;

     for i:=0 to secCnt-1 do
     begin
       ADest.Seek(start+(secMap[i]-1)*CCMI2xSectorSize,soFromBeginning);

       b1:=ASource.ReadByte;
       if b1=$01 then
       begin
         ASource.ReadBuffer(secBuf,length(secBuf));
         ADest.WriteBuffer(secBuf,length(secBuf));
       end
       else if b1=$02 then // 'compressed'
       begin
         b2:=ASource.ReadByte;
         for j:=0 to CCMI2xSectorSize-1 do
           ADest.WriteByte(b2);
       end
       else
         Assert(False);
     end;

     ADest.Seek(start+secCnt*CCMI2xSectorSize,soFromBeginning);
  end;

  Result:=True;
end;

{ TCMI2xDiskParser }

type
  TCMI2xFileEntry=packed record
    FileName:array[0..7] of AnsiChar;
    Extension:array[0..1] of AnsiChar;
    StartSectorHi,StartSectorLo:Byte;
    Valid:Byte; // 0x10 when valid
    Padding:array[13..15] of Byte;
  end;

constructor TCMI2xDiskParser.Create;
begin
  FSamples:=TCMISamples.Create;
end;

destructor TCMI2xDiskParser.Destroy;
begin
	FSamples.Free;
  inherited Destroy;
end;

procedure TCMI2xDiskParser.ImportFromRawDiskData(AStream: TStream);
const
    CVCFilePCMOffset=$1480;
    CVCFilePCMSize=16384;
    CVCFileParamsOffset=$12b2;

var entries: array[0..159] of TCMI2xFileEntry;
    entry:TCMI2xFileEntry;
    entriesCount:Integer;
    vcStart,sector,pcmSize:Integer;
    i:Integer;
    s:TCMISample;
begin
  AStream.Seek($180,soFromBeginning);

  entriesCount:=0;
  entry.FileName:='';
  for i:=0 to High(entries) do
  begin
    AStream.ReadBuffer(entry,sizeof(TCMI2xFileEntry));
    if (entry.Valid<>$10) or (entry.FileName[0]=char($ff)) then Continue;
    entries[entriesCount]:=entry;
    Inc(entriesCount);
  end;

  for i:=0 to entriesCount-1 do
  begin
    entry:=entries[i];

    if entry.Extension='VC' then
    begin
      sector:=(entry.StartSectorHi<<8) or entry.StartSectorLo;
      vcStart:=sector*CCMI2xSectorSize+2*CCMI2xSectorSize;

      s:=TCMISample.Create;

      s.Name:=TrimRight(entry.FileName);

    	AStream.Seek(vcStart+CVCFileParamsOffset,soFromBeginning);

      s.LoopStart:=AStream.ReadByte*CCMI2xSectorSize;
      s.LoopEnd:=(AStream.ReadByte+1)*CCMI2xSectorSize;

      AStream.Seek(7,soFromCurrent);

      s.LoopEnable:=AStream.ReadByte<>$00;

      AStream.Seek(vcStart+CVCFilePCMOffset,soFromBeginning);

      pcmSize:=CVCFilePCMSize;

      SetLength(s.FPCMData,pcmSize);

      AStream.ReadBuffer(s.FPCMData[0],pcmSize);

      // remove end silence
      while (pcmSize>0) and (s.FPCMData[pcmSize-1]=$80) do
        Dec(pcmSize);

      s.LoopStart:=Min(s.LoopStart,pcmSize);
      s.LoopEnd:=Min(s.LoopEnd,pcmSize);

      SetLength(s.FPCMData,pcmSize);

      Samples.Add(s);
    end;
  end;
end;

procedure TCMI2xDiskParser.ImportFromIMDStream(AStream: TStream);
var ms:TMemoryStream;
    desc:String;
begin
  ms:=TMemoryStream.Create;
  try
    desc:='';

    if not ConvertIMDToBinary(AStream,ms,desc) then
      Exit;

    if ms.Size<>CCMI2xDiskSize then
      Exit;

    ms.Seek(0,soFromBeginning);

    ImportFromRawDiskData(ms);
  finally
  	ms.Free;
  end;
end;

procedure TCMI2xDiskParser.ImportFromIMDFile(AFilename: String);
var fs:TFileStream;
begin
  fs:=TFileStream.Create(AFilename, fmOpenRead or fmShareDenyNone);
  try
    ImportFromIMDStream(fs);
  finally
  	fs.Free;
  end;
end;

{ TCMISample }

function TCMISample.GetPCMLength: Integer;
begin
  Result:=Length(FPCMData);
end;

{ TCMISamples }

function TCMISamples.GetItem(Index: Integer): TCMISample;
begin
  Result:=(inherited Items[Index]) as TCMISample;
end;

end.
