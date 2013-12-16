#include <amxmodx>
#include <fakemeta>

/**
 * - a lot
 */

#define PLUGIN "Q::Jumpstats::Beam"
#define VERSION "1.0"
#define AUTHOR "Quaker"

#define TASKID_BEAMDISPLAY 4731923

#define MAX_BEAM 120

enum
{
	BEAM_NO,
	BEAM_NORMAL,
	BEAM_UBERFLAT,
	BEAM_UBER
};

new cvar_beam;

new g_player_beam[33];
new g_player_beam_color[33];

new g_player_injump[33];

new g_beam_sprite;
new g_beam_count[33];
new Float:g_beam_point[33][MAX_BEAM][3];
new g_beam_point_induck[33][MAX_BEAM];

public plugin_precache( )
{
	g_beam_sprite = precache_model( "sprites/zbeam1.spr" );
}

public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	
	cvar_beam = register_cvar( "q_js_beam", "1" );
	
	register_forward( FM_PlayerPreThink, "PlayerPreThink" );

	register_clcmd( "cl_qkz_js_beam", "clcmd_beam" );
	register_clcmd( "cl_qkz_js_beamtype", "clcmd_beamtype" );
	register_clcmd( "cl_qkz_js_beamcolor", "clcmd_beamcolor" );
}

public client_putinserver( id )
{
	g_player_beam[id] = BEAM_UBERFLAT;
	g_player_beam_color[id] = 0xff0000;
}

public clcmd_beam( id, level, cid )
{
	if( read_argc( ) == 1 )
	{
		client_print( id, print_console, "Turn jump beam on or off." );
	}
	else
	{
		new cmd[4];
		
		read_argv( 1, cmd, charsmax(cmd) );
		
		if( equali( cmd, "on" ) && ( g_player_beam[id] == BEAM_NO ) )
		{
			g_player_beam[id] = BEAM_UBERFLAT;
		}
		else if( equali( cmd, "off" ) )
		{
			g_player_beam[id] = BEAM_NO;
		}
	}
	
	return PLUGIN_HANDLED;
}

public clcmd_beamtype( id, level, cid )
{
	if( read_argc( ) == 1 )
	{
		client_print( id, print_console, "Availlable beam types: normal, uberflat, uber." );
	}
	else
	{
		new type[9];
		
		read_argv( 1, type, charsmax(type) );
		
		if( equali( type, "normal" ) )
		{
			g_player_beam[id] = BEAM_NORMAL;
		}
		else if( equali( type, "uberflat" ) )
		{
			g_player_beam[id] = BEAM_UBERFLAT;
		}
		else if( equali( type, "uber" ) )
		{
			g_player_beam[id] = BEAM_UBER;
		}
		else
		{
			client_print( id, print_console, "Unknown beam type! Availlable beam types: normal, uberflat, uber." );
		}
	}
	
	return PLUGIN_HANDLED;
}

public clcmd_beamcolor( id, level, cid )
{
	if( read_argc( ) == 1 )
	{
		client_print( id, print_console, "Set jump beam color." );
	}
	else
	{
		new red[4];
		read_argv( 1, red, charsmax(red) );
		
		new green[4];
		read_argv( 2, green, charsmax(green) );
		
		new blue[4];
		read_argv( 3, blue, charsmax(blue) );
		
		g_player_beam_color[id] = ( str_to_num( red ) << 16 ) | ( str_to_num( green ) << 8 ) | str_to_num( blue );
	}
	
	return PLUGIN_HANDLED;
}

public PlayerPreThink( id )
{
	if( g_player_injump[id] && get_pcvar_num( cvar_beam ) && !( pev( id, pev_flags ) & FL_ONGROUND ) )
	{
		beam_frame( id );
	}
}

public q_js_jumpbegin( id )
{
	if( get_pcvar_num( cvar_beam ) )
	{
		g_beam_count[id] = 0;
		g_player_injump[id] = true;
		
		beam_frame( id );
	}
}

public q_js_jumpend( id )
{
	g_player_injump[id] = false;
	
	if( get_pcvar_num( cvar_beam ) )
	{
		beam_frame( id );
		
		if( g_player_beam[id] )
		{
			beam_display( id );
		}
	}
}

public q_js_jumpfail( id )
{
	g_player_injump[id] = false;
}

public q_js_jumpillegal( id )
{
	g_player_injump[id] = false;
}

beam_frame( id )
{
	static Float:origin[3];
	
	if( g_beam_count[id] < MAX_BEAM )
	{
		pev( id, pev_origin, origin );
		g_beam_point[id][g_beam_count[id]] = origin;
		
		if( pev( id, pev_flags ) & FL_DUCKING )
		{
			g_beam_point_induck[id][g_beam_count[id]] = true;
		}
		else
		{
			g_beam_point_induck[id][g_beam_count[id]] = false;
		}
		
		++g_beam_count[id];
	}
}

beam_display( id )
{
	switch( g_player_beam[id] )
	{
		case BEAM_NORMAL:
		{
			message_begin( MSG_ONE, SVC_TEMPENTITY, _, id );
			write_byte( TE_BEAMPOINTS );
			engfunc( EngFunc_WriteCoord, g_beam_point[id][0][0] );
			engfunc( EngFunc_WriteCoord, g_beam_point[id][0][1] );
			engfunc( EngFunc_WriteCoord, g_beam_point[id][0][2] );
			engfunc( EngFunc_WriteCoord, g_beam_point[id][g_beam_count[id] - 1][0] );
			engfunc( EngFunc_WriteCoord, g_beam_point[id][g_beam_count[id] - 1][1] );
			engfunc( EngFunc_WriteCoord, g_beam_point[id][g_beam_count[id] - 1][2] );
			write_short( g_beam_sprite );
			write_byte( 1 ); // start frame
			write_byte( 5 ); // frame rate
			write_byte( 15 ); // life
			write_byte( 20 ); // width
			write_byte( 0 ); // noise
			write_byte( g_player_beam_color[id] >> 16 ); // color red
			write_byte( g_player_beam_color[id] >> 8 ); // color green
			write_byte( g_player_beam_color[id] ); // color blue
			write_byte( 200 ); // brightness
			write_byte( 200 ); // scroll speed
			message_end( );
		}
		case BEAM_UBERFLAT:
		{
			for( new i = 1; i < g_beam_count[id]; ++i )
			{
				message_begin( MSG_ONE, SVC_TEMPENTITY, _, id );
				write_byte( TE_BEAMPOINTS );
				engfunc( EngFunc_WriteCoord, g_beam_point[id][i - 1][0] );
				engfunc( EngFunc_WriteCoord, g_beam_point[id][i - 1][1] );
				engfunc( EngFunc_WriteCoord, g_beam_point[id][0][2] ); // flat
				engfunc( EngFunc_WriteCoord, g_beam_point[id][i][0] );
				engfunc( EngFunc_WriteCoord, g_beam_point[id][i][1] );
				engfunc( EngFunc_WriteCoord, g_beam_point[id][0][2] ); // flat
				write_short( g_beam_sprite );
				write_byte( 1 ); // start frame
				write_byte( 5 ); // frame rate
				write_byte( i * 100 / g_beam_count[id] / 10 + 10 ); // life
				write_byte( 20 ); // width
				write_byte( 0 ); // noise
				if( g_beam_point_induck[id][i] )
				{
					write_byte( ~g_player_beam_color[id] >> 16 ); // color red
					write_byte( ~g_player_beam_color[id] >> 8 ); // color green
					write_byte( ~g_player_beam_color[id] ); // color blue
				}
				else
				{
					write_byte( g_player_beam_color[id] >> 16 ); // color red
					write_byte( g_player_beam_color[id] >> 8 ); // color green
					write_byte( g_player_beam_color[id] ); // color blue
				}
				write_byte( 200 ); // brightness
				write_byte( 200 ); // scroll speed
				message_end( );
			}
		}
		case BEAM_UBER:
		{
			for( new i = 2; i < g_beam_count[id]; i += 2 )
			{
				message_begin( MSG_ONE, SVC_TEMPENTITY, _, id );
				write_byte( TE_BEAMPOINTS );
				engfunc( EngFunc_WriteCoord, g_beam_point[id][i - 2][0] );
				engfunc( EngFunc_WriteCoord, g_beam_point[id][i - 2][1] );
				engfunc( EngFunc_WriteCoord, g_beam_point[id][i - 2][2] );
				engfunc( EngFunc_WriteCoord, g_beam_point[id][i][0] );
				engfunc( EngFunc_WriteCoord, g_beam_point[id][i][1] );
				engfunc( EngFunc_WriteCoord, g_beam_point[id][i][2] );
				write_short( g_beam_sprite );
				write_byte( 1 ); // start frame
				write_byte( 5 ); // frame rate
				write_byte( i * 100 / g_beam_count[id] / 10 + 10 ); // life
				write_byte( 20 ); // width
				write_byte( 0 ); // noise
				if( g_beam_point_induck[id][i] )
				{
					write_byte( ~g_player_beam_color[id] >> 16 ); // color red
					write_byte( ~g_player_beam_color[id] >> 8 ); // color green
					write_byte( ~g_player_beam_color[id] ); // color blue
				}
				else
				{
					write_byte( g_player_beam_color[id] >> 16 ); // color red
					write_byte( g_player_beam_color[id] >> 8 ); // color green
					write_byte( g_player_beam_color[id] ); // color blue
				}
				write_byte( 200 ); // brightness
				write_byte( 200 ); // scroll speed
				message_end( );
			}
		}
	}
}
