#include <amxmodx>
#include <fakemeta>

#include <q>

#pragma semicolon 1

#define PLUGIN "Q::Nightvision"
#define VERSION "1.1b"
#define AUTHOR "Quaker"

new g_cvar_nightvision;
new g_cvar_nightvision_type;

new g_player_nightvision[33];

new g_forward_LightStyle;

new g_map_defaultLightStyle[32];

public plugin_precache() {
	g_forward_LightStyle = register_forward(FM_LightStyle, "forward_LightStyle");
}

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	g_cvar_nightvision = register_cvar("q_nightvision", "1");
	g_cvar_nightvision_type = register_cvar("q_nightvision_type", "1");
	
	unregister_forward(FM_LightStyle, g_forward_LightStyle);
	register_forward(FM_AddToFullPack, "forward_AddToFullPack", 1);
	
	register_clcmd("nightvision", "clcmd_nightvision");
}

public plugin_cfg() {
	q_registerCvar(g_cvar_nightvision, "1", "Toggle nightvision plugin.");
	q_registerCvar(g_cvar_nightvision_type, "1", "Set nightvision type:^n1 - Light area around the player^n2 - Change map light style. Do not use this if there is another plugin that messes with the map light style (e.g. zombie mods).");
}

public client_connect(id) {
	g_player_nightvision[id] = false;
}

public clcmd_nightvision(id, level, cid) {
	switch(get_pcvar_num(g_cvar_nightvision_type)) {
	case 1: {
		toggle_typeOne(id);
	}
	case 2: {
		toggle_typeTwo(id);
	}
	default: {
		log_amx("Error! Invalid q_nightvision_type cvar value. Using default nightvision type.");
		toggle_typeOne(id);
	}
	}
	
	return PLUGIN_HANDLED;
}

toggle_typeOne(id) {
	if(!get_pcvar_num(g_cvar_nightvision)) {
		switch(g_player_nightvision[id]) {
		case 1: {
			g_player_nightvision[id] = false;
		}
		case 2: {
			g_player_nightvision[id] = false;
			
			message_begin(MSG_ONE_UNRELIABLE, SVC_LIGHTSTYLE, _, id);
			write_byte(0);
			write_string(g_map_defaultLightStyle);
			message_end();
		}
		}
		
		return;
	}
	
	switch(g_player_nightvision[id]) {
	case 0: {
		g_player_nightvision[id] = 1;
	}
	case 1: {
		g_player_nightvision[id] = 0;
	}
	case 2: {
		g_player_nightvision[id] = 0;
		
		message_begin(MSG_ONE_UNRELIABLE, SVC_LIGHTSTYLE, _, id);
		write_byte(0);
		write_string(g_map_defaultLightStyle);
		message_end();
	}
	}
}

toggle_typeTwo(id) {
	if(!get_pcvar_num(g_cvar_nightvision)) {
		switch(g_player_nightvision[id]) {
		case 1: {
			g_player_nightvision[id] = false;
		}
		case 2: {
			g_player_nightvision[id] = false;
			
			message_begin(MSG_ONE_UNRELIABLE, SVC_LIGHTSTYLE, _, id);
			write_byte(0);
			write_string(g_map_defaultLightStyle);
			message_end();
		}
		}
		
		return;
	}
	
	switch(g_player_nightvision[id]) {
	case 0: {
		g_player_nightvision[id] = 2;
		
		message_begin(MSG_ONE_UNRELIABLE, SVC_LIGHTSTYLE, _, id);
		write_byte(0);
		write_string("#");
		message_end();
	}
	case 1: {
		g_player_nightvision[id] = 0;
	}
	case 2: {
		g_player_nightvision[id] = 0;
		
		message_begin(MSG_ONE_UNRELIABLE, SVC_LIGHTSTYLE, _, id);
		write_byte(0);
		write_string(g_map_defaultLightStyle);
		message_end();
	}
	}
}

public forward_AddToFullPack(es_handle, e, ent, host, hostflags, player, pset) {
	if(player && (g_player_nightvision[host] == 1) && (ent == host)) {
		set_es(es_handle, ES_Effects, get_es(es_handle, ES_Effects) | EF_BRIGHTLIGHT);
	}
}

public forward_LightStyle(style, const value[]) {
	if(!style) {
		copy(g_map_defaultLightStyle, charsmax(g_map_defaultLightStyle), value);
	}
}