(*
** The libsamplerate headers Delphi translation
** By Andrei Borovsky <anb@symmetrica.net>.
**
** The original headers are
** copyright (C) 2002-2004 Erik de Castro Lopo <erikd@mega-nerd.com>
**
** Modified for static linking and portability by GliGli
*)

unit libsamplerate;

(* Unit: libsamplerate.pas
    Delphi headers for libsamplerate.dll by Andrei Borovsky
(anb@symmetrica.net) The original headers are copyright (C) 2002-2004 Erik de
Castro Lopo (erikd@mega-nerd.com). *)

interface

const

  LibsampleratePath = 'libsamplerate.dll';

type

  FloatArray = array[0..0] of Single;

  PFLOATARRAY = ^FloatArray;

  PPFLOATARRAY = ^PFLOATARRAY;

  ShortArray =  array[0..0] of SmallInt;

  PSHORTARRAY = ^ShortArray;

  PSRC_STATE = Pointer;

  SRC_DATA = record
    data_in, data_out : PFLOATARRAY;
    input_frames, output_frames : LongWord;
    nput_frames_used, output_frames_gen : LongWord;
    end_of_input : Integer;
    src_ratio  : Double;
  end;

  PSRC_DATA = ^SRC_DATA;

  SRC_CB_DATA = record
    frames : LongWord;
    data_in  : PFLOATARRAY;
  end;

  PSRC_CB_DATA = ^SRC_CB_DATA;

(*
** User supplied callback function type for use with src_callback_new()
** and src_callback_read(). First parameter is the same pointer that was
** passed into src_callback_new(). Second parameter is pointer to a
** pointer. The user supplied callback function must modify *data to
** point to the start of the user supplied float array. The user supplied
** function must return the number of frames that **data points to.
*)

 TSrcCallback = function(cb_data : Pointer; var data : PFLOATARRAY) : LongWord; cdecl;

const

  // Converter type constants
  SRC_SINC_BEST_QUALITY		= 0;
  SRC_SINC_MEDIUM_QUALITY	= 1;
  SRC_SINC_FASTEST = 2;
  SRC_ZERO_ORDER_HOLD	= 3;
  SRC_LINEAR 	= 4;

(*
**	Standard initialisation function : return an anonymous pointer to the
**	internal state of the converter. Choose a converter from the enums below.
**	Error returned in *error.
*)

function src_new(converter_type, channels : Integer; var error : Integer) : PSRC_STATE cdecl;external LibsampleratePath;

(*
**	Initilisation for callback based API : return an anonymous pointer to the
**	internal state of the converter. Choose a converter from the enums below.
**	The cb_data pointer can point to any data or be set to NULL. Whatever the
**	value, when processing, user supplied function "func" gets called with
**	cb_data as first parameter.
*)

function src_callback_new(func : TSrcCallback; converter_type, channels : Integer;
				var error : Integer; cb_data : Pointer) : PSRC_STATE cdecl;external LibsampleratePath;

(*
**	Cleanup all internal allocations.
**	Always returns NULL.
*)

function src_delete(state : PSRC_STATE) : PSRC_STATE; cdecl;external LibsampleratePath;

(*
**	Standard processing function.
**	Returns non zero on error.
*)

function src_process(state : PSRC_STATE; var data : SRC_DATA) : Integer; cdecl;external LibsampleratePath;

(*
**	Callback based processing function. Read up to frames worth of data from
**	the converter int *data and return frames read or -1 on error.
*)

function src_callback_read(state : PSRC_STATE; src_ratio : Double; frames : LongWord; data : PFLOATARRAY) : LongWord cdecl;external LibsampleratePath;

(*
**	Simple interface for performing a single conversion from input buffer to
**	output buffer at a fixed conversion ratio.
**	Simple interface does not require initialisation as it can only operate on
**	a single buffer worth of audio.
*)

function src_simple(data : PSRC_DATA; converter_type, channels : Integer) : Integer; cdecl;external LibsampleratePath;

(*
** This library contains a number of different sample rate converters,
** numbered 0 through N.
**
** Return a string giving either a name or a more full description of each
** sample rate converter or NULL if no sample rate converter exists for
** the given value. The converters are sequentially numbered from 0 to N.
*)

function src_get_name(converter_type : Integer) : PChar; cdecl;external LibsampleratePath;
function src_get_description(converter_type : Integer) : PChar; cdecl;external LibsampleratePath;
function src_get_version : PChar; cdecl;external LibsampleratePath;

(*
**	Set a new SRC ratio. This allows step responses
**	in the conversion ratio.
**	Returns non zero on error.
*)

function src_set_ratio(state : PSRC_STATE; new_ratio : Double) : Integer cdecl;external LibsampleratePath;

(*
**	Reset the internal SRC state.
**	Does not modify the quality settings.
**	Does not free any memory allocations.
**	Returns non zero on error.
*)

function src_reset(state : PSRC_STATE) : Integer; cdecl;external LibsampleratePath;

(*
** Return TRUE if ratio is a valid conversion ratio, FALSE
** otherwise.
*)

function src_is_valid_ratio(ratio : Double) : Integer; cdecl;external LibsampleratePath;

(*
**	Return an error number.
*)

function src_error(state : PSRC_STATE) : Integer; cdecl;external LibsampleratePath;

(*
**	Convert the error number into a string.
*)

function src_strerror(error : Integer) : PChar; cdecl;external LibsampleratePath;

(*
** Extra helper functions for converting from short to float and
** back again.
*)

procedure src_short_to_float_array(_in : PSHORTARRAY; _out : PFLOATARRAY; len : Integer); cdecl;external LibsampleratePath;
procedure src_float_to_short_array(_in : PFLOATARRAY; _out : PSHORTARRAY; len : Integer); cdecl;external LibsampleratePath;


implementation

end.
