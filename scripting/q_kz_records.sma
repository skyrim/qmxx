#include <amxmodx>

#include <q_kz>
#include <q_menu>

/**
 * to do:
 * - /community <map>
 * - multilingual (world, country names, menu stuff, ...)
 */

#pragma semicolon 1

#define PLUGIN "Q::KZ::Records"
#define VERSION "3.0"
#define AUTHOR "Quaker"

new QMenu:g_menu_communities;
new QMenu:g_menu_record;
new Trie:g_recordcomm_cmd2id;
new Array:g_recordcomm_name;
new Array:g_recordcomm_way;
new Array:g_recordcomm_player;
new Array:g_recordcomm_time;

public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	
	new datadir[128];
	q_kz_getDataDirectory( datadir, charsmax(datadir) );
	add( datadir, charsmax(datadir), "/records" );
	
	if( !dir_exists( datadir ) )
	{
		mkdir( datadir );
		pause( "a" );
		return;
	}
	
	new inifile[160];
	formatex( inifile, charsmax(inifile), "%s/records.ini", datadir );
	new f = fopen( inifile, "rt" );
	if( !f )
	{
		pause( "a" );
		return;
	}
	
	register_clcmd( "say /records", "clcmd_records" );
	register_clcmd( "say", "clcmd_community_record" );
	
	g_menu_communities = q_menu_create( "Records", "menu_communities_handler" );
	g_menu_record = q_menu_create( "", "menu_record_handler" );
	
	g_recordcomm_cmd2id = TrieCreate( );
	g_recordcomm_name = ArrayCreate( 32, 1 );
	g_recordcomm_way = ArrayCreate( 1, 1 );
	g_recordcomm_time = ArrayCreate( 1, 1 );
	g_recordcomm_player = ArrayCreate( 1, 1 );
	
	new buffer[128];
	new count;
	new community[32], command[32], recordfile[32];
	
	new recordfilepath[160];
	new currmap[32], currmap_len;
	get_mapname( currmap, charsmax(currmap) );
	currmap_len = strlen( currmap );
	new map[32], way[32], time[10], player[32];
	while( !feof( f ) )
	{
		fgets( f, buffer, charsmax(buffer) );
		if(buffer[0] == ';') {
			continue;
		}
		
		parse( buffer, community, charsmax(community), command, charsmax(command), recordfile, charsmax(recordfile) );
		
		formatex( recordfilepath, charsmax(recordfilepath), "%s/%s", datadir, recordfile );
		new fr = fopen( recordfilepath, "rt" );
		if( !fr )
			continue; // maybe print error
		
		new Array:way_array, Array:player_array, Array:time_array;
		
		new found = false;
		while( !feof( fr ) )
		{
			fgets( fr, buffer, charsmax(buffer) );
			
			if( equali( currmap, buffer, currmap_len ) )
			{
				parse( buffer, map, charsmax(map), time, charsmax(time), player, charsmax(player) );
				
				if( !found )
				{
					found = true;
					
					TrieSetCell( g_recordcomm_cmd2id, command, count );
					ArrayPushString( g_recordcomm_name, community );
					q_menu_item_add( g_menu_communities, "" );
					
					way_array = ArrayCreate( 32, 1 );
					player_array = ArrayCreate( 32, 1 );
					time_array = ArrayCreate( 1, 1 );
					ArrayPushCell( g_recordcomm_way, way_array );
					ArrayPushCell( g_recordcomm_player, player_array );
					ArrayPushCell( g_recordcomm_time, time_array );
					
					++count;
				}
				else
				{
					if( map[currmap_len] != '[' ) // if we get here, it means we found another map with similar name
						break;
				}
				
				if( map[currmap_len] == '[' )
					copyc( way, charsmax(way), map[currmap_len + 1], ']' );
				
				ArrayPushString( way_array, way );
				way[0] = 0;
				copyc( player, charsmax(player), player, ' ' );
				ArrayPushString( player_array, player );
				ArrayPushCell( time_array, str_to_float( time ) );
			}
			else if( found ) // if found earlier, but not now, than there are no more records for this map
			{
				break;
			}
		}
		fclose( fr );
	}
	fclose( f );
}

public plugin_end( )
{
	new Array:temp;
	
	for( new i = 0, size = ArraySize( g_recordcomm_way ); i < size; ++i )
	{
		temp = ArrayGetCell( g_recordcomm_way, i );
		ArrayDestroy( temp );
	}
	ArrayDestroy( g_recordcomm_way );
	
	for( new i = 0, size = ArraySize( g_recordcomm_player ); i < size; ++i )
	{
		temp = ArrayGetCell( g_recordcomm_player, i );
		ArrayDestroy( temp );
	}
	ArrayDestroy( g_recordcomm_player );
	
	for( new i = 0, size = ArraySize( g_recordcomm_time ); i < size; ++i )
	{
		temp = ArrayGetCell( g_recordcomm_time, i );
		ArrayDestroy( temp );
	}
	ArrayDestroy( g_recordcomm_time );
	
	ArrayDestroy( g_recordcomm_name );
}

public clcmd_community_record( id, level, cid )
{
	new command[16];
	read_argv( 1, command, charsmax(command) );
	
	new community;
	if( TrieKeyExists( g_recordcomm_cmd2id, command ) )
	{
		TrieGetCell( g_recordcomm_cmd2id, command, community );
	
		menu_record( id, community );
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

menu_record( id, community )
{
	new community_name[32];
	ArrayGetString( g_recordcomm_name, community, community_name, charsmax(community_name) );
	new map[32];
	get_mapname( map, charsmax(map) );
	new title[64];
	formatex( title, charsmax(title), "%s record on %s", community_name, map ); // multilang
	q_menu_set_title( g_menu_record, title );
	
	q_menu_item_clear( g_menu_record );
	
	new item[48];
	new player[32], Float:time, minutes, Float:seconds, way[32];
	for( new i = 0, size = ArraySize( ArrayGetCell( g_recordcomm_way, community ) ); i < size; ++i )
	{
		ArrayGetString( ArrayGetCell( g_recordcomm_player, community ), i, player, charsmax(player) );
		
		time = ArrayGetCell( ArrayGetCell( g_recordcomm_time, community ), i );
		minutes = floatround( time / 60, floatround_floor );
		seconds = time - minutes * 60.0;
		
		ArrayGetString( ArrayGetCell( g_recordcomm_way, community ), i, way, charsmax(way) );
		
		if( strlen(way) > 0 )
			formatex( item, charsmax(item), "\r[%s] \y%s \wdone in \y%d:%s%.2f", way, player, minutes, ( seconds < 10.0 ) ? "0" : "", seconds ); // multilang
		else
			formatex( item, charsmax(item), "\y%s \wdone in \y%d:%s%.2f", player, minutes, ( seconds < 10.0 ) ? "0" : "", seconds ); // multilang
			
		q_menu_item_add( g_menu_record, item, "", false, false );
	}
	
	q_menu_display( id, g_menu_record );
}

public menu_record_handler( id, menu, item )
{
	if( item < 0 )
		return PLUGIN_CONTINUE;
	
	return PLUGIN_HANDLED;
}

public clcmd_records( id, level, cid )
{
	menu_communities( id );
	
	return PLUGIN_HANDLED;
}

menu_communities( id )
{
	new name[32];
	for( new i = 0, size = ArraySize( g_recordcomm_name ); i < size; ++i )
	{
		ArrayGetString( g_recordcomm_name, i, name, charsmax(name) );
		q_menu_item_set_name( g_menu_communities, i, name );
	}
	
	// set item names at users language
	q_menu_display( id, g_menu_communities );
}

public menu_communities_handler( id, menu, item )
{
	if( item < 0 )
		return PLUGIN_CONTINUE;
	
	menu_record( id, item );
	
	return PLUGIN_HANDLED;
}
