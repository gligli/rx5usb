unit rawhid;

{$mode objfpc}

interface

function rawhid_open(max, vid, pid, usage_page, usage:Integer):Integer;stdcall;external 'rawhid_lib.dll' name 'rawhid_open@20';
function rawhid_recv(num:Integer; buf:Pointer; len, timeout: Integer):Integer;stdcall;external 'rawhid_lib.dll' name 'rawhid_recv@16';
function rawhid_send(num:Integer; buf:Pointer; len, timeout: Integer):Integer;stdcall;external 'rawhid_lib.dll' name 'rawhid_send@16';
procedure rawhid_close(num:Integer);stdcall;external 'rawhid_lib.dll' name 'rawhid_close@4';

implementation

end.

