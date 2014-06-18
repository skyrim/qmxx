/**
 * to do:
 * - q_print instead of qkz_print
 */

#include <amxmodx>
#include <fakemeta>

#include <q>
#include <q_cookies>
#include <q_menu>

#pragma semicolon 1

#define PLUGIN "Q::Speclist"
#define VERSION "1.3.3"
#define AUTHOR "Quaker"

#define TASKID_SPECLIST	5750
#define TASKTIME_SPECLIST 0.1

new g_cookies_failed;

new g_cvar_speclist;
new g_cvar_speclist_position;
new g_cvar_speclist_channel;
new g_cvar_speclist_color;
new g_cvar_speclist_immunityFlags;

new g_player_name[33][32];
new g_player_speclist[33];
new g_player_speclist_color[33][3];
new g_player_flags[33];
new bool:g_player_speclist_immunity[33];

new QMenu:g_player_menu[33];

public plugin_natives() {
	set_module_filter("module_filter");
	set_native_filter("native_filter");
}

public module_filter(module[]) {
	if(equal(module, "q_cookies")) {
		g_cookies_failed = true;
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public native_filter(name[], index, trap) {
	if(!trap) {
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_dictionary("q_speclist.txt");
	
	g_cvar_speclist = register_cvar("q_speclist", "1");
	g_cvar_speclist_position = register_cvar("q_speclist_position", "0.8 0.15");
	g_cvar_speclist_color = register_cvar("q_speclist_color", "0 125 255");
	g_cvar_speclist_channel = register_cvar("q_speclist_channel", "-1");
	g_cvar_speclist_immunityFlags = register_cvar("q_speclist_immunityflags", "");
	
	register_clcmd("say /speclist", "clcmd_speclist");
	register_clcmd("speclist_color", "clcmd_speclist_color");
	
	set_task(TASKTIME_SPECLIST, "task_SpecList", TASKID_SPECLIST, _, _, "b");
}

public plugin_cfg() {
	q_registerCvar(g_cvar_speclist, "1", "Toggle speclist plugin.");
	q_registerCvar(g_cvar_speclist_position, "0.8 0.15", "Set speclist HUD position.");
	q_registerCvar(g_cvar_speclist_color, "0 125 255", "Set default speclist HUD color.");
	q_registerCvar(g_cvar_speclist_channel, "-1", "Set speclist HUD channel, so that it does not interfere with other plugins.^n(Don't touch if you don't know what you're doing)");
	q_registerCvar(g_cvar_speclist_immunityFlags, "", "Set which flags will admin not appear in speclist.^nAdmin has to turn on immunity with /speclist command.");
}

public client_putinserver(id) {
	get_user_name(id, g_player_name[id], charsmax(g_player_name[]));
	
	if(g_cookies_failed) {
		return;
	}
	
	if(!q_get_cookie_num(id, "speclist_enabled", g_player_speclist[id])) {
		g_player_speclist[id] = false;
	}
	
	new color[12];
	if(!q_get_cookie_string(id, "speclist_color", color)) {
		get_pcvar_string(g_cvar_speclist_color, color, charsmax(color));
	}
	
	new r[4], g[4], b[4];
	parse(color, r, 4, g, 4, b, 4);
	
	g_player_speclist_color[id][0] = str_to_num(r);
	g_player_speclist_color[id][1] = str_to_num(g);
	g_player_speclist_color[id][2] = str_to_num(b);
	
	g_player_flags[id] = get_user_flags(id);
	new immunityFlags[28];
	get_pcvar_string(g_cvar_speclist_immunityFlags, immunityFlags, charsmax(immunityFlags));
	
	g_player_menu[id] = q_menu_create("Q::Speclist", "menu_speclist_handler");
	q_menu_item_add(g_player_menu[id], "");
	q_menu_item_add(g_player_menu[id], "");
	q_menu_item_add(g_player_menu[id], "");
}

public client_infochanged(id) {
	get_user_info(id, "name", g_player_name[id], charsmax(g_player_name[]));
}

public client_disconnect(id) {
	if(g_cookies_failed) {
		return;
	}
	
	q_set_cookie_num(id, "speclist_enabled", g_player_speclist[id]);
	
	new color[12];
	formatex(color, charsmax(color), "%d %d %d",
		g_player_speclist_color[id][0],
		g_player_speclist_color[id][1],
		g_player_speclist_color[id][2]);
	q_set_cookie_string(id, "speclist_color", color);
	
	g_player_flags[id] = 0;
}

public clcmd_speclist(id, level, cid)
{
	menu_speclist(id);
	
	return PLUGIN_HANDLED;
}

menu_speclist(id) {
	static buffer[64];
	
	new QMenu:menu = g_player_menu[id];
	
	formatex(buffer, charsmax(buffer), "Q::%L", id, "Q_SL_SPECLIST");
	q_menu_set_title(menu, buffer);
	
	formatex(buffer, charsmax(buffer), "%L: \y%L", id, "Q_SL_TOGGLE", id, (g_player_speclist[id] ? "Q_ON" : "Q_OFF"));
	q_menu_item_set_name(menu, 0, buffer);
	
	formatex(buffer, charsmax(buffer), "%L (%L: \y%d %d %d\w)",
		id, "Q_SL_SETCOLOR",
		id, "Q_CURRENT",
		g_player_speclist_color[id][0],
		g_player_speclist_color[id][1],
		g_player_speclist_color[id][2]);
	q_menu_item_set_name(menu, 1, buffer);
	
	get_pcvar_string(g_cvar_speclist_immunityFlags, buffer, charsmax(buffer));
	if(g_player_flags[id] & read_flags(buffer)) {
		formatex(buffer, charsmax(buffer), "%L: \y%L",
			id, "Q_SL_TOGGLEIMMUNITY",
			id, (g_player_speclist_immunity[id] ? "Q_ON" : "Q_OFF"));
		q_menu_item_set_name(menu, 2, buffer);
		q_menu_item_set_enabled(menu, 2, true);
	}
	else {
		formatex(buffer, charsmax(buffer), "%L", id, "Q_SL_NOIMMUNITYPRIVILEGE");
		q_menu_item_set_name(menu, 2, buffer);
		q_menu_item_set_enabled(menu, 2, false);
	}
	
	q_menu_display(id, g_player_menu[id]);
}

public menu_speclist_handler(id, menu, item) {
	switch(item) {
		case 0: {
			g_player_speclist[id] = !g_player_speclist[id];
			client_print(id, print_chat, "%L: %L", id, "Q_SL_SPECLIST", id, (g_player_speclist[id] ? "Q_ON" : "Q_OFF"));
			
			menu_speclist(id);
		}
		case 1: {
			client_cmd(id, "messagemode speclist_color");
			
			menu_speclist(id);
		}
		case 2: {
			g_player_speclist_immunity[id] = !g_player_speclist_immunity[id];
			
			menu_speclist(id);
		}
		default: {
			return PLUGIN_HANDLED;
		}
	}
	
	return PLUGIN_HANDLED;
}

public clcmd_speclist_color(id, level, cid) {
	new color[16];
	
	read_args(color, charsmax(color));
	remove_quotes(color);
	
	new r[4], g[4], b[4];
	parse(color, r, 3, g, 3, b, 3);
	
	g_player_speclist_color[id][0] = str_to_num(r);
	g_player_speclist_color[id][1] = str_to_num(g);
	g_player_speclist_color[id][2] = str_to_num(b);
	
	if(q_menu_current(id) == g_player_menu[id]) {
		menu_speclist(id);
	}
	
	return PLUGIN_HANDLED;
}

public task_SpecList(task_id) {
	static buffer[32][512];
	
	if(!get_pcvar_num(g_cvar_speclist)) {
		return;
	}
	
	new buffer_len[33];
	
	new spectated[33];
	new spectator[33];
	new spectatorCount[33];
	
	new maxplayers = get_maxplayers();
	
	for(new i = 1; i <= maxplayers; ++i) {
		if(is_user_connected(i)) {
			spectatorCount[pev(i, pev_iuser2)]++;
		}
	}
	
	new speced = 0;
	for(new i = 1; i <= maxplayers; ++i) {
		if(!is_user_connected(i) || g_player_speclist_immunity[i]) {
			continue;
		}
		
		if((speced = pev(i, pev_iuser2))) {
			spectated[speced] = true;
			spectator[i] = speced;
			
			if(buffer_len[speced] == 0) {
				buffer_len[speced] = formatex(buffer[speced - 1], charsmax(buffer[]), "%.12s (%d):", g_player_name[speced], spectatorCount[speced]);
			}
			buffer_len[speced] += formatex(buffer[speced - 1][buffer_len[speced]], charsmax(buffer[]) - buffer_len[speced], "^n%.15s", g_player_name[i]);
		}
	}
	
	new position[12];
	get_pcvar_string(g_cvar_speclist_position, position, charsmax(position));
	new position_x[5], position_y[5];
	parse(position, position_x, charsmax(position_x), position_y, charsmax(position_y));
	new Float:x = str_to_float(position_x);
	new Float:y = str_to_float(position_y);
	
	new channel = get_pcvar_num(g_cvar_speclist_channel);
	
	for(new i = 1; i <= maxplayers; ++i) {
		set_hudmessage(
			g_player_speclist_color[i][0],
			g_player_speclist_color[i][1],
			g_player_speclist_color[i][2],
			x, y,
			0, 0.0, 1.0, _, _, channel);
		
		if(spectated[i] && g_player_speclist[i]) {
			show_hudmessage(i, buffer[i - 1]);
		}
		else if(spectator[i] && g_player_speclist[i]) {
			show_hudmessage(i, buffer[spectator[i] - 1]);
		}
	}
}
