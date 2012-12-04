unit rawhid;

{$mode objfpc}

interface

function rawhid_open(max, vid, pid, usage_page, usage:Integer):Integer;stdcall;external 'rawhid_lib.dll';
function rawhid_recv(num:Integer; buf:Pointer; len, timeout: Integer):Integer;stdcall;external 'rawhid_lib.dll';
function rawhid_send(num:Integer; buf:Pointer; len, timeout: Integer):Integer;stdcall;external 'rawhid_lib.dll';
procedure rawhid_close(num:Integer);stdcall;external 'rawhid_lib.dll';

implementation

end.

