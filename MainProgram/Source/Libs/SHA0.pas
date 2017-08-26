{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  SHA0 Hash Calculation

  ©František Milt 2017-07-18

  Version 1.1.5

  Dependencies:
    AuxTypes    - github.com/ncs-sniper/Lib.AuxTypes
    StrRect     - github.com/ncs-sniper/Lib.StrRect
    BitOps      - github.com/ncs-sniper/Lib.BitOps
  * SimpleCPUID - github.com/ncs-sniper/Lib.SimpleCPUID

  SimpleCPUID might not be needed, see BitOps library for details.

===============================================================================}
unit SHA0;

{$DEFINE LargeBuffer}

{$IFDEF ENDIAN_BIG}
  {$MESSAGE FATAL 'Big-endian system not supported'}
{$ENDIF}

{$IFOPT Q+}
  {$DEFINE OverflowCheck}
{$ENDIF}

{$IFDEF FPC}
  {$MODE ObjFPC}{$H+}
{$ENDIF}

interface

uses
  Classes, AuxTypes;

type
  TSHA0Hash = record
    PartA:  UInt32;
    PartB:  UInt32;
    PartC:  UInt32;
    PartD:  UInt32;
    PartE:  UInt32;
  end;
  PSHA0Hash = ^TSHA0Hash;

const
  InitialSHA0: TSHA0Hash = (
    PartA:  $67452301;
    PartB:  $EFCDAB89;
    PartC:  $98BADCFE;
    PartD:  $10325476;
    PartE:  $C3D2E1F0);

  ZeroSHA0: TSHA0Hash = (PartA: 0; PartB: 0; PartC: 0; PartD: 0; PartE: 0);

Function SHA0toStr(Hash: TSHA0Hash): String;
Function StrToSHA0(Str: String): TSHA0Hash;
Function TryStrToSHA0(const Str: String; out Hash: TSHA0Hash): Boolean;
Function StrToSHA0Def(const Str: String; Default: TSHA0Hash): TSHA0Hash;
Function SameSHA0(A,B: TSHA0Hash): Boolean;
Function BinaryCorrectSHA0(Hash: TSHA0Hash): TSHA0Hash;

procedure BufferSHA0(var Hash: TSHA0Hash; const Buffer; Size: TMemSize); overload;
Function LastBufferSHA0(Hash: TSHA0Hash; const Buffer; Size: TMemSize; MessageLength: UInt64): TSHA0Hash; overload;
Function LastBufferSHA0(Hash: TSHA0Hash; const Buffer; Size: TMemSize): TSHA0Hash; overload;

Function BufferSHA0(const Buffer; Size: TMemSize): TSHA0Hash; overload;

Function AnsiStringSHA0(const Str: AnsiString): TSHA0Hash;
Function WideStringSHA0(const Str: WideString): TSHA0Hash;
Function StringSHA0(const Str: String): TSHA0Hash;

Function StreamSHA0(Stream: TStream; Count: Int64 = -1): TSHA0Hash;
Function FileSHA0(const FileName: String): TSHA0Hash;

//------------------------------------------------------------------------------

type
  TSHA0Context = type Pointer;

Function SHA0_Init: TSHA0Context;
procedure SHA0_Update(Context: TSHA0Context; const Buffer; Size: TMemSize);
Function SHA0_Final(var Context: TSHA0Context; const Buffer; Size: TMemSize): TSHA0Hash; overload;
Function SHA0_Final(var Context: TSHA0Context): TSHA0Hash; overload;
Function SHA0_Hash(const Buffer; Size: TMemSize): TSHA0Hash;


implementation

uses
  SysUtils, Math, BitOps, StrRect;

const
  BlockSize       = 64;                           // 512 bits
{$IFDEF LargeBuffers}
  BlocksPerBuffer = 16384;                        // 1MiB BufferSize
{$ELSE}
  BlocksPerBuffer = 64;                           // 4KiB BufferSize
{$ENDIF}
  BufferSize      = BlocksPerBuffer * BlockSize;  // size of read buffer

  RoundConsts: array[0..3] of UInt32 = ($5A827999, $6ED9EBA1, $8F1BBCDC, $CA62C1D6);

type
  TBlockBuffer = array[0..BlockSize - 1] of UInt8;
  PBlockBuffer = ^TBlockBuffer;

  TSHA0Context_Internal = record
    MessageHash:    TSHA0Hash;
    MessageLength:  UInt64;
    TransferSize:   UInt32;
    TransferBuffer: TBlockBuffer;
  end;
  PSHA0Context_Internal = ^TSHA0Context_Internal;

//==============================================================================

Function BlockHash(Hash: TSHA0Hash; const Block): TSHA0Hash;
var
  i:              Integer;
  Temp:           UInt32;
  FuncResult:     UInt32;
  RoundConstant:  UInt32;
  State:          array[0..79] of UInt32;  
  BlockWords:     array[0..15] of UInt32 absolute Block;
begin
Result := Hash;
For i := 0 to 15 do State[i] := EndianSwap(BlockWords[i]);
For i := 16 to 79 do State[i] := State[i - 3] xor State[i - 8] xor State[i - 14] xor State[i - 16];
For i := 0 to 79 do
  begin
    case i of
       0..19: begin
                FuncResult := (Hash.PartB and Hash.PartC) or ((not Hash.PartB) and Hash.PartD);
                RoundConstant := RoundConsts[0];
              end;
      20..39: begin
                FuncResult := Hash.PartB xor Hash.PartC xor Hash.PartD;
                RoundConstant := RoundConsts[1];
              end;
      40..59: begin
                FuncResult := (Hash.PartB and Hash.PartC) or (Hash.PartB and Hash.PartD) or (Hash.PartC and Hash.PartD);
                RoundConstant := RoundConsts[2];
              end;
    else
     {60..79:}  FuncResult := Hash.PartB xor Hash.PartC xor Hash.PartD;
                RoundConstant := RoundConsts[3];
    end;
    {$IFDEF OverflowCheck}{$Q-}{$ENDIF}
    Temp := UInt32(ROL(Hash.PartA,5) + FuncResult + Hash.PartE + RoundConstant + State[i]);
    {$IFDEF OverflowCheck}{$Q+}{$ENDIF}
    Hash.PartE := Hash.PartD;
    Hash.PartD := Hash.PartC;
    Hash.PartC := ROL(Hash.PartB,30);
    Hash.PartB := Hash.PartA;
    Hash.PartA := Temp;
  end;
{$IFDEF OverflowCheck}{$Q-}{$ENDIF}
Result.PartA := UInt32(Result.PartA + Hash.PartA);
Result.PartB := UInt32(Result.PartB + Hash.PartB);
Result.PartC := UInt32(Result.PartC + Hash.PartC);
Result.PartD := UInt32(Result.PartD + Hash.PartD);
Result.PartE := UInt32(Result.PartE + Hash.PartE);
{$IFDEF OverflowCheck}{$Q+}{$ENDIF}
end;

//==============================================================================

Function SHA0toStr(Hash: TSHA0Hash): String;
begin
Result := IntToHex(Hash.PartA,8) + IntToHex(Hash.PartB,8) +
          IntToHex(Hash.PartC,8) + IntToHex(Hash.PartD,8) +
          IntToHex(Hash.PartE,8);
end;

//------------------------------------------------------------------------------

Function StrToSHA0(Str: String): TSHA0Hash;
begin
If Length(Str) < 40 then
  Str := StringOfChar('0',40 - Length(Str)) + Str
else
  If Length(Str) > 40 then
    Str := Copy(Str,Length(Str) - 39,40);
Result.PartA := StrToInt('$' + Copy(Str,1,8));
Result.PartB := StrToInt('$' + Copy(Str,9,8));
Result.PartC := StrToInt('$' + Copy(Str,17,8));
Result.PartD := StrToInt('$' + Copy(Str,25,8));
Result.PartE := StrToInt('$' + Copy(Str,33,8));
end;

//------------------------------------------------------------------------------

Function TryStrToSHA0(const Str: String; out Hash: TSHA0Hash): Boolean;
begin
try
  Hash := StrToSHA0(Str);
  Result := True;
except
  Result := False;
end;
end;

//------------------------------------------------------------------------------

Function StrToSHA0Def(const Str: String; Default: TSHA0Hash): TSHA0Hash;
begin
If not TryStrToSHA0(Str,Result) then
  Result := Default;
end;

//------------------------------------------------------------------------------

Function SameSHA0(A,B: TSHA0Hash): Boolean;
begin
Result := (A.PartA = B.PartA) and (A.PartB = B.PartB) and
          (A.PartC = B.PartC) and (A.PartD = B.PartD) and
          (A.PartE = B.PartE);
end;

//------------------------------------------------------------------------------

Function BinaryCorrectSHA0(Hash: TSHA0Hash): TSHA0Hash;
begin
Result.PartA := EndianSwap(Hash.PartA);
Result.PartB := EndianSwap(Hash.PartB);
Result.PartC := EndianSwap(Hash.PartC);
Result.PartD := EndianSwap(Hash.PartD);
Result.PartE := EndianSwap(Hash.PartE);
end;

//==============================================================================

procedure BufferSHA0(var Hash: TSHA0Hash; const Buffer; Size: TMemSize);
var
  i:    TMemSize;
  Buff: PBlockBuffer;
begin
If Size > 0 then
  begin
    If (Size mod BlockSize) = 0 then
      begin
        Buff := @Buffer;
        For i := 0 to Pred(Size div BlockSize) do
          begin
            Hash := BlockHash(Hash,Buff^);
            Inc(Buff);
          end;
      end
    else raise Exception.CreateFmt('BufferSHA0: Buffer size is not divisible by %d.',[BlockSize]);
  end;
end;

//------------------------------------------------------------------------------

Function LastBufferSHA0(Hash: TSHA0Hash; const Buffer; Size: TMemSize; MessageLength: UInt64): TSHA0Hash;
var
  FullBlocks:     TMemSize;
  LastBlockSize:  TMemSize;
  HelpBlocks:     TMemSize;
  HelpBlocksBuff: Pointer;
begin
Result := Hash;
FullBlocks := Size div BlockSize;
If FullBlocks > 0 then BufferSHA0(Result,Buffer,FullBlocks * BlockSize);
LastBlockSize := Size - (UInt64(FullBlocks) * BlockSize);
HelpBlocks := Ceil((LastBlockSize + SizeOf(UInt64) + 1) / BlockSize);
HelpBlocksBuff := AllocMem(HelpBlocks * BlockSize);
try
  Move({%H-}Pointer({%H-}PtrUInt(@Buffer) + (FullBlocks * BlockSize))^,HelpBlocksBuff^,LastBlockSize);
  {%H-}PUInt8({%H-}PtrUInt(HelpBlocksBuff) + LastBlockSize)^ := $80;
  {%H-}PUInt64({%H-}PtrUInt(HelpBlocksBuff) + (UInt64(HelpBlocks) * BlockSize) - SizeOf(UInt64))^ := EndianSwap(MessageLength);
  BufferSHA0(Result,HelpBlocksBuff^,HelpBlocks * BlockSize);
finally
  FreeMem(HelpBlocksBuff,HelpBlocks * BlockSize);
end;
end;

//------------------------------------------------------------------------------

Function LastBufferSHA0(Hash: TSHA0Hash; const Buffer; Size: TMemSize): TSHA0Hash;
begin
Result := LastBufferSHA0(Hash,Buffer,Size,UInt64(Size) shl 3);
end;

//==============================================================================

Function BufferSHA0(const Buffer; Size: TMemSize): TSHA0Hash;
begin
Result := LastBufferSHA0(InitialSHA0,Buffer,Size);
end;

//==============================================================================

Function AnsiStringSHA0(const Str: AnsiString): TSHA0Hash;
begin
Result := BufferSHA0(PAnsiChar(Str)^,Length(Str) * SizeOf(AnsiChar));
end;

//------------------------------------------------------------------------------

Function WideStringSHA0(const Str: WideString): TSHA0Hash;
begin
Result := BufferSHA0(PWideChar(Str)^,Length(Str) * SizeOf(WideChar));
end;

//------------------------------------------------------------------------------

Function StringSHA0(const Str: String): TSHA0Hash;
begin
Result := BufferSHA0(PChar(Str)^,Length(Str) * SizeOf(Char));
end;

//==============================================================================

Function StreamSHA0(Stream: TStream; Count: Int64 = -1): TSHA0Hash;
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
      Result := InitialSHA0;
      repeat
        BytesRead := Stream.Read(Buffer^,Min(BufferSize,Count));
        If BytesRead < BufferSize then
          Result := LastBufferSHA0(Result,Buffer^,BytesRead,MessageLength)
        else
          BufferSHA0(Result,Buffer^,BytesRead);
        Dec(Count,BytesRead);
      until BytesRead < BufferSize;
    finally
      FreeMem(Buffer,BufferSize);
    end;
  end
else raise Exception.Create('StreamSHA0: Stream is not assigned.');
end;

//------------------------------------------------------------------------------

Function FileSHA0(const FileName: String): TSHA0Hash;
var
  FileStream: TFileStream;
begin
FileStream := TFileStream.Create(StrToRTL(FileName), fmOpenRead or fmShareDenyWrite);
try
  Result := StreamSHA0(FileStream);
finally
  FileStream.Free;
end;
end;

//==============================================================================

Function SHA0_Init: TSHA0Context;
begin
Result := AllocMem(SizeOf(TSHA0Context_Internal));
with PSHA0Context_Internal(Result)^ do
  begin
    MessageHash := InitialSHA0;
    MessageLength := 0;
    TransferSize := 0;
  end;
end;

//------------------------------------------------------------------------------

procedure SHA0_Update(Context: TSHA0Context; const Buffer; Size: TMemSize);
var
  FullBlocks:     TMemSize;
  RemainingSize:  TMemSize;
begin
with PSHA0Context_Internal(Context)^ do
  begin
    If TransferSize > 0 then
      begin
        If Size >= (BlockSize - TransferSize) then
          begin
            Inc(MessageLength,(BlockSize - TransferSize) shl 3);
            Move(Buffer,TransferBuffer[TransferSize],BlockSize - TransferSize);
            BufferSHA0(MessageHash,TransferBuffer,BlockSize);
            RemainingSize := Size - (BlockSize - TransferSize);
            TransferSize := 0;
            SHA0_Update(Context,{%H-}Pointer({%H-}PtrUInt(@Buffer) + (Size - RemainingSize))^,RemainingSize);
          end
        else
          begin
            Inc(MessageLength,Size shl 3);
            Move(Buffer,TransferBuffer[TransferSize],Size);
            Inc(TransferSize,Size);
          end;  
      end
    else
      begin
        Inc(MessageLength,Size shl 3);
        FullBlocks := Size div BlockSize;
        BufferSHA0(MessageHash,Buffer,FullBlocks * BlockSize);
        If (FullBlocks * BlockSize) < Size then
          begin
            TransferSize := Size - (UInt64(FullBlocks) * BlockSize);
            Move({%H-}Pointer({%H-}PtrUInt(@Buffer) + (Size - TransferSize))^,TransferBuffer,TransferSize);
          end;
      end;
  end;
end;

//------------------------------------------------------------------------------

Function SHA0_Final(var Context: TSHA0Context; const Buffer; Size: TMemSize): TSHA0Hash;
begin
SHA0_Update(Context,Buffer,Size);
Result := SHA0_Final(Context);
end;

//------------------------------------------------------------------------------

Function SHA0_Final(var Context: TSHA0Context): TSHA0Hash;
begin
with PSHA0Context_Internal(Context)^ do
  Result := LastBufferSHA0(MessageHash,TransferBuffer,TransferSize,MessageLength);
FreeMem(Context,SizeOf(TSHA0Context_Internal));
Context := nil;
end;

//------------------------------------------------------------------------------

Function SHA0_Hash(const Buffer; Size: TMemSize): TSHA0Hash;
begin
Result := LastBufferSHA0(InitialSHA0,Buffer,Size);
end;

end.
