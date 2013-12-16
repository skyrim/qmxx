/**
 * to do:
 * - flashlight message, gtfo
 */

#include <amxmodx>
#include <fakemeta>
#include <cvar_util>

#pragma semicolon 1

#define PLUGIN "Q::Flashlight"
#define VERSION "1.0"
#define AUTHOR "Quaker"

new g_msg_Flashlight;

new g_fwd_cmdstart;
new g_fwd_addtofullpack;

new g_player_flashlight[33];

public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	
	new cvar_pointer = get_cvar_pointer( "mp_flashlight" );
	CvarSetBounds( cvar_pointer, CvarBound_Lower, true, 0.0 );
	CvarSetBounds( cvar_pointer, CvarBound_Upper, true, 1.0 );
	CvarHookChange( cvar_pointer, "cvarhook_flashlight" );
	
	g_msg_Flashlight = get_user_msgid( "Flashlight" );
}

public cvarhook_flashlight( cvar_handle, old_value[], new_value[], cvar_name[] )
{
	if( str_to_num( new_value ) )
	{
		g_fwd_cmdstart = register_forward( FM_CmdStart, "fwd_CmdStart" );
		g_fwd_addtofullpack = register_forward( FM_AddToFullPack, "fwd_AddToFullPack", true );
	}
	else
	{
		unregister_forward( FM_CmdStart, g_fwd_cmdstart );
		unregister_forward( FM_AddToFullPack, g_fwd_addtofullpack, true );
	}
}

public fwd_CmdStart( id, uc_handle, seed )
{
	if( get_uc( uc_handle, UC_Impulse ) == 100 )
	{
		set_uc( uc_handle, UC_Impulse, 0 );
		
		clcmd_Flashlight( id );
		
		return FMRES_HANDLED;
	}
	
	return FMRES_IGNORED;
}

public fwd_AddToFullPack( es_handle, e, ent, host, hostflags, player, pset )
{
	if( player && g_player_flashlight[host] && ( ent == host ) )
	{
		set_es( es_handle, ES_Effects, get_es( es_handle, ES_Effects ) | EF_DIMLIGHT );
	}
}

public clcmd_Flashlight( id )
{
	g_player_flashlight[id] = !g_player_flashlight[id];
	
	if( g_player_flashlight[id] )
	{
		message_Flashlight( id, 1, 100 );
	}
	else
	{
		message_Flashlight( id, 0, 100 );
	}
	
	return PLUGIN_HANDLED;
}

stock message_Flashlight( id, flag, percent )
{
	message_begin( MSG_ONE_UNRELIABLE, g_msg_Flashlight, _, id );
	write_byte( flag );
	write_byte( percent );
	message_end( );
}
