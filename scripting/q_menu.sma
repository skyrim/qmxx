#include <amxmodx>
#include <q_message>
#include <q_menu>

/* todo
- item renderer, menu renderer
- menu parent, menu stack, item access maybe
- remove hacks in the near future
*/

#pragma semicolon 1

#define PLUGIN "Q::Menu"
#define VERSION "1.0"
#define AUTHOR "Quaker"

new g_player_menu[33];
new QMenu:g_player_menu_id[33] = { QMenu_None, ... };
new g_player_menu_forward[33];
new g_player_menu_keys[33];
new g_player_menu_page[33];
new Float:g_player_menu_expire[33];

new Array:g_menu_title;
new Array:g_menu_subtitle;
new Array:g_menu_forward;
new Array:g_menu_item_name;
new Array:g_menu_item_data;
new Array:g_menu_item_enabled;
new Array:g_menu_item_pickable;
new Array:g_menu_items_per_page;

public plugin_natives( )
{
	register_library( "q_menu" );
	
	register_dictionary("q_menu.txt");
	
	register_native( "q_menu_is_displayed", "_q_menu_is_displayed" );
	register_native( "q_menu_current", "_q_menu_current" );
	register_native( "q_menu_simple", "_q_menu_simple" );
	
	register_native( "q_menu_create", "_q_menu_create" );
	register_native( "q_menu_destroy", "_q_menu_destroy" );
	register_native( "q_menu_display", "_q_menu_display" );
	register_native( "q_menu_get_handler", "_q_menu_get_handler" );
	register_native( "q_menu_set_handler", "_q_menu_set_handler" );
	register_native( "q_menu_get_title", "_q_menu_get_title" );
	register_native( "q_menu_set_title", "_q_menu_set_title" );
	register_native( "q_menu_get_subtitle", "_q_menu_get_subtitle" );
	register_native( "q_menu_set_subtitle", "_q_menu_set_subtitle" );
	register_native( "q_menu_get_items_per_page", "_q_menu_get_items_per_page" );
	register_native( "q_menu_set_items_per_page", "_q_menu_set_items_per_page" );
	register_native( "q_menu_find_by_title", "_q_menu_find_by_title" );
	register_native( "q_menu_page_count", "_q_menu_page_count" );
	
	register_native( "q_menu_item_add", "_q_menu_item_add" );
	register_native( "q_menu_item_remove", "_q_menu_item_remove" );
	register_native( "q_menu_item_clear", "_q_menu_item_clear" );
	register_native( "q_menu_item_count", "_q_menu_item_count" );
	register_native( "q_menu_item_get_name", "_q_menu_item_get_name" );
	register_native( "q_menu_item_set_name", "_q_menu_item_set_name" );
	register_native( "q_menu_item_get_data", "_q_menu_item_get_data" );
	register_native( "q_menu_item_set_data", "_q_menu_item_set_data" );
	register_native( "q_menu_item_get_pickable", "_q_menu_item_get_pickable" );
	register_native( "q_menu_item_set_pickable", "_q_menu_item_set_pickable" );
	register_native( "q_menu_item_get_enabled", "_q_menu_item_get_enabled" );
	register_native( "q_menu_item_set_enabled", "_q_menu_item_set_enabled" );
}

public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	
	g_menu_title = ArrayCreate( 32, 8 );
	g_menu_subtitle = ArrayCreate( 32, 8 );
	g_menu_forward = ArrayCreate( 1, 8 );
	g_menu_items_per_page = ArrayCreate( 1, 8 );
	g_menu_item_name = ArrayCreate( 1, 8 );
	g_menu_item_data = ArrayCreate( 1, 8 );
	g_menu_item_enabled = ArrayCreate( 1, 8 );
	g_menu_item_pickable = ArrayCreate( 1, 8 );
	
	
	register_clcmd( "menuselect", "clcmd_menuselect" );
}

public plugin_end( )
{
	g_menu_title ? ArrayDestroy( g_menu_title ) : 0;
	g_menu_subtitle ? ArrayDestroy( g_menu_subtitle ) : 0;
	g_menu_forward ? ArrayDestroy( g_menu_forward ) : 0;
	g_menu_items_per_page ? ArrayDestroy( g_menu_items_per_page ) : 0;
	
	new Array:name, Array:data, Array:enab, Array:pick;
	for( new i = 0, size = ArraySize( g_menu_item_name ); i < size; ++i )
	{
		name = ArrayGetCell( g_menu_item_name, i );
		if( name ) ArrayDestroy( name );
		
		data = ArrayGetCell( g_menu_item_data, i );
		if( data ) ArrayDestroy( data );
		
		enab = ArrayGetCell( g_menu_item_enabled, i );
		if( enab ) ArrayDestroy( enab );
		
		pick = ArrayGetCell( g_menu_item_pickable, i );
		if( pick ) ArrayDestroy( pick );
	}
	g_menu_item_name ? ArrayDestroy( g_menu_item_name ) : 0;
	g_menu_item_data ? ArrayDestroy( g_menu_item_data ) : 0;
	g_menu_item_enabled ? ArrayDestroy( g_menu_item_enabled ) : 0;
	g_menu_item_pickable ? ArrayDestroy( g_menu_item_pickable ) : 0;
}

public clcmd_menuselect( id, level, cid )
{
	// hack
	new junk1, junk2;
	if( player_menu_info( id, junk1, junk2 ) )
		return PLUGIN_CONTINUE;
	
	if( g_player_menu[id] && ( g_player_menu_expire[id] < get_gametime( ) ) )
	{
		new slot[3];
		read_argv( 1, slot, charsmax(slot) );
		new key = str_to_num( slot ) - 1;
		
		if( g_player_menu_keys[id] & (1<<key) )
		{
			if( g_player_menu_id[id] == QMenu_Simple ) // simple menu
			{
				new ret;
				ExecuteForward( g_player_menu_forward[id], ret, id, key );
				
				g_player_menu[id] = false;
				g_player_menu_id[id] = QMenu_None;
				g_player_menu_keys[id] = 0;
				g_player_menu_expire[id] = 0.0;
				g_player_menu_forward[id] = 0;
				g_player_menu_page[id] = 0;
			}
			else
			{
				new QMenu:menu = g_player_menu_id[id];
				new page = g_player_menu_page[id];
				
				new item;
				if( q_menu_page_count( menu ) > 1 )
				{
					if( key == 7 )
						item = QMenuItem_Back;
					else if( key == 8 )
						item = QMenuItem_Next;
					else if( key == 9 )
						item = QMenuItem_Exit;
					else
						item = ( page * q_menu_get_items_per_page( menu ) ) + key;
				}
				else
				{
					if( key == 9 ) {
						item = QMenuItem_Exit;
					}
					else {
						item = key;
					}
				}
				
				g_player_menu[id] = false;
				g_player_menu_id[id] = QMenu_None;
				g_player_menu_keys[id] = 0;
				g_player_menu_expire[id] = 0.0;
				g_player_menu_forward[id] = 0;
				g_player_menu_page[id] = 0;
				
				new ret;
				ExecuteForward( ArrayGetCell( g_menu_forward, _:menu ), ret, id, _:menu, item );
				
				if( ret != PLUGIN_HANDLED )
				{
					if( item == QMenuItem_Back )
						q_menu_display( id, menu, -1, page - 1 );
					else if( item == QMenuItem_Next )
						q_menu_display( id, menu, -1, page + 1 );
				}
			}
			
			return PLUGIN_HANDLED;
		}
	}
	
	return PLUGIN_CONTINUE;
}

// q_menu_is_displayed( id )
public _q_menu_is_displayed( plugin, params )
{
	if( params != 1 )
	{
		log_error( AMX_ERR_NATIVE, "Parameters do not match. Expected 1, found %d", params );
		return 0;
	}
	
	return g_player_menu[get_param( 1 )];
}

// q_menu_current( id )
public _q_menu_current( plugin, params )
{
	if( params != 1 )
	{
		log_error( AMX_ERR_NATIVE, "Parameters do not match, Expected 1, found %d", params );
		return 0;
	}
	
	return _:g_player_menu_id[get_param( 1 )];
}

// q_menu_simple( id, keys, time, menu[], handler[] )
public _q_menu_simple( plugin, params )
{
	if( params != 5 )
	{
		log_error( AMX_ERR_NATIVE, "Parameters do not match. Expected 5, found %d", params );
		return;
	}
	
	new id = get_param( 1 );
	new keys = get_param( 2 );
	new menutime = get_param( 3 );
	new menutext[1024];
	get_string( 4, menutext, charsmax(menutext) );
	
	new handler[64];
	get_string( 5, handler, charsmax(handler) );
	new fwd = CreateOneForward( plugin, handler, FP_CELL, FP_CELL );
	if( fwd == -1 )
	{
		log_error( AMX_ERR_NATIVE, "Function ^"%s^" was not found", handler );
		return;
	}
	
	g_player_menu[id] = true;
	g_player_menu_id[id] = QMenu_Simple;
	g_player_menu_forward[id] = fwd;
	g_player_menu_keys[id] = keys;
	if( menutime == -1 )
		g_player_menu_expire[id] = Float:0xffffffff;
	else
		g_player_menu_expire[id] = get_gametime( ) + float(menutime);
	
	q_message_ShowMenu( id, id ? MSG_ONE : MSG_ALL, _, keys, menutime, menutext );
}

// q_menu_create( title[], handler[] )
public _q_menu_create( plugin, params )
{
	if( params != 2 )
	{
		log_error( AMX_ERR_NATIVE, "Parameters do not match. Expected 1, found %d", params );
		return -1;
	}
	
	new title[32];
	get_string( 1, title, charsmax(title) );
	
	new handler[32];
	get_string( 2, handler, charsmax(handler) );
	new fwd = CreateOneForward( plugin, handler, FP_CELL, FP_CELL, FP_CELL );
	if( fwd == -1 )
	{
		log_error( AMX_ERR_NATIVE, "Function ^"%s^" was not found", handler );
		return -1;
	}
	
	new Array:item_name = ArrayCreate( 64, 2 );
	ArrayPushString( item_name, "Exit" );
	ArrayPushString( item_name, "Next" );
	ArrayPushString( item_name, "Back" );
	
			
	new Array:item_data = ArrayCreate( 64, 2 );
	ArrayPushString( item_data, "" );
	ArrayPushString( item_data, "" );
	ArrayPushString( item_data, "" );
	
	new Array:item_enabled = ArrayCreate( 1, 2 );
	ArrayPushCell( item_enabled, true );
	ArrayPushCell( item_enabled, true );
	ArrayPushCell( item_enabled, true );
	
	new Array:item_pickable = ArrayCreate( 1, 2 );
	ArrayPushCell( item_pickable, true );
	ArrayPushCell( item_pickable, true );
	ArrayPushCell( item_pickable, true );
	
	new insert_index = 0;
	for( new size = ArraySize( g_menu_title ); insert_index < size; ++insert_index )
	{
		if( ArrayGetCell( g_menu_item_name, insert_index ) == 0 )
		{
			ArraySetString( g_menu_title, insert_index, title );
			ArraySetString( g_menu_subtitle, insert_index, "" );
			ArraySetCell( g_menu_forward, insert_index, fwd );
			ArraySetCell( g_menu_item_name, insert_index, item_name );
			ArraySetCell( g_menu_item_data, insert_index, item_data );
			ArraySetCell( g_menu_item_enabled, insert_index, item_enabled );
			ArraySetCell( g_menu_item_pickable, insert_index, item_pickable );
			ArraySetCell( g_menu_items_per_page, insert_index, 7 );
			
			return insert_index;
		}
	}
	
	ArrayPushString( g_menu_title, title );
	ArrayPushString( g_menu_subtitle, "" );
	ArrayPushCell( g_menu_forward, fwd );
	ArrayPushCell( g_menu_item_name, item_name );
	ArrayPushCell( g_menu_item_data, item_data );
	ArrayPushCell( g_menu_item_enabled, item_enabled );
	ArrayPushCell( g_menu_item_pickable, item_pickable );
	ArrayPushCell( g_menu_items_per_page, 7 );
	
	return ArraySize( g_menu_title ) - 1;
}

// q_menu_item_add( menu_id, item[], data[] = "", bool:pickable = true, bool:enabled = true )
public _q_menu_item_add( plugin, params )
{
	if( params != 5 )
	{
		log_error( AMX_ERR_NATIVE, "Parameters do not match. Expected 5, found %d", params );
		return -1;
	}
	
	new menu_id = get_param( 1 );
	if( ( menu_id < 0 ) || ( menu_id >= ArraySize( g_menu_title ) ) )
	{
		log_error( AMX_ERR_NATIVE, "Invalid menu id %d", menu_id );
		return -1;
	}
	
	new item[64];
	get_string( 2, item, charsmax(item) );
	ArrayPushString( ArrayGetCell( g_menu_item_name, menu_id ), item );
	
	new item_data[64];
	get_string( 3, item_data, charsmax(item_data) );
	ArrayPushString( ArrayGetCell( g_menu_item_data, menu_id ), item_data );
	
	ArrayPushCell( ArrayGetCell( g_menu_item_pickable, menu_id ), get_param( 4 ) );
	
	ArrayPushCell( ArrayGetCell( g_menu_item_enabled, menu_id ), get_param( 5 ) );
	
	return ArraySize( ArrayGetCell( g_menu_item_name, menu_id ) ) - 1;
}

// q_menu_item_get_name( menu_id, item_position, name[], len )
public _q_menu_item_get_name( plugin, params )
{
	if( params != 4 )
	{
		log_error( AMX_ERR_NATIVE, "Parameters do not match. Expected 4, found %d", params );
		return;
	}
	
	new menu_id = get_param( 1 );
	if( ( menu_id < 0 ) || ( menu_id >= ArraySize( g_menu_title ) ) )
	{
		log_error( AMX_ERR_NATIVE, "Invalid menu id %d", menu_id );
		return;
	}
	
	new Array:arr_item = ArrayGetCell( g_menu_item_name, menu_id );
	new item = get_param( 2 ) + 3;
	if( ( item < 0 ) || ( item >= ArraySize( arr_item ) ) )
	{
		log_error( AMX_ERR_NATIVE, "Invalid item id %d", item - 3 );
		return;
	}
	
	new item_name[64];
	ArrayGetString( arr_item, item, item_name, charsmax(item_name) );
	
	set_string( 3, item_name, get_param( 4 ) );
}

// q_menu_item_set_name( menu_id, item_position, name[] )
public _q_menu_item_set_name( plugin, params )
{
	if( params != 3 )
	{
		log_error( AMX_ERR_NATIVE, "Parameters do not match. Expected 3, found %d", params );
		return;
	}
	
	new menu_id = get_param( 1 );
	if( ( menu_id < 0 ) || ( menu_id >= ArraySize( g_menu_title ) ) )
	{
		log_error( AMX_ERR_NATIVE, "Invalid menu id %d", menu_id );
		return;
	}
	
	new Array:arr_item = ArrayGetCell( g_menu_item_name, menu_id );
	new item = get_param( 2 ) + 3;
	if( ( item < 0 ) || ( item >= ArraySize( arr_item ) ) )
	{
		log_error( AMX_ERR_NATIVE, "Invalid item id %d", item - 3 );
		return;
	}
	
	new item_name[64];
	get_string( 3, item_name, charsmax(item_name) );
	
	ArraySetString( arr_item, item, item_name );
}

// q_menu_item_get_data( menu_id, item, data[], len )
public _q_menu_item_get_data( plugin, params )
{
	if( params != 4 )
	{
		log_error( AMX_ERR_NATIVE, "Parameters do not match. Expected 4, found %d", params );
		return;
	}
	
	new menu_id = get_param( 1 );
	if( ( menu_id < 0 ) || ( menu_id >= ArraySize( g_menu_title ) ) )
	{
		log_error( AMX_ERR_NATIVE, "Invalid menu id %d", menu_id );
		return;
	}
	
	new Array:arr_item_data = ArrayGetCell( g_menu_item_data, menu_id );
	new item = get_param( 2 ) + 3;
	if( ( item < 0 ) || ( item >= ArraySize( arr_item_data ) ) )
	{
		log_error( AMX_ERR_NATIVE, "Invalid item id %d", item - 3 );
		return;
	}
	
	new item_data[64];
	ArrayGetString( arr_item_data, item, item_data, charsmax(item_data) );
	
	set_string( 3, item_data, get_param( 4 ) );
}

// q_menu_item_set_data( menu_id, item, item_data[] )
public _q_menu_item_set_data( plugin, params )
{
	if( params != 3 )
	{
		log_error( AMX_ERR_NATIVE, "Parameters do not match. Expected 3, found %d", params );
		return;
	}
	
	new menu_id = get_param( 1 );
	if( ( menu_id < 0 ) || ( menu_id >= ArraySize( g_menu_title ) ) )
	{
		log_error( AMX_ERR_NATIVE, "Invalid menu id %d", menu_id );
		return;
	}
	
	new Array:arr_item_data = ArrayGetCell( g_menu_item_data, menu_id );
	new item = get_param( 2 ) + 3;
	if( ( item < 0 ) || ( item >= ArraySize( arr_item_data ) ) )
	{
		log_error( AMX_ERR_NATIVE, "Invalid item id %d", item - 3 );
		return;
	}
	
	new item_data[64];
	get_string( 3, item_data, charsmax(item_data) );
	
	ArraySetString( arr_item_data, item, item_data );
}

// q_menu_item_set_pickable( menu_id, item, bool:pickable )
public _q_menu_item_set_pickable( plugin, params )
{
	if( params != 3 )
	{
		log_error( AMX_ERR_NATIVE, "Parameters do not match. Expected 3, found %d", params );
		return;
	}
	
	new menu_id = get_param( 1 );
	if( ( menu_id < 0 ) || ( menu_id >= ArraySize( g_menu_title ) ) )
	{
		log_error( AMX_ERR_NATIVE, "Invalid menu id %d", menu_id );
		return;
	}
	
	new Array:arr_item_data = ArrayGetCell( g_menu_item_data, menu_id );
	new item = get_param( 2 ) + 3;
	if( ( item < 0 ) || ( item >= ArraySize( arr_item_data ) ) )
	{
		log_error( AMX_ERR_NATIVE, "Invalid item id %d", item - 3 );
		return;
	}
	
	ArraySetCell( ArrayGetCell( g_menu_item_pickable, menu_id ), item, get_param( 3 ) );
}


// q_menu_item_get_pickable( menu_id, item )
public _q_menu_item_get_pickable( plugin, params )
{
	if( params != 2 )
	{
		log_error( AMX_ERR_NATIVE, "Parameters do not match. Expected 2, found %d", params );
		return false;
	}
	
	new menu_id = get_param( 1 );
	if( ( menu_id < 0 ) || ( menu_id >= ArraySize( g_menu_title ) ) )
	{
		log_error( AMX_ERR_NATIVE, "Invalid menu id %d", menu_id );
		return false;
	}
	
	new Array:arr_item_data = ArrayGetCell( g_menu_item_data, menu_id );
	new item = get_param( 2 ) + 3;
	if( ( item < 0 ) || ( item >= ArraySize( arr_item_data ) ) )
	{
		log_error( AMX_ERR_NATIVE, "Invalid item id %d", item - 3 );
		return false;
	}
	
	return ArrayGetCell( ArrayGetCell( g_menu_item_pickable, menu_id ), item );
}

// q_menu_item_get_enabled( menu_id, item )
public _q_menu_item_get_enabled( plugin, params )
{
	if( params != 2 )
	{
		log_error( AMX_ERR_NATIVE, "Parameters do not match. Expected 2, found %d", params );
		return false;
	}
	
	new menu_id = get_param( 1 );
	if( ( menu_id < 0 ) || ( menu_id >= ArraySize( g_menu_title ) ) )
	{
		log_error( AMX_ERR_NATIVE, "Invalid menu id %d", menu_id );
		return false;
	}
	
	new Array:arr_items = ArrayGetCell( g_menu_item_name, menu_id );
	new item = get_param( 2 ) + 3;
	if( ( item < 0 ) || ( item >= ArraySize( arr_items ) ) )
	{
		log_error( AMX_ERR_NATIVE, "Invalid item id %d", item - 3 );
		return false;
	}
	
	return ArrayGetCell( ArrayGetCell( g_menu_item_enabled, menu_id ), item );
}

// q_menu_item_set_enabled( menu_id, item, bool:enable )
public _q_menu_item_set_enabled( plugin, params )
{
	if( params != 3 )
	{
		log_error( AMX_ERR_NATIVE, "Parameters do not match. Expected 3, found %d", params );
		return;
	}
	
	new menu_id = get_param( 1 );
	if( ( menu_id < 0 ) || ( menu_id >= ArraySize( g_menu_title ) ) )
	{
		log_error( AMX_ERR_NATIVE, "Invalid menu id %d", menu_id );
		return;
	}
	
	new Array:arr_items = ArrayGetCell( g_menu_item_name, menu_id );
	new item = get_param( 2 ) + 3;
	if( ( item < 0 ) || ( item >= ArraySize( arr_items ) ) )
	{
		log_error( AMX_ERR_NATIVE, "Invalid item id %d", item - 3 );
		return;
	}
	
	ArraySetCell( ArrayGetCell( g_menu_item_enabled, menu_id ), item, get_param( 3 ) );
}

// q_menu_item_remove( menu_id, item )
public _q_menu_item_remove( plugin, params )
{
	if( params != 2 )
	{
		log_error( AMX_ERR_NATIVE, "Parameters do not match. Expected 2, found %d", params );
		return;
	}
	
	new menu_id = get_param( 1 );
	if( ( menu_id < 0 ) || ( menu_id >= ArraySize( g_menu_title ) ) )
	{
		log_error( AMX_ERR_NATIVE, "Invalid menu id %d", menu_id );
		return;
	}
	
	new Array:arr_items = ArrayGetCell( g_menu_item_name, menu_id );
	new item = get_param( 2 ) + 3;
	if( ( item < 0 ) || ( item >= ArraySize( arr_items ) ) )
	{
		log_error( AMX_ERR_NATIVE, "Invalid item id %d", item - 3 );
		return;
	}
	
	if( item < 3 )
	{
		log_error( AMX_ERR_NATIVE, "Items BACK, NEXT and EXIT cannot be removed" );
		return;
	}
	
	// It has to be a reference to some variable, so I have to do this
	ArrayDeleteItem( arr_items, item );
	
	new Array:arr_items_data = ArrayGetCell( g_menu_item_data, menu_id );
	ArrayDeleteItem( arr_items_data, item );
	
	new Array:arr_items_pickable = ArrayGetCell( g_menu_item_pickable, menu_id );
	ArrayDeleteItem( arr_items_pickable, item );
	
	new Array:arr_items_enabled = ArrayGetCell( g_menu_item_enabled, menu_id );
	ArrayDeleteItem( arr_items_enabled, item );
}

// q_menu_item_clear( menu )
public _q_menu_item_clear( plugin, params )
{
	if( params != 1 )
	{
		log_error( AMX_ERR_NATIVE, "Parameters do not match. Expected 1, found %d", params );
		return;
	}
	
	new menu_id = get_param( 1 );
	if( ( menu_id < 0 ) || ( menu_id >= ArraySize( g_menu_title ) ) )
	{
		log_error( AMX_ERR_NATIVE, "Invalid menu id %d", menu_id );
		return;
	}
	
	new Array:temp;
	temp = ArrayGetCell( g_menu_item_name, menu_id );
	ArrayClear( temp );
	ArrayPushString( temp, "Exit" );
	ArrayPushString( temp, "Next" );
	ArrayPushString( temp, "Back" );
	
	temp = ArrayGetCell( g_menu_item_data, menu_id );
	ArrayClear( temp );
	ArrayPushString( temp, "" );
	ArrayPushString( temp, "" );
	ArrayPushString( temp, "" );
	
	temp = ArrayGetCell( g_menu_item_enabled, menu_id );
	ArrayClear( temp );
	ArrayPushCell( temp, true );
	ArrayPushCell( temp, true );
	ArrayPushCell( temp, true );
	
	temp = ArrayGetCell( g_menu_item_pickable, menu_id );
	ArrayClear( temp );
	ArrayPushCell( temp, true );
	ArrayPushCell( temp, true );
	ArrayPushCell( temp, true );
}

// q_menu_item_count( menu_id )
public _q_menu_item_count( plugin, params )
{
	if( params != 1 )
	{
		log_error( AMX_ERR_NATIVE, "Parameters do not match. Expected 1, found %d", params );
		return -1;
	}
	
	new menu_id = get_param( 1 );
	if( ( menu_id < 0 ) || ( menu_id >= ArraySize( g_menu_title ) ) )
	{
		log_error( AMX_ERR_NATIVE, "Invalid menu id %d", menu_id );
		return -1;
	}
	
	return ArraySize( ArrayGetCell( g_menu_item_name, menu_id ) ) - 3;
}

// q_menu_page_count( menu_id )
public _q_menu_page_count( plugin, params )
{
	if( params != 1 )
	{
		log_error( AMX_ERR_NATIVE, "Parameters do not match. Expected 1, found %d", params );
		return 0;
	}
	
	new QMenu:menu_id = QMenu:get_param( 1 );
	if( ( _:menu_id < 0 ) || ( _:menu_id >= ArraySize( g_menu_title ) ) )
	{
		log_error( AMX_ERR_NATIVE, "Invalid menu id %d", menu_id );
		return -1;
	}
	
	new per_page = q_menu_get_items_per_page( menu_id );
	new item_count = q_menu_item_count( menu_id );
	
	if( item_count > 9 )
		return item_count / per_page + ( ( item_count % per_page ) ? 1 : 0 );
	
	return 1;
}

// q_menu_get_items_per_page( menu_id )
public _q_menu_get_items_per_page( plugin, params )
{
	if( params != 1 )
	{
		log_error( AMX_ERR_NATIVE, "Parameters do not match. Expected 1, found %d", params );
		return 0;
	}
	
	new menu_id = get_param( 1 );
	if( ( menu_id < 0 ) || ( menu_id >= ArraySize( g_menu_title ) ) )
	{
		log_error( AMX_ERR_NATIVE, "Invalid menu id %d", menu_id );
		return 0;
	}
	
	return ArrayGetCell( g_menu_items_per_page, menu_id );
}

// q_menu_set_items_per_page( menu_id, per_page )
public _q_menu_set_items_per_page( plugin, params )
{
	if( params != 2 )
	{
		log_error( AMX_ERR_NATIVE, "Parameters do not match. Expected 2, found %d", params );
		return;
	}
	
	new menu_id = get_param( 1 );
	if( ( menu_id < 0 ) || ( menu_id >= ArraySize( g_menu_title ) ) )
	{
		log_error( AMX_ERR_NATIVE, "Invalid menu id %d", menu_id );
		return;
	}
	
	new per_page = get_param( 2 );
	clamp( per_page, 1, 7 );
	
	ArraySetCell( g_menu_items_per_page, menu_id, per_page );
}

// q_menu_display( id, menu_id, menu_time, page )
public _q_menu_display( plugin, params )
{
	if( params != 4 )
	{
		log_error( AMX_ERR_NATIVE, "Parameters do not match. Expected 3, found %d", params );
		return;
	}
	
	new id = get_param( 1 );
	new QMenu:menu_id = QMenu:get_param( 2 );
	if( ( _:menu_id < 0 ) || ( _:menu_id >= ArraySize( g_menu_title ) ) )
	{
		log_error( AMX_ERR_NATIVE, "Invalid menu id %d", menu_id );
		return;
	}
	
	new junk1, junk2;
	if( player_menu_info( id, junk1, junk2 ) )
		show_menu( id, 0, "^n" ); // hack
	
	new menu_time = get_param( 3 );
	new page = get_param( 4 );
	new page_count = q_menu_page_count( menu_id );
	if( page < 0 )
		page = 0;
	else if( page >= page_count )
		page = page_count - 1;
	
	new menu[1024];
	new menu_len;
	
	new menu_title[32];
	ArrayGetString( g_menu_title, _:menu_id, menu_title, charsmax(menu_title) );
	menu_len = formatex( menu, charsmax(menu), "\r%s^n", menu_title );
	
	new menu_subtitle[32];
	ArrayGetString( g_menu_subtitle, _:menu_id, menu_subtitle, charsmax(menu_subtitle) );
	menu_len += formatex( menu[menu_len], charsmax(menu) - menu_len, "\w%s^n", menu_subtitle );
	
	new keys;
	new item[64];
	new Array:arr_items = ArrayGetCell( g_menu_item_name, _:menu_id );
	new Array:arr_items_enabled = ArrayGetCell( g_menu_item_enabled, _:menu_id );
	new Array:arr_items_pickable = ArrayGetCell( g_menu_item_pickable, _:menu_id );
	
	new c;
	new i = 3;
	
	if( page_count > 1 ) // paged menu
	{
		new per_page = q_menu_get_items_per_page( menu_id );
		
		// menu items
		for( new size = ArraySize( arr_items ); ( i - 3 < per_page ) && ( ( page * per_page ) + i < size ); ++i )
		{
			ArrayGetString( arr_items, ( page * per_page ) + i, item, charsmax(item) );
			
			if( ArrayGetCell( arr_items_pickable, ( page * per_page ) + i ) )
			{
				if( ArrayGetCell( arr_items_enabled, ( page * per_page ) + i ) )
				{
					keys |= (1<<(i-3));
					c = 'w';
				}
				else
				{
					c = 'd';
				}
				
				menu_len += formatex( menu[menu_len], charsmax(menu) - menu_len, "\y%d. \%c%s^n", i - 2, c, item ); // i + 1 - 3
			}
			else
			{
				menu_len += formatex( menu[menu_len], charsmax(menu) - menu_len, "\w%s^n", item );
			}
		}
		
		for( ; i - 3 < 7; ++i )
		{
			menu_len += formatex( menu[menu_len], charsmax(menu) - menu_len, "^n" );
		}
		
		// back button
		i = QMenuItem_Back + 3;
		ArrayGetString( arr_items, i, item, charsmax(item) );
		if( ArrayGetCell( arr_items_pickable, i ) )
		{
			if( ArrayGetCell( arr_items_enabled, i ) && ( page > 0 ) )
			{
				keys |= (1<<7);
				c = 'w';
			}
			else
			{
				c = 'd';
			}
			
			menu_len += formatex( menu[menu_len], charsmax(menu) - menu_len, "\r8. \%c%s^n", c, item );
		}
		else
		{
			menu_len += formatex( menu[menu_len], charsmax(menu) - menu_len, "\w%s^n", item );
		}
		
		// next button
		i = QMenuItem_Next + 3;
		ArrayGetString( arr_items, i, item, charsmax(item) );
		if( ArrayGetCell( arr_items_pickable, i ) )
		{
			if( ArrayGetCell( arr_items_enabled, i ) && ( page < ( page_count - 1 ) ) )
			{
				keys |= (1<<8);
				c = 'w';
			}
			else
			{
				c = 'd';
			}
			
			menu_len += formatex( menu[menu_len], charsmax(menu) - menu_len, "\r9. \%c%s^n", c, item );
		}
		else
		{
			menu_len += formatex( menu[menu_len], charsmax(menu) - menu_len, "\w%s^n", item );
		}
	}
	else // no pages => we can use all nine slots
	{
		for( new size = ArraySize( arr_items ); ( i - 3 < 9 ) && ( i < size ); ++i )
		{
			ArrayGetString( arr_items, i, item, charsmax(item) );
			
			if( ArrayGetCell( arr_items_pickable, i ) )
			{
				if( ArrayGetCell( arr_items_enabled, i ) )
				{
					keys |= (1<<(i-3));
					c = 'w';
				}
				else
				{
					c = 'd';
				}
				
				menu_len += formatex( menu[menu_len], charsmax(menu) - menu_len, "\y%d. \%c%s^n", i - 2, c, item ); // i + 1 - 3
			}
			else
			{
				menu_len += formatex( menu[menu_len], charsmax(menu) - menu_len, "\w%s^n", item );
			}
		}
		
		for( ; i - 3 < 9; ++i )
		{
			menu_len += formatex( menu[menu_len], charsmax(menu) - menu_len, "^n" );
		}
	}
	
	// exit button
	i = QMenuItem_Exit + 3;
	ArrayGetString( arr_items, i, item, charsmax(item) );
	if( ArrayGetCell( arr_items_pickable, i ) )
	{
		if( ArrayGetCell( arr_items_enabled, i ) )
		{
			keys |= (1<<9);
			c = 'w';
		}
		else
		{
			c = 'd';
		}
		
		menu_len += formatex( menu[menu_len], charsmax(menu) - menu_len, "\r0. \%c%s^n", c, item );
	}
	else
	{
		menu_len += formatex( menu[menu_len], charsmax(menu) - menu_len, "\w%s^n", item );
	}
	
	g_player_menu[id] = true;
	g_player_menu_id[id] = QMenu:menu_id;
	g_player_menu_keys[id] = keys;
	if( menu_time == -1 )
		g_player_menu_expire[id] = Float:0xffffffff;
	else
		g_player_menu_expire[id] = get_gametime( ) + float(menu_time);
	g_player_menu_forward[id] = ArrayGetCell( g_menu_forward, _:menu_id );
	g_player_menu_page[id] = page;
	
	q_message_ShowMenu( id, MSG_ONE, _, keys, menu_time, menu );
}

// q_menu_find_by_title( title[] )
public _q_menu_find_by_title( plugin, params )
{
	if( params != 1 )
	{
		log_error( AMX_ERR_NATIVE, "Parameters do not match. Expected 1, found %d", params );
		return -1;
	}
	
	new title[32];
	get_string( 1, title, charsmax(title) );
	
	new temptitle[32];
	for( new i = 0, size = ArraySize( g_menu_title ); i < size; ++i )
	{
		ArrayGetString( g_menu_title, i, temptitle, charsmax(temptitle) );
		if( equal( title, temptitle ) )
			return i;
	}
	
	return -1;
}

// q_menu_get_handler( menu_id )
public _q_menu_get_handler( plugin, params )
{
	if( params != 1 )
	{
		log_error( AMX_ERR_NATIVE, "Parameters do not match. Expected 1, found %d", params );
		return -1;
	}
	
	new menu_id = get_param( 1 );
	if( ( menu_id < 0 ) || ( menu_id >= ArraySize( g_menu_title ) ) )
	{
		log_error( AMX_ERR_NATIVE, "Invalid menu id %d", menu_id );
		return -1;
	}
	
	return ArrayGetCell( g_menu_forward, menu_id );
}

// q_menu_set_handler( menu_id, handler[] )
public _q_menu_set_handler( plugin, params )
{
	if( params != 2 )
	{
		log_error( AMX_ERR_NATIVE, "Parameters do not match. Expected 2, found %d", params );
		return;
	}
	
	new menu_id = get_param( 1 );
	if( ( menu_id < 0 ) || ( menu_id >= ArraySize( g_menu_title ) ) )
	{
		log_error( AMX_ERR_NATIVE, "Invalid menu id %d", menu_id );
		return;
	}
	
	new handler[64];
	get_string( 2, handler, charsmax(handler) );
	new fwd = CreateOneForward( plugin, handler, FP_CELL, FP_CELL, FP_CELL );
	if( fwd == -1 )
	{
		log_error( AMX_ERR_NATIVE, "Function ^"%s^" was not found", handler );
		return;
	}
	
	DestroyForward( ArrayGetCell( g_menu_forward, menu_id ) );
	ArraySetCell( g_menu_forward, menu_id, fwd );
}

// q_menu_get_title( menu, title[], len )
public _q_menu_get_title( plugin, params )
{
	if( params != 3 )
	{
		log_error( AMX_ERR_NATIVE, "Parameters do not match. Expected 3, found %d", params );
		return;
	}
	
	new menu_id = get_param( 1 );
	if( ( menu_id < 0 ) || ( menu_id >= ArraySize( g_menu_title ) ) )
	{
		log_error( AMX_ERR_NATIVE, "Invalid menu id %d", menu_id );
		return;
	}
	
	new title[32];
	ArrayGetString( g_menu_title, menu_id, title, charsmax(title) );
	set_string( 2, title, get_param( 3 ) );
}

// q_menu_set_title( menu, title[] )
public _q_menu_set_title( plugin, params )
{
	if( params != 2 )
	{
		log_error( AMX_ERR_NATIVE, "Parameters do not match. Expected 2, found %d", params );
		return;
	}
	
	new menu_id = get_param( 1 );
	if( ( menu_id < 0 ) || ( menu_id >= ArraySize( g_menu_title ) ) )
	{
		log_error( AMX_ERR_NATIVE, "Invalid menu id %d", menu_id );
		return;
	}
	
	new title[32];
	get_string( 2, title, charsmax(title) );
	ArraySetString( g_menu_title, menu_id, title );

}

// q_menu_get_subtitle( menu_id, subtitle[], len )
public _q_menu_get_subtitle( plugin, params )
{
	if( params != 3 )
	{
		log_error( AMX_ERR_NATIVE, "Parameters do not match. Expected 3, found %d", params );
		return;
	}
	
	new menu_id = get_param( 1 );
	if( ( menu_id < 0 ) || ( menu_id >= ArraySize( g_menu_title ) ) )
	{
		log_error( AMX_ERR_NATIVE, "Invalid menu id %d", menu_id );
		return;
	}
	
	new subtitle[32];
	ArrayGetString( g_menu_subtitle, menu_id, subtitle, charsmax(subtitle) );
	set_string( 2, subtitle, get_param( 3 ) );
}

// q_menu_set_subtitle( menu_id, subtitle[] )
public _q_menu_set_subtitle( plugin, params )
{
	if( params != 2 )
	{
		log_error( AMX_ERR_NATIVE, "Parameters do not match. Expected 2, found %d", params );
		return;
	}
	
	new menu_id = get_param( 1 );
	if( ( menu_id < 0 ) || ( menu_id >= ArraySize( g_menu_title ) ) )
	{
		log_error( AMX_ERR_NATIVE, "Invalid menu id %d", menu_id );
		return;
	}
	
	new subtitle[32];
	get_string( 2, subtitle, charsmax(subtitle) );
	ArraySetString( g_menu_subtitle, menu_id, subtitle );
}

// q_menu_destroy( menu_id )
public _q_menu_destroy( plugin, params )
{
	if( params != 1 )
	{
		log_error( AMX_ERR_NATIVE, "Parameters do not match. Expected 1, found %d", params );
		return;
	}
	
	new menu_id = get_param( 1 );
	if( ( menu_id < 0 ) || ( menu_id >= ArraySize( g_menu_title ) ) )
	{
		log_error( AMX_ERR_NATIVE, "Invalid menu id %d", menu_id );
		return;
	}
	
	ArraySetString( g_menu_title, menu_id, "" );
	
	new Array:arr_items = ArrayGetCell( g_menu_item_name, menu_id );
	arr_items ? ArrayDestroy( arr_items ) : 0;
	ArraySetCell( g_menu_item_name, menu_id, 0 );
	
	new Array:arr_items_data = ArrayGetCell( g_menu_item_data, menu_id );
	arr_items_data ? ArrayDestroy( arr_items_data ) : 0;
	ArraySetCell( g_menu_item_data, menu_id, 0 );
	
	new Array:arr_items_enabled = ArrayGetCell( g_menu_item_enabled, menu_id );
	arr_items_enabled ? ArrayDestroy( arr_items_enabled ) : 0;
	ArraySetCell( g_menu_item_enabled, menu_id, 0 );
	
	new Array:arr_items_pickable = ArrayGetCell( g_menu_item_pickable, menu_id );
	arr_items_pickable ? ArrayDestroy( arr_items_pickable ) : 0;
	ArraySetCell( g_menu_item_pickable, menu_id, 0 );
	
	DestroyForward( ArrayGetCell( g_menu_forward, menu_id ) );
	ArraySetCell( g_menu_forward, menu_id, 0 );
	
	ArraySetCell( g_menu_items_per_page, menu_id, 0 );
}
