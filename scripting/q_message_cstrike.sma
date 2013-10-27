#include <amxmodx>

#include <q_cstrike_const>

#pragma semicolon 1

#define PLUGIN "Q Message CStrike"
#define VERSION "1.0"
#define AUTHOR "Quaker"

public plugin_natives( )
{
	register_library( "q_message_cstrike" );
	
	register_native( "q_message_TeamInfo", "_q_message_TeamInfo" );
}

public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
}

check_dest( dest )
{
	if( ( dest < 0 ) || ( dest > 9 ) )
	{
		log_error( AMX_ERR_NATIVE, "Invalid message destination" );
		
		return true;
	}
	
	return false;
}

check_id( id )
{
	if( ( id < 1 ) || ( id > 32 ) )
	{
		log_error( AMX_ERR_NATIVE, "Invalid player id %d", id );
		return true;
	}
	
	return false;
}

check_team_cs( team )
{
	if( ( team < 0 ) || ( team > 3 ) )
	{
		log_error( AMX_ERR_NATIVE, "Invalid player team %d", team );
		return true;
	}
	
	return false;
}

public _q_message_TeamInfo( plugin, params )
{
	if( params != 5 )
	{
		log_error( AMX_ERR_NATIVE, "Parameters do not match. Expected 5, found %d", params );
		return;
	}
	
	new type = get_param( 1 );
	if( check_dest( type ) )
		return;
	
	new dest = get_param( 2 );
	//if( check_id( dest ) )
	//	return;
	
	new origin[3] = { 0, 0, 0 };
	get_array( 3, origin, sizeof(origin) );
	
	new id = get_param( 4 );
	if( check_id( id ) )
		return;
	
	new team = get_param( 5 );	
	if( check_team_cs( team ) )
		return;
	
	static team_name[][] =
	{
		"UNASSIGNED",
		"TERRORIST",
		"CT",
		"SPECTATOR"
	};
	
	message_begin( type, get_user_msgid( "TeamInfo" ), origin, dest );
	write_byte( id );
	write_string( team_name[team] );
	message_end( );
}
