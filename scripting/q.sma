#include <amxmodx>

#define PLUGIN "Q"
#define VERSION "1.0"
#define AUTHOR "Quaker"

new g_dir_data[128];

public plugin_natives( )
{
	register_library( "q" );
	
	register_native( "q_get_datadir", "_q_get_datadir" );
}

public plugin_precache( )
{
	get_localinfo( "amxx_datadir", g_dir_data, charsmax(g_dir_data) );
	add( g_dir_data, charsmax(g_dir_data), "/q" );
	if( !dir_exists( g_dir_data ) ) mkdir( g_dir_data );
}

public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
}

public _q_get_datadir( plugin, params )
{
	if( params != 2 )
	{
		log_error( AMX_ERR_NATIVE, "error" );
	}
	
	set_string( 1, g_dir_data, get_param( 2 ) );
}
