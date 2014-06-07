#include <amxmodx>
#include <fakemeta>
#include <geoip>

#include <q>

#pragma semicolon 1

#define PLUGIN "Q::Chat"
#define VERSION "1.0"
#define AUTHOR "Quaker"

#define EXTRA_OFFSET 5

#if cellbits == 32
	#define OFFSET_TEAM 114
#else
	#define OFFSET_TEAM 139
#endif

new cvar_allchat;
new cvar_teamchat;
new cvar_countrytag;
new cvar_deadtag;
new cvar_teamtag;

new g_player_countrycode2[33][3];

new const g_teamname[4][] =
{
	"Unassigned",
	"Terrorist",
	"Counter-Terrorist",
	"Spectator"
};

public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	
	cvar_allchat = register_cvar( "q_chat_allchat", "0" );
	cvar_teamchat = register_cvar( "q_chat_teamchat", "1" );
	cvar_countrytag = register_cvar( "q_chat_countrytag", "0" );
	cvar_deadtag = register_cvar( "q_chat_deadtag", "1" );
	cvar_teamtag = register_cvar( "q_chat_teamtag", "1" );
}

public plugin_cfg( )
{
	register_clcmd( "say", "clcmd_say" );
	register_clcmd( "say_team", "clcmd_say" );
	
	q_registerCvar(cvar_allchat, "0", "Toggle allchat.");
	q_registerCvar(cvar_teamchat, "1", "Toggle teamchat. Turning off teamchat will make all messages as allchat.");
	q_registerCvar(cvar_countrytag, "0", "Toggle country tag in chat next to player name.");
	q_registerCvar(cvar_deadtag, "1", "Toggle dead tag.");
	q_registerCvar(cvar_teamtag, "1", "Toggle team tag.");
}

public client_putinserver( id )
{
	new ip[16];
	get_user_ip( id, ip, charsmax(ip), true );
	geoip_code2_ex( ip, g_player_countrycode2[id] );
	if( !g_player_countrycode2[id][0] )
	{
		g_player_countrycode2[id] = "--";
	}
}

public clcmd_say( id, level, cid )
{
	static message_mode[9];
	static message_in[192];
	static message_out[192];
	new message_len;
	
	read_args( message_in, charsmax(message_in) );
	remove_quotes( message_in );
	trim( message_in );
	
	if( !message_in[0] )
	{
		return PLUGIN_HANDLED;
	}
	
	if( get_pcvar_num( cvar_countrytag ) )
	{
		message_len = formatex( message_out, charsmax(message_out), "!g[%s]!n ", g_player_countrycode2[id] );
	}
	
	new player_alive = is_user_alive( id );
	if( !player_alive && get_pcvar_num( cvar_deadtag ) )
	{
		if( q_get_user_team( id ) == 3 )
		{
			message_len += formatex( message_out[message_len], charsmax(message_out) - message_len, "*SPEC* " );
		}
		else
		{
			message_len += formatex( message_out[message_len], charsmax(message_out) - message_len, "*DEAD* " );
		}
	}
	
	new player_team;
	read_argv( 0, message_mode, charsmax(message_mode) );
	new team_message = ( message_mode[3] == '_' ); // say_team
	if( team_message && get_pcvar_num( cvar_teamchat ) && get_pcvar_num( cvar_teamtag ) )
	{
		player_team = q_get_user_team( id );
		message_len += formatex( message_out[message_len], charsmax(message_out) - message_len, "(%s) ", g_teamname[player_team] );
	}
	
	static player_name[32];
	get_user_name( id, player_name, charsmax(player_name) );
	
	message_len += formatex( message_out[message_len], charsmax(message_out) - message_len, "!t%s!n :  %s", player_name, message_in );
	
	if( get_pcvar_num( cvar_allchat ) )
	{
		if( team_message && get_pcvar_num( cvar_teamchat ) )
		{
			for( new i = 1; i <= 32; ++i )
			{
				if( is_user_connected( i ) && ( player_team == q_get_user_team( i ) ) )
				{
					message_SayText( i, message_out );
				}
			}
		}
		else
		{
			message_SayText( 0, message_out );
		}
	}
	else
	{
		if( team_message && get_pcvar_num( cvar_teamchat ) )
		{
			for( new i = 1; i <= 32; ++i )
			{
				if( is_user_connected( i ) && ( player_team == get_user_team( i ) ) && ( player_alive == is_user_alive( i ) ) )
				{
					message_SayText( i, message_out );
				}
			}
		}
		else
		{
			for( new i = 1; i <= 32; ++i )
			{
				if( is_user_connected( i ) && ( player_alive == is_user_alive( i ) ) )
				{
					message_SayText( i, message_out );
				}
			}
		}
	}
	
	return PLUGIN_HANDLED;
}

stock message_SayText( id, const message[], any:... )
{
	static msgid;
	if( !msgid )
	{
		msgid = get_user_msgid( "SayText" );
	}
	
	static buffer[192];
	buffer = "^x01";
	vformat( buffer[1], charsmax(buffer) - 1, message, 3 );
	
	replace_all( buffer, charsmax(buffer), "!n", "^x01" );
	replace_all( buffer, charsmax(buffer), "!t", "^x03" );
	replace_all( buffer, charsmax(buffer), "!g", "^x04" );
	
	if( id == 0 )
	{
		for( new i = 1; i <= 32; ++i )
		{
			if( is_user_connected( i ) )
			{
				message_begin( MSG_ONE_UNRELIABLE, msgid, _, i );
				write_byte( i );
				write_string( buffer );
				message_end( );
			}
		}
	}
	else
	{
		if( is_user_connected( id ) )
		{
			message_begin( MSG_ONE_UNRELIABLE, msgid, _, id );
			write_byte( id );
			write_string( buffer );
			message_end( );
		}
	}
}

stock q_get_user_team( id )
{
	return get_pdata_int( id, OFFSET_TEAM, EXTRA_OFFSET );
}
