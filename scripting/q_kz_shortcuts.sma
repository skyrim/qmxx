#include <amxmodx>
#include <fakemeta>
#include <q_kz>

#pragma semicolon 1

#define PLUGIN "Q KZ Shortcuts"
#define VERSION "1.0"
#define AUTHOR "Quaker"

#define MAX_SCS 32

new g_sc_count;
new g_sc_entity[MAX_SCS];

new g_player_watching[33];
new g_player_menu_sclist_page[33];
new g_player_menu_editsc[33];
new g_player_menu_editsclist_page[33];
new g_player_menu_remsclist_page[33];

public plugin_init()
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	
	register_menucmd( register_menuid( "\yQ KZ / Shortcuts^n" ), MENU_KEY_0 | MENU_KEY_1 | MENU_KEY_2 | MENU_KEY_3 | MENU_KEY_4 | MENU_KEY_5 | MENU_KEY_6 | MENU_KEY_7 | MENU_KEY_8 | MENU_KEY_9, "menu_sclist_hnd" );
	
	register_menucmd( register_menuid( "\yQ KZ / Mod SC" ), MENU_KEY_0 | MENU_KEY_1 | MENU_KEY_2 | MENU_KEY_3, "menu_modsc_hnd" );
	register_menucmd( register_menuid( "\yQ KZ / Edit shortcut^n^n" ), MENU_KEY_0 | MENU_KEY_1 | MENU_KEY_2 | MENU_KEY_3 | MENU_KEY_4 | MENU_KEY_5 | MENU_KEY_6 | MENU_KEY_7 | MENU_KEY_8 | MENU_KEY_9, "menu_editsclist_hnd" );
	register_menucmd( register_menuid( "\yQ KZ / Shortcut^n^n" ), MENU_KEY_0 | MENU_KEY_1, "menu_editsc_hnd" );
	register_menucmd( register_menuid( "\yQ KZ / Remove shortcut^n^n" ), MENU_KEY_0 | MENU_KEY_1 | MENU_KEY_2 | MENU_KEY_3 | MENU_KEY_4 | MENU_KEY_5 | MENU_KEY_6 | MENU_KEY_7 | MENU_KEY_8 | MENU_KEY_9, "menu_remsclist_hnd" );
	
	register_clcmd( "say /modsc", "clcmd_modsc" );
	register_clcmd( "say /sc", "clcmd_sc" );
	
	for( new i = 0; i < sizeof(g_player_watching); ++i )
		g_player_watching[i] = -1;
}

public clcmd_sc( id, level, cid )
{
	if( g_sc_count )
		menu_sclist( id, g_player_menu_sclist_page[id], g_player_watching[id] );
	else
		client_print( id, print_chat, "Shortcuts not found on this map." );
	
	return PLUGIN_HANDLED;
}

public menu_sclist( id, page, selected )
{
	new keys = MENU_KEY_0;
	new buffer[192];
	new len = formatex( buffer, charsmax(buffer), "\yQ KZ / Shortcuts^n^n" );
	
	if( g_sc_count > 9 )
	{
		new i = page * 7;
		new size = i + 7;
		for( ; i < size; ++i )
		{
			if( i < g_sc_count )
			{
				if( i == selected )
				{
					len += formatex( buffer[len], charsmax(buffer) - len, "\r%d. \dShortcut #%d^n", i + 1, i + 1 );
				}
				else
				{
					keys |= (1<<( i - page*7 ));
					len += formatex( buffer[len], charsmax(buffer) - len, "\r%d. \wShortcut #%d^n", i + 1, i + 1 );
				}
			}
			else
			{
				len += formatex( buffer[len], charsmax(buffer) - len, "^n" );
			}
		}
		
		new c;
		if( page )
		{
			keys |= MENU_KEY_8;
			c = 'w';
		}
		else
		{
			c = 'd';
		}
		len += formatex( buffer[len], charsmax(buffer) - len, "\r8. \%cBack^n", c );
		
		if( size < g_sc_count )
		{
			keys |= MENU_KEY_9;
			c = 'w';
		}
		else
		{
			c = 'd';
		}
		len += formatex( buffer[len], charsmax(buffer) - len, "\r9. \%cNext^n", c );
	}
	else
	{
		new i = 0;
		for( ; i < g_sc_count; ++i )
		{
			if( i == selected )
			{
				len += formatex( buffer[len], charsmax(buffer) - len, "\r%d. \dShortcut #%d^n", i + 1, i + 1 );
			}
			else
			{
				keys |= (1<<i);
				len += formatex( buffer[len], charsmax(buffer) - len, "\r%d. \wShortcut #%d^n", i + 1, i + 1 );
			}
		}
		for( ; i < 9; ++i )
		{
			len += formatex( buffer[len], charsmax(buffer) - len, "^n" );
		}
	}
	
	formatex( buffer[len], charsmax(buffer) - len, "\r0. \yExit" );
	
	show_menu( id, keys, buffer );
}

public menu_sclist_hnd( id, item )
{
	if( g_sc_count > 9 )
	{
		switch( item )
		{
			case 7: // back
			{
				menu_sclist( id, --g_player_menu_sclist_page[id], g_player_watching[id] );
			}
			case 8: // next
			{
				menu_sclist( id, ++g_player_menu_sclist_page[id], g_player_watching[id] );
			}
			case 9: // exit
			{
				g_player_watching[id] = -1;
				g_player_menu_sclist_page[id] = 0;
				engfunc( EngFunc_SetView, id, id );
			}
			default:
			{
				g_player_watching[id] = item + ( g_player_menu_sclist_page[id] * 7 );
				engfunc( EngFunc_SetView, id, g_sc_entity[g_player_watching[id]] );
				menu_sclist( id, g_player_menu_sclist_page[id], g_player_watching[id] );
			}
		}
	}
	else
	{
		if( item == 9 ) // exit
		{
			g_player_watching[id] = -1;
			g_player_menu_sclist_page[id] = 0;
			engfunc( EngFunc_SetView, id, id );
		}
		else
		{
			g_player_watching[id] = item;
			engfunc( EngFunc_SetView, id, g_sc_entity[item] );
			menu_sclist( id, 0, item );
		}
	}
}

public clcmd_modsc( id, level, cid )
{
	if( get_user_flags( id ) & ADMIN_BAN )
		show_menu( id, MENU_KEY_0 | MENU_KEY_1 | MENU_KEY_2 | MENU_KEY_3, "\yQ KZ / Mod SC^n^n\r1. \wAdd shortcut^n\r2. \wEdit shortcuts^n\r3. \wRemove shortcut^n^n^n^n^n^n\r0. \yExit" );
	
	return PLUGIN_HANDLED;
}

public menu_modsc_hnd( id, item )
{
	switch( item )
	{
		case 0:
		{
			if( g_sc_count == MAX_SCS )
			{
				client_print( id, print_chat, "Maximum number of shortcuts reached. Cannot add any more shortcuts" );
			}
			else
			{
				// FIX: What if entity creation fails?
				new ent = engfunc( EngFunc_CreateNamedEntity, engfunc( EngFunc_AllocString, "trigger_camera" ) );
				new Float:origin[3], Float:angles[3];
				pev( id, pev_origin, origin );
				pev( id, pev_v_angle, angles );
				set_pev( ent, pev_origin, origin );
				set_pev( ent, pev_angles, angles );
				set_pev( ent, pev_solid, SOLID_TRIGGER );
				set_pev( ent, pev_movetype, MOVETYPE_FLYMISSILE );
				engfunc( EngFunc_SetModel, ent, "models/w_usp.mdl" );
				set_pev( ent, pev_rendermode, kRenderTransTexture );
				set_pev( ent, pev_renderamt, 0.0 );
				
				g_sc_entity[g_sc_count] = ent;
				menu_editsc( id, g_sc_count );
				
				++g_sc_count;
			}
		}
		case 1:
		{
			g_player_menu_editsclist_page[id] = 0;
			menu_editsclist( id, g_player_menu_editsclist_page[id] );
		}
		case 2:
		{
			g_player_menu_remsclist_page[id] = 0;
			menu_remsclist( id, g_player_menu_remsclist_page[id] );
		}
	}
}

public menu_editsclist( id, page )
{
	new keys = MENU_KEY_0;
	new buffer[192];
	new len = formatex( buffer, charsmax(buffer), "\yQ KZ / Edit shortcut^n^n" );
	
	if( g_sc_count > 9 )
	{
		new i = page * 7;
		new size = i + 7;
		for( ; i < size; ++i )
		{
			if( i < g_sc_count )
			{
				keys |= (1<<( i - page*7 ));
				len += formatex( buffer[len], charsmax(buffer) - len, "\r%d. \wShortcut #%d^n", i + 1, i + 1 );
			}
			else
			{
				len += formatex( buffer[len], charsmax(buffer) - len, "^n" );
			}
		}
		
		new c;
		if( page )
		{
			keys |= MENU_KEY_8;
			c = 'w';
		}
		else
		{
			c = 'd';
		}
		len += formatex( buffer[len], charsmax(buffer) - len, "\r8. \%cBack^n", c );
		
		if( size < g_sc_count )
		{
			keys |= MENU_KEY_9;
			c = 'w';
		}
		else
		{
			c = 'd';
		}
		len += formatex( buffer[len], charsmax(buffer) - len, "\r9. \%cNext^n", c );
	}
	else
	{
		new i = 0;
		for( ; i < g_sc_count; ++i )
		{
			keys |= (1<<i);
			len += formatex( buffer[len], charsmax(buffer) - len, "\r%d. \wShortcut #%d^n", i + 1, i + 1 );
		}
		for( ; i < 9; ++i )
		{
			len += formatex( buffer[len], charsmax(buffer) - len, "^n" );
		}
	}
	
	formatex( buffer[len], charsmax(buffer) - len, "\r0. \yExit" );
	
	show_menu( id, keys, buffer );
}

public menu_editsclist_hnd( id, item )
{
	if( g_sc_count > 9 )
	{
		switch( item )
		{
			case 7:
			{
				menu_editsclist( id, --g_player_menu_editsclist_page[id] );
			}
			case 8:
			{
				menu_editsclist( id, ++g_player_menu_editsclist_page[id] );
			}
			case 9:
			{
				g_player_menu_editsclist_page[id] = 0;
			}
			default:
			{
				menu_editsc( id, item * ( g_player_menu_editsclist_page[id] * 7 ) );
			}
		}
	}
	else
	{
		if( item != 9 )
		{
			menu_editsc( id, item );
		}
	}
}

public menu_remsclist( id, page )
{
	new keys = MENU_KEY_0;
	new buffer[192];
	new len = formatex( buffer, charsmax(buffer), "\yQ KZ / Remove shortcut^n^n" );
	
	if( g_sc_count > 9 )
	{
		new i = page * 7;
		new size = i + 7;
		for( ; i < size; ++i )
		{
			if( i < g_sc_count )
			{
				keys |= (1<<( i - page*7 ));
				len += formatex( buffer[len], charsmax(buffer) - len, "\r%d. \wShortcut #%d^n", i + 1, i + 1 );
			}
			else
			{
				len += formatex( buffer[len], charsmax(buffer) - len, "^n" );
			}
		}
		
		new c;
		if( page )
		{
			keys |= MENU_KEY_8;
			c = 'w';
		}
		else
		{
			c = 'd';
		}
		len += formatex( buffer[len], charsmax(buffer) - len, "\r8. \%cBack^n", c );
		
		if( size < g_sc_count )
		{
			keys |= MENU_KEY_9;
			c = 'w';
		}
		else
		{
			c = 'd';
		}
		len += formatex( buffer[len], charsmax(buffer) - len, "\r9. \%cNext^n", c );
	}
	else
	{
		new i = 0;
		for( ; i < g_sc_count; ++i )
		{
			keys |= (1<<i);
			len += formatex( buffer[len], charsmax(buffer) - len, "\r%d. \wShortcut #%d^n", i + 1, i + 1 );
		}
		for( ; i < 9; ++i )
		{
			len += formatex( buffer[len], charsmax(buffer) - len, "^n" );
		}
	}
	
	formatex( buffer[len], charsmax(buffer) - len, "\r0. \yExit" );
	
	show_menu( id, keys, buffer );
}

public menu_remsclist_hnd( id, item )
{
	if( g_sc_count > 9 )
	{
		switch( item )
		{
			case 7:
			{
				menu_remsclist( id, --g_player_menu_remsclist_page[id] );
			}
			case 8:
			{
				menu_remsclist( id, ++g_player_menu_remsclist_page[id] );
			}
			case 9:
			{
				return;
			}
			default:
			{
				--g_sc_count;
				for( new i = item + ( g_player_menu_remsclist_page[id] * 7 ); i < g_sc_count; ++i )
					g_sc_entity[i] = g_sc_entity[i + 1];
			}
		}
	}
	else
	{
		if( item == 9 )
		{
			return;
		}
		else
		{
			--g_sc_count;
			for( new i = item; i < g_sc_count; ++i )
				g_sc_entity[i] = g_sc_entity[i + 1];
		}
	}
	
	menu_remsclist( id, g_player_menu_remsclist_page[id] );
}

public menu_editsc( id, shortcut )
{
	g_player_menu_editsc[id] = shortcut;
	show_menu( id, MENU_KEY_0 | MENU_KEY_1, "\yQ KZ / Shortcut^n^n\r1. \wSet shortcut camera^n^n^n^n^n^n^n^n\r0. \yExit" );
}

public menu_editsc_hnd( id, item )
{
	switch( item )
	{
		case 0:
		{
			new sc = g_player_menu_editsc[id];
			
			new Float:origin[3];
			pev( id, pev_origin, origin );
			set_pev( g_sc_entity[sc], pev_origin, origin );
			
			new Float:angles[3];
			pev( id, pev_v_angle, angles );
			set_pev( g_sc_entity[sc], pev_angles, angles );
			
			menu_editsc( id, sc );
		}
	}
}
