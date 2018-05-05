{$IF defined(CPU64) or defined(CPU64BITS)}
  {$DEFINE 64bit}
{$ELSEIF defined(CPU16)}
  {$MESSAGE FATAL 'Unsupported CPU.'}
{$ELSE}
  {$DEFINE 32bit}
{$IFEND}

{$IFDEF FPC}
  {$MODE Delphi}
  {$DEFINE FPC_DisableWarns}
  {$MACRO ON}
{$ENDIF}

{$IF Defined(FPC) and not Defined(Unicode) and (FPC_FULLVERSION < 20701)}
  {$DEFINE FPC_NonUnicode_NoUTF8RTL}
{$IFEND}
