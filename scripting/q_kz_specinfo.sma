#include <amxmodx>
#include <fakemeta>
#include <geoip>

#include <q_kz>

#pragma semicolon 1

#define PLUGIN "Q::KZ::SpecInfo"
#define VERSION "1.0"
#define AUTHOR "Quaker"

#define TASKID_SPECINFO 5650
#define TASKTIME_SPECINFO 1.0

new g_player_Name[33][32];
new g_player_IP[33][16];
new g_player_Country[33][46];
new g_player_SpecInfo[33];
new g_player_SpecID[33];

new cvar_specinfo;
new cvar_specinfo_pos;

public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	
	cvar_specinfo = register_cvar( "q_kz_specinfo", "1" );
	cvar_specinfo_pos = register_cvar( "q_kz_specinfo_pos_x", "-1.0 0.15" );
	
	register_event( "SpecHealth2", "event_SpecHealth2", "bd" );
	
	register_clcmd( "say /specinfo", "clcmd_SpecInfo" );
	register_clcmd( "say /kzspecinfo", "clcmd_SpecInfo" );
	
	set_task( TASKTIME_SPECINFO, "task_SpecInfo", TASKID_SPECINFO, _, _, "b" );
}

public setting_SpecInfo( id )
{
	g_player_SpecInfo[id] = !g_player_SpecInfo[id];
}

public client_putinserver( id )
{
	g_player_SpecInfo[id] = true;
	
	get_user_name( id, g_player_Name[id], charsmax(g_player_Name[]) );
	get_user_ip( id, g_player_IP[id], charsmax(g_player_IP[]), 1 );
	geoip_country( g_player_IP[id], g_player_Country[id], charsmax(g_player_Country[]) );
	if( g_player_Country[id][0] == 'e' || g_player_Country[id][0] == 0 )
	{
		g_player_Country[id] = "Unknown";
	}
}

public client_infochanged( id )
{
	get_user_info( id, "name", g_player_Name[id], charsmax(g_player_Name[]) );
}

public event_SpecHealth2( id )
{
	g_player_SpecID[id] = read_data( 2 );
}

public clcmd_SpecInfo( id )
{
	g_player_SpecInfo[id] = !g_player_SpecInfo[id];
	
	q_kz_print( id, "SpecInfo is turned %s", g_player_SpecInfo[id] ? "on" : "off" );
	
	return PLUGIN_HANDLED;
}

public task_SpecInfo( )
{
	static specmode, runtime;
	static const msg_format[] = "%s from %s^n%02d:%02d | CP: %d | TP: %d";
	
	if( !get_pcvar_num( cvar_specinfo ) ) {
		return;
	}
	
	new red, green, blue;
	q_kz_getHudColor( red, green, blue );
	
	new sz_pos[10];
	get_pcvar_string( cvar_specinfo_pos, sz_pos, charsmax(sz_pos) );
	new sz_pos_x[6];
	new sz_pos_y[6];
	parse( sz_pos, sz_pos_x, charsmax(sz_pos_x), sz_pos_y, charsmax(sz_pos_y) );
	new Float:pos_x = str_to_float( sz_pos_x );
	new Float:pos_y = str_to_float( sz_pos_y );
	
	for( new i = 1; i <= 32; i++ )
	{
		if( is_user_connected( i ) && !is_user_alive( i ) && g_player_SpecInfo[i] )
		{
			specmode = pev( i, pev_iuser1 );
			
			if ( specmode == 2 || specmode == 4 )
			{
				if( (i == g_player_SpecID[i]) || (g_player_SpecID[i] == 0) )
					continue;
				
				if( q_kz_player_isTimerStarted( g_player_SpecID[i] ) )
					runtime = floatround( q_kz_player_getTimer( g_player_SpecID[i] ) );
				else
					runtime = 0;
				
				set_hudmessage( red, green, blue, pos_x, pos_y, 0, 0.0, 1.0, 1.0, 1.0, 2 );
				show_hudmessage( i, msg_format,
					g_player_Name[g_player_SpecID[i]],
					g_player_Country[g_player_SpecID[i]],
					(runtime/60),
					(runtime%60),
					q_kz_player_getCheckpoints( g_player_SpecID[i] ),
					q_kz_player_getTeleports( g_player_SpecID[i] ) );
			}
		}
	}
}
