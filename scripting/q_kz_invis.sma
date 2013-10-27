#include <amxmodx>
#include <fakemeta>

#include <q_cookies>

#pragma semicolon 1

#define PLUGIN "Q KZ Invis"
#define VERSION "1.0"
#define AUTHOR "Quaker"

new g_cookies_failed;

new g_invis_cid[3];
new g_player_pinvis[33];
new g_player_winvis[33];

#define SET_BITVECTOR(%1,%2) (%1[%2>>5] |=  (1<<(%2 & 31)))
#define GET_BITVECTOR(%1,%2) (%1[%2>>5] &   (1<<(%2 & 31)))
#define CLR_BITVECTOR(%1,%2) (%1[%2>>5] &= ~(1<<(%2 & 31)))
new g_water[1380 / 32];

public plugin_natives( )
{
	set_module_filter( "module_filter" );
	set_native_filter( "native_filter" );
}

public module_filter( module[] )
{
	if( equal( module, "q_cookies" ) )
	{
		g_cookies_failed = true;
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public native_filter( name[], index, trap )
{
	if( !trap )
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	
	register_forward( FM_AddToFullPack, "AddToFullPack", 1 );
	
	register_menucmd( register_menuid( "\yQ KZ / Invis" ), MENU_KEY_0 | MENU_KEY_1 | MENU_KEY_2, "menu_invis_hnd" );
	
	g_invis_cid[0] = register_clcmd( "say /invis", "clcmd_invis" );
	g_invis_cid[1] = register_clcmd( "say /pinvis", "clcmd_invis" );
	g_invis_cid[2] = register_clcmd( "say /winvis", "clcmd_invis" );
	
	// find water
	new ent = -1;
	while( ( ent = engfunc( EngFunc_FindEntityByString, ent, "classname", "func_water" ) ) )
	{
		SET_BITVECTOR(g_water,ent);
	}
	ent = -1;
	while( ( ent = engfunc( EngFunc_FindEntityByString, ent, "classname", "func_illusionary" ) ) )
	{
		if( pev( ent, pev_skin ) == CONTENTS_WATER )
			SET_BITVECTOR(g_water,ent);
	}
	ent = -1;
	while( ( ent = engfunc( EngFunc_FindEntityByString, ent, "classname", "func_conveyor" ) ) )
	{
		if( pev( ent, pev_spawnflags ) == 3 )
			SET_BITVECTOR(g_water,ent);
	}
}

public client_putinserver( id )
{
	if( !g_cookies_failed && !q_get_cookie_num( id, "invis_player", g_player_pinvis[id] ) )
		g_player_pinvis[id] = false;
	
	if( !g_cookies_failed && !q_get_cookie_num( id, "invis_water", g_player_winvis[id] ) )
		g_player_winvis[id] = false;
}

public client_disconnect( id )
{
	if( !g_cookies_failed )
	{
		q_set_cookie_num( id, "invis_player", g_player_pinvis[id] );
		q_set_cookie_num( id, "invis_water", g_player_winvis[id] );
	}
}

public AddToFullPack( es_handle, e, ent, host, hostflags, player, pset )
{
	if( player && g_player_pinvis[host] && ( host != ent ) && ( ent != pev( host, pev_iuser2 ) ) )
	{
		set_es( es_handle, ES_Origin, Float:{ -4096.0, -4096.0, -4096.0 } );
	}
	if( g_player_winvis[host] && GET_BITVECTOR(g_water,ent) )
	{
		set_es( es_handle, ES_Effects, EF_NODRAW );
	}
}

public clcmd_invis( id, level, cid )
{
	if( cid == g_invis_cid[0] )
	{
		menu_invis( id );
	}
	else if( cid == g_invis_cid[1] )
	{
		g_player_pinvis[id] = !g_player_pinvis[id];
	}
	else if( cid == g_invis_cid[2] )
	{
		g_player_winvis[id] = !g_player_winvis[id];
	}
	
	return PLUGIN_HANDLED;
}

menu_invis( id )
{
	new buffer[128];
	new cp = g_player_pinvis[id] ? 'w' : 'd';
	new cw = g_player_winvis[id] ? 'w' : 'd';
	formatex( buffer, charsmax(buffer), "\yQ KZ / Invis^n^n\r1. \%cPlayers^n\r2. \%cWater^n^n^n^n^n^n^n\r0. \yExit", cp, cw );
	show_menu( id, MENU_KEY_0 | MENU_KEY_1 | MENU_KEY_2, buffer );
}

public menu_invis_hnd( id, item )
{
	switch( item )
	{
		case 0:
		{
			g_player_pinvis[id] = !g_player_pinvis[id];
		}
		case 1:
		{
			g_player_winvis[id] = !g_player_winvis[id];
		}
		case 9:
		{
			return;
		}
	}
	
	menu_invis( id );
}
