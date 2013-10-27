#include <amxmodx>
#include <q_message>

#pragma semicolon 1

#define PLUGIN "Q Message"
#define VERSION "1.0"
#define AUTHOR "Quaker"

new g_message_ShowMenu;

public plugin_natives( )
{
	register_library( "q_message" );
	register_native( "q_message_ShowMenu", "_q_message_ShowMenu" );
}

public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	
	g_message_ShowMenu = get_user_msgid( "ShowMenu" );
}

// q_message_ShowMenu( id, msg_type, msg_origin[3] = {0,0,0}, keys, time, menu[] )
// short keysbitsum
// char time
// byte notfinalpart (bool)
// string menustring
public _q_message_ShowMenu( plugin, params )
{
	if( params != 6 )
	{
		log_error( AMX_ERR_NATIVE, "Parameters do not match. Expected 6, found %d", params );
		return;
	}
	
	if( !g_message_ShowMenu )
		return;
	
	new id = get_param( 1 );
	new type = get_param( 2 );
	
	new origin[3];
	get_array( 3, origin, sizeof(origin) );
	
	new keys = get_param( 4 );
	new menutime = get_param( 5 );
	
	new menu[1024];
	get_string( 6, menu, charsmax(menu) );
	new menulen = strlen( menu );
	
	new ptr;
	new temp[176];
	while( menulen > 0 )
	{
		message_begin( type, g_message_ShowMenu, origin, id );
		write_short( keys );
		write_char( menutime );
		
		menulen -= 175;
		if( menulen > 0 )
			write_byte( 1 );
		else
			write_byte( 0 );
		
		copy( temp, charsmax(temp), menu[ptr] );
		ptr += 175;
		write_string( temp );
		
		message_end( );
	}
}
