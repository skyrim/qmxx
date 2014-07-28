/**
 * to do:
 * - saytext message for join and leave instead of client_print
 */

#include <amxmodx>
#include <geoip>

#include <q>
#include <q_menu>

#pragma semicolon 1

#define PLUGIN "Q::Country"
#define VERSION "1.2"
#define AUTHOR "Quaker"

#define STR_ENTERGAME "QCNTR_ENTERGAME"
#define STR_LEAVEGAME "QCNTR_LEAVEGAME"
#define STR_MENUTITLE "QCNTR_MENUTITLE"
#define STR_UNKNOWNCNTR "QCNTR_UNKNOWNCNTR"

new g_cvar_joinmessage;
new g_cvar_leavemessage;

new QMenu:g_menu;

new g_player_country[33][46];
new bool:g_player_unknownCountry[33] = {false, ...};

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_dictionary("q_country.txt");
	
	g_cvar_joinmessage = register_cvar("q_country_joinmessage", "0");
	g_cvar_leavemessage = register_cvar("q_country_leavemessage", "0");
	
	g_menu = q_menu_create("", "mh_country");
	
	register_clcmd("say /country", "clcmd_country");
}

public plugin_cfg() {
	q_registerCvar(g_cvar_joinmessage, "0", "Toggle join message.");
	q_registerCvar(g_cvar_leavemessage, "0", "Toggle leave message.");
}

public client_putinserver(id) {
	static buffer[128];
	
	new name[32];
	get_user_name(id, name, charsmax(name));
	
	new ip[16];
	get_user_ip(id, ip, charsmax(ip), true);
	
	new data[3];
	num_to_str(id, data, charsmax(data));
	
	geoip_country(ip, g_player_country[id]);
	if(g_player_country[id][0] == 'e' || !g_player_country[id][0]) {
		g_player_unknownCountry[id] = true;
		q_menu_item_add(g_menu, "", data, false, _, "mf_country");
	}
	else {
		g_player_unknownCountry[id] = false;
		formatex(buffer, charsmax(buffer), "%s \d(%s)", name, g_player_country[id]);
		q_menu_item_add(g_menu, buffer, data, false);
	}
	
	if(get_pcvar_num(g_cvar_joinmessage)) {
		for(new i = 1, playerCount = get_maxplayers(); i <= playerCount; ++i) {
			if(i == id) {
				continue;
			}
			
			LookupLangKey(buffer, charsmax(buffer), STR_ENTERGAME, i);
			replace_all(buffer, charsmax(buffer), "^"name^"", name);
			if(g_player_unknownCountry[id]) {
				LookupLangKey(g_player_country[id], charsmax(g_player_country[]), STR_UNKNOWNCNTR, i);
				strtolower(g_player_country[id]);
				replace_all(buffer, charsmax(buffer), "^"country^"", g_player_country[id]);
			}
			else {
				replace_all(buffer, charsmax(buffer), "^"country^"", g_player_country[id]);
			}
			client_print(i, print_chat, "%s", buffer);
		}
	}
}

public client_infochanged(id) {
	new name[32];
	get_user_info(id, "name", name, charsmax(name));
	
	new data[3];
	new buffer[64];
	for(new i = 0, itemCount = q_menu_item_count(g_menu); i < itemCount; ++i) {
		q_menu_item_get_data(g_menu, i, data, charsmax(data));
		if(str_to_num(data) == id) {
			formatex(buffer, charsmax(buffer), "%s \d(%s)", name, g_player_country[id]);
			q_menu_item_set_name(g_menu, i, buffer);
			break;
		}
	}
}

public client_disconnect(id) {
	new name[32];
	get_user_name(id, name, charsmax(name));
	
	static buffer[128];
	if(get_pcvar_num(g_cvar_leavemessage)) {
		for(new i = 1, playerCount = get_maxplayers(); i <= playerCount; ++i) {
			LookupLangKey(buffer, charsmax(buffer), STR_LEAVEGAME, i);
			replace_all(buffer, charsmax(buffer), "^"name^"", name);
			if(g_player_unknownCountry[id]) {
				LookupLangKey(g_player_country[id], charsmax(g_player_country[]), STR_UNKNOWNCNTR, i);
				strtolower(g_player_country[id]);
				replace_all(buffer, charsmax(buffer), "^"country^"", g_player_country[id]);
			}
			else {
				replace_all(buffer, charsmax(buffer), "^"country^"", g_player_country[id]);
			}
			client_print(i, print_chat, "%s", buffer);
		}
	}
	
	new data[3];
	for(new i = 0, itemCount = q_menu_item_count(g_menu); i < itemCount; ++i) {
		q_menu_item_get_data(g_menu, i, data, charsmax(data));
		if(str_to_num(data) == id) {
			q_menu_item_remove(g_menu, i);
			break;
		}
	}
}

public clcmd_country(id) {
	m_country(id);
	
	return PLUGIN_HANDLED;
}

m_country(id) {
	new title[32];
	formatex(title, charsmax(title), "%L", id, STR_MENUTITLE);
	q_menu_set_title(g_menu, title);
	q_menu_display(id, g_menu);
}

public mf_country(id, QMenu:menu, item, output[64]) {
	new data[3];
	q_menu_item_get_data(menu, item, data, charsmax(data));
	new theId = str_to_num(data);
	
	new name[32];
	get_user_name(theId, name, charsmax(name));
	
	formatex(output, charsmax(output), "%s \d(%L)", name, id, STR_UNKNOWNCNTR);
}

public mh_country(id, QMenu:menu, item) {
	return PLUGIN_HANDLED;
}
