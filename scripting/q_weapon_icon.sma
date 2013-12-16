/**
 * to do:
 * - pull out messages
 */

#include <amxmodx>
#include <cvar_util>

#pragma semicolon 1

#define PLUGIN "Q::WeaponIcon"
#define VERSION "1.0"
#define AUTHOR "Quaker"

new g_WeaponSprites[][] =
{
	"",
	"d_p228",
	"",
	"d_scout",
	"d_grenade",
	"d_xm1014",
	"c4",
	"d_mac10",
	"d_aug",
	"d_grenade",
	"d_elite",
	"d_fiveseven",
	"d_ump45",
	"d_sg550",
	"d_galil",
	"d_famas",
	"d_usp",
	"d_glock18",
	"d_awp",
	"d_mp5navy",
	"d_m249",
	"d_m3",
	"d_m4a1",
	"d_tmp",
	"d_g3sg1",
	"d_flashbang",
	"d_deagle",
	"d_sg552",
	"d_ak47",
	"d_knife",	
	"d_p90"
};

new g_server_weaponicon;

public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	
	new cvar_wpnico = CvarRegister( "q_weapon_icon", "2" );
	CvarCache( cvar_wpnico, CvarType_Int, g_server_weaponicon );
	CvarHookChange( cvar_wpnico, "cvar_hook_wpnico", true );
	
	register_event( "CurWeapon", "event_CurWeapon", "b", "1!0" );
	register_event( "Spectator", "event_Spectator", "a" );
	register_event( "DeathMsg", "event_DeathMsg", "a" );
}

public cvar_hook_wpnico( cvar_handle, oldval[], newval[], cvar_name[] )
{
	new ov = str_to_num( oldval );
	new nv = str_to_num( newval );
	
	if( ov != nv )
	{
		switch( nv )
		{
			case 1:
			{
				new wpn;
				for( new i = 1; i <= 32; ++i )
				{
					if( is_user_connected( i ) )
					{
						wpn = get_user_weapon( i );
						message_StatusIcon( i, 1, g_WeaponSprites[wpn] );
					}
				}
			}
			case 2:
			{
				new wpn;
				for( new i = 1; i <= 32; ++i )
				{
					if( is_user_connected( i ) )
					{
						wpn = get_user_weapon( i );
						message_StatusIcon( i, 0, g_WeaponSprites[get_user_weapon(i)] );
						message_Scenario( i, 1, g_WeaponSprites[wpn] );
					}
				}
			}
			default:
			{
				for( new i = 1; i <= 32; ++i )
				{
					if( is_user_connected( i ) )
					{
						message_Scenario( i, 0 );
						message_StatusIcon( i, 0, g_WeaponSprites[get_user_weapon(i)] );
					}
				}
			}
		}
	}
}

public event_CurWeapon( id )
{
	static oldwpn;
	
	new wpn = read_data( 2 );
	
	switch( g_server_weaponicon )
	{
		case 1:
		{
			message_StatusIcon( id, 0, g_WeaponSprites[oldwpn] );
			message_StatusIcon( id, 1, g_WeaponSprites[wpn] );
		}
		case 2:
		{
			message_Scenario( id, 1, g_WeaponSprites[wpn] );
		}
	}
	
	oldwpn = wpn;
}

public event_Spectator( id )
{
	id = read_data( 1 );
	
	message_StatusIcon( id, 0, g_WeaponSprites[get_user_weapon(id)] );
}

public event_DeathMsg( id )
{
	id = read_data( 2 );
	
	message_StatusIcon( id, 0, g_WeaponSprites[get_user_weapon(id)] );

}

stock message_StatusIcon( id, status, iconname[] = "" )
{
	static msg_StatusIcon;
	if( !msg_StatusIcon )
		msg_StatusIcon = get_user_msgid("StatusIcon");
	
	message_begin( MSG_ONE_UNRELIABLE, msg_StatusIcon, _, id );
	write_byte( status );
	write_string( iconname );
	write_byte( 0 );
	write_byte( 255 );
	write_byte( 0 );
	message_end( );
}

stock message_Scenario( id, active, sprite[] = "", alpha = 100, flashrate = 0 )
{
	static msg_Scenario;
	if( !msg_Scenario )
		msg_Scenario = get_user_msgid("Scenario");
	
	message_begin( MSG_ONE_UNRELIABLE, msg_Scenario, _, id );
	write_byte( active );
	if( active != 0 )
	{
		write_string( sprite );
		write_byte( alpha );
		if( flashrate )
		{
			write_short( flashrate );
			write_short( 0 );
		}
	}
	message_end( );
}
