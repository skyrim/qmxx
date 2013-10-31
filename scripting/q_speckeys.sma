/**
 * to do:
 * - a lot
 * - hud color
 */

#include <amxmodx>
#include <fakemeta>

#pragma semicolon 1

#define PLUGIN "Q SpecKeys"
#define VERSION "1.0"
#define AUTHOR "Quaker"

#define TASKID_SPECKEYS 5700
#define TASKTIME_SPECKEYS 0.1

new const g_allbuttons = IN_JUMP | IN_DUCK | IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT;

new cvar_hud_keys;

new g_player_speckeys[33];
new g_player_showkeys[33];
new g_player_SpecID[33];

public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	
	cvar_hud_keys = register_cvar( "q_hud_keys", "1" );
	
	register_clcmd( "say /speckeys", "clcmd_SpecKeys" );
	register_clcmd( "say /showkeys", "clcmd_ShowKeys" );
	
	register_event( "SpecHealth2", "event_SpecHealth2", "bd" );
	
	set_task( TASKTIME_SPECKEYS, "task_SpecKeys", TASKID_SPECKEYS, _, _, "b" );
}

public client_connect( id )
{
	g_player_speckeys[id] = true;
	g_player_showkeys[id] = false;
}

public event_SpecHealth2( id )
{
	g_player_SpecID[id] = read_data( 2 );
}

public clcmd_SpecKeys( id )
{
	g_player_speckeys[id] = !g_player_speckeys[id];
	
	client_print( id, print_chat, "SpecKeys: %L", id, ( g_player_speckeys[id] ? "QKZ_ON" : "QKZ_OFF" ) );
	
	return PLUGIN_HANDLED;
}

public clcmd_ShowKeys( id, level, cid )
{
	g_player_showkeys[id] = !g_player_showkeys[id];
	
	client_print( id, print_chat, "ShowKeys: %L", id, ( g_player_showkeys[id] ? "QKZ_ON" : "QKZ_OFF" ) );
	
	return PLUGIN_HANDLED;
}

public task_SpecKeys( )
{	
	static buttons;
	static specmode;
	static const msg_format[] = "%s^n^n%s^n^n%s^t^t^t^t^t^t^t^t%s^n^n%s^n^n%s";
	
	if( !get_pcvar_num( cvar_hud_keys ) ) {
		return;
	}
	
	for( new i = 1; i <= 32; ++i )
	{
		if( is_user_connected( i ) )
		{
			if( !is_user_alive( i ) && g_player_speckeys[i] )
			{
				specmode = pev( i, pev_iuser1 );
				
				if( specmode == 2 || specmode == 4 )
				{
					if( i == g_player_SpecID[i] )
						continue;
					
					buttons = pev( g_player_SpecID[i], pev_button );
					
					if( buttons & g_allbuttons )
					{
						set_hudmessage( 255, 125, 0, -1.0, -1.0, 0, 0.0, 0.1, 0.0, 0.0, 3 );
						show_hudmessage( i, msg_format,
							(buttons & IN_JUMP) ? "JUMP" : "    ",
							(buttons & IN_FORWARD) && !(buttons & IN_BACK) ? "W" : " ",
							(buttons & IN_MOVELEFT) && !(buttons & IN_MOVERIGHT) ? "A" : " ",
							(buttons & IN_MOVERIGHT) && !(buttons & IN_MOVELEFT) ? "D" : " ",
							(buttons & IN_BACK) && !(buttons & IN_FORWARD) ? "S" : " ",
							(buttons & IN_DUCK) ? "DUCK" : "    " );
					}
				}
			}
			else if( is_user_alive( i ) && g_player_showkeys[i] )
			{
				buttons = pev( i, pev_button );
				
				
				if( buttons & g_allbuttons )
				{
					set_hudmessage( 255, 125, 0, -1.0, -1.0, 0, 0.0, 0.1, 0.0, 0.0, 3 );
					show_hudmessage( i, msg_format,
						(buttons & IN_JUMP) ? "JUMP" : "    ",
						(buttons & IN_FORWARD) && !(buttons & IN_BACK) ? "W" : " ",
						(buttons & IN_MOVELEFT) && !(buttons & IN_MOVERIGHT) ? "A" : " ",
						(buttons & IN_MOVERIGHT) && !(buttons & IN_MOVELEFT) ? "D" : " ",
						(buttons & IN_BACK) && !(buttons & IN_FORWARD) ? "S" : " ",
						(buttons & IN_DUCK) ? "DUCK" : "    " );
				}
			}
		}
	}
}
