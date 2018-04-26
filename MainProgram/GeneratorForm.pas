{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit GeneratorForm;

{$INCLUDE '.\Source\PST_defs.inc'}

interface

uses
  SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs, StdCtrls,
  Spin, ExtCtrls;

type
  TfGeneratorForm = class(TForm)
    leSeed: TLabeledEdit;
    lblMethod: TLabel;
    cbMethod: TComboBox;
    lblLength: TLabel;
    seLength: TSpinEdit;
    lblEncoding: TLabel;    
    cbEncoding: TComboBox;
    btnGenerate: TButton;
    leResult: TLabeledEdit;
    btnAccept: TButton;
    btnCancel: TButton;
    procedure FormShow(Sender: TObject);    
    procedure cbMethodChange(Sender: TObject);
    procedure btnGenerateClick(Sender: TObject);
    procedure btnAcceptClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
  private
    PromptResult: Boolean;
  public
    Function GeneratorPrompt(out Output: String): Boolean;
  end;

var
  fGeneratorForm: TfGeneratorForm;

implementation

{$IFDEF FPC}
  {$R *.lfm}
{$ELSE}
  {$R *.dfm}
{$ENDIF}

uses
  AuxTypes, StrRect, CRC32, MD2, MD4, MD5, SHA0, SHA1, SHA2, SHA3, BinTextEnc,
  BinaryStreaming;

{$IFDEF FPC_DisableWarns}
  {$WARN 5024 OFF} // Parameter "$1" not used
{$ENDIF}

Function TfGeneratorForm.GeneratorPrompt(out Output: String): Boolean;
begin
cbMethod.OnChange(nil);
leSeed.Text := '';
leResult.Text := '';
PromptResult := False;
ShowModal;
Output := leResult.Text;
Result := PromptResult;
end;

//==============================================================================

procedure TfGeneratorForm.FormShow(Sender: TObject);
begin
leSeed.SetFocus;
end;

//------------------------------------------------------------------------------

procedure TfGeneratorForm.cbMethodChange(Sender: TObject);
begin
seLength.Enabled := cbMethod.ItemIndex in [15,20..22];
lblLength.Enabled := seLength.Enabled;
end;

//------------------------------------------------------------------------------

procedure TfGeneratorForm.btnGenerateClick(Sender: TObject);
var
  Seed:     UTF8String;
  MD2Temp:  TMD2Hash;
  MD4Temp:  TMD4Hash;
  MD5Temp:  TMD5Hash;
  SHA0Temp: TSHA0Hash;
  SHA1Temp: TSHA1Hash;
  SHA2Temp: TSHA2Hash;
  Buffer:   TMemoryStream;
  i:        Integer;

  Function EncodeHash(const Hash; Length: PtrUInt): String;
  begin
    case cbEncoding.ItemIndex of
      0:  Result := Encode_Base2(@Hash,Length);
      1:  Result := Encode_Base8(@Hash,Length);
      2:  Result := Encode_Base10(@Hash,Length);
      3:  Result := Encode_Base16(@Hash,Length);
      4:  Result := Encode_Hexadecimal(@Hash,Length);
      5:  Result := Encode_Base32(@Hash,Length);
      6:  Result := Encode_Base32Hex(@Hash,Length);
      7:  Result := Encode_Base64(@Hash,Length);
      8:  Result := Encode_Base85(@Hash,Length);
      9:  Result := Encode_ASCII85(@Hash,Length);
    else
      Result := '';
    end;
  end;

  Function EncodeKeccak(Hash: TSHA3Hash): String;
  begin
    Result := EncodeHash(Hash.HashData[0],Length(Hash.HashData))
  end;

begin
Seed := StrToUTF8(leSeed.Text);
case cbMethod.ItemIndex of
  0:  begin
        MD2Temp := BinaryCorrectMD2(AnsiStringMD2(Seed));
        leResult.Text := EncodeHash(MD2Temp,SizeOf(TMD2Hash));
      end;
  1:  begin
        MD4Temp := BinaryCorrectMD4(AnsiStringMD4(Seed));
        leResult.Text := EncodeHash(MD4Temp,SizeOf(TMD4Hash));
      end;
  2:  begin
        MD5Temp := BinaryCorrectMD5(AnsiStringMD5(Seed));
        leResult.Text := EncodeHash(MD5Temp,SizeOf(TMD5Hash));
      end;
  3:  begin
        SHA0Temp := BinaryCorrectSHA0(AnsiStringSHA0(Seed));
        leResult.Text := EncodeHash(SHA0Temp,SizeOf(TSHA0Hash));
      end;
  4:  begin
        SHA1Temp := BinaryCorrectSHA1(AnsiStringSHA1(Seed));
        leResult.Text := EncodeHash(SHA1Temp,SizeOf(TSHA1Hash));
      end;
  5:  begin
        SHA2Temp := BinaryCorrectSHA2(AnsiStringSHA2(sha224,Seed));
        leResult.Text := EncodeHash(SHA2Temp.Hash224,28);
      end;
  6:  begin
        SHA2Temp := BinaryCorrectSHA2(AnsiStringSHA2(sha256,Seed));
        leResult.Text := EncodeHash(SHA2Temp.Hash256,32);
      end;
  7:  begin
        SHA2Temp := BinaryCorrectSHA2(AnsiStringSHA2(sha384,Seed));
        leResult.Text := EncodeHash(SHA2Temp.Hash384,48);
      end;
  8:  begin
        SHA2Temp := BinaryCorrectSHA2(AnsiStringSHA2(sha512,Seed));
        leResult.Text := EncodeHash(SHA2Temp.Hash512,64);
      end;
  9:  begin
        SHA2Temp := BinaryCorrectSHA2(AnsiStringSHA2(sha512_224,Seed));
        leResult.Text := EncodeHash(SHA2Temp.Hash512_224,28);
      end;
  10: begin
        SHA2Temp := BinaryCorrectSHA2(AnsiStringSHA2(sha512_256,Seed));
        leResult.Text := EncodeHash(SHA2Temp.Hash512_256,32);
      end;
  11: leResult.Text := EncodeKeccak(BinaryCorrectSHA3(AnsiStringSHA3(Keccak224,Seed)));
  12: leResult.Text := EncodeKeccak(BinaryCorrectSHA3(AnsiStringSHA3(Keccak256,Seed)));
  13: leResult.Text := EncodeKeccak(BinaryCorrectSHA3(AnsiStringSHA3(Keccak384,Seed)));
  14: leResult.Text := EncodeKeccak(BinaryCorrectSHA3(AnsiStringSHA3(Keccak512,Seed)));
  15: leResult.Text := EncodeKeccak(BinaryCorrectSHA3(AnsiStringSHA3(Keccak_b,Seed,seLength.Value)));
  16: leResult.Text := EncodeKeccak(BinaryCorrectSHA3(AnsiStringSHA3(SHA3_224,Seed)));
  17: leResult.Text := EncodeKeccak(BinaryCorrectSHA3(AnsiStringSHA3(SHA3_256,Seed)));
  18: leResult.Text := EncodeKeccak(BinaryCorrectSHA3(AnsiStringSHA3(SHA3_384,Seed)));
  19: leResult.Text := EncodeKeccak(BinaryCorrectSHA3(AnsiStringSHA3(SHA3_512,Seed)));
  20: leResult.Text := EncodeKeccak(BinaryCorrectSHA3(AnsiStringSHA3(SHAKE128,Seed,seLength.Value)));
  21: leResult.Text := EncodeKeccak(BinaryCorrectSHA3(AnsiStringSHA3(SHAKE256,Seed,seLength.Value)));
  22: begin
        Buffer := TMemoryStream.Create;
        try
          If Seed <> '' then
            RandSeed := AnsiStringCRC32(Seed)
          else
            Randomize;
          For i := 1 to (seLength.Value shr 3) do
            Stream_WriteUInt8(Buffer,UInt8(Random(256)));
          leResult.Text := EncodeHash(Buffer.Memory^,seLength.Value shr 3);
        finally
          Buffer.Free;
        end;
      end;
end;
end;

//------------------------------------------------------------------------------

procedure TfGeneratorForm.btnAcceptClick(Sender: TObject);
begin
If leResult.Text <> '' then
  begin
    PromptResult := True;
    Close;
  end
else MessageDlg('Resulting password cannot be empty.',mtError,[mbOk],0);
end;

//------------------------------------------------------------------------------

procedure TfGeneratorForm.btnCancelClick(Sender: TObject);
begin
Close;
end;

end.
