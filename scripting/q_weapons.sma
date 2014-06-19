#include <amxmodx>
#include <amxmisc>
#include <fun>

#include <q>
#include <q_menu>

#pragma semicolon 1

#define PLUGIN "Q::Weapons"
#define VERSION "1.1"
#define AUTHOR "Quaker"

new QMenu:g_menu_main;
new QMenu:g_menu_pistols;
new QMenu:g_menu_shotguns;
new QMenu:g_menu_smg;
new QMenu:g_menu_rifles;
new QMenu:g_menu_machinegun;
new QMenu:g_menu_sniperrifles;

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	g_menu_main = q_menu_create("Q Weapons", "menu_main_handler");
	q_menu_item_add(g_menu_main, "Pistols");
	q_menu_item_add(g_menu_main, "Shotguns");
	q_menu_item_add(g_menu_main, "SMG");
	q_menu_item_add(g_menu_main, "Rifles");
	q_menu_item_add(g_menu_main, "Machine Gun");
	q_menu_item_add(g_menu_main, "Sniper Rifles");
	
	g_menu_pistols = q_menu_create("Q Weapons \ Pistols", "menu_pistols_handler");
	q_menu_item_add(g_menu_pistols, "USP");
	q_menu_item_add(g_menu_pistols, "Glock");
	q_menu_item_add(g_menu_pistols, "Deagle");
	q_menu_item_add(g_menu_pistols, "Five-Seven");
	q_menu_item_add(g_menu_pistols, "P228 Compact");
	q_menu_item_add(g_menu_pistols, "Dual-Elites");
	
	g_menu_shotguns = q_menu_create("Q Weapons \ Shotguns", "menu_shotguns_handler");
	q_menu_item_add(g_menu_shotguns, "M3");
	q_menu_item_add(g_menu_shotguns, "XM1014");
	
	g_menu_smg = q_menu_create("Q Weapons \ SMG", "menu_smg_handler");
	q_menu_item_add(g_menu_smg, "TMP");
	q_menu_item_add(g_menu_smg, "MP5 Navy");
	q_menu_item_add(g_menu_smg, "Mac-10");
	q_menu_item_add(g_menu_smg, "P90");
	q_menu_item_add(g_menu_smg, "UMP45");
	
	g_menu_rifles = q_menu_create("Q Weapons \ Rifles", "menu_rifles_handler");
	q_menu_item_add(g_menu_rifles, "Famas");
	q_menu_item_add(g_menu_rifles, "AK47");
	q_menu_item_add(g_menu_rifles, "M4A1");
	q_menu_item_add(g_menu_rifles, "Galil");
	q_menu_item_add(g_menu_rifles, "Steyr Aug");
	q_menu_item_add(g_menu_rifles, "Krieg SG-552");
	
	g_menu_machinegun = q_menu_create("Q Weapons \ Machine Gun", "menu_machinegun_handler");
	q_menu_item_add(g_menu_machinegun, "M249");
	
	g_menu_sniperrifles = q_menu_create("Q Weapons \ Sniper Rifles", "menu_sniperrifles_handler");
	q_menu_item_add(g_menu_sniperrifles, "Scout");
	q_menu_item_add(g_menu_sniperrifles, "AWP");
	q_menu_item_add(g_menu_sniperrifles, "G3/SG-1");
	q_menu_item_add(g_menu_sniperrifles, "SG-550");
	
	register_clcmd("say /w", "clcmd_weapons");
	register_clcmd("say /weapons", "clcmd_weapons");
}

public clcmd_weapons(id, level, cid) {
	q_menu_display(id, g_menu_main);
	
	return PLUGIN_HANDLED;
}

public menu_main_handler(id, menu, item) {
	switch(item) {
		case 0: {
			q_menu_display(id, g_menu_pistols);
		}
		case 1: {
			q_menu_display(id, g_menu_shotguns);
		}
		case 2: {
			q_menu_display(id, g_menu_smg);
		}
		case 3: {
			q_menu_display(id, g_menu_rifles);
		}
		case 4: {
			q_menu_display(id, g_menu_machinegun);
		}
		case 5: {
			q_menu_display(id, g_menu_sniperrifles);
		}
	}
}

public menu_pistols_handler(id, menu, item) {
	switch(item) {
		case 0: {
			give_item(id, "weapon_usp");
		}
		case 1: {
			give_item(id, "weapon_glock18");
		}
		case 2: {
			give_item(id, "weapon_deagle");
		}
		case 3: {
			give_item(id, "weapon_fiveseven");
		}
		case 4: {
			give_item(id, "weapon_p228");
		}
		case 5: {
			give_item(id, "weapon_elite");
		}
	}
}

public menu_shotguns_handler(id, menu, item) {
	switch(item) {
		case 0: {
			give_item(id, "weapon_m3");
		}
		case 1: {
			give_item(id, "weapon_xm1014");
		}
	}
}

public menu_smg_handler(id, menu, item) {
	switch(item) {
		case 0: {
			give_item(id, "weapon_tmp");
		}
		case 1: {
			give_item(id, "weapon_mp5navy");
		}
		case 2: {
			give_item(id, "weapon_mac10");
		}
		case 3: {
			give_item(id, "weapon_p90");
		}
		case 4: {
			give_item(id, "weapon_ump45");
		}
	}
}

public menu_rifles_handler(id, menu, item) {
	switch(item) {
		case 0: {
			give_item(id, "weapon_famas");
		}
		case 1: {
			give_item(id, "weapon_ak47");
		}
		case 2: {
			give_item(id, "weapon_m4a1");
		}
		case 3: {
			give_item(id, "weapon_galil");
		}
		case 4: {
			give_item(id, "weapon_aug");
		}
		case 5: {
			give_item(id, "weapon_sg552");
		}
	}
}

public menu_machinegun_handler(id, menu, item) {
	switch(item) {
		case 0: {
			give_item(id, "weapon_m249");
		}
	}
}

public menu_sniperrifles_handler(id, menu, item) {
	switch(item) {
		case 0: {
			give_item(id, "weapon_scout");
		}
		case 1: {
			give_item(id, "weapon_awp");
		}
		case 2: {
			give_item(id, "weapon_g3sg1");
		}
		case 3: {
			give_item(id, "weapon_sg550");
		}
	}
}
