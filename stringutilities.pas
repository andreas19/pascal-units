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
  TStringToBooleanMap = specialize TFPGMap<string, boolean>;

var
  StringToBooleanMap: TStringToBooleanMap;

function StringToBoolean(s: string; var b: boolean): boolean;

implementation

function StringToBoolean(s: string; var b: boolean): boolean;
var
  idx: integer;
begin
  idx := StringToBooleanMap.IndexOf(s);
  Result := idx >= 0;
  if Result then b := StringToBooleanMap.Data[idx];
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
