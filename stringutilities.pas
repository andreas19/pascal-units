unit StringUtilities;
{< Some utility functions for strings.

   This unit belongs to @link(docs_overview PascalUnits) and
   is published under the @link(docs_license BSD 3-Clause License).

   Dependencies: ./.
}

{$mode ObjFPC}{$H+}

interface

uses
  SysUtils, fgl, RegExpr;

type
  { Type for mapping strings to booleans. }
  TStringToBooleanMap = specialize TFPGMap<string, boolean>;
  { Array of strings. }
  TStringArray = array of string;
  { Array of integers. }
  TIntegerArray = array of integer;
  { Array of floats. }
  TFloatArray = array of extended;
  { Array of booleans. }
  TBooleanArray = array of boolean;

var
  { Mappings from strings to booleans.

    This is used by the @link(StringToBoolean) function and can be modified.
    The default values are:

    @unorderedList(
      @item('1', 't', 'true', 'on', 'y', 'yes', 'j', 'ja' -> @true)
      @item('0', 'f', 'false', 'off', 'n', 'no', 'nein' -> @false)) }
  StringToBooleanMap: TStringToBooleanMap;

{ Convert a string to a boolean value.

  The string is converted to lowercase before looked up in the
  @link(StringToBooleanMap).

  @param(str - the string)
  @returns(the boolean value)
  @raises(EConvertError if a value cannot be converted) }
function StringToBoolean(str: string): boolean;

{ Split a string into a string array.

  @param(str - the string)
  @param(sep - the separator)
  @returns(string array)
  @raises(EConvertError if a value cannot be converted) }
function StringToStringArray(str, sep: string): TStringArray;

{ Split a string into a integer array.

  @param(str - the string)
  @param(sep - the separator)
  @returns(integer array)
  @raises(EConvertError if a value cannot be converted) }
function StringToIntegerArray(str, sep: string): TIntegerArray;

{ Split a string into a float array.

  @param(str - the string)
  @param(sep - the separator)
  @returns(float array)
  @raises(EConvertError if a value cannot be converted) }
function StringToFloatArray(str, sep: string): TFloatArray;

{ Split a string into a boolean array.

  Uses the @link(StringToBoolean) function.

  @param(str - the string)
  @param(sep - the separator)
  @returns(boolean array)
  @raises(EConvertError if a value cannot be converted) }
function StringToBooleanArray(str, sep: string): TBooleanArray;

{ Purge a string.

  If @italic(strs) is empty all consecutive whitespace characters will be
  replaced with a single space character.

  @param(str - the string)
  @param(strs - strings to be removed from @italic(str))
  @returns(purged string) }
function Purge(str: string; strs: TStringArray): string;

implementation

function StringToBoolean(str: string): boolean;
var
  idx: integer;
begin
  idx := StringToBooleanMap.IndexOf(LowerCase(str));
  if idx < 0 then raise EConvertError.Create('"' + str +'" not found');
  Result := StringToBooleanMap.Data[idx];
end;

function StringToStringArray(str, sep: string): TStringArray;
var i: integer;
begin
  Result := str.Split([sep]);
  for i := 0 to length(Result) - 1 do
    Result[i] := Trim(Result[i]);
end;

function StringToIntegerArray(str, sep: string): TIntegerArray;
var
  i: integer;
  ar: TStringArray;
begin
  ar := StringToStringArray(str, sep);
  Result := TIntegerArray.create;
  setLength(Result, length(ar));
  for i := 0 to length(ar) - 1 do
    Result[i] := ar[i].ToInteger;
end;

function StringToFloatArray(str, sep: string): TFloatArray;
var
  i: integer;
  ar: TStringArray;
begin
  ar := StringToStringArray(str, sep);
  Result := TFloatArray.create;
  setLength(Result, length(ar));
  for i := 0 to length(ar) - 1 do
    Result[i] := ar[i].ToExtended;
end;

function StringToBooleanArray(str, sep: string): TBooleanArray;
var
  i: integer;
  ar: TStringArray;
begin
  ar := StringToStringArray(str, sep);
  Result := TBooleanArray.create;
  setLength(Result, length(ar));
  for i := 0 to length(ar) - 1 do
    Result[i] := StringToBoolean(ar[i]);
end;

function Purge(str: string; strs: TStringArray): string;
begin
  if length(strs) = 0 then
    Result := ReplaceRegExpr('\s+', str, ' ')
  else
    Result := ReplaceRegExpr('(?:' + ''.Join('|', strs) + ')', str, '');
end;

initialization
  begin
    StringToBooleanMap := TStringToBooleanMap.Create;
    StringToBooleanMap.Add('1', True);
    StringToBooleanMap.Add('t', True);
    StringToBooleanMap.Add('true', True);
    StringToBooleanMap.Add('on', True);
    StringToBooleanMap.Add('y', True);
    StringToBooleanMap.Add('yes', True);
    StringToBooleanMap.Add('j', True);
    StringToBooleanMap.Add('ja', True);
    StringToBooleanMap.Add('0', False);
    StringToBooleanMap.Add('f', False);
    StringToBooleanMap.Add('false', False);
    StringToBooleanMap.Add('off', False);
    StringToBooleanMap.Add('n', False);
    StringToBooleanMap.Add('no', False);
    StringToBooleanMap.Add('nein', False);
  end;

finalization
  begin
    StringToBooleanMap.Free;
  end;

end.
