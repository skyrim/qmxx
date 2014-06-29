#include <amxmodx>
#include <fakemeta>

#pragma semicolon 1

#define PLUGIN "Q::Nightvision"
#define VERSION "1.0"
#define AUTHOR "Quaker"

new g_player_nightvision[33];

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_forward(FM_AddToFullPack, "fwd_AddToFullPack", 1);
	
	register_clcmd("nightvision", "clcmd_nightvision");
}

public client_connect(id) {
	g_player_nightvision[id] = false;
}

public clcmd_nightvision(id, level, cid) {
	g_player_nightvision[id] = !g_player_nightvision[id];
	
	return PLUGIN_HANDLED;
}

public fwd_AddToFullPack(es_handle, e, ent, host, hostflags, player, pset) {
	if(player && g_player_nightvision[host] && (ent == host)) {
		set_es(es_handle, ES_Effects, get_es(es_handle, ES_Effects) | EF_BRIGHTLIGHT);
	}
}
