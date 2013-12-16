/**
 * to do:
 * - saytext message for join and leave instead of client_print
 * - multilingual everything (even country names)
 * - looks like i'll have to make country locale (after a year or so, I cant remember what I meant by this)
 */

#include <amxmodx>
#include <geoip>
#include <cvar_util>

#include <q>
#include <q_menu>

#pragma semicolon 1

#define PLUGIN "Q::Country"
#define VERSION "1.0"
#define AUTHOR "Quaker"

new cvar_joinmsg;
new cvar_leavemsg;

new country_menu;

new player_country[33][46];

public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	
	CvarCache( register_cvar( "q_country_joinmessage", "0" ), CvarType_Int, cvar_joinmsg );
	CvarCache( register_cvar( "q_country_leavemessage", "0" ), CvarType_Int, cvar_leavemsg );
	
	q_menu_create( "Q Countries", "menu_countries_handler" );
	
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
	
	if( cvar_joinmsg )
	{
		client_print( 0, print_chat, "%s from %s entered the game", name, player_country[id] );
	}
	
	new fmt[64];
	formatex( fmt, charsmax(fmt), "\y%s \wfrom \y%s", name, player_country[id] );
	q_menu_item_add( country_menu, fmt, name, false );
}

public client_infochanged( id )
{
	new oldname[32];
	get_user_name( id, oldname, charsmax(oldname) );
	
	new newname[32];
	get_user_info( id, "name", newname, charsmax(newname) );
	
	new buffer[64];
	for( new i = 0, size = q_menu_item_count( country_menu ); i < size; ++i )
	{
		q_menu_item_get_data( country_menu, i, buffer, charsmax(buffer) );
		if( equal( oldname, buffer, charsmax(oldname) ) )
		{
			formatex( buffer, charsmax(buffer), "\y%s \wfrom \y%s", newname, player_country[id] );
			q_menu_item_set_name( country_menu, i, buffer );
			q_menu_item_set_data( country_menu, i, newname );
			break;
		}
	}
}

public client_disconnect( id )
{
	new name[32];
	get_user_name( id, name, charsmax(name) );
	
	if( cvar_leavemsg )
	{
		client_print( 0, print_chat, "%s from %s left the game", name, player_country[id] );
	}
	
	new i = 0;
	new size = q_menu_item_count( country_menu );
	new buffer[32];
	for( ; i < size; ++i )
	{
		q_menu_item_get_data( country_menu, i, buffer, charsmax(buffer) );
		if( equal( buffer, name ) )
		{
			q_menu_item_remove( country_menu, i );
			break;
		}
	}
}

public clcmd_country( id )
{
	q_menu_display( id, country_menu );
	
	return PLUGIN_HANDLED;
}

public menu_countries_handler( id, menu, item )
{
	return PLUGIN_HANDLED;
}
