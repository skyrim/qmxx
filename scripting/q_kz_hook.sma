#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#include <q>
#include <q_kz>
#include <q_cookies>
#include <q_menu>

#pragma semicolon 1

#define PLUGIN "Q::KZ::Hook"
#define VERSION "1.2.1"
#define AUTHOR "Quaker"

#define TASKID_HOOKBEAM 4817923

#define HOOK_NO 0
#define HOOK_YES 1
#define HOOK_ACTIVE 2

#define STR_MENUTITLE "QKZHOOK_MENUTITLE"
#define STR_MENUSPEED "QKZHOOK_MENUSPEED"
#define STR_MENUCOLOR "QKZHOOK_MENUCOLOR"
#define STR_WAIT "QKZHOOK_WAIT"
#define STR_NOTAVAIL "QKZHOOK_NOTAVAIL"
#define STR_GIVEHOOK "QKZHOOK_GIVEHOOK"
#define STR_GIVEHOOKCVAR "QKZHOOK_GIVEHOOKCVAR"
#define STR_GIVEHOOKON "QKZHOOK_GIVEHOOKON"
#define STR_GIVEHOOKOFF "QKZHOOK_GIVEHOOKOFF"
#define STR_TERMINATERUN "QKZHOOK_TERMINATERUN"

new g_cookies_failed;

new g_sprite_hook;

new cvar_hook;
new cvar_hook_speed;
new cvar_hook_color;
new cvar_hook_color_random;

new g_player_hook[33];
new g_player_hook_color[33][3];
new Float:g_player_hook_speed[33];
new Float:g_player_hook_origin[33][3];
new Float:g_player_hook_lastused[33];

new QMenu:g_menu_hook;
new QMenu:g_menu_hookspeed;
new QMenu:g_menu_hookcolor;

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

public plugin_precache() {
	g_sprite_hook = precache_model("sprites/zbeam2.spr");
}

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_dictionary("q_kz_hook.txt");
	
	cvar_hook = register_cvar("q_kz_hook", "3");
	cvar_hook_color = register_cvar("q_kz_hook_color", "255 128 64");
	cvar_hook_color_random = register_cvar("q_kz_hook_color_random", "1");
	cvar_hook_speed = register_cvar("q_kz_hook_speed", "600.0");
	
	register_clcmd("say /hook", "clcmd_Hook");
	register_clcmd("say /hookmenu", "clcmd_Hook");
	register_clcmd("say /givehook", "clcmd_GiveHook");
	register_clcmd("+hook", "clcmd_HookOn");
	register_clcmd("-hook", "clcmd_HookOff");
	register_clcmd("HookSpeed", "messagemode_HookSpeed");
	register_clcmd("HookColor", "messagemode_HookColor");
	
	register_forward(FM_PlayerPreThink, "fwd_PlayerPreThink");
	
	q_kz_registerForward(Q_KZ_TimerStart, "forward_KZTimerStart");
	
	g_menu_hook = q_menu_create("Hook", "mh_hook");
	q_menu_item_add(g_menu_hook, "", _, _, _, "mf_hook");
	q_menu_item_add(g_menu_hook, "", _, _, _, "mf_hook");
	
	g_menu_hookspeed = q_menu_create("", "mh_hookspeed");
	q_menu_item_add(g_menu_hookspeed, "", _, _, _, "mf_hookspeed");
	q_menu_item_add(g_menu_hookspeed, "500");
	q_menu_item_add(g_menu_hookspeed, "750");
	q_menu_item_add(g_menu_hookspeed, "1000");
	q_menu_item_add(g_menu_hookspeed, "1250");
	q_menu_item_add(g_menu_hookspeed, "1500");
	
	g_menu_hookcolor = q_menu_create("", "mh_hookcolor");
	q_menu_item_add(g_menu_hookcolor, "", _, _, _, "mf_hookcolor");
	q_menu_item_add(g_menu_hookcolor, "", _, _, _, "mf_hookcolor");
	q_menu_item_add(g_menu_hookcolor, "", _, _, _, "mf_hookcolor");
}

public plugin_cfg() {
	q_registerCvar(cvar_hook, "3", "Set hook mode: 0 - disabled, 1 - vip only, 2 - vip and after finishing map, 3 - always available.");
	q_registerCvar(cvar_hook_color, "255 128 64", "Default hook color.");
	q_registerCvar(cvar_hook_color_random, "1", "Toggle random hook color for players that haven't set it yet.");
	q_registerCvar(cvar_hook_speed, "600.0", "Default hook speed.");
}

public client_putinserver(id) {
	switch(clamp(get_pcvar_num(cvar_hook), 0, 3)) {
	case 0: {
		g_player_hook[id] = HOOK_NO;
	}
	case 1, 2: {
		if(q_kz_player_isVip(id)) {
			g_player_hook[id] = HOOK_YES;
		}
		else {
			g_player_hook[id] = HOOK_NO;
		}
	}
	case 3: {
		g_player_hook[id] = HOOK_YES;
	}
	}
	
	if(g_cookies_failed || !q_get_cookie_float(id, "hook_speed", g_player_hook_speed[id])) {
		g_player_hook_speed[id] = get_pcvar_float(cvar_hook_speed); // default hook speed set by cvar
	}
	g_player_hook_speed[id] = floatclamp(g_player_hook_speed[id], 0.0, 2000.0);
	
	new players_hook_color[12];
	if(!g_cookies_failed && q_get_cookie_string(id, "hook_color", players_hook_color)) {
		new r[4], g[4], b[4];
		parse(players_hook_color, r, 3, g, 3, b, 3);
		g_player_hook_color[id][0] = str_to_num(r);
		g_player_hook_color[id][1] = str_to_num(g);
		g_player_hook_color[id][2] = str_to_num(b);
	}
	else {
		if(get_pcvar_num(cvar_hook_color_random)) {
			g_player_hook_color[id][0] = random_num(0, 255);//clamp(str_to_num(r), 0, 255);
			g_player_hook_color[id][1] = random_num(0, 255);//clamp(str_to_num(g), 0, 255);
			g_player_hook_color[id][2] = random_num(0, 255);//clamp(str_to_num(b), 0, 255);
		}
		else {
			new hook_color[12]; // yes, i see similar variable above, but, this is better practice
			get_pcvar_string(cvar_hook_color, hook_color, charsmax(hook_color));
			new r[4], g[4], b[4];
			parse(hook_color, r, 3, g, 3, b, 3);
			g_player_hook_color[id][0] = str_to_num(r);
			g_player_hook_color[id][1] = str_to_num(g);
			g_player_hook_color[id][2] = str_to_num(b);
		}
	}
}

public client_infochanged(id) {
	new hook = get_pcvar_num(cvar_hook);
	if((hook == 3) || ((hook != 0) && q_kz_player_isVip(id))) {
		g_player_hook[id] = HOOK_YES;
	}
}

public client_disconnect(id) {
	if(!g_cookies_failed) {
		q_set_cookie_float(id, "hook_speed", g_player_hook_speed[id]);
		
		new players_hook_color[12];
		formatex(players_hook_color, charsmax(players_hook_color), "%d %d %d",
			g_player_hook_color[id][0],
			g_player_hook_color[id][1],
			g_player_hook_color[id][2]);
		q_set_cookie_string(id, "hook_color", players_hook_color);
	}
}

public fwd_PlayerPreThink(id) {
	static Float:origin[3];
	static Float:velocity[3];
	
	if(g_player_hook[id] & HOOK_ACTIVE) {
		pev(id, pev_origin, origin);
		
		xs_vec_sub(g_player_hook_origin[id], origin, velocity);
		xs_vec_normalize(velocity, velocity);
		xs_vec_mul_scalar(velocity, g_player_hook_speed[id], velocity);
		
		set_pev(id, pev_velocity, velocity);
	}
}

public forward_KZTimerStart(id) {
	if(g_player_hook[id] & HOOK_ACTIVE) {
		clcmd_HookOff(id);
	}
	
	if((get_gametime() - g_player_hook_lastused[id]) < 3.0) {
		q_kz_print(id, "%L", id, STR_WAIT);
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public reward_Hook_handler(id) {
	g_player_hook[id] = HOOK_YES;
}

public reward_HookItem_callback(id) {
	if(g_player_hook[id] & HOOK_YES) {
		return ITEM_DISABLED;
	}
	else {
		return ITEM_ENABLED;
	}
	
	return ITEM_DISABLED;
}

public clcmd_HookOn(id) {
	if(!is_user_alive(id)) {
		return PLUGIN_HANDLED;
	}
	
	new hook = get_pcvar_num(cvar_hook);
	if((hook == 0) || ((hook == 1) && !q_kz_player_isVip(id))) {
		q_kz_print(id, "%L", id, "QKZ_CMD_DISABLED");
		
		return PLUGIN_HANDLED;
	}
	
	if(!g_player_hook[id]) {
		q_kz_print(id, "%L", id, STR_NOTAVAIL);
		
		return PLUGIN_HANDLED;
	}
	
	q_kz_player_stopTimer(id, "%L", id, STR_TERMINATERUN);
	
	g_player_hook_lastused[id] = get_gametime();
	
	g_player_hook[id] |= HOOK_ACTIVE;
	fm_get_aim_origin(id, g_player_hook_origin[id]);
	
	message_te_hook(id, 0x1000);
	
	set_task(5.0, "task_HookBeam", id + TASKID_HOOKBEAM, _, _, "b");
	
	return PLUGIN_HANDLED;
}

public clcmd_HookOff(id) {
	g_player_hook[id] &= ~HOOK_ACTIVE;
	
	message_te_killbeam(id | 0x1000);
	
	if(task_exists(id + TASKID_HOOKBEAM)) {
		remove_task(id + TASKID_HOOKBEAM);
	}
	
	return PLUGIN_HANDLED;
}

public clcmd_Hook(id) {
	m_hook(id);
	
	return PLUGIN_HANDLED;
}

public clcmd_GiveHook(id) {
	if(!q_kz_player_isVip(id)) {
		return PLUGIN_CONTINUE;
	}
	
	if(get_pcvar_num(cvar_hook) != 2) {
		q_kz_print(id, "%L", id, STR_GIVEHOOKCVAR);
	}
	else {
		m_givehook(id);
	}
	
	return PLUGIN_HANDLED;
}

m_hook(id) {
	new title[32];
	formatex(title, charsmax(title), "%L", id, STR_MENUTITLE);
	q_menu_set_title(g_menu_hook, title);
	q_menu_display(id, g_menu_hook);
}

public mf_hook(id, QMenu:menu, item, output[64]) {
	switch(item) {
	case 0: { // speed
		formatex(output, charsmax(output), "%L \y(%d)",
			id, STR_MENUSPEED,
			floatround(g_player_hook_speed[id]));
	}
	case 1: { // color
		formatex(output, charsmax(output), "%L \y(%d %d %d)",
			id, STR_MENUCOLOR,
			g_player_hook_color[id][0],
			g_player_hook_color[id][1],
			g_player_hook_color[id][2]);
	}
	}
}

public mh_hook(id, QMenu:menu, item) {
	switch(item) {
	case 0: { // speed
		m_hookspeed(id);
	}
	case 1: { // color
		m_hookcolor(id);
	}
	}
	
	return PLUGIN_HANDLED;
}

m_hookspeed(id) {
	new title[32];
	formatex(title, charsmax(title), "%L", id, STR_MENUSPEED);
	q_menu_set_title(g_menu_hookspeed, title);
	q_menu_display(id, g_menu_hookspeed);
}

public mf_hookspeed(id, QMenu:menu, item, output[64]) {
	switch(item) {
	case 0: {
		formatex(output, charsmax(output), "%L", id, "Q_CUSTOM");
	}
	}
}

public mh_hookspeed(id, QMenu:menu, item) {
	switch(item) {
	case 0: {
		client_cmd(id, "messagemode HookSpeed");
		return PLUGIN_HANDLED;
	}
	case 1: {
		g_player_hook_speed[id] = 500.0;
	}
	case 2: {
		g_player_hook_speed[id] = 750.0;
	}
	case 3: {
		g_player_hook_speed[id] = 1000.0;
	}
	case 4: {
		g_player_hook_speed[id] = 1250.0;
	}
	case 5: {
		g_player_hook_speed[id] = 1500.0;
	}
	}
	
	m_hook(id);
	
	return PLUGIN_HANDLED;
}

m_hookcolor(id) {
	new title[32];
	formatex(title, charsmax(title), "%L", id, STR_MENUCOLOR);
	q_menu_set_title(g_menu_hookcolor, title);
	q_menu_display(id, g_menu_hookcolor);
}

public mf_hookcolor(id, QMenu:menu, item, output[64]) {
	switch(item) {
	case 0: { // custom
		formatex(output, charsmax(output), "%L", id, "Q_CUSTOM");
	}
	case 1: { // pink
		formatex(output, charsmax(output), "%L \d(255 0 255)", id, "Q_PINK");
	}
	case 2: { // yellow
		formatex(output, charsmax(output), "%L \d(255 255 0)", id, "Q_YELLOW");
	}
	}
}

public mh_hookcolor(id, QMenu:menu, item) {
	switch(item) {
	case 0: {
		client_cmd(id, "messagemode HookColor");
		return PLUGIN_HANDLED;
	}
	case 1: {
		g_player_hook_color[id] = {255, 0, 255};
	}
	case 2: {
		g_player_hook_color[id] = {255, 255, 0};
	}
	}
	
	m_hook(id);
	
	return PLUGIN_HANDLED;
}

public m_givehook(id) {
	new title[32];
	formatex(title, charsmax(title), "%L", id, STR_GIVEHOOK);
	new QMenu:menu = q_menu_create(title, "mh_givehook");
	
	new itemname[32];
	new itemdata[3];
	for(new i = 1, playerCount = get_maxplayers(); i < playerCount; ++i) {
		if(!is_user_connected(i)) {
			continue;
		}
		
		get_user_name(i, itemname, charsmax(itemname));
		if(g_player_hook[i]) {
			formatex(itemname, charsmax(itemname), "%s: %L", itemname, id, "Q_ON");
		}
		else {
			formatex(itemname, charsmax(itemname), "%s: %L", itemname, id, "Q_OFF");
		}
		num_to_str(i, itemdata, charsmax(itemdata));
		q_menu_item_add(menu, itemname, itemdata);
	}
	
	q_menu_display(id, menu);
}

public mh_givehook(id, QMenu:menu, item) {
	switch(item) {
	case QMenuItem_Exit, QMenuItem_Back, QMenuItem_Next: {
	}
	default: {
		new data[3];
		q_menu_item_get_data(menu, item, data, charsmax(data));
		
		new message[128];
		
		new pickedPlayerId = str_to_num(data);
		if(is_user_connected(pickedPlayerId)) {
			g_player_hook[pickedPlayerId] = !g_player_hook[pickedPlayerId];
			
			new pickedPlayerName[32];
			get_user_name(pickedPlayerId, pickedPlayerName, charsmax(pickedPlayerName));
			
			formatex(message, charsmax(message), "%L",
				pickedPlayerId,
				g_player_hook[pickedPlayerId] ? STR_GIVEHOOKON : STR_GIVEHOOKOFF);
			replace_all(message, charsmax(message), "^"name^"", pickedPlayerName);
			client_print(pickedPlayerId, print_chat, "%s", message);
			
			m_givehook(id);
		}
	}
	}
	
	q_menu_destroy(menu);
	
	return PLUGIN_HANDLED;
}

public messagemode_HookSpeed(id) {
	new szSpeed[8];
	
	read_args(szSpeed, charsmax(szSpeed));
	remove_quotes(szSpeed);
	
	g_player_hook_speed[id] = str_to_float(szSpeed);
	
	m_hook(id);
	
	return PLUGIN_HANDLED;
}

public messagemode_HookColor(id) {
	new szColor[15], szRed[4], szGreen[4], szBlue[4];
	
	read_args(szColor, charsmax(szColor));
	remove_quotes(szColor);
	parse(szColor, szRed, 3, szGreen, 3, szBlue, 3);
	
	g_player_hook_color[id][0] = str_to_num(szRed);
	g_player_hook_color[id][1] = str_to_num(szGreen);
	g_player_hook_color[id][2] = str_to_num(szBlue);
	
	m_hook(id);
	
	return PLUGIN_HANDLED;
}

fm_get_aim_origin(id, Float:origin[3]) {
	new Float:start[3], Float:view_ofs[3];
	
	pev(id, pev_origin, start);
	pev(id, pev_view_ofs, view_ofs);
	xs_vec_add(start, view_ofs, start);

	new Float:dest[3];
	
	pev(id, pev_v_angle, dest);
	engfunc(EngFunc_MakeVectors, dest);
	global_get(glb_v_forward, dest);
	xs_vec_mul_scalar(dest, 9999.0, dest);
	xs_vec_add(start, dest, dest);

	engfunc(EngFunc_TraceLine, start, dest, IGNORE_MONSTERS, id, 0);
	get_tr2(0, TR_vecEndPos, origin);

	return 1;
}

public task_HookBeam(id) {
	id -= TASKID_HOOKBEAM;
	
	message_te_hook(id, 0x1000);
}

message_te_hook(id, attpoint = 0) {
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMENTPOINT);
	write_short(id | attpoint);					// entity ID
	write_coord(floatround(g_player_hook_origin[id][0]));	// X Origin
	write_coord(floatround(g_player_hook_origin[id][1]));	// Y Origin
	write_coord(floatround(g_player_hook_origin[id][2]));	// Z Origin
	write_short(g_sprite_hook);				// sprite handle
	write_byte(0); 					// starting frame
	write_byte(0); 					// frame rate in 0.1s
	write_byte(50);					// life in 0.1s
	write_byte(10); 					// line width in 0.1s
	write_byte(0); 					// noise amplitude in 0.01s
	write_byte(g_player_hook_color[id][0]);		// red
	write_byte(g_player_hook_color[id][1]);		// green
	write_byte(g_player_hook_color[id][2]);		// blue
	write_byte(200);					// brigtness
	write_byte(5);					// scroll speed in 0.1s
	message_end();
}

message_te_killbeam(id, attpoint = 0) {
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_KILLBEAM);
	write_short(id | attpoint);
	message_end();
}
