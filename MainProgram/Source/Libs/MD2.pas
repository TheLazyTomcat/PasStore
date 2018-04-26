{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  MD2 Hash Calculation

  ©František Milt 2017-07-18

  Version 1.1.6

  Dependencies:
    AuxTypes - github.com/ncs-sniper/Lib.AuxTypes
    StrRect  - github.com/ncs-sniper/Lib.StrRect

===============================================================================}
unit MD2;

{$DEFINE LargeBuffers}

{$IFDEF FPC}
  {$MODE ObjFPC}{$H+}
  {$DEFINE FPC_DisableWarns}
{$ENDIF}

interface

uses
  Classes, AuxTypes;

const
  BlockSize = 16;  // 128 bits

type
  TMD2Block = array[0..Pred(BlockSize)] of UInt8;
  PMD2Block = ^TMD2Block;

  TMD2Hash = TMD2Block;
  PMD2Hash = ^TMD2Hash;

  TMD2State = record
    Checksum:   TMD2Block;
    HashBuffer: array[0..47] of UInt8;
  end;

const
  InitialMD2State: TMD2State = (
    Checksum:   (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
    HashBuffer: (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0));

  ZeroMD2: TMD2Hash = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);

Function MD2toStr(Hash: TMD2Hash): String;
Function StrToMD2(Str: String): TMD2Hash;
Function TryStrToMD2(const Str: String; out Hash: TMD2Hash): Boolean;
Function StrToMD2Def(const Str: String; Default: TMD2Hash): TMD2Hash;
Function SameMD2(A,B: TMD2Hash): Boolean;
Function BinaryCorrectMD2(Hash: TMD2Hash): TMD2Hash;

procedure BufferMD2(var MD2State: TMD2State; const Buffer; Size: TMemSize); overload;
Function LastBufferMD2(MD2State: TMD2State; const Buffer; Size: TMemSize): TMD2Hash;

Function BufferMD2(const Buffer; Size: TMemSize): TMD2Hash; overload;

Function AnsiStringMD2(const Str: AnsiString): TMD2Hash;
Function WideStringMD2(const Str: WideString): TMD2Hash;
Function StringMD2(const Str: String): TMD2Hash;

Function StreamMD2(Stream: TStream; Count: Int64 = -1): TMD2Hash;
Function FileMD2(const FileName: String): TMD2Hash;

//------------------------------------------------------------------------------

type
  TMD2Context = type Pointer;

Function MD2_Init: TMD2Context;
procedure MD2_Update(Context: TMD2Context; const Buffer; Size: TMemSize);
Function MD2_Final(var Context: TMD2Context; const Buffer; Size: TMemSize): TMD2Hash; overload;
Function MD2_Final(var Context: TMD2Context): TMD2Hash; overload;
Function MD2_Hash(const Buffer; Size: TMemSize): TMD2Hash;


implementation

uses
  SysUtils, StrRect;

{$IFDEF FPC_DisableWarns}
  {$WARN 4055 OFF} // Conversion between ordinals and pointers is not portable
  {$WARN 4056 OFF} // Conversion between ordinals and pointers is not portable  
  {$IF FPC_FULLVERSION >= 30000}
    {$WARN 5092 OFF} // Variable "$1" of a managed type does not seem to be initialized
  {$ENDIF}
{$ENDIF}

const
{$IFDEF LargeBuffers}
  BlocksPerBuffer = 65536;                        // 1MiB BufferSize
{$ELSE}
  BlocksPerBuffer = 256;                          // 4KiB BufferSize
{$ENDIF}
  BufferSize      = BlocksPerBuffer * BlockSize;  // Size of read buffer

  PiTable: Array[UInt8] of UInt8 =(
    $29, $2E, $43, $C9, $A2, $D8, $7C, $01, $3D, $36, $54, $A1, $EC, $F0, $06, $13,
    $62, $A7, $05, $F3, $C0, $C7, $73, $8C, $98, $93, $2B, $D9, $BC, $4C, $82, $CA,
    $1E, $9B, $57, $3C, $FD, $D4, $E0, $16, $67, $42, $6F, $18, $8A, $17, $E5, $12,
    $BE, $4E, $C4, $D6, $DA, $9E, $DE, $49, $A0, $FB, $F5, $8E, $BB, $2F, $EE, $7A,
    $A9, $68, $79, $91, $15, $B2, $07, $3F, $94, $C2, $10, $89, $0B, $22, $5F, $21,
    $80, $7F, $5D, $9A, $5A, $90, $32, $27, $35, $3E, $CC, $E7, $BF, $F7, $97, $03,
    $FF, $19, $30, $B3, $48, $A5, $B5, $D1, $D7, $5E, $92, $2A, $AC, $56, $AA, $C6,
    $4F, $B8, $38, $D2, $96, $A4, $7D, $B6, $76, $FC, $6B, $E2, $9C, $74, $04, $F1,
    $45, $9D, $70, $59, $64, $71, $87, $20, $86, $5B, $CF, $65, $E6, $2D, $A8, $02,
    $1B, $60, $25, $AD, $AE, $B0, $B9, $F6, $1C, $46, $61, $69, $34, $40, $7E, $0F,
    $55, $47, $A3, $23, $DD, $51, $AF, $3A, $C3, $5C, $F9, $CE, $BA, $C5, $EA, $26,
    $2C, $53, $0D, $6E, $85, $28, $84, $09, $D3, $DF, $CD, $F4, $41, $81, $4D, $52,
    $6A, $DC, $37, $C8, $6C, $C1, $AB, $FA, $24, $E1, $7B, $08, $0C, $BD, $B1, $4A,
    $78, $88, $95, $8B, $E3, $63, $E8, $6D, $E9, $CB, $D5, $FE, $3B, $00, $1D, $39,
    $F2, $EF, $B7, $0E, $66, $58, $D0, $E4, $A6, $77, $72, $F8, $EB, $75, $4B, $0A,
    $31, $44, $50, $B4, $8F, $ED, $1F, $1A, $DB, $99, $8D, $33, $9F, $11, $83, $14);

type
  TMD2Context_Internal = record
    MD2State:       TMD2State;
    TransferSize:   UInt32;
    TransferBuffer: TMD2Block;
  end;
  PMD2Context_Internal = ^TMD2Context_Internal;

//==============================================================================

procedure BlockChecksum(var MD2State: TMD2State; const Block: TMD2Block);
var
  i:      Integer;
  State:  UInt8;
begin
State := MD2State.Checksum[Pred(BlockSize)];
For i := 0 to Pred(BlockSize) do
  begin
    MD2State.Checksum[i] := MD2State.Checksum[i] xor PiTable[Block[i] xor State];
    State := MD2State.Checksum[i];
  end;
end;

//------------------------------------------------------------------------------

procedure BlockHash(var MD2State: TMD2State; const Block: TMD2Block);
var
  i,j,k:    Integer;
  PiIndex:  UInt8;
begin
For i := 0 to Pred(BlockSize) do
  begin
    MD2State.HashBuffer[BlockSize + i] := Block[i];
    MD2State.HashBuffer[(BlockSize * 2) + i] := Block[i] xor MD2State.HashBuffer[i];
  end;
PiIndex := 0;
For j := 0 to 17 do
  begin
    For k := Low(MD2State.HashBuffer) to High(MD2State.HashBuffer) do
      begin
        MD2State.HashBuffer[k] := MD2State.HashBuffer[k] xor PiTable[PiIndex];
        PiIndex := MD2State.HashBuffer[k];
      end;
    PiIndex := UInt8(Int32(PiIndex) + j);
  end;
end;

//==============================================================================

Function MD2toStr(Hash: TMD2Hash): String;
var
  i:  Integer;
begin
Result := StringOfChar('0',32);
For i := Low(Hash) to High(Hash) do
  begin
    Result[(i * 2) + 2] := IntToHex(Hash[i] and $0F,1)[1];
    Result[(i * 2) + 1] := IntToHex(Hash[i] shr 4,1)[1];
  end;
end;

//------------------------------------------------------------------------------

Function StrToMD2(Str: String): TMD2Hash;
var
  i:  Integer;
begin
If Length(Str) < 32 then
  Str := StringOfChar('0',32 - Length(Str)) + Str
else
  If Length(Str) > 32 then
    Str := Copy(Str,Length(Str) - 31,32);
For i := 0 to 15 do
  Result[i] := StrToInt('$' + Copy(Str,(i * 2) + 1,2));
end;

//------------------------------------------------------------------------------

Function TryStrToMD2(const Str: String; out Hash: TMD2Hash): Boolean;
begin
try
  Hash := StrToMD2(Str);
  Result := True;
except
  Result := False;
end;
end;

//------------------------------------------------------------------------------

Function StrToMD2Def(const Str: String; Default: TMD2Hash): TMD2Hash;
begin
If not TryStrToMD2(Str,Result) then
  Result := Default;
end;

//------------------------------------------------------------------------------

Function SameMD2(A,B: TMD2Hash): Boolean;
var
  i:  Integer;
begin
Result := True;
For i := Low(TMD2Hash) to High(TMD2Hash) do
  If A[i] <> B[i] then
    begin
      Result := False;
      Break;
    end;
end;

//------------------------------------------------------------------------------

Function BinaryCorrectMD2(Hash: TMD2Hash): TMD2Hash;
begin
Result := Hash;
end;

//==============================================================================

procedure BufferMD2(var MD2State: TMD2State; const Buffer; Size: TMemSize);
var
  i:    TMemSize;
  Buff: PMD2Block;
begin
If Size > 0 then
  begin
    If (Size mod BlockSize) = 0 then
      begin
        Buff := @Buffer;
        For i := 0 to Pred(Size div BlockSize) do
          begin
            BlockChecksum(MD2State,Buff^);
            BlockHash(MD2State,Buff^);
            Inc(Buff);
          end;
      end
    else raise Exception.CreateFmt('BufferMD2: Buffer size is not divisible by %d.',[BlockSize]);
  end;
end;

//------------------------------------------------------------------------------

Function LastBufferMD2(MD2State: TMD2State; const Buffer; Size: TMemSize): TMD2Hash;
var
  FullBlocks:     TMemSize;
  HelpBlocks:     TMemSize;
  HelpBlocksBuff: Pointer;
begin
Result := ZeroMD2;
FullBlocks := Size div BlockSize;
BufferMD2(MD2State,Buffer,FullBlocks * BlockSize);
HelpBlocks := Succ(Size div BlockSize) - FullBlocks;
HelpBlocksBuff := AllocMem(HelpBlocks * BlockSize);
try
  FillChar(HelpBlocksBuff^,HelpBlocks * BlockSize,UInt8(((UInt64(FullBlocks) + HelpBlocks) * BlockSize) - Size));
  Move(Pointer(PtrUInt(@Buffer) + (FullBlocks * BlockSize))^,HelpBlocksBuff^,Size - (FullBlocks * Int64(BlockSize)));
  BufferMD2(MD2State,HelpBlocksBuff^,HelpBlocks * BlockSize);
  BlockHash(MD2State,MD2State.Checksum);
  Move(MD2State.HashBuffer,Result,SizeOf(Result));
finally
  FreeMem(HelpBlocksBuff,HelpBlocks * BlockSize);
end;
end;

//==============================================================================

Function BufferMD2(const Buffer; Size: TMemSize): TMD2Hash;
begin
Result := LastBufferMD2(InitialMD2State,Buffer,Size);
end;

//==============================================================================

Function AnsiStringMD2(const Str: AnsiString): TMD2Hash;
begin
Result := BufferMD2(PAnsiChar(Str)^,Length(Str) * SizeOf(AnsiChar));
end;

//------------------------------------------------------------------------------

Function WideStringMD2(const Str: WideString): TMD2Hash;
begin
Result := BufferMD2(PWideChar(Str)^,Length(Str) * SizeOf(WideChar));
end;

//------------------------------------------------------------------------------

Function StringMD2(const Str: String): TMD2Hash;
begin
Result := BufferMD2(PChar(Str)^,Length(Str) * SizeOf(Char));
end;

//==============================================================================

Function StreamMD2(Stream: TStream; Count: Int64 = -1): TMD2Hash;
var
  Buffer:     Pointer;
  BytesRead:  Integer;
  MD2State:   TMD2State;

  Function Min(A,B: Int64): Int64;
  begin
    If A < B then Result := A
      else Result := B;
  end;

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
    GetMem(Buffer,BufferSize);
    try
      MD2State := InitialMD2State;
      repeat
        BytesRead := Stream.Read(Buffer^,Min(BufferSize,Count));
        If BytesRead < BufferSize then
          Result := LastBufferMD2(MD2State,Buffer^,BytesRead)
        else
          BufferMD2(MD2State,Buffer^,BytesRead);
        Dec(Count,BytesRead);
      until BytesRead < BufferSize;
    finally
      FreeMem(Buffer,BufferSize);
    end;
  end
else raise Exception.Create('StreamMD2: Stream is not assigned.');
end;

//------------------------------------------------------------------------------

Function FileMD2(const FileName: String): TMD2Hash;
var
  FileStream: TFileStream;
begin
FileStream := TFileStream.Create(StrToRTL(FileName), fmOpenRead or fmShareDenyWrite);
try
  Result := StreamMD2(FileStream);
finally
  FileStream.Free;
end;
end;

//==============================================================================

Function MD2_Init: TMD2Context;
begin
Result := AllocMem(SizeOf(TMD2Context_Internal));
with PMD2Context_Internal(Result)^ do
  begin
    MD2State := InitialMD2State;
    TransferSize := 0;
  end;
end;

//------------------------------------------------------------------------------

procedure MD2_Update(Context: TMD2Context; const Buffer; Size: TMemSize);
var
  FullBlocks:     TMemSize;
  RemainingSize:  TMemSize;
begin
with PMD2Context_Internal(Context)^ do
  begin
    If TransferSize > 0 then
      begin
        If Size >= (BlockSize - TransferSize) then
          begin
            Move(Buffer,TransferBuffer[TransferSize],BlockSize - TransferSize);
            BufferMD2(MD2State,TransferBuffer,BlockSize);
            RemainingSize := Size - (BlockSize - TransferSize);
            TransferSize := 0;
            MD2_Update(Context,Pointer(PtrUInt(@Buffer) + (Size - RemainingSize))^,RemainingSize);
          end
        else
          begin
            Move(Buffer,TransferBuffer[TransferSize],Size);
            Inc(TransferSize,Size);
          end;  
      end
    else
      begin
        FullBlocks := Size div BlockSize;
        BufferMD2(MD2State,Buffer,FullBlocks * BlockSize);
        If TMemSize(FullBlocks * BlockSize) < Size then
          begin
            TransferSize := Size - (FullBlocks * Int64(BlockSize));
            Move(Pointer(PtrUInt(@Buffer) + (Size - TransferSize))^,TransferBuffer,TransferSize)
          end;
      end;
  end;
end;

//------------------------------------------------------------------------------

Function MD2_Final(var Context: TMD2Context; const Buffer; Size: TMemSize): TMD2Hash;
begin
MD2_Update(Context,Buffer,Size);
Result := MD2_Final(Context);
end;


//------------------------------------------------------------------------------

Function MD2_Final(var Context: TMD2Context): TMD2Hash;
begin
with PMD2Context_Internal(Context)^ do
  Result := LastBufferMD2(MD2State,TransferBuffer,TransferSize);
FreeMem(Context,SizeOf(TMD2Context_Internal));
Context := nil;
end;

//------------------------------------------------------------------------------

Function MD2_Hash(const Buffer; Size: TMemSize): TMD2Hash;
begin
Result := LastBufferMD2(InitialMD2State,Buffer,Size);
end;

end.
