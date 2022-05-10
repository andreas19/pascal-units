unit Gemina;
{< Implementation of the
   @url(https://github.com/andreas19/gemina-spec Gemina)
   specification for data encryption.

   For more details see the section
   @url(https://github.com/andreas19/gemina-spec#description Description).

   This unit belongs to @link(docs_overview PascalUnits) and
   is published under the @link(docs_license BSD 3-Clause License).

   Dependencies:
   @url(https://github.com/Xor-el/CryptoLib4Pascal  CryptoLib4Pascal)
   package.
}

{$mode ObjFPC}{$H+}

interface

uses
  SysUtils, ClpRandomNumberGenerator, ClpPkcs5S2ParametersGenerator,
  ClpDigestUtilities, ClpICipherParameters, ClpKeyParameter,
  ClpMacUtilities, ClpArrayUtils, ClpCipherUtilities, ClpIBufferedCipher,
  ClpParametersWithIV, ClpParameterUtilities;

type
  { Version enum. }
  TVersion = (Version1, Version2, Version3, Version4);

{ Create a secret key. It can be used with the functions
  @link(EncryptWithKey), @link(DecryptWithKey), and @link(VerifyWithKey).

  @param(version - the version)
  @returns(the secret key) }
function CreateSecretKey(version: TVersion): TBytes;

{ Decrypt data with a secret key.

  @param(key - the secret key)
  @param(data - the data to decrypt)
  @returns(decrypted data or @nil if decryption failed) }
function DecryptWithKey(key, data: TBytes): TBytes;

{ Decrypt data with a password.

  @param(password - the password)
  @param(data - the data to decrypt)
  @return(decrypted data or @nil if decryption failed) }
function DecryptWithPassword(password, data: TBytes): TBytes;

{ Encrypt data with a secret key.

  @param(key - the secret key)
  @param(data - the data to encrypt)
  @param(version - the version)
  @returns(encrypted data or @nil if encryption failed) }
function EncryptWithKey(key, data: TBytes; version: TVersion): TBytes;

{ Encrypt data with a password.

  @param(password - the password)
  @param(data - the data to encrypt)
  @param(version - the version)
  @returns(encrypted data or @nil if encryption failed) }
function EncryptWithPassword(password, data: TBytes;
  version: TVersion): TBytes;

{ Verify data with a secret key.

  @param(key - the secret key)
  @param(data - the data)
  @returns(@true if secret key, authenticity and integrity are okay) }
function VerifyWithKey(key, data: TBytes): boolean;

{ Verify data with a password.

  @param(password - the password)
  @param(data - the data)
  @returns(@true if secret key, authenticity and integrity are okay) }
function VerifyWithPassword(password, data: TBytes): boolean;

implementation

type
  TVersionProps = record
    VersionByte: byte;
    EncKeyLen, MACKeyLen: integer;
  end;

const
  VersionProps: array[TVersion] of TVersionProps = (
    (VersionByte: $8a; EncKeyLen: 16; MACKeyLen: 16),
    (VersionByte: $8b; EncKeyLen: 16; MACKeyLen: 32),
    (VersionByte: $8c; EncKeyLen: 24; MACKeyLen: 32),
    (VersionByte: $8d; EncKeyLen: 32; MACKeyLen: 32));
  Iterations = 100000;
  VersionLength = 1; // Byte
  SaltLength = 16; // Bytes
  IVLength = 16; // Bytes
  BlockLength = 16; // Bytes
  MACLength = 32; // Bytes

var
  RandNumGen: TOSRandomNumberGenerator;
  PBKDF2Gen: TPkcs5S2ParametersGenerator;

function VersionPropsFromData(data: TBytes; var props: TVersionProps): boolean;
begin
  if (length(data) > VersionLength) then
  begin
    Result := True;
    case data[0] of
      $8a: props := VersionProps[Version1];
      $8b: props := VersionProps[Version2];
      $8c: props := VersionProps[Version3];
      $8d: props := VersionProps[Version4];
      else
        Result := False;
    end;
  end
  else
    Result := False;
end;

function DeriveKey(password, salt: TBytes; props: TVersionProps): TBytes;
var
  params: ICipherParameters;
begin
  if salt = nil then
    Result := nil
  else
  begin
    PBKDF2Gen.Clear;
    PBKDF2Gen.Init(password, salt, Iterations);
    params := PBKDF2Gen.GenerateDerivedMacParameters(
      (props.EncKeyLen + props.MACKeyLen) * 8);
    Result := (params as TKeyParameter).GetKey;
  end;
end;

function GetEncKey(key: TBytes; props: TVersionProps): TBytes;
begin
  Result := Copy(key, 0, props.EncKeyLen);
end;

function GetMACKey(key: TBytes; props: TVersionProps): TBytes;
begin
  Result := Copy(key, props.EncKeyLen, props.MACKeyLen);
end;

function Decrypt(key, salt, data: TBytes; props: TVersionProps): TBytes;
var
  cipher: IBufferedCipher;
begin
  cipher := TCipherUtilities.GetCipher('AES/CBC/PKCS7PADDING');
  cipher.Init(False, TParametersWithIV.Create(
    TParameterUtilities.CreateKeyParameter('AES', GetEncKey(key, props)),
    Copy(data, VersionLength + length(salt), IVLength)));
  Result := cipher.DoFinal(data, VersionLength + length(salt) +
    IVLength, length(data) - VersionLength - length(salt) -
    IVLength - MACLength);
end;

function Decrypt(key, salt, data: TBytes): TBytes;
var
  props: TVersionProps;
begin
  if VersionPropsFromData(data, props) then
    Result := Decrypt(key, salt, data, props)
  else
    Result := nil;
end;

function Encrypt(key, salt, data: TBytes; props: TVersionProps): TBytes;
var
  cipher: IBufferedCipher;
  iv, encdata: TBytes;
begin
  if (length(key) = props.EncKeyLen + props.MACKeyLen) then
  begin
    setlength(iv, IVLength);
    RandNumGen.GetBytes(iv);
    cipher := TCipherUtilities.GetCipher('AES/CBC/PKCS7PADDING');
    cipher.Init(True, TParametersWithIV.Create(
      TParameterUtilities.CreateKeyParameter(
      'AES', GetEncKey(key, props)), iv));
    encdata := cipher.DoFinal(data);
    Result := TBytes.Create(props.VersionByte);
    if salt <> nil then Result := Concat(Result, salt);
    Result := Concat(Result, iv, encdata);
    Result := Concat(Result, TMacUtilities.CalculateMac('HMAC-SHA256',
      TKeyParameter.Create(GetMACKey(key, props)), Result));
  end
  else
    Result := nil;
end;

function Verify(key, salt, data: TBytes; props: TVersionProps): boolean;
begin
  if (length(key) = props.EncKeyLen + props.MACKeyLen) and
    (length(data) >= VersionLength + length(salt) + IVLength +
    BlockLength + MACLength) then
  begin
    Result := TArrayUtils.AreEqual(
      Copy(data, length(data) - MACLength, MACLength),
      TMacUtilities.CalculateMac('HMAC-SHA256',
      TKeyParameter.Create(GetMACKey(key, props)),
      Copy(data, 0, length(data) - MACLength)));
  end
  else
    Result := False;
end;

function Verify(key, salt, data: TBytes): boolean;
var
  props: TVersionProps;
begin
  if VersionPropsFromData(data, props) then
    Result := Verify(key, salt, data, props)
  else
    Result := False;
end;

function GetSalt(data: TBytes): TBytes;
var
  salt: TBytes;
begin
  if data = nil then
  begin
    setlength(salt, SaltLength);
    RandNumGen.GetBytes(salt);
  end
  else
  if length(data) >= VersionLength + SaltLength then
    salt := Copy(data, VersionLength, SaltLength);

  Result := salt;
end;

function CreateSecretKey(version: TVersion): TBytes;
var
  props: TVersionProps;
  key: TBytes;
begin
  props := VersionProps[version];
  setlength(key, props.EncKeyLen + props.MACKeyLen);
  RandNumGen.GetBytes(key);
  Result := key;
end;

function DecryptWithKey(key, data: TBytes): TBytes;
begin
  if Verify(key, nil, data) then
    Result := Decrypt(key, nil, data)
  else
    Result := nil;
end;

function DecryptWithPassword(password, data: TBytes): TBytes;
var
  key, salt: TBytes;
  props: TVersionProps;
begin
  if VersionPropsFromData(data, props) then
  begin
    salt := GetSalt(data);
    key := DeriveKey(password, salt, props);
    if Verify(key, salt, data, props) then
      Result := Decrypt(key, salt, data, props)
    else
      Result := nil;
  end
  else
    Result := nil;
end;

function EncryptWithKey(key, data: TBytes; version: TVersion): TBytes;
begin
  Result := Encrypt(key, nil, data, VersionProps[version]);
end;

function EncryptWithPassword(password, data: TBytes;
  version: TVersion): TBytes;
var
  key, salt: TBytes;
begin
  salt := GetSalt(nil);
  key := DeriveKey(password, salt, VersionProps[version]);
  Result := Encrypt(key, salt, data, VersionProps[version]);
end;

function VerifyWithKey(key, data: TBytes): boolean;
begin
  Result := Verify(key, nil, data);
end;

function VerifyWithPassword(password, data: TBytes): boolean;
var
  key, salt: TBytes;
  props: TVersionProps;
begin
  if VersionPropsFromData(data, props) then
  begin
    salt := GetSalt(data);
    key := DeriveKey(password, salt, props);
    Result := Verify(key, salt, data, props);
  end
  else
    Result := False;
end;

initialization
  begin
    RandNumGen := TOSRandomNumberGenerator.Create();
    PBKDF2Gen := TPkcs5S2ParametersGenerator.Create(
      TDigestUtilities.GetDigest('SHA-256'));
  end;

finalization
  begin
    RandNumGen.Free;
    PBKDF2Gen.Free;
  end;

end.
