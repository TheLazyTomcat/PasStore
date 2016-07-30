unit PST_Manager;

interface

uses
  Classes;

type
  TPSTEntryHistoryItem = record
    Time:     TDateTime;
    Password: String;
  end;
  PPSTEntryHistoryItem = ^TPSTEntryHistoryItem;

  TPSTEntryHistory = array of TPSTEntryHistoryItem;

  TPSTEntry = record
    Name:     String;
    Address:  String;
    Notes:    String;
    Password: String;
    History:  TPSTEntryHistory;
  end;
  PPSTEntry = ^TPSTEntry;

  TPSTList = array of TPSTEntry;

  TPSTEntryEvent = procedure(Sender: TObject; Entry: PPSTEntry) of object;

  TPSTManager = class(TObject)
  private
    fEntries:         TPSTList;
    fFileName:        String;
    fMasterPassword:  String;
    fCurrentEntryIdx: Integer;
    fOnEntrySet:      TPSTEntryEvent;
    fOnEntryGet:      TPSTEntryEvent;
    Function GetEntryCount: Integer;
    Function GetEntryPtr(Index: Integer): PPSTEntry;
    Function GetEntry(Index: Integer): TPSTEntry;
    procedure SetEntry(Index: Integer; Value: TPSTEntry);
    procedure SetCurrentEntryIdx(Value: Integer);
    Function GetCurrentEntry: TPSTEntry;
    procedure SetCurrentEntry(Value: TPSTEntry);
  protected
    Function ValidIndex(Idx: Integer): Boolean; virtual;
    procedure GetKeyAndInitVector(var Key, InitVec); virtual;
    procedure EncryptStream(Stream: TMemoryStream); virtual;
    procedure DecryptStream(Stream: TMemoryStream); virtual;
  public
    constructor Create;
    destructor Destroy; override;
    Function IndexOfEntry(const Name: String): Integer; virtual;
    Function AddEntry(const Name: String): Integer; virtual;
    Function RemoveEntry(const Name: String): Integer; virtual;
    procedure DeleteEntry(Index: Integer); virtual;
    Function Load: Boolean; virtual;
    procedure Save; virtual;
    property EntriesPtr[Index: Integer]: PPSTEntry read GetEntryPtr;
    property Entries[Index: Integer]: TPSTEntry read GetEntry write SetEntry; default;
  published
    property EntryCount: Integer read GetEntryCount;
    property FileName: String read fFileName write fFileName;
    property MasterPassword: String read fMasterPassword write fMasterPassword;
    property CurrentEntryIdx: Integer read fCurrentEntryIdx write SetCurrentEntryIdx;
    property CurrentEntry: TPSTEntry read GetCurrentEntry write SetCurrentEntry;
    property OnEntrySet: TPSTEntryEvent read fOnEntrySet write fOnEntrySet;
    property OnEntryGet: TPSTEntryEvent read fOnEntryGet write fOnEntryGet;
  end;

implementation

uses
  AuxTypes, BinaryStreaming, SimpleCompress,
  MD5, SHA2, SHA3, AES,
  SysUtils, StrUtils;

{-------------------------------------------------------------------------------

  File structure:

    4B    32b uint    signature (0x72745350)
    4B    32b uint    entry count
    []                entry array

  Entry:

    4B    32b uint    signature (0xFFFA0102)
    []    String      name
    []    String      address
    []    String      notes
    []    String      password
    4B    32b uint    history count
    []                history array

  History item:

    8B    TDateTime   time of addition
    []    String      password


  File is then compressed using ZLIB and encrypted using Rijndael (160bit block,
  224bit key). Init vector is Keccak[] hash of password, key is obtained as
  SHA-512/224 of 1024bit SHAKE256 of salted password (utf8 encoded).

-------------------------------------------------------------------------------}

const
  PST_FileSignature  = UInt32($72745350);
  PST_EntrySignature = UInt32($FFFA0102);

//******************************************************************************  

Function TPSTManager.GetEntryCount: Integer;
begin
Result := Length(fEntries);
end;

//------------------------------------------------------------------------------

Function TPSTManager.GetEntryPtr(Index: Integer): PPSTEntry;
begin
If (Index >= Low(fEntries)) and (Index <= High(fEntries)) then
  Result := Addr(fEntries[Index])
else
  raise Exception.CreateFmt('TPSTManager.GetEntryPtr: Index (%d) out of bounds.',[Index]);
end;

//------------------------------------------------------------------------------

Function TPSTManager.GetEntry(Index: Integer): TPSTEntry;
begin
Result := GetEntryPtr(Index)^;
end;

//------------------------------------------------------------------------------

procedure TPSTManager.SetEntry(Index: Integer; Value: TPSTEntry);
begin
GetEntryPtr(Index)^ := Value;
end;

//------------------------------------------------------------------------------

procedure TPSTManager.SetCurrentEntryIdx(Value: Integer);
begin
If Value <> fCurrentEntryIdx then
  begin
    If ValidIndex(fCurrentEntryIdx) and Assigned(fOnEntryGet) then
      fOnEntryGet(Self,GetEntryPtr(fCurrentEntryIdx));
    fCurrentEntryIdx := Value;
    If Assigned(fOnEntrySet) then
      begin
        If ValidIndex(fCurrentEntryIdx) then
          fOnEntrySet(Self,GetEntryPtr(fCurrentEntryIdx))
        else
          fOnEntrySet(Self,nil)
      end;
  end;
end;

//------------------------------------------------------------------------------

Function TPSTManager.GetCurrentEntry: TPSTEntry;
begin
If ValidIndex(fCurrentEntryIdx) then
  Result := fEntries[fCurrentEntryIdx]
else
  raise Exception.CreateFmt('TPSTManager.GetCurrentEntry: Index (%d) out of bounds.',[fCurrentEntryIdx]);
end;

//------------------------------------------------------------------------------

procedure TPSTManager.SetCurrentEntry(Value: TPSTEntry);
begin
If ValidIndex(fCurrentEntryIdx) then
  fEntries[fCurrentEntryIdx] := Value
else
  raise Exception.CreateFmt('TPSTManager.GetCurrentEntry: Index (%d) out of bounds.',[fCurrentEntryIdx]);
end;

//==============================================================================

Function TPSTManager.ValidIndex(Idx: Integer): Boolean;
begin
Result := (Idx >= Low(fEntries)) and (Idx <= High(fEntries));
end;
 
//------------------------------------------------------------------------------

procedure TPSTManager.GetKeyAndInitVector(var Key, InitVec);
var
  Pswd: UTF8String;
  Temp: TSHA2Hash;
begin
Pswd := AnsiToUTF8(fMasterPassword);
Move(StringSHA3(Keccak_b,Pswd,160).HashData[0],InitVec,20);
Pswd := Pswd + '&' + ReverseString(AnsiUpperCase(MD5ToStr(StringMD5(Pswd))));
Temp := BufferSHA2(sha512_224,StringSHA3(SHAKE256,Pswd,1024).HashData[0],128);
Move(Temp.Hash512_224,Key,28);
end;

//------------------------------------------------------------------------------

procedure TPSTManager.EncryptStream(Stream: TMemoryStream);
var
  Key:      array[0..27] of Byte;
  InitVec:  array[0..19] of Byte;
begin
Stream.Position := 0;
ZCompressStream(Stream);
Stream_WriteUInt8(Stream,$FF);
GetKeyAndInitVector(Key,InitVec);
with TRijndaelCipher.Create(Key,InitVec,r224bit,r160bit,cmEncrypt) do
try
  ModeOfOperation := moCBC;
  Padding := padZeroes;
  Stream.Position := 0;
  ProcessStream(Stream);
finally
  Free;
end;
end;

//------------------------------------------------------------------------------

procedure TPSTManager.DecryptStream(Stream: TMemoryStream);
var
  Key:      array[0..27] of Byte;
  InitVec:  array[0..19] of Byte;
begin
GetKeyAndInitVector(Key,InitVec);
with TRijndaelCipher.Create(Key,InitVec,r224bit,r160bit,cmDecrypt) do
try
  ModeOfOperation := moCBC;
  Padding := padZeroes;
  Stream.Position := 0;
  ProcessStream(Stream);
finally
  Free;
end;
// Find end of compressed stream and shrink it accordingly
Stream.Position := Pred(Stream.Size);
If Stream_ReadUInt8(Stream,False) = 0 then
  while Stream.Position >= 0 do
    begin
      If Stream_ReadUInt8(Stream,False) <> 0 then
        begin
          Stream.Size := Stream.Position;
          Break {while};
        end;
      Stream.Position := Stream.Position - 1;
    end;
Stream.Position := 0;
ZDecompressStream(Stream);
end;

//==============================================================================


constructor TPSTManager.Create;
begin
inherited Create;
SetLength(fEntries,0);
fCurrentEntryIdx := -2;
end;

//------------------------------------------------------------------------------

destructor TPSTManager.Destroy;
begin
SetLength(fEntries,0);
inherited;
end;

//------------------------------------------------------------------------------

Function TPSTManager.IndexOfEntry(const Name: String): Integer;
var
  i:  Integer;
begin
Result := -1;
For i := Low(fEntries) to High(fEntries) do
  If AnsiSameText(Name,fEntries[i].Name) then
    begin
      Result := i;
      Break {For i};
    end;
end;

//------------------------------------------------------------------------------

Function TPSTManager.AddEntry(const Name: String): Integer;
begin
SetLength(fEntries,Length(fEntries) + 1);
Result := High(fEntries);
fEntries[Result].Name := Name;
end;

//------------------------------------------------------------------------------

Function TPSTManager.RemoveEntry(const Name: String): Integer;
begin
Result := IndexOfEntry(Name);
If Result >= 0 then
  DeleteEntry(Result);
end;

//------------------------------------------------------------------------------

procedure TPSTManager.DeleteEntry(Index: Integer);
var
  i:  Integer;
begin
If (Index >= Low(fEntries)) and (Index <= High(fEntries)) then
  begin
    For i := Index to Pred(High(fEntries)) do
      fEntries[i] := fEntries[i + 1];
    SetLength(fEntries,Length(fEntries) - 1);
  end
else raise Exception.CreateFmt('TPSTManager.Delete: Index (%d) out of bounds.',[Index]);
end;

//------------------------------------------------------------------------------

Function TPSTManager.Load: Boolean;
var
  WorkStream: TMemoryStream;
  i,j:        Integer;
begin
try
  WorkStream := TMemoryStream.Create;
  try
    Result := False;
    WorkStream.LoadFromFile(fFileName);
    DecryptStream(WorkStream);
    WorkStream.Position := 0;
    with TStreamStreamer.Create(WorkStream) do
    try
      If ReadUInt32 = PST_FileSignature then
        begin
          SetLength(fEntries,ReadUInt32);
          For i := Low(fEntries) to High(fEntries) do
            If ReadUInt32 = PST_EntrySignature then
              begin
                ReadString(fEntries[i].Name);
                ReadString(fEntries[i].Address);
                ReadString(fEntries[i].Notes);
                ReadString(fEntries[i].Password);
                SetLength(fEntries[i].History,ReadUInt32);
                For j := Low(fEntries[i].History) to High(fEntries[i].History) do
                  begin
                    ReadBuffer(fEntries[i].History[j].Time,SizeOf(TDateTime));
                    ReadString(fEntries[i].History[j].Password);
                  end;
                Result := True;  
              end
            else raise Exception.Create('Wrong entry signature.');
        end;
    finally
      Free;
    end;
  finally
    WorkStream.Free;
  end;
except
  SetLength(fEntries,0);
  Result := False;
end;
end;

//------------------------------------------------------------------------------

procedure TPSTManager.Save;
var
  WorkStream: TMemoryStream;
  i,j:        Integer;
begin
WorkStream := TMemoryStream.Create;
try
  with TStreamStreamer.Create(WorkStream) do
  try
    WriteUInt32(PST_FileSignature);
    WriteUInt32(Length(fEntries));
    For i := Low(fEntries) to High(fEntries) do
      begin
        WriteUInt32(PST_EntrySignature);
        WriteString(fEntries[i].Name);
        WriteString(fEntries[i].Address);
        WriteString(fEntries[i].Notes);
        WriteString(fEntries[i].Password);
        WriteUInt32(Length(fEntries[i].History));
        For j := Low(fEntries[i].History) to High(fEntries[i].History) do
          begin
            WriteBuffer(fEntries[i].History[j].Time,SizeOf(TDateTime));
            WriteString(fEntries[i].History[j].Password);
          end;
      end;
  finally
    Free;
  end;
  EncryptStream(WorkStream);
  WorkStream.Position := 0;
  WorkStream.SaveToFile(fFileName);
finally
  WorkStream.Free;
end;
end;

end.
