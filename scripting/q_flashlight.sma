/**
 * TODO:
 * - flashlight message
 */

#include <amxmodx>
#include <fakemeta>

#pragma semicolon 1

#define PLUGIN "Q::Flashlight"
#define VERSION "1.1"
#define AUTHOR "Quaker"

new g_msg_Flashlight;

new g_cvar_flashlight;

new g_player_flashlight[33];

public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	
	register_forward(FM_CmdStart, "fwd_CmdStart");
	register_forward(FM_AddToFullPack, "fwd_AddToFullPack", true);
	
	g_cvar_flashlight = get_cvar_pointer("mp_flashlight");
	
	g_msg_Flashlight = get_user_msgid( "Flashlight" );
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
	if(!get_pcvar_num(g_cvar_flashlight)) {
		// TODO: print "Flashlight disabled by the server"
		
		if(g_player_flashlight[id]) {
			g_player_flashlight[id] = false;
			message_Flashlight(id, 0, 100);
		}
		
		return PLUGIN_HANDLED;
	}
	
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
