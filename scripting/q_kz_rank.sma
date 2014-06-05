/**
 * to do:
 * - rank by unique steamid instead of name
 * - prefix redudant?
 */

#include <amxmodx>
#include <geoip>
#include <q_kz>

#pragma semicolon 1

#define PLUGIN  "Q::KZ::Rank"
#define VERSION "1.0"
#define AUTHOR  "Quaker"

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* Global Variables
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

new g_plugin_Prefix[32];

new g_dir_Rank[80];

new g_map_Name[32];

new g_player_Name[33][32];
new g_player_AuthID[33][40];
new g_player_IP[33][16];
new g_player_rank_ProPos[33];
new g_player_rank_NoobPos[33];
new Float:g_player_rank_ProTime[33];

new Float:g_player_rank_NoobTime[33];

new g_rank_pro_Top15[1500];
new g_rank_noob_Top15[1500];

new Array:g_rank_pro_Name;
new Trie:g_rank_pro_AuthID;
new Trie:g_rank_pro_IP;
new Trie:g_rank_pro_Time;
new Trie:g_rank_pro_Weapon;
new Trie:g_rank_pro_Date;

new Array:g_rank_noob_Name;
new Trie:g_rank_noob_AuthID;
new Trie:g_rank_noob_IP;
new Trie:g_rank_noob_CPs;
new Trie:g_rank_noob_TPs;
new Trie:g_rank_noob_Time;
new Trie:g_rank_noob_Weapon;
new Trie:g_rank_noob_Date;

new const g_sz_WeaponName[][] =
{
	"",
	"P228",
	"Shield",
	"Scout",
	"HE Grenade",
	"XM1014",
	"C4",
	"MAC-10",
	"AUG",
	"SG Grenade",
	"Dual Elites",
	"FiveSeven",
	"UMP45",
	"Kreig 550",
	"Galil",
	"Famas",
	"USP/Knife",
	"Glock",
	"AWP",
	"MP5 Navy",
	"Machine Gun",
	"M3 Shotgun",
	"M4A1",
	"TMP",
	"G3SG1",
	"Flashbang",
	"Desert Eagle",
	"Kreig 552",
	"AK47",
	"USP/Knife",
	"P90"
};

new const g_szPlural[][] = { "st", "nd", "rd", "th" };

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* Plugin Schtuff
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	
	register_menucmd( register_menuid( "\yQ KZ / Top 10" ), MENU_KEY_0 | MENU_KEY_1 | MENU_KEY_2, "menu_top10" );
	
	register_clcmd( "say /rank", "clcmd_Rank" );
	register_clcmd( "say /top15", "clcmd_Top10" );
	register_clcmd( "say /top10", "clcmd_Top10" );
	register_clcmd( "say /pro15", "clcmd_Pro10" );
	register_clcmd( "say /pro10", "clcmd_Pro10" );
	register_clcmd( "say /nub15", "clcmd_Noob10" );
	register_clcmd( "say /nub10", "clcmd_Noob10" );
	register_clcmd( "say /noob15", "clcmd_Noob10" );
	register_clcmd( "say /noob10", "clcmd_Noob10" );
	
	g_rank_pro_Name = ArrayCreate( 32, 1 );
	g_rank_pro_AuthID = TrieCreate( );
	g_rank_pro_IP = TrieCreate( );
	g_rank_pro_Time = TrieCreate( );
	g_rank_pro_Weapon = TrieCreate( );
	g_rank_pro_Date = TrieCreate( );
	
	g_rank_noob_Name = ArrayCreate( 32, 1 );
	g_rank_noob_AuthID = TrieCreate( );
	g_rank_noob_IP = TrieCreate( );
	g_rank_noob_Time = TrieCreate( );
	g_rank_noob_Weapon = TrieCreate( );
	g_rank_noob_CPs = TrieCreate( );
	g_rank_noob_TPs = TrieCreate( );
	g_rank_noob_Date = TrieCreate( );
	
	q_kz_registerForward( Q_KZ_TimerStop, "forward_KZTimerStop", true );
}

public plugin_cfg( )
{
	get_mapname( g_map_Name, charsmax(g_map_Name) );
	strtolower( g_map_Name );
	
	q_kz_getDataDirectory( g_dir_Rank, charsmax(g_dir_Rank) );
	add( g_dir_Rank, charsmax(g_dir_Rank), "/rank" );
	if( !dir_exists( g_dir_Rank ) )
		mkdir( g_dir_Rank );
	
	rank_load( );
	
	ArraySort( g_rank_pro_Name, "rank_sortPro" );
	ArraySort( g_rank_noob_Name, "rank_sortNoob" );
	
	rank_cacheProTop( );
	rank_cacheNoobTop( );
}

public plugin_end( )
{
	rank_save( );
	
	ArrayDestroy( g_rank_pro_Name );
	TrieDestroy( g_rank_pro_AuthID );
	TrieDestroy( g_rank_pro_IP );
	TrieDestroy( g_rank_pro_Time );
	TrieDestroy( g_rank_pro_Weapon );
	TrieDestroy( g_rank_pro_Date );
	
	ArrayDestroy( g_rank_noob_Name );
	TrieDestroy( g_rank_noob_AuthID );
	TrieDestroy( g_rank_noob_IP );
	TrieDestroy( g_rank_noob_CPs );
	TrieDestroy( g_rank_noob_TPs );
	TrieDestroy( g_rank_noob_Time );
	TrieDestroy( g_rank_noob_Weapon );
	TrieDestroy( g_rank_noob_Date );
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* Client Schtuff
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

public client_putinserver( id )
{
	// get user info
	get_user_name( id, g_player_Name[id], charsmax(g_player_Name[]) );
	get_user_authid( id, g_player_AuthID[id], charsmax(g_player_AuthID[]) );
	get_user_ip( id, g_player_IP[id], charsmax(g_player_IP[]), 1 );
	
	if( TrieKeyExists( g_rank_pro_Time, g_player_Name[id] ) )
	{
		g_player_rank_ProPos[id] = rank_position( id, g_rank_pro_Name );
		TrieGetCell( g_rank_pro_Time, g_player_Name[id], g_player_rank_ProTime[id] );
	}
	else
	{
		g_player_rank_ProTime[id] = 0.0;
	}
	
	if( TrieKeyExists( g_rank_noob_Time, g_player_Name[id] ) )
	{
		g_player_rank_NoobPos[id] = rank_position( id, g_rank_noob_Name );
		TrieGetCell( g_rank_noob_Time, g_player_Name[id], g_player_rank_NoobTime[id] );
	}
	else
	{
		g_player_rank_NoobTime[id] = 0.0;
	}
}

public client_infochanged( id )
{
	get_user_info( id, "name", g_player_Name[id], 31 );
	
	g_player_rank_ProPos[id] = rank_position( id, g_rank_pro_Name );
	g_player_rank_NoobPos[id] = rank_position( id, g_rank_noob_Name );
	TrieGetCell( g_rank_pro_Time, g_player_Name[id], g_player_rank_ProTime[id] );
	TrieGetCell( g_rank_noob_Time, g_player_Name[id], g_player_rank_NoobTime[id] );
}

public client_disconnect( id )
{
	g_player_rank_ProPos[id] = 0;
	g_player_rank_NoobPos[id] = 0;
	g_player_rank_ProTime[id] = 0.0;
	g_player_rank_NoobTime[id] = 0.0;
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* Forwards
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

public forward_KZTimerStop( id, successful )
{
	// need time, weapon, cps, tps
	if( !successful ) {
		return;
	}
	
	new Float:time = q_kz_player_getTimer( id );
	new cps = q_kz_player_getCheckpoints( id );
	new tps = q_kz_player_getTeleports( id );
	new weapon = get_user_weapon( id );
	
	if( tps ) {
		rank_updateNoob( id, time, weapon, cps, tps );
	}
	else {
		rank_updatePro( id, time, weapon );
	}
		
	return;
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* Rank
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

public rank_updateNoob( id, Float:rtime, weapon, cps, tps )
{
	q_kz_getPrefix( g_plugin_Prefix, charsmax(g_plugin_Prefix) );
	
	// if player had no record (time == 0.0 or pos == -1) or his record is slower than this one
	if( ( g_player_rank_NoobPos[id] == -1 ) || ( g_player_rank_NoobTime[id] > rtime ) )
	{
		// player had no record so insert him in the list
		if( g_player_rank_NoobPos[id] == -1 )
			ArrayPushString( g_rank_noob_Name, g_player_Name[id] );
		
		// save old data so that we can determine some stats
		new old = g_player_rank_NoobPos[id]; // new old, indeed
		new Float:oldtime = g_player_rank_NoobTime[id];
		
		// update the data
		TrieSetString( g_rank_noob_AuthID,	g_player_Name[id], g_player_AuthID[id] );
		TrieSetString( g_rank_noob_IP,		g_player_Name[id], g_player_IP[id] );
		TrieSetCell( g_rank_noob_Time,		g_player_Name[id], rtime );
		TrieSetCell( g_rank_noob_Weapon,	g_player_Name[id], weapon );
		TrieSetCell( g_rank_noob_CPs,		g_player_Name[id], cps );
		TrieSetCell( g_rank_noob_TPs,		g_player_Name[id], tps );
		TrieSetCell( g_rank_noob_Date,		g_player_Name[id], get_systime( ) );
		
		// sort the rank now that we have inserted our data
		ArraySort( g_rank_noob_Name, "rank_sortNoob" );
		
		// cache our new rank and player's new data
		rank_cacheNoobTop( );
		g_player_rank_NoobPos[id] = rank_position( id, g_rank_noob_Name );
		g_player_rank_NoobTime[id] = rtime;
		
		if( old == -1 ) 	// player's old position was -1 which means he never had a record so this is his first record
		{
			q_kz_saytext( 0, "!g[%s] !t%s !ngot into !gNOOB !nrank at !g%d%s !nplace",
				g_plugin_Prefix,
				g_player_Name[id],
				g_player_rank_NoobPos[id] + 1,
				g_szPlural[plural(g_player_rank_NoobPos[id] + 1)] );
			
			if( g_player_rank_NoobPos[id] == 0 )
				client_cmd( 0, "spk woop" );
		}
		else 		// player had a record and now he improved it
		{
			// if new and old position are equal it would be stupid
			// to write "someone improved from 2nd to 2nd place"
			// so we check that posibility and print different messages accordingly
			if( old == g_player_rank_NoobPos[id] )
			{
				q_kz_saytext( 0,	"!g[%s] !t%s!n improved his !gNOOB !nrecord by !g%.2f!n seconds and stayed on !g%d%s!n place",
					g_plugin_Prefix,
					g_player_Name[id],
					oldtime - rtime,
					g_player_rank_NoobPos[id] + 1,
					g_szPlural[plural(g_player_rank_NoobPos[id] + 1)] );
			}
			else
			{
				q_kz_saytext( 0, "!g[%s] !t%s!n improved his !gNOOB !nrecord from !g%d%s!n to !g%d%s!n place by !g%.2f seconds",
					g_plugin_Prefix,
					g_player_Name[id],
					old + 1,
					g_szPlural[plural(old + 1)],
					g_player_rank_NoobPos[id] + 1,
					g_szPlural[plural(g_player_rank_NoobPos[id] + 1)],
					oldtime - rtime );
			}
			
			if( g_player_rank_NoobPos[id] == 0 )
				client_cmd( 0, "spk woop" );
		}
	}
	else // player had a record but he failed to improve it
	{
		q_kz_saytext( 0, "!g[%s] !t%s!n failed to improve his !gNOOB !nrecord",
			g_plugin_Prefix,
			g_player_Name[id] );
	}
}

public rank_updatePro( id, Float:rtime, weapon )
{
	q_kz_getPrefix( g_plugin_Prefix, charsmax(g_plugin_Prefix) );
	
	// if player had no record (cached pos == -1) or hes record is slower than this one
	if( ( g_player_rank_ProPos[id] == -1 ) || ( g_player_rank_ProTime[id] > rtime ) )
	{
		// player had no record so insert him in the list
		if( g_player_rank_ProPos[id] == -1 )
			ArrayPushString( g_rank_pro_Name, g_player_Name[id] );
		
		// save old data so that we can determine some stats
		new old = g_player_rank_ProPos[id];
		new Float:oldtime = g_player_rank_ProTime[id];
		
		// update the data
		TrieSetString( g_rank_pro_AuthID,	g_player_Name[id], g_player_AuthID[id] );
		TrieSetString( g_rank_pro_IP,		g_player_Name[id], g_player_IP[id] );
		TrieSetCell( g_rank_pro_Time,		g_player_Name[id], rtime );
		TrieSetCell( g_rank_pro_Weapon,		g_player_Name[id], weapon );
		TrieSetCell( g_rank_pro_Date,		g_player_Name[id], get_systime( ) );
		
		// sort rank with our new data
		ArraySort( g_rank_pro_Name, "rank_sortPro" );
		
		// sort the rank now that we have inserted our data
		rank_cacheProTop( );
		g_player_rank_ProPos[id] = rank_position( id, g_rank_pro_Name );
		g_player_rank_ProTime[id] = rtime;
		
		if( old == -1 ) 	// player's old position was -1 which means he never had a record so this is his first record
		{
			q_kz_saytext( 0, "!g[%s] !t%s!n got into !gPRO !nrank at !g%d%s!n place",
				g_plugin_Prefix,
				g_player_Name[id],
				g_player_rank_ProPos[id] + 1,
				g_szPlural[plural(g_player_rank_ProPos[id] + 1)] );
			
			if( g_player_rank_ProPos[id] == 0 )
				client_cmd( 0, "spk woop" );
		}
		else 		// player had a record and now he improved it
		{
			// if new and old position are equal it would be stupid
			// to write "someone improved from 2nd to 2nd place"
			// so we check that posibility and print different messages accordingly
			if( old == g_player_rank_ProPos[id] )
			{
				q_kz_saytext( 0,	"!g[%s] !t%s!n improved his !gPRO !nrecord by !g%.2f!n seconds and stayed on !g%d%s!n place",
					g_plugin_Prefix,
					g_player_Name[id],
					oldtime - rtime,
					g_player_rank_ProPos[id] + 1,
					g_szPlural[plural(g_player_rank_ProPos[id] + 1)] );
			}
			else
			{
				q_kz_saytext( 0, "!g[%s] !t%s!n improved his !gPRO !nrecord from !g%d%s!n to !g%d%s!n place by !g%.2f",
					g_plugin_Prefix,
					g_player_Name[id],
					old + 1, g_szPlural[plural(old + 1)],
					g_player_rank_ProPos[id] + 1,
					g_szPlural[plural(g_player_rank_ProPos[id] + 1)],
					oldtime - rtime );
			}
			
			if( g_player_rank_ProPos[id] == 0 )
				client_cmd( 0, "spk woop" );
		}
	}
	else // player had a record but he failed to improve it
	{
		q_kz_saytext( 0, "!g[%s] !t%s!n failed to improve his !gPRO !nrecord",
			g_plugin_Prefix,
			g_player_Name[id] );
	}
}

rank_position( id, Array:list )
{
	static name[32];
	
	for( new i, size = ArraySize( list ); i < size; i++ )
	{
		ArrayGetString( list, i, name, 31 );
		
		if( equal( name, g_player_Name[id] ) )
			return i;
	}
	
	return -1;
}

public rank_sortPro( Array:rank_arr, p1, p2 )
{
	static szComp1[32], szComp2[32];
	
	ArrayGetString( rank_arr, p1, szComp1, 31 );
	ArrayGetString( rank_arr, p2, szComp2, 31 );
	
	static rtime1, rtime2;
	TrieGetCell( g_rank_pro_Time, szComp1, rtime1 );
	TrieGetCell( g_rank_pro_Time, szComp2, rtime2 );
	
	if( rtime1 < rtime2 )
		return -1;
	else if( rtime1 > rtime2 )
		return 1;
	
	return 0;
}

public rank_sortNoob( Array:rank_arr, p1, p2 )
{
	static szComp1[32], szComp2[32];
	ArrayGetString( rank_arr, p1, szComp1, 31 );
	ArrayGetString( rank_arr, p2, szComp2, 31 );
	
	static rtime1, rtime2;
	TrieGetCell( g_rank_noob_Time, szComp1, rtime1 );
	TrieGetCell( g_rank_noob_Time, szComp2, rtime2 );
	
	static tps1, tps2;
	TrieGetCell( g_rank_noob_TPs, szComp1, tps1 );
	TrieGetCell( g_rank_noob_TPs, szComp2, tps2 );
	
	static cps1, cps2;
	TrieGetCell( g_rank_noob_CPs, szComp1, cps1 );
	TrieGetCell( g_rank_noob_CPs, szComp2, cps2 );
	
	if( rtime1 < rtime2 )
		return -1;
	else if( rtime1 > rtime2 )
		return 1;
		
	if( tps1 < tps2 )
		return -1;
	else if( tps1 > tps2 )
		return 1;
		
	if( cps1 < cps2 )
		return -1;
	else if( cps1 > cps2 )
		return 1;
	
	return 0;
}

rank_cacheProTop( )
{
	new name[64];
	new Float:rtime;
	new minutes;
	new Float:seconds;
	new weapon;
	new szDate[30];
	new iDate;
	new ip[16];
	new country[3];
	
	new len = formatex( g_rank_pro_Top15, charsmax(g_rank_pro_Top15), "<body text=ffffff style=margin:3px;font-family:monospace bgcolor=000000><table width=100%% style=font-size:9pt><col align=center><col align=left><col align=center><col align=center><col align=center><tr bgcolor=222222 style=color:#fc0><td>#<td align=center>Jumper<td>Time<td>Weapon<td>Date" );
	
	new size = min( 10, ArraySize( g_rank_pro_Name ) );
	for( new i = 0; i < size; i++ )
	{
		ArrayGetString( g_rank_pro_Name, i, name, sizeof(name) );
		
		TrieGetCell( g_rank_pro_Time, name, rtime );
		TrieGetCell( g_rank_pro_Weapon, name, weapon );
		TrieGetCell( g_rank_pro_Date, name, iDate );
		TrieGetString( g_rank_pro_IP, name, ip, sizeof(ip) );
		
		geoip_code2_ex( ip, country );
		if( !country[0] )
		{
			country = "--";
		}
		
		minutes = floatround( rtime / 60.0, floatround_floor );
		seconds = rtime - (minutes * 60);
		
		format_time( szDate, charsmax(szDate), "%d/%m/%y", iDate );
		
		replace_all( name, charsmax(name), "<", "&lt;" );
		replace_all( name, charsmax(name), ">", "&gt;" );
		len += formatex( g_rank_pro_Top15[len],
				 charsmax(g_rank_pro_Top15) - len,
				 "<tr bgcolor=%s><td>%d<td>[%s]%s<td>%02d:%s%.2f<td>%s<td>%s",
				 i % 2 ? "111111" : "000000",
				 i+1,
				 country,
				 name,
				 minutes,
				 seconds < 10 ? "0" : "",
				 seconds,
				 g_sz_WeaponName[weapon],
				 szDate );
	}
	
	for( new i = size; i < 10; ++i )
	{
		len += formatex( g_rank_pro_Top15[len],
				 charsmax(g_rank_pro_Top15) - len,
				 "<tr bgcolor=%s><td>%d<td><td><td><td>",
				 i % 2 ? "111111" : "000000",
				 i + 1 );
	}
}

rank_cacheNoobTop( )
{
	new len;
	
	new country[3];
	new name[64];
	new Float:rtime;
	new minutes;
	new Float:seconds;
	new cps;
	new tps;
	new weapon;
	new ip[16];
	new szDate[30];
	new iDate;
	
	len = formatex( g_rank_noob_Top15, charsmax(g_rank_noob_Top15), "<body text=ffffff style=margin:3px;font-family:monospace; bgcolor=000000><table width=100%% style=font-size:9pt><col align=center><col align=left><col align=center><col align=center><col align=center><col align=center><col align=center><tr style=color:#fc0 bgcolor=222222><td>#<td align=center>Jumper<td>CPs<td>TPs<td>Time<td>Weapon<td>Date" );
	
	new size = min( 10, ArraySize( g_rank_noob_Name ) );
	for( new i = 0; i < size; ++i )
	{
		ArrayGetString( g_rank_noob_Name, i, name, 31 );
		
		TrieGetCell( g_rank_noob_Time, name, rtime );
		TrieGetCell( g_rank_noob_CPs, name, cps );
		TrieGetCell( g_rank_noob_TPs, name, tps );
		TrieGetCell( g_rank_noob_Weapon, name, weapon );
		TrieGetCell( g_rank_noob_Date, name, iDate );
		TrieGetString( g_rank_noob_IP, name, ip, sizeof(ip) );
		
		geoip_code2_ex( ip, country );
		if( !country[0] )
		{
			country = "--";
		}
		
		minutes = floatround( rtime / 60.0, floatround_floor );
		seconds = rtime - (minutes * 60);
		
		format_time( szDate, charsmax(szDate), "%d/%m/%y", iDate );
		
		replace_all( name, charsmax(name), "<", "&lt;" );
		replace_all( name, charsmax(name), ">", "&gt;" );
		len += formatex( g_rank_noob_Top15[len],
				 charsmax(g_rank_noob_Top15) - len,
				 "<tr bgcolor=%s><td>%d<td>[%s]%22s<td>%d<td>%d<td>%02d:%s%.2f<td>%s<td>%s",
				 i % 2 ? "111111" : "000000",
				 i+1,
				 country,
				 name,
				 cps,
				 tps,
				 minutes,
				 seconds < 10 ? "0" : "",
				 seconds,
				 g_sz_WeaponName[weapon],
				 szDate );
	}
	
	for( new i = size; i < 10; ++i )
	{
		len += formatex( g_rank_noob_Top15[len],
				 charsmax(g_rank_noob_Top15) - len,
				 "<tr bgcolor=%s><td>%d<td><td><td><td><td><td>",
				 i % 2 ? "111111" : "000000",
				 i + 1 );
	}
}

rank_load( )
{
	new hFile;
	new szFile[128];
	new iSize;
	
	new szName[32];
	new szAuthID[40];
	new szIP[16];
	new flTime;
	new iWeapon;
	new iCPs;
	new iTPs;
	new iDate;
	
	formatex( szFile, charsmax(szFile), "%s/%s_pro.dat", g_dir_Rank, g_map_Name );
	hFile = fopen( szFile, "rb" );
	if( hFile )
	{
		fseek( hFile, 28, SEEK_SET );
		fread( hFile, iSize, BLOCK_INT );
		
		for( new i = 0; i < iSize; ++i )
		{
			fread_blocks( hFile, szName, 32, BLOCK_BYTE );
			fread_blocks( hFile, szAuthID, 40, BLOCK_BYTE );
			fread_blocks( hFile, szIP, 16, BLOCK_BYTE );
			fread( hFile, flTime, BLOCK_INT );
			fread( hFile, iWeapon, BLOCK_BYTE );
			fread( hFile, iDate, BLOCK_INT );
			
			ArrayPushString( g_rank_pro_Name, szName );
			TrieSetString( g_rank_pro_AuthID, szName, szAuthID );
			TrieSetString( g_rank_pro_IP, szName, szIP );
			TrieSetCell( g_rank_pro_Time, szName, flTime );
			TrieSetCell( g_rank_pro_Weapon, szName, iWeapon );
			TrieSetCell( g_rank_pro_Date, szName, iDate );
		}
		
		fclose( hFile );
	}
	
	formatex( szFile, charsmax(szFile), "%s/%s_noob.dat", g_dir_Rank, g_map_Name );
	hFile = fopen( szFile, "rb" );
	if( hFile )
	{
		fseek( hFile, 28, SEEK_SET );
		fread( hFile, iSize, BLOCK_INT );
		
		for( new i = 0; i < iSize; ++i )
		{
			fread_blocks( hFile, szName, 32, BLOCK_BYTE );
			fread_blocks( hFile, szAuthID, 40, BLOCK_BYTE );
			fread_blocks( hFile, szIP, 16, BLOCK_BYTE );
			fread( hFile, flTime, BLOCK_INT );
			fread( hFile, iWeapon, BLOCK_BYTE );
			fread( hFile, iCPs, BLOCK_SHORT );
			fread( hFile, iTPs, BLOCK_SHORT );
			fread( hFile, iDate, BLOCK_INT );
			
			ArrayPushString( g_rank_noob_Name, szName );
			TrieSetString( g_rank_noob_AuthID, szName, szAuthID );
			TrieSetString( g_rank_noob_IP, szName, szIP );
			TrieSetCell( g_rank_noob_CPs, szName, iCPs );
			TrieSetCell( g_rank_noob_TPs, szName, iTPs );
			TrieSetCell( g_rank_noob_Time, szName, flTime );
			TrieSetCell( g_rank_noob_Weapon, szName, iWeapon );
			TrieSetCell( g_rank_noob_Date, szName, iDate );
		}
		
		fclose( hFile );
	}
}

rank_save( )
{
	static const szFileType[16] = "QKZ Rank File";
	static const szRankPro[12] = "PRO";
	static const szRankNoob[12] = "NOOB";
	
	new hFile;
	new szFile[128];
	new iSize;
	
	new szName[32];
	new szAuthID[40];
	new szIP[40];
	new flTime;
	new iWeapon;
	new iCPs;
	new iTPs;
	new iDate;
	
	formatex( szFile, charsmax(szFile), "%s/%s_pro.dat", g_dir_Rank, g_map_Name );
	hFile = fopen( szFile, "wb" );
	if( hFile )
	{
		iSize = ArraySize( g_rank_pro_Name );
		
		fwrite_blocks( hFile, szFileType, 16, BLOCK_BYTE );
		fwrite_blocks( hFile, szRankPro, 12, BLOCK_BYTE );
		fwrite( hFile, iSize, BLOCK_INT );
		
		for( new i = 0; i < iSize; ++i )
		{
			ArrayGetString( g_rank_pro_Name, i, szName, charsmax(szName) );
			TrieGetString( g_rank_pro_AuthID, szName, szAuthID, charsmax(szAuthID) );
			TrieGetString( g_rank_pro_IP, szName, szIP, charsmax(szIP) );
			TrieGetCell( g_rank_pro_Time, szName, flTime );
			TrieGetCell( g_rank_pro_Weapon, szName, iWeapon );
			TrieGetCell( g_rank_pro_Date, szName, iDate );
			
			fwrite_blocks( hFile, szName, 32, BLOCK_BYTE );
			fwrite_blocks( hFile, szAuthID, 40, BLOCK_BYTE );
			fwrite_blocks( hFile, szIP, 16, BLOCK_BYTE );
			fwrite( hFile, flTime, BLOCK_INT );
			fwrite( hFile, iWeapon, BLOCK_BYTE );
			fwrite( hFile, iDate, BLOCK_INT );
		}
		
		fclose( hFile );
	}
	
	formatex( szFile, charsmax(szFile), "%s/%s_noob.dat", g_dir_Rank, g_map_Name );
	hFile = fopen( szFile, "wb" );
	if( hFile )
	{
		iSize = ArraySize( g_rank_noob_Name );
		
		fwrite_blocks( hFile, szFileType, 16, BLOCK_BYTE );
		fwrite_blocks( hFile, szRankNoob, 12, BLOCK_BYTE );
		fwrite( hFile, iSize, BLOCK_INT );
		
		for( new i = 0; i < iSize; ++i )
		{
			ArrayGetString( g_rank_noob_Name, i, szName, charsmax(szName) );
			TrieGetString( g_rank_noob_AuthID, szName, szAuthID, charsmax(szAuthID) );
			TrieGetString( g_rank_noob_IP, szName, szIP, charsmax(szIP) );
			TrieGetCell( g_rank_noob_Time, szName, flTime );
			TrieGetCell( g_rank_noob_Weapon, szName, iWeapon );
			TrieGetCell( g_rank_noob_CPs, szName, iCPs );
			TrieGetCell( g_rank_noob_TPs, szName, iTPs );
			TrieGetCell( g_rank_noob_Date, szName, iDate );
			
			fwrite_blocks( hFile, szName, 32, BLOCK_BYTE );
			fwrite_blocks( hFile, szAuthID, 40, BLOCK_BYTE );
			fwrite_blocks( hFile, szIP, 16, BLOCK_BYTE );
			fwrite( hFile, flTime, BLOCK_INT );
			fwrite( hFile, iWeapon, BLOCK_BYTE );
			fwrite( hFile, iCPs, BLOCK_SHORT );
			fwrite( hFile, iTPs, BLOCK_SHORT );
			fwrite( hFile, iDate, BLOCK_INT );
		}
		
		fclose( hFile );
	}
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* Client Commands
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

public clcmd_Top10( id, level, cid )
{
	show_menu( id, MENU_KEY_0 | MENU_KEY_1 | MENU_KEY_2, "\yQ KZ / Top 10^n^n\r1. \wPro^n\r2. \wNoob^n^n^n^n^n^n^n\r0. \yExit" );
	
	return PLUGIN_HANDLED;
}

public menu_top10( id, item )
{
	switch( item )
	{
		case 0:
		{
			clcmd_Pro10( id, 0, 0 );
		}
		case 1:
		{
			clcmd_Noob10( id, 0, 0 );
		}
	}
}

public clcmd_Pro10( id, level, cid )
{
	show_motd( id, g_rank_pro_Top15 );
	
	return PLUGIN_HANDLED;
}

public clcmd_Noob10( id, level, cid )
{
	show_motd( id, g_rank_noob_Top15 );
	
	return PLUGIN_HANDLED;
}

public clcmd_Rank( id, level, cid )
{	
	q_kz_getPrefix( g_plugin_Prefix, charsmax(g_plugin_Prefix) );
	
	new iWeapon;
	new Float:flTime, minutes, Float:seconds;
	new iDate, szDate[30];
	
	if( !TrieKeyExists( g_rank_pro_Time, g_player_Name[id] ) )
	{
		q_kz_saytext( id, "[%s] You have no PRO records on this map", g_plugin_Prefix );
	}
	else
	{
		TrieGetCell( g_rank_pro_Time, g_player_Name[id], flTime );	
		minutes = floatround( flTime / 60, floatround_floor );
		seconds = flTime - ( minutes * 60 );
		
		TrieGetCell( g_rank_pro_Weapon, g_player_Name[id], iWeapon );
		
		TrieGetCell( g_rank_pro_Date, g_player_Name[id], iDate );
		format_time( szDate, charsmax(szDate), "%d/%m/%Y", iDate );
		
		q_kz_saytext( id, "[%s] You're %d%s in PRO rank finished in %02d:%s%.2f with %s on the date %s",
			g_plugin_Prefix,
			g_player_rank_ProPos[id] + 1,
			g_szPlural[plural( g_player_rank_ProPos[id] + 1 )],
			minutes,
			seconds < 10 ? "0" : "",
			seconds,
			g_sz_WeaponName[iWeapon],
			szDate );
	}
	
	if( !TrieKeyExists( g_rank_noob_Time, g_player_Name[id] )) 
	{
		q_kz_saytext( id, "[%s] You have no NOOB records on this map", g_plugin_Prefix );
	}
	else
	{
		TrieGetCell( g_rank_noob_Time, g_player_Name[id], flTime );	
		minutes = floatround( flTime / 60, floatround_floor );
		seconds = flTime - ( minutes * 60 );
		
		TrieGetCell( g_rank_noob_Weapon, g_player_Name[id], iWeapon );
		
		TrieGetCell( g_rank_noob_Date, g_player_Name[id], iDate );
		format_time( szDate, charsmax(szDate), "%d/%m/%Y", iDate );
		
		q_kz_saytext( id, "[%s] You're %d%s in NOOB rank finished in %02d:%s%.2f with %s on the date %s",
			g_plugin_Prefix,
			g_player_rank_NoobPos[id] + 1,
			g_szPlural[plural( g_player_rank_NoobPos[id] + 1 )],
			minutes,
			seconds < 10 ? "0" : "",
			seconds,
			g_sz_WeaponName[iWeapon],
			szDate );
	}
	
	return PLUGIN_HANDLED;
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* Misc
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

plural( num )
{
	switch( num )
	{
		case 11, 12, 13: return 3;
		default:
		{
			new temp;
			temp = num % 10;
			switch( temp )
			{
				case 1: return 0;
				case 2: return 1;
				case 3: return 2;
				default: return 3;
			}
		}
	}
	
	return 3;
}
