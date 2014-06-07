/**
 * to do:
 * - there's probably something that can be improved, cvar_util first comes to my mind
 */

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#include <q>
#include <q_kz>
#include <q_cookies>

#pragma semicolon 1

#define PLUGIN "Q::KZ::Hook"
#define VERSION "1.1"
#define AUTHOR "Quaker"

#define TASKID_HOOKBEAM 4817923

#define HOOK_NO 0
#define HOOK_YES 1
#define HOOK_ACTIVE 2

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* Globals
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

new g_cookies_failed;

new g_sprite_hook;

new cvar_hook;
new cvar_hook_speed;
new cvar_hook_color;
new cvar_hook_color_random;

new g_player_hook[33];
new g_player_hook_color[33][3];
new Float:g_player_hook_speed[33];
new Float:g_player_hook_origin[33][3];
new Float:g_player_hook_lastused[33];

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* Plugin Schtuff
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

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

public plugin_precache( )
{
	g_sprite_hook = precache_model( "sprites/zbeam2.spr" );
}

public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	
	register_dictionary( "q_kz_hook.txt" );
	
	cvar_hook 			= register_cvar( "q_kz_hook", 			"3" );
	cvar_hook_color 		= register_cvar( "q_kz_hook_color",		"255 128 64" );
	cvar_hook_color_random 		= register_cvar( "q_kz_hook_color_random",	"1" );
	cvar_hook_speed 		= register_cvar( "q_kz_hook_speed", 		"600.0" );
	
	register_clcmd( "say /hook",		"clcmd_Hook" );
	register_clcmd( "say /hookmenu",	"clcmd_Hook" );
	register_clcmd( "say /givehook",	"clcmd_GiveHook" );
	register_clcmd( "+hook",		"clcmd_HookOn" );
	register_clcmd( "-hook",		"clcmd_HookOff" );
	register_clcmd( "HookSpeed",		"messagemode_HookSpeed" );
	register_clcmd( "HookColor",		"messagemode_HookColor" );
	
	register_forward( FM_PlayerPreThink, "fwd_PlayerPreThink" );
	
	q_kz_registerForward( Q_KZ_TimerStart, "forward_KZTimerStart" );
}

public plugin_cfg() {
	q_registerCvar(cvar_hook, "3", "Set hook mode: 0 - disabled, 1 - vip only, 2 - vip and after finishing map, 3 - always available.");
	q_registerCvar(cvar_hook_color, "255 128 64", "Default hook color.");
	q_registerCvar(cvar_hook_color_random, "1", "Toggle random hook color for players that haven't set it yet.");
	q_registerCvar(cvar_hook_speed, "600.0", "Default hook speed.");
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* Client Schtuff
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

public client_putinserver( id ) // DRY principle died in this function
{
	switch( clamp( get_pcvar_num( cvar_hook ), 0, 3 ) )
	{
		case 0:
		{
			g_player_hook[id] = HOOK_NO;
		}
		case 1, 2:
		{
			if( q_kz_player_isVip( id ) )
			{
				g_player_hook[id] = HOOK_YES;
			}
			else
			{
				g_player_hook[id] = HOOK_NO;
			}
		}
		case 3:
		{
			g_player_hook[id] = HOOK_YES;
		}
	}
	
	if( g_cookies_failed || !q_get_cookie_float( id, "hook_speed", g_player_hook_speed[id] ) )
		g_player_hook_speed[id] = get_pcvar_float( cvar_hook_speed ); // default hook speed set by cvar
	g_player_hook_speed[id] = floatclamp( g_player_hook_speed[id], 0.0, 2000.0 );
	
	new players_hook_color[12];
	if( !g_cookies_failed && q_get_cookie_string( id, "hook_color", players_hook_color ) )
	{
		new r[4], g[4], b[4];
		parse( players_hook_color, r, 3, g, 3, b, 3 );
		g_player_hook_color[id][0] = str_to_num( r );
		g_player_hook_color[id][1] = str_to_num( g );
		g_player_hook_color[id][2] = str_to_num( b );
	}
	else
	{
		if( get_pcvar_num( cvar_hook_color_random ) )
		{
			g_player_hook_color[id][0] = random_num( 0, 255 );//clamp( str_to_num( r ), 0, 255 );
			g_player_hook_color[id][1] = random_num( 0, 255 );//clamp( str_to_num( g ), 0, 255 );
			g_player_hook_color[id][2] = random_num( 0, 255 );//clamp( str_to_num( b ), 0, 255 );
		}
		else
		{
			new hook_color[12]; // yes, i see similar variable above, but, this is better practice
			get_pcvar_string( cvar_hook_color, hook_color, charsmax(hook_color) );
			new r[4], g[4], b[4];
			parse( hook_color, r, 3, g, 3, b, 3 );
			g_player_hook_color[id][0] = str_to_num( r );
			g_player_hook_color[id][1] = str_to_num( g );
			g_player_hook_color[id][2] = str_to_num( b );
		}
	}
}

public client_infochanged( id )
{
	new hook = get_pcvar_num( cvar_hook );
	if( ( hook == 3 ) || ( ( hook != 0 ) && q_kz_player_isVip( id ) ) )
	{
		g_player_hook[id] = HOOK_YES;
	}
}

public client_disconnect( id )
{
	if( !g_cookies_failed )
	{
		q_set_cookie_float( id, "hook_speed", g_player_hook_speed[id] );
		
		new players_hook_color[12];
		formatex( players_hook_color, charsmax(players_hook_color), "%d %d %d",
			g_player_hook_color[id][0],
			g_player_hook_color[id][1],
			g_player_hook_color[id][2] );
		q_set_cookie_string( id, "hook_color", players_hook_color );
	}
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* Forwards
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

public fwd_PlayerPreThink( id )
{
	static Float:origin[3];
	static Float:velocity[3];
	
	if( g_player_hook[id] & HOOK_ACTIVE )
	{
		pev( id, pev_origin, origin );
		
		xs_vec_sub( g_player_hook_origin[id], origin, velocity );
		xs_vec_normalize( velocity, velocity );
		xs_vec_mul_scalar( velocity, g_player_hook_speed[id], velocity );
		
		set_pev( id, pev_velocity, velocity );
	}
}

public forward_KZTimerStart( id ) {
	if( g_player_hook[id] & HOOK_ACTIVE )
	{
		clcmd_HookOff( id );
	}
	
	if( ( get_gametime( ) - g_player_hook_lastused[id] ) < 3.0 )
	{
		q_kz_print( id, "%L", id, "QKZ_HOOK_WAIT" );
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public reward_Hook_handler( id )
{
	g_player_hook[id] = HOOK_YES;
}

public reward_HookItem_callback( id )
{
	if( g_player_hook[id] & HOOK_YES )
		return ITEM_DISABLED;
	else
		return ITEM_ENABLED;
	
	return ITEM_DISABLED;
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* Client Commands
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

public clcmd_HookOn( id )
{
	if( !is_user_alive( id ) )
	{
		return PLUGIN_HANDLED;
	}
	
	new hook = get_pcvar_num( cvar_hook );
	if( ( hook == 0 ) || ( ( hook == 1 ) && !q_kz_player_isVip( id ) ) )
	{
		q_kz_print( id, "%L", id, "QKZ_CMD_DISABLED" );
		
		return PLUGIN_HANDLED;
	}
	
	if( !g_player_hook[id] )
	{
		q_kz_print( id, "%L", id, "QKZ_HOOK_NOTAVAIL" );
		
		return PLUGIN_HANDLED;
	}
	
	q_kz_player_stopTimer( id, "%L", id, "QKZ_HOOK_TERMINATERUN" );
	
	g_player_hook_lastused[id] = get_gametime( );
	
	g_player_hook[id] |= HOOK_ACTIVE;
	fm_get_aim_origin( id, g_player_hook_origin[id] );
	
	message_te_hook( id, 0x1000 );
	
	set_task( 5.0, "task_HookBeam", id + TASKID_HOOKBEAM, _, _, "b" );
	
	return PLUGIN_HANDLED;
}

public clcmd_HookOff( id )
{
	g_player_hook[id] &= ~HOOK_ACTIVE;
	
	message_te_killbeam( id | 0x1000 );
	
	if( task_exists( id + TASKID_HOOKBEAM ) )
		remove_task( id + TASKID_HOOKBEAM );
	
	return PLUGIN_HANDLED;
}

public clcmd_Hook( id )
{
	menu_Hook( id );
	
	return PLUGIN_HANDLED;
}

public clcmd_GiveHook( id )
{
	if( !q_kz_player_isVip( id ) )
		return PLUGIN_CONTINUE;
	
	if( get_pcvar_num( cvar_hook ) != 2 )
		q_kz_print( id, "%L", id, "QKZ_HOOK_GIVEHOOK_CVAR" );
	else
		menu_GiveHook( id );
	
	return PLUGIN_HANDLED;
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* Menus
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

public menu_Hook( id )
{
	new title[26];
	formatex( title, charsmax(title), "QKZ %L", id, "QKZ_HOOK" );
	
	new menu = menu_create( title, "menu_Hook_handler" );
	
	new itemname[16];
	formatex( itemname, charsmax(itemname), "%L", id, "QKZ_HOOK_SPEED" );
	menu_additem( menu, itemname );
	
	formatex( itemname, charsmax(itemname), "%L", id, "QKZ_HOOK_COLOR" );
	menu_additem( menu, itemname );
	
	formatex( itemname, charsmax(itemname), "%L", id, "QKZ_EXIT" );
	menu_setprop( menu, MPROP_EXITNAME, itemname );
	
	menu_display( id, menu );
}

public menu_Hook_handler( id, menu, item )
{
	switch( item )
	{
		case 0:
		{
			menu_HookSpeed( id );
		}
		case 1:
		{
			menu_HookColor( id );
		}
	}
	
	menu_destroy( menu );
	
	return PLUGIN_HANDLED;
}

public menu_HookSpeed( id )
{
	new title[26];
	formatex( title, charsmax(title), "QKZ %L", id, "QKZ_HOOK_SPEED" );
	new menu = menu_create( title, "menu_HookSpeed_handler" );
	
	new itemname[16];
	formatex( itemname, charsmax(itemname), "%L", id, "QKZ_CUSTOM" );
	menu_additem( menu, itemname );
	menu_additem( menu, "500" );
	menu_additem( menu, "750" );
	menu_additem( menu, "1000" );
	menu_additem( menu, "1250" );
	menu_additem( menu, "1500" );
	
	formatex( itemname, charsmax(itemname), "%L", id, "QKZ_BACK" );
	menu_setprop( menu, MPROP_EXITNAME, itemname );
	
	menu_display( id, menu );
}

public menu_HookSpeed_handler( id, menu, item )
{
	switch( item )
	{
		case 0:
			client_cmd( id, "messagemode HookSpeed" );
		case 1:
			g_player_hook_speed[id] = 500.0;
		case 2:
			g_player_hook_speed[id] = 750.0;
		case 3:
			g_player_hook_speed[id] = 1000.0;
		case 4:
			g_player_hook_speed[id] = 1250.0;
		case 5:
			g_player_hook_speed[id] = 1500.0;
		case MENU_EXIT:
			menu_Hook( id );
	}
	
	menu_destroy( menu );
	
	return PLUGIN_HANDLED;
}

public menu_HookColor( id )
{
	new title[23];
	formatex( title, charsmax(title), "QKZ %L", id, "QKZ_HOOK_COLOR" );
	new menu = menu_create( title, "menu_HookColor_handler" );
	
	new itemname[16];
	formatex( itemname, charsmax(itemname), "%L", id, "QKZ_CUSTOM" );
	menu_additem( menu, itemname );
	
	formatex( itemname, charsmax(itemname), "%L", id, "QKZ_PINK" );
	menu_additem( menu, itemname );
	
	formatex( itemname, charsmax(itemname), "%L", id, "QKZ_YELLOW" );
	menu_additem( menu, itemname );
	
	formatex( itemname, charsmax(itemname), "%L", id, "QKZ_BACK" );
	menu_setprop( menu, MPROP_EXITNAME, itemname );
	
	menu_display( id, menu );
}

public menu_HookColor_handler( id, menu, item )
{
	switch( item )
	{
		case 0:
			client_cmd( id, "messagemode HookColor" );
		case 1:
			g_player_hook_color[id] = { 255, 0, 255 };
		case 2:
			g_player_hook_color[id] = { 255, 255, 0 };
		case MENU_EXIT:
			menu_Hook( id );
	}
	
	menu_destroy( menu );
	
	return PLUGIN_HANDLED;
}

public menu_GiveHook( id )
{
	new title[32];
	formatex( title, charsmax(title), "QKZ %L", id, "QKZ_HOOK_GIVEHOOK" );
	new menu = menu_create( title, "menu_GiveHook_handler" );
	
	new szPlayerName[32];
	new szItemBuffer[60];
	new szItemInfo[2];
	for( new i = 1; i <= 32; ++i )
	{
		if( is_user_connected( i ) && ( i != id ) )
		{
			get_user_name( i, szPlayerName, charsmax(szPlayerName) );
			formatex( szItemBuffer, charsmax(szItemBuffer), "%s%s",
				g_player_hook[i] & HOOK_YES ? "\w" : "\d",
				szPlayerName );
			szItemInfo[0] = i;
			szItemInfo[1] = 0;
			menu_additem( menu, szItemBuffer, szItemInfo );
		}
	}
	
	new itemname[16];
	formatex( itemname, charsmax(itemname), "%L", id, "QKZ_EXIT" );
	menu_setprop( menu, MPROP_EXITNAME, itemname );
	
	formatex( itemname, charsmax(itemname), "%L", id, "QKZ_BACK" );
	menu_setprop( menu, MPROP_BACKNAME, itemname );
	
	formatex( itemname, charsmax(itemname), "%L", id, "QKZ_NEXT" );
	menu_setprop( menu, MPROP_NEXTNAME, itemname );
	
	menu_display( id, menu );
}

public menu_GiveHook_handler( id, menu, item )
{
	if( item != MENU_EXIT )
	{
		new info[2], name[32];
		new access, callback;
		menu_item_getinfo( menu, item, access, info, 1, name, 31, callback );
		
		new id2 = info[0];
		g_player_hook[id2] = !g_player_hook[id2];
		
		new szPlayerName[32];
		get_user_name( id2, szPlayerName, charsmax(szPlayerName) );
		
		new message[80];
		formatex( message, charsmax(message), "%L", id2, g_player_hook[id2] ? "QKZ_HOOK_GIVEHOOK_TOGGLE_ON" : "QKZ_HOOK_GIVEHOOK_TOGGLE_OFF" );
		replace_all( message, charsmax(message), "^"name^"", szPlayerName );
		q_kz_print( id, message );
		
		menu_GiveHook( id );
	}
	
	menu_destroy( menu );

	return PLUGIN_HANDLED;
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* Messagemodes
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

public messagemode_HookSpeed( id )
{
	new szSpeed[8];
	
	read_args( szSpeed, charsmax(szSpeed) );
	remove_quotes( szSpeed );
	
	g_player_hook_speed[id] = str_to_float( szSpeed );
	
	menu_Hook( id );
	
	return PLUGIN_HANDLED;
}

public messagemode_HookColor( id )
{
	new szColor[15], szRed[4], szGreen[4], szBlue[4];
	
	read_args( szColor, charsmax(szColor) );
	remove_quotes( szColor );
	parse( szColor, szRed, 3, szGreen, 3, szBlue, 3 );
	
	g_player_hook_color[id][0] = str_to_num( szRed );
	g_player_hook_color[id][1] = str_to_num( szGreen );
	g_player_hook_color[id][2] = str_to_num( szBlue );
	
	menu_Hook( id );
	
	return PLUGIN_HANDLED;
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* Misc
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

fm_get_aim_origin( id, Float:origin[3] )
{
	new Float:start[3], Float:view_ofs[3];
	
	pev( id, pev_origin, start );
	pev( id, pev_view_ofs, view_ofs );
	xs_vec_add( start, view_ofs, start );

	new Float:dest[3];
	
	pev( id, pev_v_angle, dest );
	engfunc( EngFunc_MakeVectors, dest );
	global_get( glb_v_forward, dest );
	xs_vec_mul_scalar( dest, 9999.0, dest );
	xs_vec_add( start, dest, dest );

	engfunc( EngFunc_TraceLine, start, dest, IGNORE_MONSTERS, id, 0 );
	get_tr2( 0, TR_vecEndPos, origin );

	return 1;
}

public task_HookBeam( id )
{
	id -= TASKID_HOOKBEAM;
	
	message_te_hook( id, 0x1000 );
}

message_te_hook( id, attpoint = 0 )
{
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte( TE_BEAMENTPOINT );
	write_short( id | attpoint );					// entity ID
	write_coord( floatround(g_player_hook_origin[id][0]) );	// X Origin
	write_coord( floatround(g_player_hook_origin[id][1]) );	// Y Origin
	write_coord( floatround(g_player_hook_origin[id][2]) );	// Z Origin
	write_short( g_sprite_hook );				// sprite handle
	write_byte( 0 ); 					// starting frame
	write_byte( 0 ); 					// frame rate in 0.1s
	write_byte( 50 );					// life in 0.1s
	write_byte( 10 ); 					// line width in 0.1s
	write_byte( 0 ); 					// noise amplitude in 0.01s
	write_byte( g_player_hook_color[id][0] );		// red
	write_byte( g_player_hook_color[id][1] );		// green
	write_byte( g_player_hook_color[id][2] );		// blue
	write_byte( 200 );					// brigtness
	write_byte( 5 );					// scroll speed in 0.1s
	message_end( );
}

message_te_killbeam( id, attpoint = 0 )
{
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte( TE_KILLBEAM );
	write_short( id | attpoint );
	message_end( );
}
