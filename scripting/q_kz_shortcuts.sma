#include <amxmodx>
#include <fakemeta>

#include <q>
#include <q_menu>
#include <q_kz>

#pragma semicolon 1

#define PLUGIN "Q::KZ::Shortcuts"
#define VERSION "2.0 alpha"
#define AUTHOR "Quaker"

new QMenu:g_menu_list;
new QMenu:g_menu_admin;

new g_player_cameraEntity[33] = {-1, ...};
new g_player_currentlyViewing[33] = {-1, ...};
new g_player_currentlyEditting[33] = {-1, ...};

new g_shortcut_count;
new Array:g_shortcut_name;
new Array:g_shortcut_origin;
new Array:g_shortcut_angle;

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	g_shortcut_name = ArrayCreate(16, 1);
	g_shortcut_origin = ArrayCreate(3, 1);
	g_shortcut_angle = ArrayCreate(3, 1);
	
	g_menu_list = q_menu_create("Shortcuts");
	g_menu_admin = q_menu_create("Shortcuts", "mh_shortcut_admin");
	q_menu_item_add(g_menu_admin, "Add");
	q_menu_item_add(g_menu_admin, "Edit");
	q_menu_item_add(g_menu_admin, "Remove");
	
	register_clcmd("say /sc", "clcmd_sc");
	register_clcmd("say /modsc", "clcmd_modsc");
	register_clcmd("ShortcutName", "clcmd_ShortcutName");
}

public client_putinserver(id) {
	shortcut_camera_create(id);
}

public client_disconnect(id) {
	shortcut_camera_destroy(id);
}

shortcut_camera_create(id) {
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "trigger_camera"));
	set_pev(ent, pev_solid, SOLID_TRIGGER);
	set_pev(ent, pev_movetype, MOVETYPE_FLYMISSILE);
	engfunc(EngFunc_SetModel, ent, "models/w_usp.mdl");
	set_pev(ent, pev_rendermode, kRenderTransTexture);
	set_pev(ent, pev_renderamt, 0.0 );
	
	g_player_cameraEntity[id] = ent;
}

shortcut_camera_destroy(id) {
	engfunc(EngFunc_RemoveEntity, g_player_cameraEntity[id]);
	g_player_cameraEntity[id] = -1;
}

shortcut_add(name[], Float:origin[3], Float:angle[3]) {
	ArrayPushString(g_shortcut_name, name);
	ArrayPushArray(g_shortcut_origin, origin);
	ArrayPushArray(g_shortcut_angle, angle);
	q_menu_item_add(g_menu_list, name);
	
	g_shortcut_count++;
}

shortcut_setName(shortcutIndex, name[]) {
	ArraySetString(g_shortcut_name, shortcutIndex, name);
	q_menu_item_set_name(g_menu_list, shortcutIndex, name);
}

shortcut_setOrigin(shortcutIndex, Float:origin[3]) {
	ArraySetArray(g_shortcut_origin, shortcutIndex, origin);
}

shortcut_setAngle(shortcutIndex, Float:angle[3]) {
	ArraySetArray(g_shortcut_angle, shortcutIndex, angle);
}

shortcut_remove(id) {
	ArrayDeleteItem(g_shortcut_name, id);
	ArrayDeleteItem(g_shortcut_origin, id);
	ArrayDeleteItem(g_shortcut_angle, id);
	q_menu_item_remove(g_menu_list, id);
	
	g_shortcut_count--;
}

shortcut_view(id, shortcutIndex) {
	new camera = g_player_cameraEntity[id];
	
	new Float:origin[3];
	ArrayGetArray(g_shortcut_origin, shortcutIndex, origin);
	set_pev(camera, pev_origin, origin);
	
	new Float:angle[3];
	ArrayGetArray(g_shortcut_angle, shortcutIndex, angle);
	set_pev(camera, pev_angles, angle);
	set_pev(camera, pev_v_angle, angle);
	
	engfunc(EngFunc_SetView, id, camera);
	
	g_player_currentlyViewing[id] = shortcutIndex;
}

shortcut_resetView(id) {
	g_player_currentlyViewing[id] = -1;
	engfunc(EngFunc_SetView, id, id);
}

public clcmd_sc(id, level, cid) {
	if(g_shortcut_count > 0) {
		m_shortcut_view(id);
	}
	else {
		client_print(id, print_chat, "Shortcuts not found on this map.");
	}
	
	return PLUGIN_HANDLED;
}

m_shortcut_view(id) {
	q_menu_display(id, g_menu_list, _, _, "mh_shortcut_view");
}

public mh_shortcut_view(id, menu, item) {
	switch(item) {
	case QMenuItem_Exit: {
		shortcut_resetView(id);
		
		return PLUGIN_CONTINUE;
	}
	case QMenuItem_Back, QMenuItem_Next: {
		return PLUGIN_CONTINUE;
	}
	default: {
		shortcut_view(id, item);
		
		m_shortcut_view(id);
	}
	}
	
	return PLUGIN_HANDLED;
}

public clcmd_modsc(id, level, cid) {
	if(get_user_flags(id) & ADMIN_BAN) {
		m_shortcut_admin(id);
	}
	else {
		return PLUGIN_CONTINUE;
	}
	
	return PLUGIN_HANDLED;
}

m_shortcut_admin(id) {
	q_menu_display(id, g_menu_admin, _, _, "mh_shortcut_admin");
}

public mh_shortcut_admin(id, menu, item) {
	switch(item) {
	case QMenuItem_Exit: {
		return PLUGIN_CONTINUE;
	}
	case QMenuItem_Back, QMenuItem_Next: {
		return PLUGIN_CONTINUE;
	}
	default: {
		switch(item) {
		case 0: {
			m_shortcut_add(id);
			
			m_shortcut_admin(id);
		}
		case 1: {
			m_shortcut_pickEdit(id);
		}
		case 2: {
			m_shortcut_remove(id);
		}
		}
	}
	}
	
	return PLUGIN_HANDLED;
}

m_shortcut_add(id) {
	new name[16];
	formatex(name, charsmax(name), "Shortcut #%d", g_shortcut_count);
	
	new Float:origin[3];
	pev(id, pev_origin, origin);
	
	new Float:angle[3];
	pev(id, pev_v_angle, angle);
	
	shortcut_add(name, origin, angle);
}

m_shortcut_pickEdit(id) {
	q_menu_display(id, g_menu_list, _, _, "mh_shortcut_pickEdit");
}

public mh_shortcut_pickEdit(id, menu, item) {
	switch(item) {
	case QMenuItem_Exit, QMenuItem_Back, QMenuItem_Next: {
		return PLUGIN_CONTINUE;
	}
	default: {
		m_shortcut_edit(id, item);
	}
	}
	
	return PLUGIN_HANDLED;
}

m_shortcut_edit(id, item) {
	new QMenu:menu = q_menu_create("Edit shortcut", "mh_shortcut_edit");
	g_player_currentlyEditting[id] = item;
	
	new buffer[128];
	
	new name[16];
	ArrayGetString(g_shortcut_name, item, name, charsmax(name));
	formatex(buffer, charsmax(buffer), "Set name: %s", name);
	q_menu_item_add(menu, buffer);
	
	new Float:origin[3];
	ArrayGetArray(g_shortcut_origin, item, origin);
	new Float:angle[3];
	ArrayGetArray(g_shortcut_angle, item, angle);
	q_menu_item_add(menu, "Change origin and angle");
	formatex(buffer, charsmax(buffer), "\dx:%.2f y:%.2f z:%.2f",
		origin[0], origin[1], origin[2]);
	q_menu_item_add(menu, buffer, _, false);
	formatex(buffer, charsmax(buffer), "\dy:%.2f p:%.2f r:%.2f",
		angle[0], angle[1], angle[2]);
	q_menu_item_add(menu, buffer, _, false);
	q_menu_display(id, menu);
}

public mh_shortcut_edit(id, QMenu:menu, item) {
	switch(item) {
	case QMenuItem_Exit: {
		m_shortcut_admin(id);
		
		return PLUGIN_CONTINUE;
	}
	case QMenuItem_Back, QMenuItem_Next: {
		return PLUGIN_CONTINUE;
	}
	case 0: { // set name
		client_cmd(id, "messagemode ShortcutName");
	}
	case 1: {
		new scid = g_player_currentlyEditting[id];
		
		new Float:origin[3];
		pev(id, pev_origin, origin);
		shortcut_setOrigin(scid, origin);
		
		new Float:angle[3];
		pev(id, pev_v_angle, angle);
		shortcut_setAngle(scid, angle);
		
		m_shortcut_edit(id, scid);
	}
	}
	
	q_menu_destroy(menu);
	
	return PLUGIN_HANDLED;
}

public clcmd_ShortcutName(id, level, cid) {
	new name[20];
	read_args(name, charsmax(name));
	remove_quotes(name);
	
	new scid = g_player_currentlyEditting[id];
	
	shortcut_setName(scid, name);
	
	m_shortcut_edit(id, scid);
	
	return PLUGIN_HANDLED;

}

m_shortcut_remove(id) {
	q_menu_display(id, g_menu_list, _, _, "mh_shortcut_remove");
}

public mh_shortcut_remove(id, menu, item) {
	switch(item) {
	case QMenuItem_Exit: {
		m_shortcut_admin(id);
		
		return PLUGIN_CONTINUE;
	}
	case QMenuItem_Back, QMenuItem_Next: {
		return PLUGIN_CONTINUE;
	}
	default: {
		shortcut_remove(item);
		
		m_shortcut_remove(id);
	}
	}
	
	return PLUGIN_HANDLED;
}
