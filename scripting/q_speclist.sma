/**
 * to do:
 * - q_print instead of qkz_print
 * - hud color!
 */

#include <amxmodx>
#include <fakemeta>

#include <q>
#include <q_cookies>
#include <q_menu>

#pragma semicolon 1

#define PLUGIN "Q::Speclist"
#define VERSION "1.2"
#define AUTHOR "Quaker"

#define TASKID_SPECLIST	5750
#define TASKTIME_SPECLIST 0.1

new g_cookies_failed;

new g_cvar_speclist;
new g_cvar_speclist_position;
new g_cvar_speclist_color;

new g_player_name[33][32];
new g_player_speclist[33];
new g_player_speclist_color[33][3];

new g_menu;

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
	
	g_menu = q_menu_create("QKZ / Speclist", "menu_speclist");
	q_menu_item_add(g_menu, "Turn on/off");
	q_menu_item_add(g_menu, "Set color");
	
	register_clcmd("say /speclist", "clcmd_speclist");
	register_clcmd("speclist_color", "clcmd_speclist_color");
	
	set_task(TASKTIME_SPECLIST, "task_SpecList", TASKID_SPECLIST, _, _, "b");
}

public plugin_cfg() {
	q_registerCvar(g_cvar_speclist, "1", "Toggle speclist plugin.");
	q_registerCvar(g_cvar_speclist_position, "0.8 0.15", "Set speclist HUD position.");
	q_registerCvar(g_cvar_speclist_color, "0 125 255", "Set speclist HUD color.");
}

public client_putinserver(id) {
	get_user_name(id, g_player_name[id], charsmax(g_player_name[]));
	
	if(!g_cookies_failed) {
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
	}
}

public client_infochanged(id) {
	get_user_info(id, "name", g_player_name[id], charsmax(g_player_name[]));
}

public client_disconnect(id) {
	if(!g_cookies_failed) {
		q_set_cookie_num(id, "speclist_enabled", g_player_speclist[id]);
		
		new color[12];
		formatex(color, charsmax(color), "%d %d %d",
			g_player_speclist_color[id][0],
			g_player_speclist_color[id][1],
			g_player_speclist_color[id][2]);
		q_set_cookie_string(id, "speclist_color", color);
	}
}

public clcmd_speclist(id, level, cid)
{
	q_menu_display(id, g_menu);
	
	return PLUGIN_HANDLED;
}

public menu_speclist(id, menu, item) {
	switch(item) {
		case 0: {
			g_player_speclist[id] = !g_player_speclist[id];
			client_print(id, print_chat, "%L: %L", id, "QKZ_SL_SPECTATORLIST", id, (g_player_speclist[id] ? "QKZ_ON" : "QKZ_OFF"));
		}
		case 1: {
			client_cmd(id, "messagemode speclist_color");
		}
	}
	
	return PLUGIN_HANDLED;
}

public clcmd_speclist_color(id, level, cid) {
	new color[12];
	
	read_args(color, charsmax(color));
	remove_quotes(color);
	
	new r[4], g[4], b[4];
	parse(color, r, 3, g, 3, b, 3);
	
	g_player_speclist_color[id][0] = str_to_num(r);
	g_player_speclist_color[id][1] = str_to_num(g);
	g_player_speclist_color[id][2] = str_to_num(b);
	
	return PLUGIN_HANDLED;
}

public task_SpecList(task_id) {
	static buffer[32][512];
	new buffer_len[33];
	
	if(!get_pcvar_num(g_cvar_speclist)) {
		return;
	}
	
	new spectated[33];
	new spectator[33];
	
	new speced = 0;
	for(new i = 1; i <= 32; ++i) {
		if(!is_user_connected(i)) {
			continue;
		}
		
		if((speced = pev(i, pev_iuser2))) {
			spectated[speced] = true;
			spectator[i] = speced;
			
			if(buffer_len[speced] == 0) {
				buffer_len[speced] = formatex(buffer[speced - 1], charsmax(buffer[]), "> %.12s <", g_player_name[speced]);
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
	
	for(new i = 1; i <= 32; ++i) {
		set_hudmessage(
			g_player_speclist_color[i][0],
			g_player_speclist_color[i][1],
			g_player_speclist_color[i][2],
			x, y,
			0, 0.0, 1.0, _, _, 4);
		
		if(spectated[i] && g_player_speclist[i]) {
			show_hudmessage(i, buffer[i - 1]);
		}
		else if(spectator[i] && g_player_speclist[i]) {
			show_hudmessage(i, buffer[spectator[i] - 1]);
		}
	}
}
