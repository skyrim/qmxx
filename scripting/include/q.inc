/* 
 * Q API by Quaker
 *
 * This file is provided as is (no warranties).
 */

#if defined _q_included
	#endinput
#endif

#define _q_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib q
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib q
	#endif
#else
	#pragma library q
#endif

native q_get_datadir( path[], len );
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
