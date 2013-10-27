#include <amxmodx>

#pragma semicolon 1

#define PLUGIN "Q StatusText"
#define VERSION "1.0"
#define AUTHOR "Quaker"

public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	
	register_message( get_user_msgid( "StatusText" ), "msg_hook_StatusText" );
}

public msg_hook_StatusText( msg_id, msg_dest, msg_sender )
{
	set_msg_arg_int( 1, ARG_BYTE, 0 );
	set_msg_arg_string( 2, "1 %p2" );
}
