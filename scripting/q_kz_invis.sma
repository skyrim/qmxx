#include <amxmodx>
#include <fakemeta>

#include <q>
#include <q_kz>
#include <q_cookies>
#include <q_menu>

#pragma semicolon 1

#define PLUGIN "Q::KZ::Invis"
#define VERSION "1.2"
#define AUTHOR "Quaker"

new g_cookies_failed;

new g_invis_cid[3];
new g_player_pinvis[33];
new g_player_winvis[33];

#define SET_BITVECTOR(%1,%2) (%1[%2>>5] |=  (1<<(%2 & 31)))
#define GET_BITVECTOR(%1,%2) (%1[%2>>5] &   (1<<(%2 & 31)))
#define CLR_BITVECTOR(%1,%2) (%1[%2>>5] &= ~(1<<(%2 & 31)))
new g_water[1380 / 32];

new QMenu:g_menu;

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
	if(!trap)
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_dictionary("q_kz_invis.txt");
	
	register_forward(FM_AddToFullPack, "AddToFullPack", 1);
	
	g_menu = q_menu_create("", "mh_invis");
	q_menu_item_add(g_menu, "", _, _, _, "mf_invis");
	q_menu_item_add(g_menu, "", _, _, _, "mf_invis");
	
	g_invis_cid[0] = register_clcmd("say /invis", "clcmd_invis");
	g_invis_cid[1] = register_clcmd("say /pinvis", "clcmd_invis");
	g_invis_cid[2] = register_clcmd("say /winvis", "clcmd_invis");
	
	// find water
	new ent = -1;
	while((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "func_water"))) {
		SET_BITVECTOR(g_water,ent);
	}
	ent = -1;
	while((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "func_illusionary"))) {
		if(pev(ent, pev_skin) == CONTENTS_WATER)
			SET_BITVECTOR(g_water,ent);
	}
	ent = -1;
	while((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "func_conveyor"))) {
		if(pev(ent, pev_spawnflags) == 3)
			SET_BITVECTOR(g_water,ent);
	}
}

public client_putinserver(id) {
	if(!g_cookies_failed && !q_get_cookie_num(id, "invis_player", g_player_pinvis[id]))
		g_player_pinvis[id] = false;
	
	if(!g_cookies_failed && !q_get_cookie_num(id, "invis_water", g_player_winvis[id]))
		g_player_winvis[id] = false;
}

public client_disconnect(id) {
	if(!g_cookies_failed) {
		q_set_cookie_num(id, "invis_player", g_player_pinvis[id]);
		q_set_cookie_num(id, "invis_water", g_player_winvis[id]);
	}
}

public AddToFullPack(es_handle, e, ent, host, hostflags, player, pset) {
	if(player && g_player_pinvis[host] && (host != ent) && (ent != pev(host, pev_iuser2))) {
		set_es(es_handle, ES_Origin, Float:{-4096.0, -4096.0, -4096.0});
	}
	if(g_player_winvis[host] && GET_BITVECTOR(g_water,ent)) {
		set_es(es_handle, ES_Effects, EF_NODRAW);
	}
}

public clcmd_invis(id, level, cid) {
	if(cid == g_invis_cid[0]) {
		m_invis(id);
	}
	else if(cid == g_invis_cid[1]) {
		g_player_pinvis[id] = !g_player_pinvis[id];
	}
	else if(cid == g_invis_cid[2]) {
		g_player_winvis[id] = !g_player_winvis[id];
	}
	
	return PLUGIN_HANDLED;
}

m_invis(id) {
	new title[32];
	formatex(title, charsmax(title), "%L", id, "QINV_MENUTITLE");
	q_menu_set_title(g_menu, title);
	q_menu_display(id, g_menu);
}

public mf_invis(id, QMenu:menu, item, output[64]) {
	switch(item) {
	case 0: {
		formatex(output, charsmax(output), "%L - %L", id, "QINV_PLAYERS", id, g_player_pinvis[id] ? "Q_ON" : "Q_OFF");
	}
	case 1: {
		formatex(output, charsmax(output), "%L - %L", id, "QINV_WATER", id, g_player_winvis[id] ? "Q_ON" : "Q_OFF");
	}
	}
}

public mh_invis(id, QMenu:menu, item) {
	switch(item) {
	case QMenuItem_Exit: {
		return PLUGIN_HANDLED;
	}
	case 0: { // players
		g_player_pinvis[id] = !g_player_pinvis[id];
	}
	case 1: { // water
		g_player_winvis[id] = !g_player_winvis[id];
	}
	}
	
	m_invis(id);
	
	return PLUGIN_HANDLED;
}
