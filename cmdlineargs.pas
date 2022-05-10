unit CmdLineArgs;
{< Command line arguments parsing.

   This unit belongs to @link(docs_overview PascalUnits) and
   is published under the @link(docs_license BSD 3-Clause License).

   Dependencies: ./.
}

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, getopts, Math, StrUtils;

type
  { Array of integers. }
  TIntegerArray = array of integer;
  { Array of floats. }
  TFloatArray = array of extended;
  { Array of strings. }
  TStringArray = array of string;
  { Error in the definition of command line arguments. }
  ECmdLineArgsException = class(Exception);
  { @exclude }
  TArgKind = (akFlag, akOption, akPositional);

  { Class for defining command line arguments. }
  TCmdLineArgs = class
  private
  type
    PArg = ^TArg;

    TArg = record
      name, help, value, metavar: string;
      abbr: char;
      multiple, required: boolean;
      kind: TArgKind;
      values: TStringArray;
    end;
  var
    fDescription: string;
    fEpilog: string;
    fVersion: string;
    fUsage: string;
    fHelpArg: PArg;
    fVersionArg: PArg;
    fArgArray: array of PArg;
    fMaxLenName: integer;
    fHasAbbr: boolean;
    fHasMultiplePos: boolean;
    fLongFlagsAndOptsCnt: integer;
    fPositionalsCnt: integer;
    function CreateArg(name, help, value, metavar: string;
      abbr: char; multiple, required: boolean; kind: TArgKind): PArg;
    function GetArgByName(name: string): PArg;
    function GetArgByAbbr(abbr: char): PArg;
    function FormatHelp: string;
    function FormatLine(arg: PArg; width: integer): string;
    procedure CheckNameAndAbbr(name: string; abbr: char);
    procedure CheckArgs;
    procedure AddValue(arg: PArg; value: string);
    procedure WriteErrMsg(arg: PArg; msg: string);
    function IsFlagSet(arg: PArg): boolean;
    function GetFlagCount(arg: PArg): integer;
    function GetInteger(arg: PArg): integer;
    function GetIntegers(arg: PArg): TIntegerArray;
    function GetFloat(arg: PArg): extended;
    function GetFloats(arg: PArg): TFloatArray;
    function GetString(arg: PArg): string;
    function GetStrings(arg: PArg): TStringArray;
  public
    { Constructor.

      @param(description - short description of the program)
      @param(epilog - displayed at the end of the help text)
      @param(version - required when @link(AddVersion) is used)
      @param(usage - the usage string in the first line after
             @code(USAGE: <program name>)) }
    constructor Create(description: string;
      epilog: string = ''; version: string = '';
      usage: string = '[FLAG | OPTION | POSITIONAL ARGUMENT] ...');

    { Add a flag.

      A flag can be used on the command line by prefixing its name with
      '@--' or the abbrevation character with '-'. Either the name or the
      abbrevation can be set to '' or #0 respectively so that it is not used.

      @param(name - name of the flag)
      @param(abbr - abbrevation)
      @param(help - help text)
      @param(multiple - if @true the flag can be used multiple times) }
    procedure AddFlag(name: string; abbr: char; help: string;
      multiple: boolean = False);

    { Add an option.

      An option can be used on the command line by prefixing its name with
      '@--' or the abbrevation character with '-'. Either the name or the
      abbrevation can be set to '' or #0 respectively so that it is not used.

      @param(name - name of the option)
      @param(abbr - abbrevation)
      @param(help - help text)
      @param(value - if not the empty string, it is the value when the
             option is used like a flag (w/o a value))
      @param(required - if @true it must be used at least once)
      @param(multiple - if @true the option can be used multiple times) }
    procedure AddOption(name: string; abbr: char; help: string;
      value: string = ''; required: boolean = False;
      multiple: boolean = False);

    { Add a postional argument.

      @param(name - name of the argument)
      @param(help - help text)
      @param(value - default value)
      @param(required - if @true it must be used at least once)
      @param(multiple - if @true the option can be used multiple times)
      @param(metavar - shown in the help text instead of the name) }
    procedure AddPositional(name, help: string; value: string = '';
      required: boolean = False; multiple: boolean = False;
      metavar: string = '');

    { Add a help flag.

      @param(name - name of the flag)
      @param(abbr - abbrevation)
      @param(help - help text) }
    procedure AddHelp(name: string = 'help'; abbr: char = 'h';
      help: string = 'show this help message and exit');

    { Add a version flag.

      @param(name - name of the flag)
      @param(abbr - abbrevation)
      @param(help - help text) }
    procedure AddVersion(name: string = 'version'; abbr: char = 'V';
      help: string = 'show version and exit');

    { Parse the command line. }
    procedure Parse;

    { Check if a flag/option/positional argument was set on the command line. }
    function HasName(name: string): boolean;

    { Check if a flag/option/positional argument was set on the command line. }
    function HasAbbr(abbr: char): boolean;

    function IsFlagSet(name: string): boolean;
    function IsFlagSet(abbr: char): boolean;
    function GetFlagCount(name: string): integer;
    function GetFlagCount(abbr: char): integer;
    function GetInteger(name: string): integer;
    function GetInteger(abbr: char): integer;
    function GetIntegers(name: string): TIntegerArray;
    function GetIntegers(abbr: char): TIntegerArray;
    function GetFloat(name: string): extended;
    function GetFloat(abbr: char): extended;
    function GetFloats(name: string): TFloatArray;
    function GetFloats(abbr: char): TFloatArray;
    function GetString(name: string): string;
    function GetString(abbr: char): string;
    function GetStrings(name: string): TStringArray;
    function GetStrings(abbr: char): TStringArray;
  end;

implementation

{ TCmdLineArgs }

function TCmdLineArgs.CreateArg(name, help, value, metavar: string;
  abbr: char; multiple, required: boolean; kind: TArgKind): PArg;
begin
  Result := new(PArg);
  Result^.name := name;
  Result^.help := help;
  Result^.value := value;
  Result^.metavar := metavar;
  Result^.abbr := abbr;
  Result^.multiple := multiple;
  Result^.required := required;
  Result^.kind := kind;
end;

function TCmdLineArgs.GetArgByName(name: string): PArg;
var
  arg: PArg;
begin
  Result := nil;
  if name <> '' then
    for arg in fArgArray do
    begin
      if arg^.name = name then
      begin
        Result := arg;
        break;
      end;
    end;
end;

function TCmdLineArgs.GetArgByAbbr(abbr: char): PArg;
var
  arg: PArg;
begin
  Result := nil;
  if abbr <> #0 then
    for arg in fArgArray do
    begin
      if arg^.abbr = abbr then
      begin
        Result := arg;
        break;
      end;
    end;
end;

function TCmdLineArgs.FormatHelp: string;
var
  flags, options, positionals: string;
  width: integer;
  arg: PArg;
begin
  flags := '';
  options := '';
  positionals := '';
  width := 0;

  if fHasAbbr then width := 2;
  if fHasAbbr and (fMaxLenName > 0) then width := width + 2;
  if fMaxLenName > 0 then width := width + 2 + fMaxLenName;

  Result := 'USAGE: ' + ApplicationName + ' ' + fUsage + LineEnding;

  if fDescription <> '' then
    Result := Result + LineEnding + fDescription + LineEnding;

  for arg in fArgArray do
  begin
    if arg^.kind = akFlag then
      flags := flags + FormatLine(arg, width);

    if arg^.kind = akOption then
      options := options + FormatLine(arg, width);

    if arg^.kind = akPositional then
      positionals := positionals + FormatLine(arg, width);
  end;

  if flags <> '' then
    Result := Result + LineEnding + 'FLAGS' + LineEnding + flags;

  if options <> '' then
    Result := Result + LineEnding + 'OPTIONS' + LineEnding + options;

  if positionals <> '' then
    Result := Result + LineEnding + 'POSITIONAL' + LineEnding + positionals;

  if fEpilog <> '' then
    Result := Result + LineEnding + fEpilog + LineEnding;
end;

function TCmdLineArgs.FormatLine(arg: PArg; width: integer): string;
var
  s, symbol: string;
begin
  if arg^.kind = akPositional then
    if arg^.metavar <> '' then
      s := arg^.metavar
    else
      s := arg^.name
  else
  begin
    if fHasAbbr then
    begin
      if arg^.abbr = #0 then s := '  '
      else
        s := '-' + arg^.abbr;
      if (arg^.name = '') or (arg^.abbr = #0) then
        s := s + '  '
      else
        s := s + ', ';
    end;
    if arg^.name <> '' then s := s + '--' + arg^.name;
  end;

  if arg^.multiple and arg^.required then
    symbol := '+'
  else if arg^.multiple then
    symbol := '*'
  else if arg^.required then
    symbol := '!'
  else
    symbol := ' ';

  Result := Format(' %-*s %s ', [width, s, symbol]) + arg^.help + LineEnding;
end;

procedure TCmdLineArgs.CheckNameAndAbbr(name: string; abbr: char);
begin
  if (name = '') and (abbr = #0) then
    raise ECmdLineArgsException.Create('name and abbrevation not set');

  if (abbr <> #0) and (GetArgByAbbr(abbr) <> nil) then
    raise ECmdLineArgsException.Create('abbrevation "' + abbr +
      '" already exists');

  if (name <> '') and (GetArgByName(name) <> nil) then
    raise ECmdLineArgsException.Create('name "' + name + '" already exists');

  fMaxLenName := Max(fMaxLenName, length(name));
  if not fHasAbbr and (abbr <> #0) then fHasAbbr := True;
end;

procedure TCmdLineArgs.CheckArgs;
var
  arg: PArg;
begin
  for arg in fArgArray do
    if arg^.required and (length(arg^.values) = 0) then
      WriteErrMsg(arg, 'missing required');
end;

procedure TCmdLineArgs.AddValue(arg: PArg; value: string);
begin
  if not arg^.multiple and (length(arg^.values) > 0) then
    WriteErrMsg(arg, 'option not multiple');
  setlength(arg^.values, length(arg^.values) + 1);
  arg^.values[length(arg^.values) - 1] := value;
end;

procedure TCmdLineArgs.WriteErrMsg(arg: PArg; msg: string);
begin
  write(argv[0], ': ', msg);
  if arg = nil then
    writeln
  else
    writeln(' -- ', IfThen(arg^.name = '', arg^.abbr, arg^.name));
  halt;
end;

function TCmdLineArgs.IsFlagSet(arg: PArg): boolean;
var
  msg: string;
begin
  if arg^.kind = akFlag then
    Result := length(arg^.values) > 0
  else
  begin
    msg := 'not a flag: ';
    if arg^.name = '' then msg := msg + arg^.abbr else msg := msg + arg^.name;
    raise ECmdLineArgsException.Create(msg);
  end;
end;

function TCmdLineArgs.GetFlagCount(arg: PArg): integer;
var
  msg: string;
begin
  if arg^.kind = akFlag then
    Result := length(arg^.values)
  else
  begin
    msg := 'not a flag: ';
    if arg^.name = '' then msg := msg + arg^.abbr else msg := msg + arg^.name;
    raise ECmdLineArgsException.Create(msg);
  end;
end;

function TCmdLineArgs.GetInteger(arg: PArg): integer;
begin
  Result := StrToInt(arg^.values[0]);
end;

function TCmdLineArgs.GetIntegers(arg: PArg): TIntegerArray;
var
  idx: integer;
begin
  Result := TIntegerArray.Create;
  setlength(Result, length(arg^.values));
  for idx := 0 to length(Result) - 1 do
    Result[idx] := StrToInt(arg^.values[idx]);
end;

function TCmdLineArgs.GetFloat(arg: PArg): extended;
begin
  Result := StrToFloat(arg^.values[0]);
end;

function TCmdLineArgs.GetFloats(arg: PArg): TFloatArray;
var
  idx: integer;
begin
  Result := TFloatArray.Create;
  setlength(Result, length(arg^.values));
  for idx := 0 to length(Result) - 1 do
    Result[idx] := StrToFloat(arg^.values[idx]);
end;

function TCmdLineArgs.GetString(arg: PArg): string;
begin
  Result := arg^.values[0];
end;

function TCmdLineArgs.GetStrings(arg: PArg): TStringArray;
var
  idx: integer;
begin
  Result := TStringArray.Create;
  setlength(Result, length(arg^.values));
  for idx := 0 to length(Result) - 1 do
    Result[idx] := arg^.values[idx];
end;

constructor TCmdLineArgs.Create(description, epilog, version: string;
  usage: string);
begin
  inherited Create;
  fDescription := StringReplace(description, '\n', LineEnding, [rfReplaceAll]);
  fEpilog := StringReplace(epilog, '\n', LineEnding, [rfReplaceAll]);
  fVersion := version;
  fUsage := StringReplace(usage, '\n', LineEnding, [rfReplaceAll]);
end;

procedure TCmdLineArgs.AddFlag(name: string; abbr: char;
  help: string; multiple: boolean);
begin
  CheckNameAndAbbr(name, abbr);
  setlength(fArgArray, length(fArgArray) + 1);
  fArgArray[length(fArgArray) - 1] :=
    CreateArg(name, help, '', '', abbr, multiple, False, akFlag);
  if name <> '' then
    fLongFlagsAndOptsCnt := fLongFlagsAndOptsCnt + 1;
end;

procedure TCmdLineArgs.AddOption(name: string; abbr: char;
  help: string; value: string; required: boolean; multiple: boolean);
begin
  CheckNameAndAbbr(name, abbr);
  setlength(fArgArray, length(fArgArray) + 1);
  fArgArray[length(fArgArray) - 1] :=
    CreateArg(name, help, value, '', abbr, multiple, required, akOption);
  if name <> '' then
    fLongFlagsAndOptsCnt := fLongFlagsAndOptsCnt + 1;
end;

procedure TCmdLineArgs.AddPositional(name, help: string;
  value: string; required: boolean; multiple: boolean; metavar: string);
begin
  if multiple then
    if fHasMultiplePos then
      raise ECmdLineArgsException.Create('only last postional can be multiple')
    else
      fHasMultiplePos := True;
  CheckNameAndAbbr(name, #0);
  setlength(fArgArray, length(fArgArray) + 1);
  fArgArray[length(fArgArray) - 1] :=
    CreateArg(name, help, value, metavar, #0, multiple, required,
    akPositional);
  fPositionalsCnt := fPositionalsCnt + 1;
end;

procedure TCmdLineArgs.AddHelp(name: string; abbr: char; help: string);
begin
  AddFlag(name, abbr, help, False);
  fHelpArg := fArgArray[length(fArgArray) - 1];
end;

procedure TCmdLineArgs.AddVersion(name: string; abbr: char; help: string);
begin
  if fVersion = '' then
    raise ECmdLineArgsException.Create('version not set');
  AddFlag(name, abbr, help, False);
  fVersionArg := fArgArray[length(fArgArray) - 1];
end;

procedure TCmdLineArgs.Parse;
var
  shortOpts: string;
  longOpts: array of TOption;
  idx, posIdx: integer;
  arg: PArg;
  c: char;
  positionals: array of PArg;
begin
  OptErr := True;
  shortOpts := '';
  setlength(longOpts, fLongFlagsAndOptsCnt + 1);
  idx := 0;
  setlength(positionals, fPositionalsCnt);
  posIdx := 0;

  for arg in fArgArray do
  begin
    if arg^.kind = akPositional then
    begin
      positionals[posIdx] := arg;
      Inc(posIdx);
    end
    else
    begin
      if arg^.name <> '' then
      begin
        longOpts[idx].Name := arg^.name;
        if arg^.kind = akOption then
          if arg^.value = '' then
            longOpts[idx].Has_arg := Required_Argument
          else
            longOpts[idx].Has_arg := Optional_Argument;
        Inc(idx);
      end;

      if arg^.abbr <> #0 then
      begin
        shortOpts := shortOpts + arg^.abbr;
        if arg^.kind = akOption then
          if arg^.value = '' then
            shortOpts := shortOpts + ':'
          else
            shortOpts := shortOpts + '::';
      end;
    end;
  end;

  repeat
    c := GetLongOpts(shortOpts, @longOpts[0], idx);
    if c = '?' then halt;

    if c = #0 then
      arg := GetArgByName(longOpts[idx - 1].Name)
    else
      arg := GetArgByAbbr(c);

    if arg = fHelpArg then
    begin
      writeln(FormatHelp);
      halt;
    end;

    if arg = fVersionArg then
    begin
      writeln(fVersion);
      halt;
    end;

    if arg <> nil then
      if arg^.kind = akFlag then
        AddValue(arg, '')
      else if arg^.kind = akOption then
        if OptArg = '' then
          AddValue(arg, arg^.value)
        else
          AddValue(arg, OptArg);
  until c = EndOfOptions;

  posIdx := 0;

  while OptInd <= ParamCount do
  begin
    if posIdx = fPositionalsCnt then
      WriteErrMsg(nil, 'too many arguments');
    AddValue(positionals[posIdx], ParamStr(OptInd));
    if not positionals[posIdx]^.multiple then
      Inc(posIdx);
    Inc(OptInd);
  end;

  CheckArgs;
end;

function TCmdLineArgs.HasName(name: string): boolean;
var
  arg: PArg;
begin
  arg := GetArgByName(name);
  Result := (arg <> nil) and (length(arg^.values) > 0);
end;

function TCmdLineArgs.HasAbbr(abbr: char): boolean;
var
  arg: PArg;
begin
  arg := GetArgByAbbr(abbr);
  Result := (arg <> nil) and (length(arg^.values) > 0);
end;

function TCmdLineArgs.IsFlagSet(name: string): boolean;
begin
  Result := IsFlagSet(GetArgByName(name));
end;

function TCmdLineArgs.IsFlagSet(abbr: char): boolean;
begin
  Result := IsFlagSet(GetArgByAbbr(abbr));
end;

function TCmdLineArgs.GetFlagCount(name: string): integer;
begin
  Result := GetFlagCount(GetArgByName(name));
end;

function TCmdLineArgs.GetFlagCount(abbr: char): integer;
begin
  Result := GetFlagCount(GetArgByAbbr(abbr));
end;

function TCmdLineArgs.GetInteger(name: string): integer;
begin
  Result := GetInteger(GetArgByName(name));
end;

function TCmdLineArgs.GetInteger(abbr: char): integer;
begin
  Result := GetInteger(GetArgByAbbr(abbr));
end;

function TCmdLineArgs.GetIntegers(name: string): TIntegerArray;
begin
  Result := GetIntegers(GetArgByName(name));
end;

function TCmdLineArgs.GetIntegers(abbr: char): TIntegerArray;
begin
  Result := GetIntegers(GetArgByAbbr(abbr));
end;

function TCmdLineArgs.GetFloat(name: string): extended;
begin
  Result := GetFloat(GetArgByName(name));
end;

function TCmdLineArgs.GetFloat(abbr: char): extended;
begin
  Result := GetFloat(GetArgByAbbr(abbr));
end;

function TCmdLineArgs.GetFloats(name: string): TFloatArray;
begin
  Result := GetFloats(GetArgByName(name));
end;

function TCmdLineArgs.GetFloats(abbr: char): TFloatArray;
begin
  Result := GetFloats(GetArgByAbbr(abbr));
end;

function TCmdLineArgs.GetString(name: string): string;
begin
  Result := GetString(GetArgByName(name));
end;

function TCmdLineArgs.GetString(abbr: char): string;
begin
  Result := GetString(GetArgByAbbr(abbr));
end;

function TCmdLineArgs.GetStrings(name: string): TStringArray;
begin
  Result := GetStrings(GetArgByName(name));
end;

function TCmdLineArgs.GetStrings(abbr: char): TStringArray;
begin
  Result := GetStrings(GetArgByAbbr(abbr));
end;

end.
