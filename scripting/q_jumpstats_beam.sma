#include <amxmodx>
#include <fakemeta>
#include <q>
#include <q_menu>
#include <q_cookies>
#include <q_kz>

#define PLUGIN "Q::Jumpstats::Beam"
#define VERSION "1.0"
#define AUTHOR "Quaker"

#define TASKID_BEAMDISPLAY 4731923

#define MAX_BEAM 120

enum
{
	BEAM_STRAIGHT,
	BEAM_UBERFLAT,
	BEAM_UBER
};

new beam_type_names[3][] =
{
	"Normal",
	"Uberflat",
	"Uber"
};

new cvar_beam;

new QMenu:g_menu;

new g_cookies_failed;

new g_player_beam_enabled[33];
new g_player_beam_type[33];

new g_player_injump[33];

new g_beam_sprite;
new g_beam_count[33];
new Float:g_beam_point[33][MAX_BEAM][3];
new g_beam_point_induck[33][MAX_BEAM];

public plugin_natives( )
{
	set_module_filter( "module_filter" );
	set_native_filter( "native_filter" );
}

public module_filter( module[] ) {
	if ( equal( module, "q_cookies" ) ) {
		g_cookies_failed = true;
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public native_filter( name[], index, trap ) {
	if ( !trap ) {
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public plugin_precache( )
{
	g_beam_sprite = precache_model( "sprites/zbeam1.spr" );
}

public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );

	register_dictionary( "q_jumpstats_beam.txt" );
	
	cvar_beam = register_cvar( "q_js_beam", "1" );
	
	register_forward( FM_PlayerPreThink, "PlayerPreThink" );

	q_registerClcmd( "q_js_beammenu", "clcmd_beammenu", _, "Open jump beam menu." );
	q_registerClcmd( "q_js_beam", "clcmd_beam", _, "Toggle jump beam." );
	q_registerClcmd( "q_js_beamtype", "clcmd_beamtype", _, "Set jump beam type." );

	g_menu = q_menu_create("", "mh_jsbeam_menu");
	q_menu_item_add(g_menu, "", _, _, _, "mf_jsbeam_menu");
	q_menu_item_add(g_menu, "", _, _, _, "mf_jsbeam_menu");
}

public client_putinserver( id )
{
	if ( !g_cookies_failed && !is_user_bot( id ) ) {
		if ( !q_get_cookie_num( id, "js_beam_enabled", g_player_beam_enabled[id] ) ) {
			g_player_beam_enabled[id] = true;
		}

		if ( !q_get_cookie_num( id, "js_beam_type", g_player_beam_type[id] ) ) {
			g_player_beam_type[id] = BEAM_UBERFLAT;
		}
	}
}

public client_disconnect( id )
{
	q_set_cookie_num( id, "js_beam_enabled", g_player_beam_enabled[id] );
	q_set_cookie_num( id, "js_beam_type", g_player_beam_type[id] );
}

public clcmd_beammenu( id, level, cid )
{
	m_jsbeam_menu( id );
	
	return PLUGIN_HANDLED;
}

m_jsbeam_menu(id) {
	new title[32];
	formatex( title, charsmax(title), "%L", id, "Q_JSBEAM_MENU" );
	q_menu_set_title( g_menu, title );
	q_menu_display( id, g_menu );
}

public mf_jsbeam_menu( id, QMenu:menu, item, output[64] ) {
	switch( item ) {
	case 0: {
		formatex( output, charsmax(output), "%L - \y%L", id, "Q_JSBEAM_ENABLED", id, g_player_beam_enabled[id] ? "Q_YES" : "Q_NO" );
	}
	case 1: {
		formatex( output, charsmax(output), "%L - \y%s", id, "Q_JSBEAM_TYPE", beam_type_names[g_player_beam_type[id]] );
	}
	}
}

public mh_jsbeam_menu( id, QMenu:menu, item )
{
	switch(item)
	{
		case 0:
		{
			g_player_beam_enabled[id] = !g_player_beam_enabled[id];

			m_jsbeam_menu( id );
		}
		case 1:
		{
			g_player_beam_type[id] = ( g_player_beam_type[id] + 1 ) % 3;

			m_jsbeam_menu( id );
		}
		case QMenuItem_Exit:
		{
			return PLUGIN_HANDLED;
		}
	}
	
	return PLUGIN_HANDLED;
}

public clcmd_beam( id, level, cid )
{
	g_player_beam_enabled[id] = !g_player_beam_enabled[id];

	q_kz_print(id, "%L", id, g_player_beam_enabled[id] ?  "Q_JS_BEAM_ON" : "Q_JS_BEAM_OFF" );

	return PLUGIN_HANDLED;
}

public clcmd_beamtype( id, level, cid )
{
	new type[9];
	
	read_argv( 1, type, charsmax(type) );
	
	if( equali( type, "normal" ) )
	{
		g_player_beam_type[id] = BEAM_STRAIGHT;
	}
	else if( equali( type, "uberflat" ) )
	{
		g_player_beam_type[id] = BEAM_UBERFLAT;
	}
	else if( equali( type, "uber" ) )
	{
		g_player_beam_type[id] = BEAM_UBER;
	}
	else
	{
		client_print( id, print_console, "Unknown beam type! Availlable beam types: normal, uberflat, uber." );
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
		
		if( g_player_beam_enabled[id] )
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
		g_beam_point[id][g_beam_count[id]][2] -= 18.0;
		
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
	static Float:p1[3];
	static Float:p2[3];

	switch( g_player_beam_type[id] )
	{
		case BEAM_STRAIGHT:
		{
			p1[0] = g_beam_point[id][0][0];
			p1[1] = g_beam_point[id][0][1];
			p1[2] = g_beam_point[id][0][2];

			p2[0] = g_beam_point[id][g_beam_count[id] - 1][0];
			p2[1] = g_beam_point[id][g_beam_count[id] - 1][1];
			p2[2] = g_beam_point[id][0][2];

			message_te_beampoints(
				id,
				p1,
				p2,
				g_beam_sprite,
				1, // start frame
				5, // frame rate
				15, // life
				20, // width
				0, // noise
				0, // r
				255, // g
				0, // b
				200, // brightness
				200  // scroll speed
			)
		}
		case BEAM_UBERFLAT:
		{
			for( new i = 2; i < g_beam_count[id]; i += 2 )
			{
				p1[0] = g_beam_point[id][i - 2][0];
				p1[1] = g_beam_point[id][i - 2][1];
				p1[2] = g_beam_point[id][0][2];

				p2[0] = g_beam_point[id][i][0];
				p2[1] = g_beam_point[id][i][1];
				p2[2] = g_beam_point[id][0][2];

				message_te_beampoints(
					id,
					p1,
					p2,
					g_beam_sprite,
					1, // start frame
					5, // frame rate
					i * 100 / g_beam_count[id] / 10 + 10, // life
					20, // width
					0, // noise
					g_beam_point_induck[id][i] ? 255 : 0, // r
					g_beam_point_induck[id][i] ? 0 : 255, // g
					g_beam_point_induck[id][i] ? 0 : 255, // b
					200, // brightness
					200  // scroll speed
				);
			}
		}
		case BEAM_UBER:
		{
			for( new i = 2; i < g_beam_count[id]; i += 2 )
			{
				message_te_beampoints( 
					id,
					g_beam_point[id][i - 2],
					g_beam_point[id][i],
					g_beam_sprite,
					1, // start frame
					5, // frame rate
					i * 100 / g_beam_count[id] / 10 + 10, // life
					20, // width
					0, // noise
					g_beam_point_induck[id][i] ? 255 : 0, // r
					g_beam_point_induck[id][i] ? 0 : 255, // g
					g_beam_point_induck[id][i] ? 0 : 255, // b
					200, // brightness
					200  // scroll speed
				);
			}
		}
	}
}

message_te_beampoints( id, Float:start[3], Float:end[3], sprite, startFrameIdx, frameRate, life, width, noise, r, g, b, brightness, scrollSpeed )
{
	message_begin( MSG_ONE, SVC_TEMPENTITY, _, id );
	write_byte( TE_BEAMPOINTS );
	engfunc( EngFunc_WriteCoord, start[0] );
	engfunc( EngFunc_WriteCoord, start[1] );
	engfunc( EngFunc_WriteCoord, start[2] );
	engfunc( EngFunc_WriteCoord, end[0] );
	engfunc( EngFunc_WriteCoord, end[1] );
	engfunc( EngFunc_WriteCoord, end[2] );
	write_short( sprite );
	write_byte( startFrameIdx );
	write_byte( frameRate );
	write_byte( life );
	write_byte( width );
	write_byte( noise );
	write_byte( r );
	write_byte( g );
	write_byte( b );
	write_byte( brightness );
	write_byte( scrollSpeed );
	message_end( );
}