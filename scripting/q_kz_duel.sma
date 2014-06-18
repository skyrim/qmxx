#include <amxmodx>
#include <fakemeta>

#include <q>
#include <q_menu>
#include <q_kz>

#pragma semicolon 1

#define PLUGIN "Q::KZ::Duel"
#define VERSION "0.9 alpha"
#define AUTHOR "Quaker"

#define MAX_DUELS 16

#define DUEL_CONSIDERING_TIME 10.0

#define TASKID_DUEL_TIMEOUT 489234

//#define DEBUG

enum Q_KZ_DuelStatus
{
	Q_KZ_DS_INVALID = 0,
	Q_KZ_DS_CONSIDERING = 1,
	Q_KZ_DS_PREPARING = 2,
	Q_KZ_DS_INPROGRESS = 3
};

new Q_KZ_DuelStatus:g_duel_status[MAX_DUELS];
new g_duel_players[MAX_DUELS][2];
new g_duel_countdown[MAX_DUELS];

new g_player_duel[33];

new mfwd_duel_start;
new mfwd_duel_end;

new QMenu:g_menu;

new g_player_menuPosition[33];

public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	
	register_clcmd( "/duel", "clcmd_duel" );
	register_clcmd( "/kzduel", "clcmd_duel" );
	register_clcmd( "say /duel", "clcmd_duel" );
	register_clcmd( "say /kzduel", "clcmd_duel" );
	
	register_clcmd( "say /accept", "clcmd_accept" );
	register_clcmd( "say /reject", "clcmd_reject" );
	register_clcmd( "say /surrender", "clcmd_surrender" );
	
	mfwd_duel_start = CreateMultiForward( "q_kz_duel_start", ET_IGNORE, FP_CELL, FP_CELL );
	mfwd_duel_end = CreateMultiForward( "q_kz_duel_end", ET_IGNORE, FP_CELL, FP_CELL );
	
	q_kz_registerForward( Q_KZ_TimerStop, "forward_KZTimerStop", true );
	
	g_menu = q_menu_create("Q KZ Duel", "menu_duel_handler");
	
	for(new i = 0; i < sizeof(g_player_menuPosition); ++i) {
		g_player_menuPosition[i] = -1;
	}
}

public client_connect( id )
{
	g_player_duel[id] = -1;
	
	new name[32];
	get_user_name(id, name, charsmax(name));
	g_player_menuPosition[id] = q_menu_item_count(g_menu);
	q_menu_item_add(g_menu, name);
}

public client_disconnect( id )
{
	new duel_id = get_player_duel( id );
	
	if( is_duel_valid( duel_id ) )
	{
		if( g_duel_status[duel_id] == Q_KZ_DS_CONSIDERING )
		{
			if( g_duel_players[duel_id][0] == id )
			{
				duel_reset( duel_id );
			}
			else
			{
				duel_rejected( id );
			}
		}
		else
		{
			duel_disconnect( id );
		}
	}
	
	q_menu_item_remove(g_menu, g_player_menuPosition[id]);
	for(new i = 1, size = get_maxplayers(); i <= size; ++i) {
		if(g_player_menuPosition[i] > g_player_menuPosition[id]) {
			g_player_menuPosition[i]--;
		}
	}
	g_player_menuPosition[id] = -1;
}

public menu_duel(id) {
	q_menu_item_set_enabled(g_menu, g_player_menuPosition[id], false);
	
	q_menu_display(id, g_menu);
	
	q_menu_item_set_enabled(g_menu, g_player_menuPosition[id], true);
}

public menu_duel_handler(id, menu, item) {
	new opponentPicked;
	for(new i = 1, size = get_maxplayers(); i < size; ++i) {
		if(g_player_menuPosition[i] == item) {
			opponentPicked = i;
		}
	}
	
	challenge(id, opponentPicked);
	
	return PLUGIN_HANDLED;
}

challenge(id, opponent) {
	if(g_player_duel[id] > -1) {
		if(g_duel_status[g_player_duel[id]] == Q_KZ_DS_CONSIDERING) {
			client_print(id, print_chat, "You already challenged someone to duel. Wait for response.");
			return PLUGIN_HANDLED;
		}
		else {
			client_print(id, print_chat, "You already dueling. Finish the duel or surrender, then try again.");
			return PLUGIN_HANDLED;
		}
	}
	
	if(!is_user_connected(opponent)) {
		client_print(id, print_chat, "You must aim at someone you want to duel.");
		return PLUGIN_HANDLED;
	}
	
	if(g_player_duel[opponent] > -1) {
		client_print(id, print_chat, "He is already in a duel.");
		return PLUGIN_HANDLED;
	}
	
	if(!q_kz_isStartOriginFound()) {
		client_print(id, print_chat, "Start button not found. Find and press the start button, then try duel again.");
		return PLUGIN_HANDLED;
	}
		
	duel_create(id, opponent);
	
	new name[32];
	get_user_name(id, name, charsmax(name));
	client_print(opponent, print_chat, "%s challenges you in a duel. Say /accept, /reject or ignore this message.", name);
	
	if(is_user_bot(opponent)) {
#if defined DEBUG
		set_task(2.0, "wtf", opponent);
#else
		client_print(id, print_chat, "You cannot challenge a bot.");
#endif
	}

	return PLUGIN_HANDLED;
}

#if defined DEBUG
public wtf( id )
{
	if( is_user_connected( id ) )
		clcmd_accept( id, 0, 0 );
}
#endif

public clcmd_duel( id, level, cid )
{
	menu_duel(id);
	
	return PLUGIN_HANDLED;
}

public clcmd_accept( id, level, cid )
{
	if( !is_duel_valid( get_player_duel( id ) ) )
	{
		client_print( id, print_chat, "You have not been challenged to duel." );
		return PLUGIN_HANDLED;
	}
	
	duel_accepted( id );
	
	return PLUGIN_HANDLED;
}

public clcmd_reject( id, level, cid )
{
	if( !is_duel_valid( get_player_duel( id ) ) )
	{
		client_print( id, print_chat, "You have not been challenged to duel." );
		return PLUGIN_HANDLED;
	}
	
	duel_rejected( id );
	
	return PLUGIN_HANDLED;
}

public clcmd_surrender( id, level, cid )
{
	new duel_id = get_player_duel( id );
	
	if( !is_duel_valid( duel_id ) )
	{
		client_print( id, print_chat, "You are not in a duel." );
		return PLUGIN_HANDLED;
	}
	
	if( g_duel_status[duel_id] == Q_KZ_DS_PREPARING )
	{
		client_print( id, print_chat, "You cannot surrender before the duel starts." );
		return PLUGIN_HANDLED;
	}
	
	duel_surrender( id );
	
	return PLUGIN_HANDLED;
}

public forward_KZTimerStop( id, successful ) {
	new duel_id = get_player_duel( id );
	
	if( is_duel_valid( duel_id ) && ( g_duel_status[duel_id] == Q_KZ_DS_INPROGRESS ) )
	{
		duel_end( duel_id, successful ? id : duel_opponent( id ) );
	}
}

// duel core stuff

duel_opponent( id ) {
	if( g_player_duel[id] != 2 && g_player_duel[id] != 3 ) {
		return 0;
	}
	
	new duel_id = get_player_duel( id );
	if( g_duel_players[duel_id][0] == id ) {
		return g_duel_players[duel_id][1];
	}
	else {
		return g_duel_players[duel_id][0];
	}
	
	return 0;
}

duel_create( challenger, challenged )
{
	for( new i = 0; i < MAX_DUELS; ++i )
	{
		if( g_duel_status[i] == Q_KZ_DS_INVALID )
		{
			g_duel_status[i] = Q_KZ_DS_CONSIDERING;
			g_duel_players[i][0] = challenger;
			g_duel_players[i][1] = challenged;
			
			g_player_duel[challenger] = i;
			g_player_duel[challenged] = i;
			
			set_task( DUEL_CONSIDERING_TIME, "duel_timeout", i + TASKID_DUEL_TIMEOUT );
			
			return i;
		}
	}
	
	return -1;
}

public duel_timeout( id )
{
	new duel_id = id - TASKID_DUEL_TIMEOUT;
	
	if( g_duel_status[duel_id] == Q_KZ_DS_CONSIDERING )
	{
		client_print( g_duel_players[duel_id][0], print_chat, "He did not respond to the challenge." );
		
		duel_reset( duel_id );
	}
}


duel_accepted( id )
{
	new duel_id = get_player_duel( id );
	
	client_print( id, print_chat, "You accepted the duel." );
	client_print( g_duel_players[duel_id][0], print_chat, "He accepted the duel." );
	
	duel_start( duel_id );
}

duel_rejected( id )
{
	new duel_id = get_player_duel( id );
	
	client_print( id, print_chat, "You rejected the duel." );
	client_print( g_duel_players[duel_id][0], print_chat, "He rejected the duel." );
	
	duel_reset( duel_id );
}

duel_start( duel_id )
{
	g_duel_status[duel_id] = Q_KZ_DS_PREPARING;
	
	new Float:origin[3];
	q_kz_getStartOrigin( origin );
	
	set_pev( g_duel_players[duel_id][0], pev_origin, origin );
	set_pev( g_duel_players[duel_id][0], pev_flags, pev( g_duel_players[duel_id][0], pev_flags ) | FL_FROZEN );
	
	set_pev( g_duel_players[duel_id][1], pev_origin, origin );
	set_pev( g_duel_players[duel_id][1], pev_flags, pev( g_duel_players[duel_id][1], pev_flags ) | FL_FROZEN );
	
	g_duel_countdown[duel_id] = 5;
	set_task( 1.0, "duel_countdown", duel_id );
	
	new ret;
	ExecuteForward( mfwd_duel_start, ret, g_duel_players[duel_id][0], g_duel_players[duel_id][1] );
}

public duel_countdown( duel_id )
{
	if( g_duel_countdown[duel_id] )
	{
		set_task( 1.0, "duel_countdown", duel_id );
		
		client_print( g_duel_players[duel_id][0], print_chat, "Duel starts in %d.", g_duel_countdown[duel_id] );
		client_print( g_duel_players[duel_id][1], print_chat, "Duel starts in %d.", g_duel_countdown[duel_id] );
	}
	else
	{
		g_duel_status[duel_id] = Q_KZ_DS_INPROGRESS;
		
		set_pev( g_duel_players[duel_id][0], pev_flags, pev( g_duel_players[duel_id][0], pev_flags ) & ~FL_FROZEN );
		set_pev( g_duel_players[duel_id][1], pev_flags, pev( g_duel_players[duel_id][1], pev_flags ) & ~FL_FROZEN );
		
		client_print( g_duel_players[duel_id][0], print_chat, "Go, go, go!", g_duel_countdown[duel_id] );
		client_print( g_duel_players[duel_id][1], print_chat, "Go, go, go!", g_duel_countdown[duel_id] );
	}
	
	--g_duel_countdown[duel_id];
}

duel_end( duel_id, winner )
{
	new winner_name[32];
	get_user_name( winner, winner_name, charsmax(winner_name) );
	
	new loser = ( g_duel_players[duel_id][0] == winner ) ? g_duel_players[duel_id][1] : g_duel_players[duel_id][0];
	new loser_name[32];
	get_user_name( loser, loser_name, charsmax(loser_name) );
	
	client_print( 0, print_chat, "%s beat %s in a duel.", winner_name, loser_name );
	
	new ret;
	ExecuteForward( mfwd_duel_end, ret, winner, loser );
	
	duel_reset( duel_id );
}

duel_surrender( id )
{
	new duel_id = get_player_duel( id );
	
	new winner = ( g_duel_players[duel_id][0] == id ) ? g_duel_players[duel_id][1] : g_duel_players[duel_id][0];
	new winner_name[32];
	get_user_name( winner, winner_name, charsmax(winner_name) );
	
	new loser_name[32];
	get_user_name( id, loser_name, charsmax(loser_name) );
	
	client_print( 0, print_chat, "%s surrendered the duel to %s.", loser_name, winner_name );
	
	duel_reset( duel_id );
}

duel_disconnect( id )
{
	new duel_id = get_player_duel( id );
	
	new winner = ( g_duel_players[duel_id][0] == id ) ? g_duel_players[duel_id][1] : g_duel_players[duel_id][0];
	new winner_name[32];
	get_user_name( winner, winner_name, charsmax(winner_name) );
	
	new loser_name[32];
	get_user_name( id, loser_name, charsmax(loser_name) );
	
	client_print( 0, print_chat, "%s disconnected. %s won the duel.", loser_name, winner_name );
	
	duel_reset( duel_id );
}

duel_reset( duel_id )
{
	g_duel_status[duel_id] = Q_KZ_DS_INVALID;
	g_player_duel[g_duel_players[duel_id][0]] = -1;
	g_player_duel[g_duel_players[duel_id][1]] = -1;
	g_duel_players[duel_id][0] = 0;
	g_duel_players[duel_id][1] = 0;
}

is_duel_valid( duel_id )
{
	if( duel_id >= 0 && duel_id < 16 && g_duel_status[duel_id] != Q_KZ_DS_INVALID )
		return true;
	
	return  false;
}

get_player_duel( id )
{
	return g_player_duel[id];
}
