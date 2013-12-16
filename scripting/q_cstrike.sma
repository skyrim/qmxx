#include <amxmodx>
#include <fakemeta>

#include <q_cstrike>
#include <q_message_cstrike>

#pragma semicolon 1

#define PLUGIN "Q::CStrike"
#define VERSION "1.0"
#define AUTHOR "Quaker"

public plugin_natives( )
{
	register_library( "q_cstrike" );
	
	register_native( "q_get_user_team", "_q_get_user_team" );
	register_native( "q_set_user_team", "_q_set_user_team" );
}

public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
}

public CsTeams:_q_get_user_team( plugin, params )
{
	if( params != 1 )
	{
		log_error( AMX_ERR_NATIVE, "Parameters do not match. Expected 1, found %d", params );
		return CS_TEAM_UNASSIGNED;
	}
	
	new id = get_param( 1 );
	if( ( id < 1 ) || ( id > 32 ) )
	{
		log_error( AMX_ERR_NATIVE, "Invalid player id %d", id );
		return CS_TEAM_UNASSIGNED;
	}
	if( !pev_valid( id ) )
	{
		log_error( AMX_ERR_NATIVE, "Invalid player %d", id );
		return CS_TEAM_UNASSIGNED;
	}
	
	return CsTeams:get_pdata_int( get_param( 1 ), OFFSET_TEAM, EXTRA_OFFSET );
}

public _q_set_user_team( plugin, params )
{
	if( params != 2 )
	{
		log_error( AMX_ERR_NATIVE, "Parameters do not match. Expected 2, found %d", params );
		return;
	}
	
	new id = get_param( 1 );
	if( ( id < 1 ) || ( id > 32 ) )
	{
		log_error( AMX_ERR_NATIVE, "Invalid player id %d", id );
		return;
	}
	if( !pev_valid( id ) )
	{
		log_error( AMX_ERR_NATIVE, "Invalid player %d", id );
		return;
	}
	
	new team = get_param( 2 );
	if( ( team < 0 ) || ( team > 3 ) )
	{
		log_error( AMX_ERR_NATIVE, "Invalid player team %d", team );
		return;
	}
	
	set_pdata_int( id, OFFSET_TEAM, team, EXTRA_OFFSET );
	
	dllfunc( DLLFunc_ClientUserInfoChanged, id, engfunc( EngFunc_GetInfoKeyBuffer, id ) );
	
	q_message_TeamInfo( MSG_ALL, 0, _, id, CsTeams:team );
}
