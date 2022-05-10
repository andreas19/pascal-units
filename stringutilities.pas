unit StringUtilities;
{< Some utility functions for strings.

   This unit belongs to @link(docs_overview PascalUnits) and
   is published under the @link(docs_license BSD 3-Clause License).

   Dependencies: ./.
}

{$mode ObjFPC}{$H+}

interface

uses
  SysUtils, fgl;

type
  { Type for mapping strings to booleans. }
  TStringToBooleanMap = specialize TFPGMap<string, boolean>;

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
  @param(bool - the boolean value)
  @returns(@true if str was found in the map, @false otherwise) }
function StringToBoolean(str: string; var bool: boolean): boolean;

implementation

function StringToBoolean(str: string; var bool: boolean): boolean;
var
  idx: integer;
begin
  idx := StringToBooleanMap.IndexOf(str);
  Result := idx >= 0;
  if Result then bool := StringToBooleanMap.Data[idx];
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
