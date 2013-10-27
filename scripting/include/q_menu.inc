/* 
 * Q Menu API by Quaker
 *
 * This file is provided as is (no warranties).
 */

#if defined _q_menu_included
	#endinput
#endif

#define _q_menu_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib q_menu
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib q_menu
	#endif
#else
	#pragma library q_menu
#endif

#include <q_menu_const>

/**
 * @param   id  player id
 * @return      boolean value is menu currently displayed
 */
native q_menu_is_displayed( id );

/**
 * Returns menu id of the currently displayed menu to a given player id.
 *
 * @param   id  player id
 * @return      menu id
 *              QMenu_None   = no menu
 *              QMenu_Simple = simple menu
 *              0 or greater = menu created with q_menu_create (complex menu?)
 */
native QMenu:q_menu_current( id );

/**
 * @param  id       player id to whom the menu will be displayed or 0 for all
 * @param  keys     bitsum of keys available in the menu
 * @param  time     how long will the menu be valid (in seconds)
 * @param  menu     string of the entire menu
 * @param  handler  name of the handler function
 *                  prototype:
 *                  public handler_func_name( id, item )
 */
native q_menu_simple( id, keys, time, menu[], handler[] );

native q_menu_create( title[], handler[] );

native q_menu_destroy( menu_id );

native q_menu_display( id, menu_id, menu_time = -1, page = 0 );

native q_menu_get_handler( menu_id );

native q_menu_set_handler( menu_id, handler[] );

native q_menu_get_subtitle( menu_id, subtitle[], len );

native q_menu_set_subtitle( menu_id, subtitle[] );

native q_menu_get_items_per_page( menu_id );

native q_menu_set_items_per_page( menu_id, per_page );

native q_menu_page_count( menu_id );

native q_menu_item_add( menu_id, name[], data[] = "", bool:pickable = true, bool:enabled = true );

native q_menu_item_remove( menu_id, item_position );

native q_menu_item_count( menu_id );

native q_menu_item_get_name( menu_id, item_position, item_name[], len );

native q_menu_item_set_name( menu_id, item_position, item_name[] );

native q_menu_item_get_data( menu_id, item_position, item_data[], len );

native q_menu_item_set_data( menu_id, item_position, item_data[] );

native q_menu_item_get_type( menu_id, item_position );

native q_menu_item_set_type( menu_id, item_position, type );

native q_menu_item_get_enabled( menu_id, item_position );

native q_menu_item_set_enabled( menu_id, item_position, bool:enabled );

native q_menu_item_get_pickable( menu_id, item_position );

native q_menu_item_set_pickable( menu_id, item_position, bool:pickable );

/**
 * @param   title  menu title
 * @return         menu id or -1 if not found
 */
native q_menu_find_by_title( title[] );
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
