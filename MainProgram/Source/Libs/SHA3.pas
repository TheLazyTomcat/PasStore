{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  SHA3/Keccak hash calculation

  ©František Milt 2018-05-03

  Version 1.1.5

  Following hash variants are supported in current implementation:
    Keccak224
    Keccak256
    Keccak384
    Keccak512
    Keccak[] (in this library marked as Keccak_b)
    SHA3-224
    SHA3-256
    SHA3-384
    SHA3-512
    SHAKE128
    SHAKE256

  Dependencies:
    AuxTypes    - github.com/ncs-sniper/Lib.AuxTypes
    StrRect     - github.com/ncs-sniper/Lib.StrRect
    BitOps      - github.com/ncs-sniper/Lib.BitOps
  * SimpleCPUID - github.com/ncs-sniper/Lib.SimpleCPUID

  SimpleCPUID might not be needed, see BitOps library for details.

===============================================================================}
unit SHA3;

{$DEFINE LargeBuffer}

{$IFDEF ENDIAN_BIG}
  {$MESSAGE FATAL 'Big-endian system not supported'}
{$ENDIF}

{$IFDEF FPC}
  {$MODE ObjFPC}{$H+}
  {$DEFINE FPC_DisableWarns}
  {$MACRO ON}
{$ENDIF}

interface

uses
  Classes, AuxTypes;

type
  TKeccakHashSize = (Keccak224,Keccak256,Keccak384,Keccak512,Keccak_b,
                     SHA3_224,SHA3_256,SHA3_384,SHA3_512,SHAKE128,SHAKE256);

  TSHA3HashSize = TKeccakHashSize;

  TKeccakSponge = array[0..4,0..4] of UInt64;  // First index is Y, second X
  
  TKeccakSpongeOverlay = array[0..24] of UInt64;

  TKeccakState = record
    HashSize:   TKeccakHashSize;
    HashBits:   UInt32;
    BlockSize:  UInt32;
    Sponge:     TKeccakSponge;
  end;

  TSHA3State = TKeccakState;

  TKeccakHash = record
    HashSize: TKeccakHashSize;
    HashBits: UInt32;
    HashData: array of UInt8;
  end;

  TSHA3Hash = TKeccakHash;

Function GetBlockSize(HashSize: TSHA3HashSize): UInt32;

Function InitialSHA3State(HashSize: TSHA3HashSize; HashBits: UInt32 = 0): TSHA3State;

Function SHA3ToStr(Hash: TSHA3Hash): String;
Function StrToSHA3(HashSize: TSHA3HashSize; Str: String): TSHA3Hash;
Function TryStrToSHA3(HashSize: TSHA3HashSize;const Str: String; out Hash: TSHA3Hash): Boolean;
Function StrToSHA3Def(HashSize: TSHA3HashSize;const Str: String; Default: TSHA3Hash): TSHA3Hash;
Function SameSHA3(A,B: TSHA3Hash): Boolean;
Function BinaryCorrectSHA3(Hash: TSHA3Hash): TSHA3Hash;

procedure BufferSHA3(var State: TSHA3State; const Buffer; Size: TMemSize); overload;
Function LastBufferSHA3(State: TSHA3State; const Buffer; Size: TMemSize): TSHA3Hash;

Function BufferSHA3(HashSize: TSHA3HashSize; const Buffer; Size: TMemSize; HashBits: UInt32 = 0): TSHA3Hash; overload;

Function AnsiStringSHA3(HashSize: TSHA3HashSize; const Str: AnsiString; HashBits: UInt32 = 0): TSHA3Hash;
Function WideStringSHA3(HashSize: TSHA3HashSize; const Str: WideString; HashBits: UInt32 = 0): TSHA3Hash;
Function StringSHA3(HashSize: TSHA3HashSize; const Str: String; HashBits: UInt32 = 0): TSHA3Hash;

Function StreamSHA3(HashSize: TSHA3HashSize; Stream: TStream; Count: Int64 = -1; HashBits: UInt32 = 0): TSHA3Hash;
Function FileSHA3(HashSize: TSHA3HashSize; const FileName: String; HashBits: UInt32 = 0): TSHA3Hash;

//------------------------------------------------------------------------------

type
  TSHA3Context = type Pointer;

Function SHA3_Init(HashSize: TSHA3HashSize; HashBits: UInt32 = 0): TSHA3Context;
procedure SHA3_Update(Context: TSHA3Context; const Buffer; Size: TMemSize);
Function SHA3_Final(var Context: TSHA3Context; const Buffer; Size: TMemSize): TSHA3Hash; overload;
Function SHA3_Final(var Context: TSHA3Context): TSHA3Hash; overload;
Function SHA3_Hash(HashSize: TSHA3HashSize; const Buffer; Size: TMemSize; HashBits: UInt32 = 0): TSHA3Hash;


implementation

uses
  SysUtils, Math, BitOps, StrRect;

{$IFDEF FPC_DisableWarns}
  {$DEFINE FPCDWM}
  {$DEFINE W4055:={$WARN 4055 OFF}} // Conversion between ordinals and pointers is not portable
  {$DEFINE W4056:={$WARN 4056 OFF}} // Conversion between ordinals and pointers is not portable
  {$PUSH}{$WARN 2005 OFF} // Comment level $1 found
  {$IF Defined(FPC) and (FPC_FULLVERSION >= 30000)}
    {$DEFINE W5092:={$WARN 5092 OFF}} // Variable "$1" of a managed type does not seem to be initialized
  {$ELSE}
    {$DEFINE W5092:=}
  {$IFEND}
  {$POP}
{$ENDIF}

const
  RoundConsts: array[0..23] of UInt64 = (
    UInt64($0000000000000001), UInt64($0000000000008082), UInt64($800000000000808A),
    UInt64($8000000080008000), UInt64($000000000000808B), UInt64($0000000080000001),
    UInt64($8000000080008081), UInt64($8000000000008009), UInt64($000000000000008A),
    UInt64($0000000000000088), UInt64($0000000080008009), UInt64($000000008000000A),
    UInt64($000000008000808B), UInt64($800000000000008B), UInt64($8000000000008089),
    UInt64($8000000000008003), UInt64($8000000000008002), UInt64($8000000000000080),
    UInt64($000000000000800A), UInt64($800000008000000A), UInt64($8000000080008081),
    UInt64($8000000000008080), UInt64($0000000080000001), UInt64($8000000080008008));

  RotateCoefs: array[0..4,0..4] of UInt8 = ( // first index is X, second Y
    {X = 0} ( 0,36, 3,41,18),
    {X = 1} ( 1,44,10,45, 2),
    {X = 2} (62, 6,43,15,61),
    {X = 3} (28,55,25,21,56),
    {X = 4} (27,20,39, 8,14));

type
  TSHA3Context_Internal = record
    HashState:      TSHA3State;
    TransferSize:   UInt32;
    TransferBuffer: array[0..199] of UInt8;
  end;
  PSHA3Context_Internal = ^TSHA3Context_Internal;

//==============================================================================

procedure Permute(var State: TKeccakState);
var
  i:    Integer;
  B:    TKeccakSponge;
  C,D:  array[0..4] of UInt64;
begin
For i := 0 to 23 do // 24 rounds (12 + 2L; where L = log2(64) = 6; 64 is length of sponge word in bits)
  begin
    C[0] := State.Sponge[0,0] xor State.Sponge[1,0] xor State.Sponge[2,0] xor State.Sponge[3,0] xor State.Sponge[4,0];
    C[1] := State.Sponge[0,1] xor State.Sponge[1,1] xor State.Sponge[2,1] xor State.Sponge[3,1] xor State.Sponge[4,1];
    C[2] := State.Sponge[0,2] xor State.Sponge[1,2] xor State.Sponge[2,2] xor State.Sponge[3,2] xor State.Sponge[4,2];
    C[3] := State.Sponge[0,3] xor State.Sponge[1,3] xor State.Sponge[2,3] xor State.Sponge[3,3] xor State.Sponge[4,3];
    C[4] := State.Sponge[0,4] xor State.Sponge[1,4] xor State.Sponge[2,4] xor State.Sponge[3,4] xor State.Sponge[4,4];

    D[0] := C[4] xor ROL(C[1],1);
    D[1] := C[0] xor ROL(C[2],1);
    D[2] := C[1] xor ROL(C[3],1);
    D[3] := C[2] xor ROL(C[4],1);
    D[4] := C[3] xor ROL(C[0],1);

    State.Sponge[0,0] := State.Sponge[0,0] xor D[0];
    State.Sponge[0,1] := State.Sponge[0,1] xor D[1];
    State.Sponge[0,2] := State.Sponge[0,2] xor D[2];
    State.Sponge[0,3] := State.Sponge[0,3] xor D[3];
    State.Sponge[0,4] := State.Sponge[0,4] xor D[4];
    State.Sponge[1,0] := State.Sponge[1,0] xor D[0];
    State.Sponge[1,1] := State.Sponge[1,1] xor D[1];
    State.Sponge[1,2] := State.Sponge[1,2] xor D[2];
    State.Sponge[1,3] := State.Sponge[1,3] xor D[3];
    State.Sponge[1,4] := State.Sponge[1,4] xor D[4];
    State.Sponge[2,0] := State.Sponge[2,0] xor D[0];
    State.Sponge[2,1] := State.Sponge[2,1] xor D[1];
    State.Sponge[2,2] := State.Sponge[2,2] xor D[2];
    State.Sponge[2,3] := State.Sponge[2,3] xor D[3];
    State.Sponge[2,4] := State.Sponge[2,4] xor D[4];
    State.Sponge[3,0] := State.Sponge[3,0] xor D[0];
    State.Sponge[3,1] := State.Sponge[3,1] xor D[1];
    State.Sponge[3,2] := State.Sponge[3,2] xor D[2];
    State.Sponge[3,3] := State.Sponge[3,3] xor D[3];
    State.Sponge[3,4] := State.Sponge[3,4] xor D[4];
    State.Sponge[4,0] := State.Sponge[4,0] xor D[0];
    State.Sponge[4,1] := State.Sponge[4,1] xor D[1];
    State.Sponge[4,2] := State.Sponge[4,2] xor D[2];
    State.Sponge[4,3] := State.Sponge[4,3] xor D[3];
    State.Sponge[4,4] := State.Sponge[4,4] xor D[4];

    B[0,0] := ROL(State.Sponge[0,0],RotateCoefs[0,0]);
    B[2,0] := ROL(State.Sponge[0,1],RotateCoefs[1,0]);
    B[4,0] := ROL(State.Sponge[0,2],RotateCoefs[2,0]);
    B[1,0] := ROL(State.Sponge[0,3],RotateCoefs[3,0]);
    B[3,0] := ROL(State.Sponge[0,4],RotateCoefs[4,0]);
    B[3,1] := ROL(State.Sponge[1,0],RotateCoefs[0,1]);
    B[0,1] := ROL(State.Sponge[1,1],RotateCoefs[1,1]);
    B[2,1] := ROL(State.Sponge[1,2],RotateCoefs[2,1]);
    B[4,1] := ROL(State.Sponge[1,3],RotateCoefs[3,1]);
    B[1,1] := ROL(State.Sponge[1,4],RotateCoefs[4,1]);
    B[1,2] := ROL(State.Sponge[2,0],RotateCoefs[0,2]);
    B[3,2] := ROL(State.Sponge[2,1],RotateCoefs[1,2]);
    B[0,2] := ROL(State.Sponge[2,2],RotateCoefs[2,2]);
    B[2,2] := ROL(State.Sponge[2,3],RotateCoefs[3,2]);
    B[4,2] := ROL(State.Sponge[2,4],RotateCoefs[4,2]);
    B[4,3] := ROL(State.Sponge[3,0],RotateCoefs[0,3]);
    B[1,3] := ROL(State.Sponge[3,1],RotateCoefs[1,3]);
    B[3,3] := ROL(State.Sponge[3,2],RotateCoefs[2,3]);
    B[0,3] := ROL(State.Sponge[3,3],RotateCoefs[3,3]);
    B[2,3] := ROL(State.Sponge[3,4],RotateCoefs[4,3]);
    B[2,4] := ROL(State.Sponge[4,0],RotateCoefs[0,4]);
    B[4,4] := ROL(State.Sponge[4,1],RotateCoefs[1,4]);
    B[1,4] := ROL(State.Sponge[4,2],RotateCoefs[2,4]);
    B[3,4] := ROL(State.Sponge[4,3],RotateCoefs[3,4]);
    B[0,4] := ROL(State.Sponge[4,4],RotateCoefs[4,4]);

    State.Sponge[0,0] := B[0,0] xor ((not B[0,1]) and B[0,2]);
    State.Sponge[0,1] := B[0,1] xor ((not B[0,2]) and B[0,3]);
    State.Sponge[0,2] := B[0,2] xor ((not B[0,3]) and B[0,4]);
    State.Sponge[0,3] := B[0,3] xor ((not B[0,4]) and B[0,0]);
    State.Sponge[0,4] := B[0,4] xor ((not B[0,0]) and B[0,1]);
    State.Sponge[1,0] := B[1,0] xor ((not B[1,1]) and B[1,2]);
    State.Sponge[1,1] := B[1,1] xor ((not B[1,2]) and B[1,3]);
    State.Sponge[1,2] := B[1,2] xor ((not B[1,3]) and B[1,4]);
    State.Sponge[1,3] := B[1,3] xor ((not B[1,4]) and B[1,0]);
    State.Sponge[1,4] := B[1,4] xor ((not B[1,0]) and B[1,1]);
    State.Sponge[2,0] := B[2,0] xor ((not B[2,1]) and B[2,2]);
    State.Sponge[2,1] := B[2,1] xor ((not B[2,2]) and B[2,3]);
    State.Sponge[2,2] := B[2,2] xor ((not B[2,3]) and B[2,4]);
    State.Sponge[2,3] := B[2,3] xor ((not B[2,4]) and B[2,0]);
    State.Sponge[2,4] := B[2,4] xor ((not B[2,0]) and B[2,1]);
    State.Sponge[3,0] := B[3,0] xor ((not B[3,1]) and B[3,2]);
    State.Sponge[3,1] := B[3,1] xor ((not B[3,2]) and B[3,3]);
    State.Sponge[3,2] := B[3,2] xor ((not B[3,3]) and B[3,4]);
    State.Sponge[3,3] := B[3,3] xor ((not B[3,4]) and B[3,0]);
    State.Sponge[3,4] := B[3,4] xor ((not B[3,0]) and B[3,1]);
    State.Sponge[4,0] := B[4,0] xor ((not B[4,1]) and B[4,2]);
    State.Sponge[4,1] := B[4,1] xor ((not B[4,2]) and B[4,3]);
    State.Sponge[4,2] := B[4,2] xor ((not B[4,3]) and B[4,4]);
    State.Sponge[4,3] := B[4,3] xor ((not B[4,4]) and B[4,0]);
    State.Sponge[4,4] := B[4,4] xor ((not B[4,0]) and B[4,1]);

    State.Sponge[0,0] := State.Sponge[0,0] xor RoundConsts[i];
  end;
end;

//------------------------------------------------------------------------------

procedure BlockHash(var State: TKeccakState; const Block);
var
  i:    Integer;
  Buff: TKeccakSpongeOverlay absolute Block;
begin
For i := 0 to Pred(State.BlockSize shr 3) do
  TKeccakSpongeOverlay(State.Sponge)[i] := TKeccakSpongeOverlay(State.Sponge)[i] xor Buff[i];
Permute(State);
end;

//------------------------------------------------------------------------------

procedure Squeeze(var State: TKeccakState; var Buffer);
var
  BytesToSqueeze: UInt32;
begin
BytesToSqueeze := State.HashBits shr 3;
If BytesToSqueeze > State.BlockSize then
  while BytesToSqueeze > 0 do
    begin
    {$IFDEF FPCDWM}{$PUSH}W4055 W4056{$ENDIF}
      Move(State.Sponge,Pointer(PtrUInt(@Buffer) + UInt64(State.HashBits shr 3) - BytesToSqueeze)^,Min(BytesToSqueeze,State.BlockSize));
    {$IFDEF FPCDWM}{$POP}{$ENDIF}
      Permute(State);
      Dec(BytesToSqueeze,Min(BytesToSqueeze,State.BlockSize));
    end
else Move(State.Sponge,Buffer,BytesToSqueeze);
end;

//==============================================================================

procedure PrepareHash(State: TSHA3State; out Hash: TSHA3Hash);
begin
Hash.HashSize := State.HashSize;
Hash.HashBits := State.HashBits;
SetLength(Hash.HashData,Hash.HashBits shr 3);
end;

//==============================================================================

Function GetBlockSize(HashSize: TKeccakHashSize): UInt32;
begin
case HashSize of
  Keccak224, SHA3_224:  Result := (1600 - (2 * 224)) shr 3;
  Keccak256, SHA3_256:  Result := (1600 - (2 * 256)) shr 3;
  Keccak384, SHA3_384:  Result := (1600 - (2 * 384)) shr 3;
  Keccak512, SHA3_512:  Result := (1600 - (2 * 512)) shr 3;
  Keccak_b:             Result := (1600 - 576) shr 3;
  SHAKE128:             Result := (1600 - (2 * 128)) shr 3;
  SHAKE256:             Result := (1600 - (2 * 256)) shr 3;
else
  raise Exception.CreateFmt('GetBlockSize: Unknown hash size (%d).',[Ord(HashSize)]);
end;
end;

//------------------------------------------------------------------------------

Function InitialSHA3State(HashSize: TSHA3HashSize; HashBits: UInt32 = 0): TSHA3State;
begin
Result.HashSize := HashSize;
case HashSize of
  Keccak224, SHA3_224:  Result.HashBits := 224;
  Keccak256, SHA3_256:  Result.HashBits := 256;
  Keccak384, SHA3_384:  Result.HashBits := 384;
  Keccak512, SHA3_512:  Result.HashBits := 512;
  Keccak_b,
  SHAKE128,
  SHAKE256: begin
              If (HashBits and $7) <> 0 then
                raise Exception.Create('InitialSHA3State: HashBits must be divisible by 8.')
              else
                Result.HashBits := HashBits;
            end;
else
  raise Exception.CreateFmt('InitialSHA3State: Unknown hash size (%d).',[Ord(HashSize)]);
end;
Result.BlockSize := GetBlockSize(HashSize);
FillChar(Result.Sponge,SizeOf(Result.Sponge),0);
end;

//==============================================================================

Function SHA3ToStr(Hash: TSHA3Hash): String;
var
  i:  Integer;
begin
SetLength(Result,Length(Hash.HashData) * 2);
For i := Low(Hash.HashData) to High(Hash.HashData) do
  begin
    Result[(i * 2) + 1] := IntToHex(Hash.HashData[i],2)[1];
    Result[(i * 2) + 2] := IntToHex(Hash.HashData[i],2)[2];
  end;
end;

//------------------------------------------------------------------------------

{$IFDEF FPCDWM}{$PUSH}W5092{$ENDIF}
Function StrToSHA3(HashSize: TSHA3HashSize; Str: String): TSHA3Hash;
var
  HashCharacters: Integer;
  i:              Integer;
begin
Result.HashSize := HashSize;
case HashSize of
  Keccak224, SHA3_224:  Result.HashBits := 224;
  Keccak256, SHA3_256:  Result.HashBits := 256;
  Keccak384, SHA3_384:  Result.HashBits := 384;
  Keccak512, SHA3_512:  Result.HashBits := 512;
  Keccak_b,
  SHAKE128,
  SHAKE256:  Result.HashBits := (Length(Str) shr 1) shl 3;
else
  raise Exception.CreateFmt('StrToSHA3: Unknown source hash size (%d).',[Ord(HashSize)]);
end;
HashCharacters := Result.HashBits shr 2;
If Length(Str) < HashCharacters then
  Str := StringOfChar('0',HashCharacters - Length(Str)) + Str
else
  If Length(Str) > HashCharacters then
    Str := Copy(Str,Length(Str) - HashCharacters + 1,HashCharacters);
SetLength(Result.HashData,Length(Str) shr 1);    
For i := Low(Result.HashData) to High(Result.HashData) do
  Result.HashData[i] := UInt8(StrToInt('$' + Copy(Str,(i * 2) + 1,2)));
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------

Function TryStrToSHA3(HashSize: TSHA3HashSize; const Str: String; out Hash: TSHA3Hash): Boolean;
begin
try
  Hash := StrToSHA3(HashSize,Str);
  Result := True;
except
  Result := False;
end;
end;

//------------------------------------------------------------------------------

Function StrToSHA3Def(HashSize: TSHA3HashSize; const Str: String; Default: TSHA3Hash): TSHA3Hash;
begin
If not TryStrToSHA3(HashSize,Str,Result) then
  Result := Default;
end;

//------------------------------------------------------------------------------

Function SameSHA3(A,B: TSHA3Hash): Boolean;
var
  i:  Integer;
begin
Result := False;
If (A.HashBits = B.HashBits) and (A.HashSize = B.HashSize) and
  (Length(A.HashData) = Length(B.HashData)) then
  begin
    For i := Low(A.HashData) to High(A.HashData) do
      If A.HashData[i] <> B.HashData[i] then Exit;
    Result := True;
  end;
end;

//------------------------------------------------------------------------------

Function BinaryCorrectSHA3(Hash: TSHA3Hash): TSHA3Hash;
begin
Result := Hash;
end;

//==============================================================================

procedure BufferSHA3(var State: TSHA3State; const Buffer; Size: TMemSize);
var
  i:    TMemSize;
  Buff: PUInt8;
begin
If Size > 0 then
  begin
    If (Size mod State.BlockSize) = 0 then
      begin
        Buff := @Buffer;
        For i := 0 to Pred(Size div State.BlockSize) do
          begin
            BlockHash(State,Buff^);
            Inc(Buff,State.BlockSize);
          end;
      end
    else raise Exception.CreateFmt('BufferSHA3: Buffer size is not divisible by %d.',[State.BlockSize]);
  end;
end;

//------------------------------------------------------------------------------

Function LastBufferSHA3(State: TSHA3State; const Buffer; Size: TMemSize): TSHA3Hash;
var
  FullBlocks:     TMemSize;
  LastBlockSize:  TMemSize;
  HelpBlocks:     TMemSize;
  HelpBlocksBuff: Pointer;
begin
FullBlocks := Size div State.BlockSize;
If FullBlocks > 0 then BufferSHA3(State,Buffer,FullBlocks * State.BlockSize);
LastBlockSize := Size - (UInt64(FullBlocks) * State.BlockSize);
HelpBlocks := Ceil((LastBlockSize + 1) / State.BlockSize);
HelpBlocksBuff := AllocMem(HelpBlocks * State.BlockSize);
try
{$IFDEF FPCDWM}{$PUSH}W4055 W4056{$ENDIF}
  Move(Pointer(PtrUInt(@Buffer) + (FullBlocks * State.BlockSize))^,HelpBlocksBuff^,LastBlockSize);
  case State.HashSize of
    Keccak224..Keccak_b:  PUInt8(PtrUInt(HelpBlocksBuff) + LastBlockSize)^ := $01;
     SHA3_224..SHA3_512:  PUInt8(PtrUInt(HelpBlocksBuff) + LastBlockSize)^ := $06;
     SHAKE128..SHAKE256:  PUInt8(PtrUInt(HelpBlocksBuff) + LastBlockSize)^ := $1F;
  else
    raise Exception.CreateFmt('LastBufferSHA3: Unknown hash size (%d)',[Ord(State.HashSize)]);
  end;
  PUInt8(PtrUInt(HelpBlocksBuff) + (UInt64(HelpBlocks) * State.BlockSize) - 1)^ := PUInt8(PtrUInt(HelpBlocksBuff) + (UInt64(HelpBlocks) * State.BlockSize) - 1)^ xor $80;
  BufferSHA3(State,HelpBlocksBuff^,HelpBlocks * State.BlockSize);
{$IFDEF FPCDWM}{$POP}{$ENDIF}
finally
  FreeMem(HelpBlocksBuff,HelpBlocks * State.BlockSize);
end;
PrepareHash(State,Result);
If Length(Result.HashData) > 0 then
  Squeeze(State,Addr(Result.HashData[0])^);
end;

//==============================================================================

Function BufferSHA3(HashSize: TSHA3HashSize; const Buffer; Size: TMemSize; HashBits: UInt32 = 0): TSHA3Hash;
begin
Result := LastBufferSHA3(InitialSHA3State(HashSize,HashBits),Buffer,Size);
end;

//==============================================================================

Function AnsiStringSHA3(HashSize: TSHA3HashSize; const Str: AnsiString; HashBits: UInt32 = 0): TSHA3Hash;
begin
Result := BufferSHA3(HashSize,PAnsiChar(Str)^,Length(Str) * SizeOf(AnsiChar),HashBits);
end;

//------------------------------------------------------------------------------

Function WideStringSHA3(HashSize: TSHA3HashSize; const Str: WideString; HashBits: UInt32 = 0): TSHA3Hash;
begin
Result := BufferSHA3(HashSize,PWideChar(Str)^,Length(Str) * SizeOf(WideChar),HashBits);
end;

//------------------------------------------------------------------------------

Function StringSHA3(HashSize: TSHA3HashSize; const Str: String; HashBits: UInt32 = 0): TSHA3Hash;
begin
Result := BufferSHA3(HashSize,PChar(Str)^,Length(Str) * SizeOf(Char),HashBits);
end;

//==============================================================================

Function StreamSHA3(HashSize: TSHA3HashSize; Stream: TStream; Count: Int64 = -1; HashBits: UInt32 = 0): TSHA3Hash;
var
  Buffer:     Pointer;
  BytesRead:  UInt32;
  State:      TSHA3State;
  BufferSize: UInt32;
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
  {$IFDEF LargeBuffer}
    BufferSize := ($100000 div GetBlockSize(HashSize)) * GetBlockSize(HashSize);
  {$ELSE}
    BufferSize := ($1000 div GetBlockSize(HashSize)) * GetBlockSize(HashSize);
  {$ENDIF}
    GetMem(Buffer,BufferSize);
    try
      State := InitialSHA3State(HashSize,HashBits);
      repeat
        BytesRead := Stream.Read(Buffer^,Min(BufferSize,Count));
        If BytesRead < BufferSize then
          Result := LastBufferSHA3(State,Buffer^,BytesRead)
        else
          BufferSHA3(State,Buffer^,BytesRead);
        Dec(Count,BytesRead);
      until BytesRead < BufferSize;
    finally
      FreeMem(Buffer,BufferSize);
    end;
  end
else raise Exception.Create('StreamSHA3: Stream is not assigned.');
end;

//------------------------------------------------------------------------------

Function FileSHA3(HashSize: TSHA3HashSize; const FileName: String; HashBits: UInt32 = 0): TSHA3Hash;
var
  FileStream: TFileStream;
begin
FileStream := TFileStream.Create(StrToRTL(FileName), fmOpenRead or fmShareDenyWrite);
try
  Result := StreamSHA3(HashSize,FileStream,-1,HashBits);
finally
  FileStream.Free;
end;
end;

//==============================================================================

Function SHA3_Init(HashSize: TSHA3HashSize; HashBits: UInt32 = 0): TSHA3Context;
begin
Result := AllocMem(SizeOf(TSHA3Context_Internal));
with PSHA3Context_Internal(Result)^ do
  begin
    HashState := InitialSHA3State(HashSize,HashBits);
    TransferSize := 0;
  end;
end;

//------------------------------------------------------------------------------

procedure SHA3_Update(Context: TSHA3Context; const Buffer; Size: TMemSize);
var
  FullBlocks:     TMemSize;
  RemainingSize:  TMemSize;
begin
with PSHA3Context_Internal(Context)^ do
  begin
    If TransferSize > 0 then
      begin
        If Size >= (HashState.BlockSize - TransferSize) then
          begin
            Move(Buffer,TransferBuffer[TransferSize],HashState.BlockSize - TransferSize);
            BufferSHA3(HashState,TransferBuffer,HashState.BlockSize);
            RemainingSize := Size - (HashState.BlockSize - TransferSize);
            TransferSize := 0;
          {$IFDEF FPCDWM}{$PUSH}W4055 W4056{$ENDIF}
            SHA3_Update(Context,Pointer(PtrUInt(@Buffer) + (Size - RemainingSize))^,RemainingSize);
          {$IFDEF FPCDWM}{$POP}{$ENDIF}
          end
        else
          begin
            Move(Buffer,TransferBuffer[TransferSize],Size);
            Inc(TransferSize,Size);
          end;  
      end
    else
      begin
        FullBlocks := Size div HashState.BlockSize;
        BufferSHA3(HashState,Buffer,FullBlocks * HashState.BlockSize);
        If (FullBlocks * HashState.BlockSize) < Size then
          begin
            TransferSize := Size - (UInt64(FullBlocks) * HashState.BlockSize);
          {$IFDEF FPCDWM}{$PUSH}W4055 W4056{$ENDIF}
            Move(Pointer(PtrUInt(@Buffer) + (Size - TransferSize))^,TransferBuffer,TransferSize);
          {$IFDEF FPCDWM}{$POP}{$ENDIF}
          end;
      end;
  end;
end;

//------------------------------------------------------------------------------

Function SHA3_Final(var Context: TSHA3Context; const Buffer; Size: TMemSize): TSHA3Hash;
begin
SHA3_Update(Context,Buffer,Size);
Result := SHA3_Final(Context);
end;

//------------------------------------------------------------------------------

Function SHA3_Final(var Context: TSHA3Context): TSHA3Hash;
begin
with PSHA3Context_Internal(Context)^ do
  Result := LastBufferSHA3(HashState,TransferBuffer,TransferSize);
FreeMem(Context,SizeOf(TSHA3Context_Internal));
Context := nil;
end;

//------------------------------------------------------------------------------

Function SHA3_Hash(HashSize: TSHA3HashSize; const Buffer; Size: TMemSize; HashBits: UInt32 = 0): TSHA3Hash;
begin
Result := LastBufferSHA3(InitialSHA3State(HashSize,HashBits),Buffer,Size);
end;

end.

