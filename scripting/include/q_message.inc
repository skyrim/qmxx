/* 
 * Q Message API by Quaker
 *
 * This file is provided as is (no warranties).
 */

#if defined _q_message_included
	#endinput
#endif

#define _q_message_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib q_message
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib q_message
	#endif
#else
	#pragma library q_message
#endif

native q_message_ShowMenu( id, msg_type, msg_origin[3] = {0,0,0}, keys, time, menu[] );
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
