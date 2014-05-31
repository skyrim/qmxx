/**
 * to do:
 * - saytext message for join and leave instead of client_print
 */

#include <amxmodx>
#include <geoip>

#include <q>
#include <q_menu>

#pragma semicolon 1

#define PLUGIN "Q::Country"
#define VERSION "1.0"
#define AUTHOR "Quaker"

new g_cvar_joinmessage;
new g_cvar_leavemessage;

new g_menu;

new player_country[33][46];

public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	
	g_cvar_joinmessage = register_cvar("q_counter_joinmessage", "0");
	g_cvar_leavemessage = register_cvar("q_counter_leavemessage", "0");
	
	g_menu = q_menu_create( "Q Countries", "menu_countries_handler" );
	
	register_clcmd( "say /country", "clcmd_country" );
}

public client_putinserver( id )
{
	new name[32];
	get_user_name( id, name, charsmax(name) );
	
	new ip[16];
	get_user_ip( id, ip, charsmax(ip), true );
	
	geoip_country( ip, player_country[id] );
	
	if( player_country[id][0] == 'e' || !player_country[id][0] )
	{
		player_country[id] = "Unknown Country";
	}
	
	if( get_pcvar_num(g_cvar_joinmessage) )
	{
		client_print( 0, print_chat, "%s from %s entered the game", name, player_country[id] );
	}
	
	new fmt[64];
	formatex( fmt, charsmax(fmt), "\r%s \wfrom \y%s", name, player_country[id] );
	q_menu_item_add( g_menu, fmt, name, false );
}

public client_infochanged( id )
{
	new oldname[32];
	get_user_name( id, oldname, charsmax(oldname) );
	
	new newname[32];
	get_user_info( id, "name", newname, charsmax(newname) );
	
	new buffer[64];
	for( new i = 0, size = q_menu_item_count( g_menu ); i < size; ++i )
	{
		q_menu_item_get_data( g_menu, i, buffer, charsmax(buffer) );
		if( equal( oldname, buffer, charsmax(oldname) ) )
		{
			formatex( buffer, charsmax(buffer), "\y%s \wfrom \y%s", newname, player_country[id] );
			q_menu_item_set_name( g_menu, i, buffer );
			q_menu_item_set_data( g_menu, i, newname );
			break;
		}
	}
}

public client_disconnect( id )
{
	new name[32];
	get_user_name( id, name, charsmax(name) );
	
	if( get_pcvar_num(g_cvar_leavemessage) )
	{
		client_print( 0, print_chat, "%s from %s left the game", name, player_country[id] );
	}
	
	new i = 0;
	new size = q_menu_item_count( g_menu );
	new buffer[32];
	for( ; i < size; ++i )
	{
		q_menu_item_get_data( g_menu, i, buffer, charsmax(buffer) );
		if( equal( buffer, name ) )
		{
			q_menu_item_remove( g_menu, i );
			break;
		}
	}
}

public clcmd_country( id )
{
	q_menu_display( id, g_menu );
	
	return PLUGIN_HANDLED;
}

public menu_countries_handler( id, menu, item )
{
	return PLUGIN_HANDLED;
}
