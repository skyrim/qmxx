#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#include <q>
#include <q_kz>
#include <q_menu>

#pragma semicolon 1

#define PLUGIN "Q::KZ::Ghost"
#define VERSION "1.0"
#define AUTHOR "Quaker"

new g_demoDirectory[256];

new g_ghost_Model;

new g_player_Demo[33];
new g_player_DemoIndex[33];
new g_player_DemoPlaying[33];
new Float:g_player_DemoStartTime[33];
new g_player_DemoPaused[33];
new Float:g_player_DemoPauseTime[33];
new g_player_DemoPosition[33];
new g_player_GhostEntity[33];

new Array:g_demoFileName;
new Array:g_demoFileHandle;
new Array:g_demoBeginningTime;
new Array:g_demoBeginningOffset;

new Array:g_startButtonEntityOrigins;
new Array:g_stopButtonEntityOrigins;

public plugin_precache( ) {
	g_ghost_Model = precache_model( "sprites/flare1.spr" );
}

public plugin_init( ) {
	register_plugin( PLUGIN, VERSION, AUTHOR );
	
	q_kz_getDataDirectory( g_demoDirectory, charsmax(g_demoDirectory) );
	formatex( g_demoDirectory, charsmax(g_demoDirectory), "%s/demos/", g_demoDirectory );
	if( !dir_exists(g_demoDirectory) ) {
		mkdir( g_demoDirectory );
		
		return;
	}
	
	g_demoFileName = ArrayCreate( 128 );
	g_demoFileHandle = ArrayCreate( );
	g_demoBeginningTime = ArrayCreate( );
	g_demoBeginningOffset = ArrayCreate( );
	
	g_startButtonEntityOrigins = ArrayCreate( 3 );
	g_stopButtonEntityOrigins = ArrayCreate( 3 );
	
	new filepath[256];
	new filename[128];
	
	new dir = open_dir( g_demoDirectory, filename, charsmax(filename) );
	do {
		if( !( equali( filename, "." ) || equali( filename, ".." ) ) ) {
			formatex( filepath, charsmax(filepath), "%s%s", g_demoDirectory, filename );
			
			new f = fopen( filepath, "rb" );
			if( f && valid_demo_file( filename, f ) ) {
				ArrayPushCell( g_demoFileHandle, f );
				ArrayPushString( g_demoFileName, filename );
				ArrayPushCell( g_demoBeginningTime, 0 );
				ArrayPushCell( g_demoBeginningOffset, 0 );
			}
			else {
				fclose( f );
			}
		}
	} while( next_file( dir, filename, charsmax(filename) ) );
	
	new Float:mins[3], Float:maxs[3], Float:origin[3];
	new Array:startButtonEntities = q_kz_getStartButtonEntities( );
	for( new i = 0, size = ArraySize( startButtonEntities ); i < size; ++i ) {
		new button = ArrayGetCell( startButtonEntities, i );
		
		pev( button, pev_mins, mins );
		pev( button, pev_maxs, maxs );
		origin[0] = mins[0] + ( ( maxs[0] - mins[0] ) / 2 );
		origin[1] = mins[1] + ( ( maxs[1] - mins[1] ) / 2 );
		origin[2] = mins[2] + ( ( maxs[2] - mins[2] ) / 2 );
		
		ArrayPushArray( g_startButtonEntityOrigins, origin );
	}
	new Array:stopButtonEntities = q_kz_getStopButtonEntities( );
	for( new i = 0, size = ArraySize( stopButtonEntities ); i < size; ++i ) {
		new button = ArrayGetCell( stopButtonEntities, i );
		
		pev( button, pev_mins, mins );
		pev( button, pev_maxs, maxs );
		origin[0] = mins[0] + ( ( maxs[0] - mins[0] ) / 2 );
		origin[1] = mins[1] + ( ( maxs[1] - mins[1] ) / 2 );
		origin[2] = mins[2] + ( ( maxs[2] - mins[2] ) / 2 );
		
		ArrayPushArray( g_stopButtonEntityOrigins, origin );
	}
	
	register_forward( FM_AddToFullPack, "forward_AddToFullPack", false );
	register_forward( FM_PlayerPostThink, "forward_PlayerThink" );
	
	q_kz_registerForward( Q_KZ_TimerStart, "forward_KZTimerStart" );
	q_kz_registerForward( Q_KZ_TimerStop, "forward_KZTimerStop" );
	q_kz_registerForward( Q_KZ_TimerPause, "forward_KZTimerPause", true );
	
	register_clcmd( "say /kzghost", "clcmd_kzghost" );
}

public plugin_end( ) {
	for( new i = 0, size = ArraySize(g_demoFileHandle); i < size; ++i ) {
		fclose( ArrayGetCell( g_demoFileHandle, i ) );
	}
	
	g_demoFileName ? ArrayDestroy( g_demoFileName ) : 0;
	g_demoFileHandle ? ArrayDestroy( g_demoFileHandle ) : 0;
	g_demoBeginningTime ? ArrayDestroy( g_demoBeginningTime ) : 0;
	g_demoBeginningOffset ? ArrayDestroy( g_demoBeginningOffset ) : 0;
	g_startButtonEntityOrigins ? ArrayDestroy( g_startButtonEntityOrigins ) : 0;
	g_stopButtonEntityOrigins ? ArrayDestroy( g_stopButtonEntityOrigins ) : 0;
}

valid_demo_file( name[], handle ) {
	new ext_pos = strlen(name) - 3;
	if( !(name[ext_pos] == 'd' && name[ext_pos+1] == 'e' && name[ext_pos + 2] == 'm') ) {
		return false;
	}
	
	new f = handle;
	
	new magic[8];
	fread_blocks( f, magic, 8, BLOCK_BYTE );
	if( !equal( magic, "HLDEMO" ) ) {
		return false;
	}
	
	fseek( f, 8, SEEK_CUR );
	
	new map[32];
	get_mapname( map, charsmax(map) );
	
	new demoMap[32];
	fread_blocks( f, demoMap, 32, BLOCK_BYTE );
	
	if( !equali( map, demoMap ) ) {
		return false;
	}
	
	fseek( f, 0, SEEK_SET );
	return true;
}

public clcmd_kzghost( id ) {
	menu_kzghost( id );
	
	return PLUGIN_HANDLED;
}

menu_kzghost( id ) {
	new QMenu:menu = q_menu_create( "KZ Ghost", "menu_kzghost_handler" );
	
	if( g_player_Demo[id] != 0 ) {
		new demoName[128] = "Select demo^nDemo: ";
		ArrayGetString( g_demoFileName, g_player_DemoIndex[id], demoName[18], charsmax(demoName) - 13 );
		q_menu_item_add( menu, demoName );
		q_menu_item_add( menu, "Clear demo" );
	}
	else {
		q_menu_item_add( menu, "Select demo^nDemo: ..." );
		q_menu_item_add( menu, "Clear demo" );
	}
	
	q_menu_display( id, menu );
}

public menu_kzghost_handler( id, menu, item ) {
	switch( item ) {
	case 0: {
		menu_demolist( id );
		
		return PLUGIN_HANDLED;
	}
	case 1: {
		demo_clear( id );
		
		menu_kzghost( id );
		
		return PLUGIN_HANDLED;
	}
	}
	
	return PLUGIN_CONTINUE;
}

menu_demolist( id ) {
	new QMenu:menu = q_menu_create( "KZ Ghost", "menu_demolist_handler" );
	
	new size = ArraySize( g_demoFileName );
	if( size == 0 ) {
		q_menu_item_add( menu, "Demos for this map not found.", _, false );
		q_menu_item_add( menu, "Add demos to data/q/kz/demos folder.", _, false );
	}
	else {
		new demoname[128];
		for( new i = 0; i < size; ++i ) {
			ArrayGetString( g_demoFileName, i, demoname, charsmax(demoname) );
			q_menu_item_add( menu, demoname );
		}
	}
	q_menu_item_set_name( menu, QMenuItem_Exit, "Back to KZ Ghost Menu" );
	
	q_menu_display( id, menu );
}

public menu_demolist_handler( id, menu, item ) {
	if( item >= 0 ) {
		demo_select( id, item );
		
		menu_kzghost( id );
		
		return PLUGIN_HANDLED;
	}
	else if( item == QMenuItem_Exit ) {
		menu_kzghost( id );
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

create_ghost( ) {
	new entity = engfunc( EngFunc_CreateNamedEntity, engfunc( EngFunc_AllocString, "info_target" ) );
	set_pev( entity, pev_classname, "info_target" );
	set_pev( entity, pev_solid, SOLID_TRIGGER );
	set_pev( entity, pev_movetype, MOVETYPE_FLY );
	engfunc( EngFunc_SetSize, entity, Float:{-50.0,-50.0,-50.0}, Float:{50.0,50.0,50.0} );
	set_pev( entity, pev_modelindex, g_ghost_Model );
	set_pev( entity, pev_rendermode, kRenderTransAdd );
	set_pev( entity, pev_renderamt, 0.0 );
	
	return entity;
}

demo_select( id, demo ) {
	if( g_player_GhostEntity[id] == 0 ) {
		g_player_GhostEntity[id] = create_ghost( );
	}
	
	g_player_Demo[id] = ArrayGetCell( g_demoFileHandle, demo );
	g_player_DemoIndex[id] = demo;
	
	new f = g_player_Demo[id];
	new beginningOffset = ArrayGetCell( g_demoBeginningOffset, demo );
	if( beginningOffset == 0 ) {
		fseek( f, 540, SEEK_CUR );
		
		new dirOffset;
		fread( f, dirOffset, BLOCK_INT );
		
		fseek( f, dirOffset, SEEK_SET );
		
		new dirCount;
		fread( f, dirCount, BLOCK_INT );
		for( new i = 0; i < dirCount; ++i ) {
			fseek( f, 4, SEEK_CUR );
			
			new dirName[64];
			fread_blocks( f, dirName, 64, BLOCK_BYTE );
			if( equali( dirName, "playback" ) ) {
				fseek( f, 16, SEEK_CUR );
				
				new playbackOffset;
				fread( f, playbackOffset, BLOCK_INT );
				fseek( f, playbackOffset, SEEK_SET );
				
				break;
			}
			else {
				fseek( f, 24, SEEK_CUR );
			}
		}
		
		new startNotFound = false;
		for(;;) {
			new macro;
			fread( f, macro, BLOCK_BYTE );
			
			new Float:time;
			fread( f, _:time, BLOCK_INT );
			fseek( f, 4, SEEK_CUR );
			
			switch( macro ) {
			case 0, 1: {
				new ghost = g_player_GhostEntity[id];
				fseek( f, 4, SEEK_CUR );
				
				new Float:origin[3];
				fread_blocks( f, _:origin, 3, BLOCK_INT );
				set_pev( ghost, pev_origin, origin );
				
				fseek( f, 448, SEEK_CUR );
				
				new length;
				fread( f, length, BLOCK_INT );
				fseek( f, length, SEEK_CUR );
			}
			
			case 3: {
				new command[64];
				fread_blocks( f, command, 64, BLOCK_BYTE );
				if( equal( command, "+use" ) ) {
					new Float:ghostOrigin[3];
					pev( g_player_GhostEntity[id], pev_origin, ghostOrigin );
					
					new Float:buttonOrigin[3];
					for( new i = 0, size = ArraySize( g_startButtonEntityOrigins ); i < size; ++i ) {
						ArrayGetArray( g_startButtonEntityOrigins, i, buttonOrigin );
						
						xs_vec_sub( ghostOrigin, buttonOrigin, buttonOrigin );
						
						if( xs_vec_len( buttonOrigin ) < 90.0 ) {
							ArraySetCell( g_demoBeginningTime, g_player_DemoIndex[id], time );
							ArraySetCell( g_demoBeginningOffset, g_player_DemoIndex[id], ftell( f ) );
							
							return;
						}
					}
				}
			}
			
			case 4: {
				fseek( f, 32, SEEK_CUR );
			}
			
			case 5: {
				startNotFound = true;
				break;
			}
			
			case 6: {
				fseek( f, 84, SEEK_CUR );
			}
			
			case 7: {
				fseek( f, 8, SEEK_CUR );
			}
			
			case 8: {
				fseek( f, 4, SEEK_CUR );
				new length;
				fread( f, length, BLOCK_INT );
				fseek( f, length, SEEK_CUR );
				fseek( f, 16, SEEK_CUR );
			}
			
			case 9: {
				new length;
				fread( f, length, BLOCK_INT );
				fseek( f, length, SEEK_CUR );
			}
			}
		}
		
		if( startNotFound ) {
			demo_clear( id );
			client_print( id, print_chat, "Could not find start of the demo. Choose some other demo." );
			return;
		}
	}
	else {
		fseek( f, beginningOffset, SEEK_SET );
	}
}

demo_clear( id ) {
	g_player_Demo[id] = 0;
	
	demo_stop( id );
}

demo_play( id ) {
	g_player_DemoPlaying[id] = true;
	
	g_player_DemoStartTime[id] = get_gametime( ) - Float:ArrayGetCell( g_demoBeginningTime, g_player_DemoIndex[id] );
	g_player_DemoPosition[id] = ArrayGetCell( g_demoBeginningOffset, g_player_DemoIndex[id] );
	
	ghost_show( g_player_GhostEntity[id] );
}

demo_pause( id ) {
	g_player_DemoPaused[id] = true;
	g_player_DemoPauseTime[id] = get_gametime( );
}

demo_unpause( id ) {
	g_player_DemoPaused[id] = false;
	g_player_DemoStartTime[id] += get_gametime( ) - g_player_DemoPauseTime[id];
}

demo_stop( id ) {
	g_player_DemoPlaying[id] = false;
	
	ghost_hide( g_player_GhostEntity[id] );
}

is_ghost_entity( entity ) {
	for( new i = 1; i <= 32; ++i ) {
		if( entity == g_player_GhostEntity[i] ) {
			return true;
		}
	}
	
	return false;
}

ghost_show( ghost_entity ) {
	set_pev( ghost_entity, pev_rendermode, kRenderTransAdd );
	set_pev( ghost_entity, pev_renderamt, 128.0 );
}

ghost_hide( ghost_entity ) {
	set_pev( ghost_entity, pev_rendermode, kRenderTransAdd );
	set_pev( ghost_entity, pev_renderamt, 0.0 );
}

stock ghost_toggle( ghost_entity ) {
	pev( ghost_entity, pev_rendermode ) == kRenderTransAlpha ? ghost_show( ghost_entity ) : ghost_hide( ghost_entity );
}

public forward_AddToFullPack( es, e, ent, host, hostflags, player, pset ) {
	
	if( !player && is_ghost_entity( ent ) ) {
		if( ent != g_player_GhostEntity[host] ) {
			return FMRES_SUPERCEDE;
		}
		else {
			if( !g_player_DemoPlaying[host] ) {
				return FMRES_SUPERCEDE;
			}
			
			new Float:ghostOrigin[3];
			pev( ent, pev_origin, ghostOrigin );
			
			new Float:hostOrigin[3];
			pev( host, pev_origin, hostOrigin );
			
			xs_vec_sub( ghostOrigin, hostOrigin, hostOrigin );
			new Float:distance = xs_vec_len( hostOrigin );
			if( distance < 500.0 ) {
				set_pev( ent, pev_renderamt, ( distance / 500.0 ) * 255.0 );
			}
		}
	}
	
	return FMRES_IGNORED;
}

public forward_PlayerThink( id ) {
	if( !g_player_DemoPlaying[id] || g_player_DemoPaused[id] ) {
		return;
	}
	
	new Float:currentTime = get_gametime( );
	
	new f = g_player_Demo[id];
	fseek( f, g_player_DemoPosition[id], SEEK_SET );
	
	for(;;) {
		new macro;
		fread( f, macro, BLOCK_BYTE );
		
		new Float:time;
		fread( f, _:time, BLOCK_INT );
		if( time > ( currentTime - g_player_DemoStartTime[id] ) ) {
			fseek( f, -5, SEEK_CUR );
			break;
		}
		
		fseek( f, 4, SEEK_CUR );
		
		switch( macro ) {
		case 0, 1: {
			new ghost = g_player_GhostEntity[id];
			fseek( f, 4, SEEK_CUR );
			
			new Float:origin[3];
			fread_blocks( f, _:origin, 3, BLOCK_INT );
			set_pev( ghost, pev_origin, origin );
			
			fseek( f, 448, SEEK_CUR );
			
			new length;
			fread( f, length, BLOCK_INT );
			fseek( f, length, SEEK_CUR );
		}
		
		case 3: {
			new command[64];
			fread_blocks( f, command, 64, BLOCK_BYTE );
			if( equal( command, "+use" ) ) {
				new Float:ghostOrigin[3];
				pev( g_player_GhostEntity[id], pev_origin, ghostOrigin );
				
				new Float:buttonOrigin[3];
				for( new i = 0, size = ArraySize( g_stopButtonEntityOrigins ); i < size; ++i ) {
					ArrayGetArray( g_stopButtonEntityOrigins, i, buttonOrigin );
					
					xs_vec_sub( ghostOrigin, buttonOrigin, buttonOrigin );
					
					if( xs_vec_len( buttonOrigin ) < 90.0 ) {
						ArraySetCell( g_demoBeginningTime, g_player_DemoIndex[id], time );
						ArraySetCell( g_demoBeginningOffset, g_player_DemoIndex[id], ftell( f ) );
						
						client_print( id, print_chat, "Ghost finished the map." );
						demo_stop( id );
					}
				}
			}
		}
		
		case 4: {
			fseek( f, 32, SEEK_CUR );
		}
		
		case 5: {
			demo_stop( id );
		}
		
		case 6: {
			fseek( f, 84, SEEK_CUR );
		}
		
		case 7: {
			fseek( f, 8, SEEK_CUR );
		}
		
		case 8: {
			fseek( f, 4, SEEK_CUR );
			new length;
			fread( f, length, BLOCK_INT );
			fseek( f, length, SEEK_CUR );
			fseek( f, 16, SEEK_CUR );
		}
		
		case 9: {
			new length;
			fread( f, length, BLOCK_INT );
			fseek( f, length, SEEK_CUR );
		}
		}
	}
	
	g_player_DemoPosition[id] = ftell( f );
}

public forward_KZTimerStart( id ) {
	if( g_player_Demo[id] ) {
		demo_play( id );
	}
}

public forward_KZTimerStop( id, successful ) {
	if( g_player_Demo[id] && g_player_DemoPlaying[id] ) {
		demo_stop( id );
	}
}

public forward_KZTimerPause( id, paused ) {
	if( g_player_Demo[id] && g_player_DemoPlaying[id] ) {
		paused ? demo_pause( id ) : demo_unpause( id );
	}
}
