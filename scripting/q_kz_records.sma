/**
* to do:
* - better directory structure
* - multilingual for everything (menu title, community name, ...)
* - saytext message abstraction (like show_hudmessage)
* - maybe, just maybe, add support for map name as argument e.g /wr kz_map_name
*/

#include <amxmodx>
#include <q_kz>

#pragma semicolon 1

#define PLUGIN "Q KZ Records"
#define VERSION "1.0"
#define AUTHOR "Quaker"

#define MAX_RECORDS 32
#define MAX_WAYS 5

new g_map_name_len;
new g_map_name[32];

new g_record_count = 0;
new g_record_cid[MAX_RECORDS];
new g_record_community[MAX_RECORDS][32];

new g_record_player[MAX_RECORDS][MAX_WAYS][32];
new Float:g_record_time[MAX_RECORDS][MAX_WAYS];

new g_record_waycount[MAX_RECORDS];
new g_record_wayname[MAX_RECORDS][MAX_WAYS][16];

new msg_SayText;

new g_menu_records;

public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	
	register_dictionary( "q_kz_records.txt" );
	
	get_mapname( g_map_name, charsmax(g_map_name) );
	g_map_name_len = strlen( g_map_name );
	
	msg_SayText = get_user_msgid( "SayText" );
	
	new recd[128];
	q_kz_get_datadir( recd, charsmax(recd) );
	add( recd, charsmax(recd), "/records" );
	if( !dir_exists( recd ) )
	{
		mkdir( recd );
		
		return;
	}
	
	new recf[64];
	new recdh = open_dir( recd, recf, charsmax(recf) );
	if( recdh )
	{
		new recfname[64];
		new recfext[64];
		new recfpath[128];
		new reccmd[32];
		do
		{
			strtok( recf, recfname, charsmax(recfname), recfext, charsmax(recfext), '.', true );
			if( equal( recfext, "qkzrec" ) )
			{
				formatex( reccmd, charsmax(reccmd), "say /%s", recfname );
				g_record_cid[g_record_count] = register_clcmd( reccmd, "clcmd_record" );
				
				formatex( recfpath, charsmax(recfpath), "%s/%s", recd, recf );
				new f = fopen( recfpath, "rt" );
				if( f )
				{
					fgets( f, g_record_community[g_record_count], charsmax(g_record_community[]) );
					trim( g_record_community[g_record_count] );
					
					g_record_waycount[g_record_count] = 0;
					
					new buffer[128];
					new mname[32];
					new pname[32];
					new rtime[16];
					while( !feof( f ) )
					{
						fgets( f, buffer, charsmax(buffer) );
						parse( buffer, mname, charsmax(mname), rtime, charsmax(rtime), pname, charsmax(pname) );
						
						if( equal( mname, g_map_name, g_map_name_len ) )
						{
							g_record_player[g_record_count][g_record_waycount[g_record_count]] = pname;
							g_record_time[g_record_count][g_record_waycount[g_record_count]] = str_to_float( rtime );
							
							new sqbpos = strfind( mname, "[" );
							if( sqbpos != -1 )
							{
								copyc( g_record_wayname[g_record_count][g_record_waycount[g_record_count]], charsmax(g_record_wayname[][]), mname[sqbpos + 1], ']' );
								++g_record_waycount[g_record_count];
							}
							else
							{
								break;
							}
						}
					}
					
					fclose( f );
				}
				
				g_record_count += 1;
			}
		}
		while( next_file( recdh, recf, charsmax(recf) ) );
		
		close_dir( recdh );
	}
	
	if( g_record_count )
	{
		g_menu_records = menu_create( "QKZ Records", "menu_records_hnd" );
		for( new i = 0; i < g_record_count; ++i )
		{
			menu_additem( g_menu_records, g_record_community[i] );
		}
		
		register_clcmd( "say /records", "clcmd_records" );
	}
}

public plugin_end( )
{
	menu_destroy( g_menu_records );
}

public clcmd_record( id, level, cid )
{
	for( new i = 0; i < g_record_count; ++i )
	{
		if( g_record_cid[i] == cid )
		{
			new mins, Float:secs, szTime[10];
			new buffer[128];
			
			if( g_record_waycount[i] )
			{
				buffer[0] = 1;
				LookupLangKey( buffer[1], charsmax(buffer), "Q_KZ_RECORDS_RECORD_ON", id );
				replace( buffer, charsmax(buffer), "%COMMUNITY%", g_record_community[i] );
				replace( buffer, charsmax(buffer), "%MAP%", g_map_name );
				replace_all( buffer, charsmax(buffer), "!n", "^x01" );
				replace_all( buffer, charsmax(buffer), "!t", "^x03" );
				replace_all( buffer, charsmax(buffer), "!g", "^x04" );
				
				message_begin( MSG_ONE_UNRELIABLE, msg_SayText, _, id );
				write_byte( id );
				write_string( buffer );
				message_end( );
				
				for( new j = 0; j < g_record_waycount[i]; ++j )
				{
					mins = floatround( g_record_time[i][j] / 60, floatround_floor );
					secs = g_record_time[i][j] - float( mins * 60 );
					formatex( szTime, charsmax(szTime), "%d:%s%.2f", mins, secs < 10 ? "0" : "", secs );
					
					buffer[0] = 1;
					LookupLangKey( buffer[1], charsmax(buffer), "Q_KZ_RECORDS_WAY_RECORD", id );
					replace( buffer, charsmax(buffer), "%WAY%", g_record_wayname[i][j] );
					replace( buffer, charsmax(buffer), "%PLAYER%", g_record_player[i][j] );
					replace( buffer, charsmax(buffer), "%TIME%", szTime );
					replace_all( buffer, charsmax(buffer), "!n", "^x01" );
					replace_all( buffer, charsmax(buffer), "!t", "^x03" );
					replace_all( buffer, charsmax(buffer), "!g", "^x04" );
					
					message_begin( MSG_ONE_UNRELIABLE, msg_SayText, _, id );
					write_byte( id );
					write_string( buffer );
					message_end( );
				}
			}
			else
			{
				mins = floatround( g_record_time[i][0] / 60, floatround_floor );
				secs = g_record_time[i][0] - float( mins * 60 );
				formatex( szTime, charsmax(szTime), "%d:%s%.2f", mins, secs < 10 ? "0" : "", secs );
				
				buffer[0] = 1;
				LookupLangKey( buffer[1], charsmax(buffer), "Q_KZ_RECORDS_MAP_RECORD", id );
				replace( buffer, charsmax(buffer), "%COMMUNITY%", g_record_community[i] );
				replace( buffer, charsmax(buffer), "%MAP%", g_map_name );
				replace( buffer, charsmax(buffer), "%PLAYER%", g_record_player[i][0] );
				replace( buffer, charsmax(buffer), "%TIME%", szTime );
				replace_all( buffer, charsmax(buffer), "!n", "^x01" );
				replace_all( buffer, charsmax(buffer), "!t", "^x03" );
				replace_all( buffer, charsmax(buffer), "!g", "^x04" );
				
				message_begin( MSG_ONE_UNRELIABLE, msg_SayText, _, id );
				write_byte( id );
				write_string( buffer );
				message_end( );
			}
		}
	}
	
	return PLUGIN_HANDLED;
}

public clcmd_records( id, level, cid )
{
	menu_display( id, g_menu_records );
	
	return PLUGIN_HANDLED;
}

public menu_records_hnd( id, menu, item )
{
	clcmd_record( id, 0, g_record_cid[item] );
	
	return PLUGIN_HANDLED;
}
