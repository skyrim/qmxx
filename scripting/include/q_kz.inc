/* 
 * Quaker's KZ Mod API by Quaker
 *
 * This file is provided as is (no warranties).
 */

#if defined _q_kz_included
	#endinput
#endif

#define _q_kz_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib q_kz
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib q_kz
	#endif
#else
	#pragma library q_kz
#endif

/**
 *  Gets qkz version. */
native q_kz_version( version[], len );

/**
 *  Gets qkz data folder path. */
native q_kz_get_datadir( path[], len );

/**
 *  Gets qkz config folder path. */
native q_kz_get_configdir( path[], len );

/**
 *  Gets commonly used kzq_prefix cvar string */
native q_kz_get_prefix( output[], len );

/**
 *  Prints message to user in QKZ style. */
native q_kz_print( id, message[], any:... );

/**
 * ... */
native q_kz_saytext( id, message[], any:... );

/**
 *  Terminates player's run by given id only if player is actually in a run. */
native q_kz_terminate_run( id, reason[], any:... );

/**
 *  Retrieves hud color from main QKZ plugin. */
native q_kz_get_hud_color( &red, &green, &blue );

/**
 *  Returns 1 or 0 */
native q_kz_is_user_running( id );

/**
 *  Returns how much time has passed since run started. */
native Float:q_kz_get_user_runtime( id );

/**
 *  Returns number of checpoints user set */
native q_kz_get_user_cps( id );

/**
 *  Returns number of teleports user did */
native q_kz_get_user_tps( id );

/**
 *  Returns 1 if start position is set or 0 otherwise */
native q_kz_is_start_set( );

/**
 *  Gets start origin if set */
native q_kz_get_start_pos( Float:origin[3] );

/**
 *  Returns 1 if end position is set or 0 otherwise */
native q_kz_is_end_set( );

/**
 *  Get end origin if set */
native q_kz_get_end_pos( Float:origin[3] );

/**
 *  Returns 1 if its time for daily update or 0 otherwise */
native q_kz_daily_update( );

/**
 *  Safer way to register clcmds for qkz extension plugins */
native q_kz_register_clcmd( command[], handler[], flags = -1, description[] = "" );

/**
 *  Exactly the same as kzmenu, except that this here
 *  is for settings menu  */
native q_kz_settings_additem( name[], handler[] );

/**
 *  Returns 1 if user is vip or 0 otherwise */
native q_kz_is_user_vip( id );

/**
 *  This seems like a cool feature to me.
 *  How it works? Well, you pass pcvar handle of cvar
 *  you wish to register and description (optional).
 *  Later when map changes or server shuts down,
 *  all registered cvars are saved automaticly
 *  in amxx_qkz.cfg. No need to worry about
 *  making cfg generator anymore. Awesome, huh?
 *  NOTE: You can register cvar only in QKZ_RegisteringCvars */
native q_kz_register_cvar( pcvar_handle, description[] = "" );

/**
 *  Registers help menu in QKZ Help menu. After this func
 *  you should add help items, otherwise you'll screw up
 *  everything.
 *  NOTE: You can call this func only in QKZ_RegisteringHelp */
native q_kz_register_help( help_name[] );

/**
 *  Call this only after only after registering help.
 *  You can add up to 32 help items. Also content is
 *  limited to 128 characters, so be short and precise.
 *  NOTE: You can call this func only in QKZ_RegisteringHelp */
native q_kz_help_additem( item_name[], item_content[] );

/**
 *  Registers rewards in QKZ Rewards menu.
 *  When player finishes the map a menu with a list of
 *  all registered rewards will appear. Before displaying
 *  your item callback function will be called. You can
 *  create and pass callback function, but you don't have to.
 *  Callback func should be prototyped as:
 *  public <func>( id )
 *  You should return ITEM_ENABLED or ITEM_DISABLED from it.
 *  Usefull when player already has your reward, so you can
 *  disable it.
 *  When player selects an item, handler function will be called
 *  prototyped as:
 *  public <func>( id )
 *  In handler function you should enable user's reward or
 *  do some weird stuff I haven't predicted.
 *  NOTE: You can call this func only in QKZ_RegisteringRewards */
native q_kz_register_reward( name[], handler[], callback[] = "" );

// FORWARDS
forward QKZ_Init( );
forward QKZ_Shutdown( );

forward QKZ_RunStart_pre( id );
forward QKZ_RunStart_post( id );
forward QKZ_RunEnd_pre( id, Float:time, weapon, cps, tps );
forward QKZ_RunEnd_post( id, Float:time, weapon, cps, tps );

forward QKZ_RegisterSettings( );
forward QKZ_RegisterCvars( );
forward QKZ_RegisterHelp( );
forward QKZ_RegisterRewards( );
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
