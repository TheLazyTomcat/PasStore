{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  MD4 Hash Calculation

  ©František Milt 2017-07-18

  Version 1.3.6

  Dependencies:
    AuxTypes    - github.com/ncs-sniper/Lib.AuxTypes
    StrRect     - github.com/ncs-sniper/Lib.StrRect
    BitOps      - github.com/ncs-sniper/Lib.BitOps
  * SimpleCPUID - github.com/ncs-sniper/Lib.SimpleCPUID

  SimpleCPUID might not be needed, see BitOps library for details.

===============================================================================}
unit MD4;

{$DEFINE LargeBuffer}

{$IFDEF ENDIAN_BIG}
  {$MESSAGE FATAL 'Big-endian system not supported'}
{$ENDIF}

{$IFOPT Q+}
  {$DEFINE OverflowCheck}
{$ENDIF}

{$IFDEF FPC}
  {$MODE ObjFPC}{$H+}
  {$DEFINE FPC_DisableWarns}
{$ENDIF}

interface

uses
  Classes, AuxTypes;

type
  TMD4Hash = record
    PartA:  UInt32;
    PartB:  UInt32;
    PartC:  UInt32;
    PartD:  UInt32;
  end;
  PMD4Hash = ^TMD4Hash;

const
  InitialMD4: TMD4Hash = (
    PartA:  $67452301;
    PartB:  $EFCDAB89;
    PartC:  $98BADCFE;
    PartD:  $10325476);

  ZeroMD4: TMD4Hash = (PartA: 0; PartB: 0; PartC: 0; PartD: 0);

Function MD4toStr(Hash: TMD4Hash): String;
Function StrToMD4(Str: String): TMD4Hash;
Function TryStrToMD4(const Str: String; out Hash: TMD4Hash): Boolean;
Function StrToMD4Def(const Str: String; Default: TMD4Hash): TMD4Hash;
Function SameMD4(A,B: TMD4Hash): Boolean;
Function BinaryCorrectMD4(Hash: TMD4Hash): TMD4Hash;

procedure BufferMD4(var Hash: TMD4Hash; const Buffer; Size: TMemSize); overload;
Function LastBufferMD4(Hash: TMD4Hash; const Buffer; Size: TMemSize; MessageLength: UInt64): TMD4Hash; overload;
Function LastBufferMD4(Hash: TMD4Hash; const Buffer; Size: TMemSize): TMD4Hash; overload;

Function BufferMD4(const Buffer; Size: TMemSize): TMD4Hash; overload;

Function AnsiStringMD4(const Str: AnsiString): TMD4Hash;
Function WideStringMD4(const Str: WideString): TMD4Hash;
Function StringMD4(const Str: String): TMD4Hash;

Function StreamMD4(Stream: TStream; Count: Int64 = -1): TMD4Hash;
Function FileMD4(const FileName: String): TMD4Hash;

//------------------------------------------------------------------------------

type
  TMD4Context = type Pointer;

Function MD4_Init: TMD4Context;
procedure MD4_Update(Context: TMD4Context; const Buffer; Size: TMemSize);
Function MD4_Final(var Context: TMD4Context; const Buffer; Size: TMemSize): TMD4Hash; overload;
Function MD4_Final(var Context: TMD4Context): TMD4Hash; overload;
Function MD4_Hash(const Buffer; Size: TMemSize): TMD4Hash;


implementation

uses
  SysUtils, Math, BitOps, StrRect;

{$IFDEF FPC_DisableWarns}
  {$WARN 4055 OFF} // Conversion between ordinals and pointers is not portable
  {$WARN 4056 OFF} // Conversion between ordinals and pointers is not portable
  {$IF Defined(FPC) and (FPC_FULLVERSION >= 30000)}
    {$WARN 5092 OFF} // Variable "$1" of a managed type does not seem to be initialized
  {$IFEND}
{$ENDIF}

const
  ChunkSize       = 64;                           // 512 bits
{$IFDEF LargeBuffers}
  ChunksPerBuffer = 16384;                        // 1MiB BufferSize
{$ELSE}
  ChunksPerBuffer = 64;                           // 4KiB BufferSize
{$ENDIF}
  BufferSize      = ChunksPerBuffer * ChunkSize;  // size of read buffer

  ShiftCoefs: array[0..47] of UInt8 = (
    3,  7, 11, 19,  3,  7, 11, 19,  3,  7, 11, 19,  3,  7, 11, 19,
    3,  5,  9, 13,  3,  5,  9, 13,  3,  5,  9, 13,  3,  5,  9, 13,
    3,  9, 11, 15,  3,  9, 11, 15,  3,  9, 11, 15,  3,  9, 11, 15);

  RoundConsts: array[0..2] of UInt32 = ($0, $5A827999, $6ED9EBA1);

  IndexConsts: array[0..47] of UInt8 = (
    0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15,
    0,  4,  8, 12,  1,  5,  9, 13,  2,  6, 10, 14,  3,  7, 11, 15,
    0,  8,  4, 12,  2, 10,  6, 14,  1,  9,  5, 13,  3, 11,  7, 15);

type
  TChunkBuffer = array[0..ChunkSize - 1] of UInt8;
  PChunkBuffer = ^TChunkBuffer;

  TMD4Context_Internal = record
    MessageHash:    TMD4Hash;
    MessageLength:  UInt64;
    TransferSize:   UInt32;
    TransferBuffer: TChunkBuffer;
  end;
  PMD4Context_Internal = ^TMD4Context_Internal;

//==============================================================================

Function ChunkHash(Hash: TMD4Hash; const Chunk): TMD4Hash;
var
  i:              Integer;
  Temp:           UInt32;
  FuncResult:     UInt32;
  RoundConstant:  UInt32;
  ChunkWords:     array[0..15] of UInt32 absolute Chunk;
begin
Result := Hash;
For i := 0 to 47 do
  begin
    case i of
       0..15: begin
                FuncResult := (Hash.PartB and Hash.PartC) or ((not Hash.PartB) and Hash.PartD);
                RoundConstant := RoundConsts[0];
              end;
      16..31: begin
                FuncResult := (Hash.PartB and Hash.PartC) or (Hash.PartB and Hash.PartD) or (Hash.PartC and Hash.PartD);
                RoundConstant := RoundConsts[1];
              end;
    else
      {32..47:} FuncResult := Hash.PartB xor Hash.PartC xor Hash.PartD;
                RoundConstant := RoundConsts[2];
    end;
    Temp := Hash.PartD;
    Hash.PartD := Hash.PartC;
    Hash.PartC := Hash.PartB;
    {$IFDEF OverflowCheck}{$Q-}{$ENDIF}
    Hash.PartB := ROL(UInt32(Hash.PartA + FuncResult + ChunkWords[IndexConsts[i]] + RoundConstant), ShiftCoefs[i]);
    {$IFDEF OverflowCheck}{$Q+}{$ENDIF}
    Hash.PartA := Temp;
  end;
{$IFDEF OverflowCheck}{$Q-}{$ENDIF}
Result.PartA := UInt32(Result.PartA + Hash.PartA);
Result.PartB := UInt32(Result.PartB + Hash.PartB);
Result.PartC := UInt32(Result.PartC + Hash.PartC);
Result.PartD := UInt32(Result.PartD + Hash.PartD);
{$IFDEF OverflowCheck}{$Q+}{$ENDIF}
end;

//==============================================================================

Function MD4toStr(Hash: TMD4Hash): String;
var
  HashArray:  array[0..15] of UInt8 absolute Hash;
  i:          Integer;
begin
Result := StringOfChar('0',32);
For i := Low(HashArray) to High(HashArray) do
  begin
    Result[(i * 2) + 2] := IntToHex(HashArray[i] and $0F,1)[1];
    Result[(i * 2) + 1] := IntToHex(HashArray[i] shr 4,1)[1];
  end;
end;

//------------------------------------------------------------------------------

Function StrToMD4(Str: String): TMD4Hash;
var
  HashArray:  array[0..15] of UInt8 absolute Result;
  i:          Integer;
begin
If Length(Str) < 32 then
  Str := StringOfChar('0',32 - Length(Str)) + Str
else
  If Length(Str) > 32 then
    Str := Copy(Str,Length(Str) - 31,32);
For i := 0 to 15 do
  HashArray[i] := StrToInt('$' + Copy(Str,(i * 2) + 1,2));
end;

//------------------------------------------------------------------------------

Function TryStrToMD4(const Str: String; out Hash: TMD4Hash): Boolean;
begin
try
  Hash := StrToMD4(Str);
  Result := True;
except
  Result := False;
end;
end;

//------------------------------------------------------------------------------

Function StrToMD4Def(const Str: String; Default: TMD4Hash): TMD4Hash;
begin
If not TryStrToMD4(Str,Result) then
  Result := Default;
end;

//------------------------------------------------------------------------------

Function SameMD4(A,B: TMD4Hash): Boolean;
begin
Result := (A.PartA = B.PartA) and (A.PartB = B.PartB) and
          (A.PartC = B.PartC) and (A.PartD = B.PartD);
end;

//------------------------------------------------------------------------------

Function BinaryCorrectMD4(Hash: TMD4Hash): TMD4Hash;
begin
Result := Hash;
end;

//==============================================================================

procedure BufferMD4(var Hash: TMD4Hash; const Buffer; Size: TMemSize);
var
  i:    TMemSize;
  Buff: PChunkBuffer;
begin
If Size > 0 then
  begin
    If (Size mod ChunkSize) = 0 then
      begin
        Buff := @Buffer;
        For i := 0 to Pred(Size div ChunkSize) do
          begin
            Hash := ChunkHash(Hash,Buff^);
            Inc(Buff);
          end;
      end
    else raise Exception.CreateFmt('BufferMD4: Buffer size is not divisible by %d.',[ChunkSize]);
  end;
end;

//------------------------------------------------------------------------------

Function LastBufferMD4(Hash: TMD4Hash; const Buffer; Size: TMemSize; MessageLength: UInt64): TMD4Hash;
var
  FullChunks:     TMemSize;
  LastChunkSize:  TMemSize;
  HelpChunks:     TMemSize;
  HelpChunksBuff: Pointer;
begin
Result := Hash;
FullChunks := Size div ChunkSize;
If FullChunks > 0 then BufferMD4(Result,Buffer,FullChunks * ChunkSize);
LastChunkSize := Size - (UInt64(FullChunks) * ChunkSize);
HelpChunks := Ceil((LastChunkSize + SizeOf(UInt64) + 1) / ChunkSize);
HelpChunksBuff := AllocMem(HelpChunks * ChunkSize);
try
  Move(Pointer(PtrUInt(@Buffer) + (FullChunks * ChunkSize))^,HelpChunksBuff^,LastChunkSize);
  PUInt8(PtrUInt(HelpChunksBuff) + LastChunkSize)^ := $80;
  PUInt64(PtrUInt(HelpChunksBuff) + (UInt64(HelpChunks) * ChunkSize) - SizeOf(UInt64))^ := MessageLength;
  BufferMD4(Result,HelpChunksBuff^,HelpChunks * ChunkSize);
finally
  FreeMem(HelpChunksBuff,HelpChunks * ChunkSize);
end;
end;

//------------------------------------------------------------------------------

Function LastBufferMD4(Hash: TMD4Hash; const Buffer; Size: TMemSize): TMD4Hash;
begin
Result := LastBufferMD4(Hash,Buffer,Size,UInt64(Size) shl 3);
end;

//==============================================================================

Function BufferMD4(const Buffer; Size: TMemSize): TMD4Hash;
begin
Result := LastBufferMD4(InitialMD4,Buffer,Size);
end;

//==============================================================================

Function AnsiStringMD4(const Str: AnsiString): TMD4Hash;
begin
Result := BufferMD4(PAnsiChar(Str)^,Length(Str) * SizeOf(AnsiChar));
end;

//------------------------------------------------------------------------------

Function WideStringMD4(const Str: WideString): TMD4Hash;
begin
Result := BufferMD4(PWideChar(Str)^,Length(Str) * SizeOf(WideChar));
end;

//------------------------------------------------------------------------------

Function StringMD4(const Str: String): TMD4Hash;
begin
Result := BufferMD4(PChar(Str)^,Length(Str) * SizeOf(Char));
end;

//==============================================================================

Function StreamMD4(Stream: TStream; Count: Int64 = -1): TMD4Hash;
var
  Buffer:         Pointer;
  BytesRead:      Integer;
  MessageLength:  UInt64;
begin
If Assigned(Stream) then
  begin
    If Count = 0 then
      Count := Stream.Size - Stream.Position;
    If Count < 0 then
      begin
        Stream.Position := 0;
        Count := Stream.Size;
      end;
    MessageLength := UInt64(Count shl 3);
    GetMem(Buffer,BufferSize);
    try
      Result := InitialMD4;
      repeat
        BytesRead := Stream.Read(Buffer^,Min(BufferSize,Count));
        If BytesRead < BufferSize then
          Result := LastBufferMD4(Result,Buffer^,BytesRead,MessageLength)
        else
          BufferMD4(Result,Buffer^,BytesRead);
        Dec(Count,BytesRead);
      until BytesRead < BufferSize;
    finally
      FreeMem(Buffer,BufferSize);
    end;
  end
else raise Exception.Create('StreamMD4: Stream is not assigned.');
end;

//------------------------------------------------------------------------------

Function FileMD4(const FileName: String): TMD4Hash;
var
  FileStream: TFileStream;
begin
FileStream := TFileStream.Create(StrToRTL(FileName), fmOpenRead or fmShareDenyWrite);
try
  Result := StreamMD4(FileStream);
finally
  FileStream.Free;
end;
end;

//==============================================================================

Function MD4_Init: TMD4Context;
begin
Result := AllocMem(SizeOf(TMD4Context_Internal));
with PMD4Context_Internal(Result)^ do
  begin
    MessageHash := InitialMD4;
    MessageLength := 0;
    TransferSize := 0;
  end;
end;

//------------------------------------------------------------------------------

procedure MD4_Update(Context: TMD4Context; const Buffer; Size: TMemSize);
var
  FullChunks:     TMemSize;
  RemainingSize:  TMemSize;
begin
with PMD4Context_Internal(Context)^ do
  begin
    If TransferSize > 0 then
      begin
        If Size >= (ChunkSize - TransferSize) then
          begin
            Inc(MessageLength,UInt64(ChunkSize - TransferSize) shl 3);
            Move(Buffer,TransferBuffer[TransferSize],ChunkSize - TransferSize);
            BufferMD4(MessageHash,TransferBuffer,ChunkSize);
            RemainingSize := Size - (ChunkSize - TransferSize);
            TransferSize := 0;
            MD4_Update(Context,Pointer(PtrUInt(@Buffer) + (Size - RemainingSize))^,RemainingSize);
          end
        else
          begin
            Inc(MessageLength,UInt64(Size) shl 3);
            Move(Buffer,TransferBuffer[TransferSize],Size);
            Inc(TransferSize,Size);
          end;  
      end
    else
      begin
        Inc(MessageLength,UInt64(Size) shl 3);
        FullChunks := Size div ChunkSize;
        BufferMD4(MessageHash,Buffer,FullChunks * ChunkSize);
        If TMemSize(FullChunks * ChunkSize) < Size then
          begin
            TransferSize := Size - (UInt64(FullChunks) * ChunkSize);
            Move(Pointer(PtrUInt(@Buffer) + (Size - TransferSize))^,TransferBuffer,TransferSize)
          end;
      end;
  end;
end;

//------------------------------------------------------------------------------

Function MD4_Final(var Context: TMD4Context; const Buffer; Size: TMemSize): TMD4Hash;
begin
MD4_Update(Context,Buffer,Size);
Result := MD4_Final(Context);
end;

//------------------------------------------------------------------------------

Function MD4_Final(var Context: TMD4Context): TMD4Hash;
begin
with PMD4Context_Internal(Context)^ do
  Result := LastBufferMD4(MessageHash,TransferBuffer,TransferSize,MessageLength);
FreeMem(Context,SizeOf(TMD4Context_Internal));
Context := nil;
end;

//------------------------------------------------------------------------------

Function MD4_Hash(const Buffer; Size: TMemSize): TMD4Hash;
begin
Result := LastBufferMD4(InitialMD4,Buffer,Size);
end;

end.
