//   To do:
// - create irc module
// - Duel System & Duel Rank
// - Cup System & Cup Rank

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#include <q>
#include <q_cookies>
#include <q_kz>
#include <q_menu>

#pragma dynamic 32768
#pragma semicolon 1

#define PLUGIN  "Q::KZ"
#define VERSION "1.4b"
#define AUTHOR  "Quaker"

#define SET_BITVECTOR(%1,%2) (%1[%2>>5] |=  (1<<(%2 & 31)))
#define GET_BITVECTOR(%1,%2) (%1[%2>>5] &   (1<<(%2 & 31)))
#define CLR_BITVECTOR(%1,%2) (%1[%2>>5] &= ~(1<<(%2 & 31)))

#define MAX_PLAYERS 32
#define MAX_ENTS (900 + (MAX_PLAYERS * 15))
#define MAX_ENTS_BITVECTOR ((MAX_ENTS / 32) + _:!!(MAX_ENTS % 32))

#define EXTRA_OFFSET 5
#define EXTRA_OFFSET_WEAPONS 4

#define OFFSET_RADIO 192

#if cellbits == 32
	#define OFFSET_CLIPAMMO	51
	#define OFFSET_TEAM 114
	#define OFFSET_INTERNALMODEL 126
	#define OFFSET_BUYZONE 235
	#define OFFSET_CSDEATHS	444
#else
	#define OFFSET_CLIPAMMO	65
	#define OFFSET_TEAM 139
	#define OFFSET_INTERNALMODEL 152
	#define OFFSET_BUYZONE 268
	#define OFFSET_CSDEATHS	493
#endif

#define TASKID_ROUNDTIME 5550
#define TASKID_RESPAWN 5800
#define TASKID_DOWNLOAD	6000
#define TASKID_JOINTEAM	6100
#define TASKID_JOINCLASS 6150

#define SCOREATTRIB_NONE 0
#define SCOREATTRIB_DEAD 1
#define SCOREATTRIB_BOMB 2
#define SCOREATTRIB_VIP 4

#define HIDEW_CH_AMMO_WLIST 1
#define HIDEW_FLASHLIGHT 2
#define HIDEW_ALL 4
#define HIDEW_RADAR_HP_AP 8
#define HIDEW_TIMER 16
#define HIDEW_MONEY 32
#define HIDEW_CROSSHAIR 64
#define HIDEW_PLUS 128

#define STR_ON "Q_ON"
#define STR_OFF "Q_OFF"
#define STR_REWARDS "QKZ_REWARDS"
#define STR_WELCOME "QKZ_WELCOME"
#define STR_ENTERGAME "QKZ_ENTER_GAME"
#define STR_ENTERSPEC "QKZ_ENTER_SPEC"
#define STR_RESPAWNNOTICE "QKZ_RESPAWN_IN_TIME"
#define STR_SUICIDE "QKZ_SUICIDE"
#define STR_DROP "QKZ_DROP"
#define STR_RUNSTARTED "QKZ_RUN_STARTED"
#define STR_RUNSTOPPED "QKZ_RUN_STOPPED"
#define STR_WEAPONSPEED "QKZ_WEAPON_SPEED"
#define STR_CMDDISABLED "QKZ_CMD_DISABLED"
#define STR_NOTINRUN "QKZ_NOT_IN_RUN"
#define STR_NOTALIVE "QKZ_NOT_ALIVE"
#define STR_NOTONGROUND "QKZ_NOT_ONGROUND"
#define STR_NOTWHILERUN "QKZ_NOT_WHILE_RUN"
#define STR_NOTWHILEPAUSE "QKZ_NOT_WHILE_PAUSE"
#define STR_NOCHECKPOINTS "QKZ_NO_CHECKPOINTS"
#define STR_NOTENOUGHCHECKPOINTS "QKZ_NOT_ENOUGH_CHECKPOINTS"
#define STR_TELEPORTTOSTART "QKZ_TELEPORT_TO_START"
#define STR_TELEPORTTOEND "QKZ_TELEPORT_TO_END"
#define STR_NOSTARTPOS "QKZ_NO_START_POS"
#define STR_NOENDPOS "QKZ_NO_END_POS"
#define STR_RUNPAUSED "QKZ_RUN_PAUSED"
#define STR_RUNUNPAUSED "QKZ_RUN_UNPAUSED"
#define STR_CUSTOMSTARTSET "QKZ_CUSTOM_START_SET"
#define STR_CUSTOMSTARTUNSET "QKZ_CUSTOM_START_UNSET"
#define STR_WELCOMEPLAY "QKZ_WELCOMEPLAY"
#define STR_WELCOMESPEC "QKZ_WELCOMESPEC"
#define STR_CHECKPOINT "QKZ_CHECKPOINT"
#define STR_TELEPORT "QKZ_TELEPORT"
#define STR_UNSTUCK "QKZ_UNSTUCK"
#define STR_START "QKZ_START"
#define STR_PAUSE "QKZ_PAUSE"
#define STR_UNPAUSE "QKZ_UNPAUSE"
#define STR_STOP "QKZ_STOP"
#define STR_TIMERSAVED "QKZ_TIMERSAVED"
#define STR_NOSAVEDTIMER "QKZ_NOSAVEDTIMER"

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* Global Variables
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

new g_cookies_failed;

new cvar_Checkpoints;
new cvar_CheckpointAngles;
new cvar_TeleportSplash;
new cvar_Pause;
new cvar_GodMode;
new cvar_Noclip;
new cvar_Semiclip;
new cvar_SemiclipAlpha;
new cvar_PrintType;
new cvar_PrintColor;
new cvar_PrintPos;
new cvar_Respawn;
new cvar_RespawnTime;
new cvar_Weapons;
new cvar_WeaponsSpeed;
new cvar_WeaponsAmmo;
new cvar_Prefix;
new cvar_HPBug;
new cvar_SpawnWithMenu;
new cvar_VipFlags;
new cvar_Rewards;
new g_cvar_command_save;

new g_dir_data[128];
new g_dir_config[128];
new g_file_buttons[80];
new g_file_config[80];
new g_file_spawns[80];

new g_plugin_Name[32];

new g_server_Name[32];

new g_map_Name[32];
new g_map_Spawns;
new g_map_SpawnCount;
new g_map_SpawnsNeeded;
new g_map_HealerExists;
new g_map_ent_StartButton[MAX_ENTS_BITVECTOR];
new g_map_ent_EndButton[MAX_ENTS_BITVECTOR];

new QMenu:g_menu_welcome;
new QMenu:g_menu_chooseteam;
new QMenu:g_menu_kreedz;

new g_start_bDefault;
new Float:g_start_vDefault[3];
new g_end_bDefault;
new Float:g_end_vDefault[3];
new g_start_bCurrent[MAX_PLAYERS + 1];
new Float:g_start_vCurrent[MAX_PLAYERS + 1][3];
new g_start_bCustom[MAX_PLAYERS + 1];
new Float:g_start_vCustom[MAX_PLAYERS + 1][3];

new g_rewards_registering;
new Array:g_rewards_name;
new Array:g_rewards_plugin;
new Array:g_rewards_handler;
new Array:g_rewards_callback;

new Array:g_startButtonEntities;
new Array:g_stopButtonEntities;

new g_player_ingame[MAX_PLAYERS + 1];
new g_player_Connected[MAX_PLAYERS + 1];
new g_player_Alive[MAX_PLAYERS + 1];
new g_player_VIP[MAX_PLAYERS + 1];
new g_player_Welcome[MAX_PLAYERS + 1];
new g_player_stripping[MAX_PLAYERS + 1];
new g_player_Name[MAX_PLAYERS + 1][32];
new g_player_MaxSpeed[MAX_PLAYERS + 1];
new g_player_God[MAX_PLAYERS + 1];
new g_player_Noclip[MAX_PLAYERS + 1];
new g_player_CPcounter[MAX_PLAYERS + 1];
new g_player_TPcounter[MAX_PLAYERS + 1];
new g_player_setting_CPangles[MAX_PLAYERS + 1];
new Float:g_player_CPorigin[MAX_PLAYERS + 1][2][3];
new Float:g_player_CPangles[MAX_PLAYERS + 1][2][3];
new g_player_ClipAmmo[MAX_PLAYERS + 1];
new g_player_BackAmmo[MAX_PLAYERS + 1];
new g_player_SpecID[MAX_PLAYERS + 1];
new g_player_run_Running[MAX_PLAYERS + 1];
new g_player_run_Paused[MAX_PLAYERS + 1];
new g_player_run_WeaponID[MAX_PLAYERS + 1];
new Float:g_player_run_StartTime[MAX_PLAYERS + 1];
new Float:g_player_run_PauseTime[MAX_PLAYERS + 1];
new bool:g_player_psave_exists[33];
new Float:g_player_psave_time[33];
new g_player_psave_checkpoints[33];
new g_player_psave_teleports[33];
new g_player_psave_weapon[33];
new Float:g_player_psave_origin[33][3];

new Array:forward_TimerStart_pre;
new Array:forward_TimerStart_post;
new Array:forward_TimerStop_pre;
new Array:forward_TimerStop_post;
new Array:forward_TimerPause_pre;
new Array:forward_TimerPause_post;
new Array:forward_OnCheckpoint_pre;
new Array:forward_OnCheckpoint_post;
new Array:forward_OnTeleport_pre;
new Array:forward_OnTeleport_post;

new g_msg_Health;
new g_msg_SayText;
new g_msg_ScoreAttrib;
new g_msg_TeamInfo;
new g_msg_AmmoPickup;
new g_msg_WeapPickup;
new g_msg_HideWeapon;
new g_msg_ScreenFade;
new g_msg_RoundTime;
new g_msg_StatusIcon;
new g_msg_Crosshair;
new g_msg_ClCorpse;
new g_msg_VGUIMenu;
new g_msg_ShowMenu;

new const FL_ONGROUND2 = (FL_ONGROUND | FL_PARTIALGROUND | FL_INWATER | FL_CONVEYOR | FL_FLOAT);

new const g_szRemoveEnts[][] = {
	"func_bomb_target", "info_bomb_target", "hostage_entity",
	"monster_scientist", "func_hostage_rescue", "info_hostage_rescue",
	"info_vip_start", "func_vip_safetyzone", "func_escapezone",
	"armoury_entity", "game_player_equip", "player_weaponstrip",
	"info_deathmatch_start"
};

enum CsTeams {
	CS_TEAM_UNASSIGNED = 0,
	CS_TEAM_T,
	CS_TEAM_CT,
	CS_TEAM_SPECTATOR
};

enum CsInternalModel {
	CS_DONTCHANGE = 0,
	CS_CT_URBAN,
	CS_T_TERROR,
	CS_T_LEET,
	CS_T_ARCTIC,
	CS_CT_GSG9,
	CS_CT_GIGN,
	CS_CT_SAS,
	CS_T_GUERILLA,
	CS_CT_VIP,
	CZ_T_MILITIA,
	CZ_CT_SPETSNAZ
};

new const g_sz_WeaponEntName[][] = {
	"",
	"p228",
	"shield",
	"scout",
	"hegrenade",
	"xm1014",
	"c4",
	"mac10",
	"aug",
	"smokegrenade",
	"elite",
	"fiveseven",
	"ump45",
	"sg550",
	"galil",
	"famas",
	"usp",
	"glock18",
	"awp",
	"mp5navy",
	"m249",
	"m3",
	"m4a1",
	"tmp",
	"g3sg1",
	"flashbang",
	"deagle",
	"sg552",
	"ak47",
	"knife",
	"p90"
};

new const g_sz_WeaponName[][] = {
	"",
	"P228",
	"Shield",
	"Scout",
	"HE Grenade",
	"XM1014",
	"C4",
	"MAC-10",
	"AUG",
	"SG Grenade",
	"Dual Elites",
	"FiveSeven",
	"UMP45",
	"Kreig 550",
	"Galil",
	"Famas",
	"USP/Knife",
	"Glock",
	"AWP",
	"MP5 Navy",
	"Machine Gun",
	"M3 Shotgun",
	"M4A1",
	"TMP",
	"G3SG1",
	"Flashbang",
	"Desert Eagle",
	"Kreig 552",
	"AK47",
	"USP/Knife",
	"P90"
};

enum {
	OFFSET_AMMO_AWP = 377,		// AWP
	OFFSET_AMMO_SCOUT,		// AK47, G3SG1
	OFFSET_AMMO_M249,		// M249
	OFFSET_AMMO_M4A1,		// FAMAS, AUG, SG550, GALIL, SG552
	OFFSET_AMMO_M3,			// XM1014
	OFFSET_AMMO_USP,		// UMP45, MAC10
	OFFSET_AMMO_FIVESEVEN,		// P90
	OFFSET_AMMO_DEAGLE,		// DEAGLE
	OFFSET_AMMO_P228,		// P228
	OFFSET_AMMO_GLOCK18,		// MP5NAVY, TMP, ELITE
	OFFSET_AMMO_FLASHBANG,		// FLASH
	OFFSET_AMMO_HEGRENADE,		// HE
	OFFSET_AMMO_SMOKEGRENADE,	// SMOKE
	OFFSET_AMMO_C4			// C4
};

new const g_weapon_AmmoOffset[] = {
	0,
	OFFSET_AMMO_P228,
	0,
	OFFSET_AMMO_SCOUT,
	OFFSET_AMMO_HEGRENADE,
	OFFSET_AMMO_M3,
	OFFSET_AMMO_C4,
	OFFSET_AMMO_USP,
	OFFSET_AMMO_M4A1,
	OFFSET_AMMO_SMOKEGRENADE,
	OFFSET_AMMO_GLOCK18,
	OFFSET_AMMO_FIVESEVEN,
	OFFSET_AMMO_USP,
	OFFSET_AMMO_M4A1,
	OFFSET_AMMO_M4A1,
	OFFSET_AMMO_M4A1,
	OFFSET_AMMO_USP,
	OFFSET_AMMO_GLOCK18,
	OFFSET_AMMO_AWP,
	OFFSET_AMMO_GLOCK18,
	OFFSET_AMMO_M249,
	OFFSET_AMMO_M3,
	OFFSET_AMMO_M4A1,
	OFFSET_AMMO_GLOCK18,
	OFFSET_AMMO_SCOUT,
	OFFSET_AMMO_FLASHBANG,
	OFFSET_AMMO_DEAGLE,
	OFFSET_AMMO_M4A1,
	OFFSET_AMMO_SCOUT,
	0, 
	OFFSET_AMMO_FIVESEVEN
};

new const g_weapon_Ammo[] = {
	0,	// CSW_NONE
	13,	// CSW_P228
	0,	// CSW_SHIELD
	10, 	// CSW_SCOUT
	0, 	// CSW_HEGRENADE
	7, 	// CSW_XM1014
	0,  	// CSW_C4
	30,	// CSW_MAC10
	30,	// CSW_AUG
	0, 	// CSW_SMOKEGRENADE
	15,	// CSW_ELITE
	20,	// CSW_FIVESEVEN
	25,	// CSW_UMP45
	30,	// CSW_SG550
	35, 	// CSW_GALIL
	25, 	// CSW_FAMAS
	12,	// CSW_USP
	20,	// CSW_GLOCK18
	10,	// CSW_AWP
	30,	// CSW_MP5NAVY
	100,	// CSW_M249
	8, 	// CSW_M3
	30,	// CSW_M4A1
	30,	// CSW_TMP
	20, 	// CSW_G3SG1
	0,  	// CSW_FLASHBANG
	7, 	// CSW_DEAGLE
	30,	// CSW_SG552
	30, 	// CSW_AK47
	0, 	// CSW_KNIFE
	50,	// CSW_P90
	0,	// CSW_VEST
	0	// CSW_VESTHELM
};

new const g_int_WeaponBPAmmo[] = {
	0,	// CSW_NONE
	52,	// CSW_P228
	0,	// CSW_SHIELD
	90,	// CSW_SCOUT
	0,	// CSW_HE
	32,	// CSW_XM1014
	0,	// CSW_C4
	100,	// CSW_MAX10
	90,	// CSW_AUG
	0,	// CSW_SMOKE
	120,	// CSW_ELITE
	100,	// CSW_FIVESEVEN
	100,	// CSW_UMP45
	90,	// CSW_SG550
	90,	// CSW_GALIL
	90,	// CSW_FAMAS
	100,	// CSW_USP
	120,	// CSW_GLOCK
	30,	// CSW_AWP
	120,	// CSW_MP5
	200,	// CSW_M249
	32,	// CSW_M3
	90,	// CSW_M4
	120,	// CSW_TMP
	90,	// CSW_G3SG1
	0,	// CSW_FLASH
	35,	// CSW_DEAGLE
	90,	// CSW_SG552
	90,	// CSW_AK47
	0,	// CSW_KNIFE
	100,	// CSW_P90
	0,	// CSW_VEST
	0	// CSW_VESTHELM
};

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* Plugin INIT
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

public plugin_natives() {
	set_native_filter("native_filter");
	set_module_filter("module_filter");
	
	register_library("q_kz");
	register_native("q_kz_getVersion",			"_q_kz_getVersion");
	register_native("q_kz_getDataDirectory",		"_q_kz_getDataDirectory");
	register_native("q_kz_getConfigDirectory",		"_q_kz_getConfigDirectory");
	register_native("q_kz_getPrefix",			"_q_kz_getPrefix");
	register_native("q_kz_registerReward",			"_q_kz_registerReward");
	register_native("q_kz_print",				"_q_kz_print");
	register_native("q_kz_saytext",				"_q_kz_saytext");
	register_native("q_kz_getHudColor",			"_q_kz_getHudColor");
	register_native("q_kz_player_getCheckpoints",		"_q_kz_player_getCheckpoints");
	register_native("q_kz_player_getTeleports",		"_q_kz_player_getTeleports");
	register_native("q_kz_player_isVip",			"_q_kz_player_isVip");
	register_native("q_kz_player_isTimerStarted",		"_q_kz_player_isTimerStarted");
	register_native("q_kz_player_stopTimer",		"_q_kz_player_stopTimer");
	register_native("q_kz_player_getTimer",			"_q_kz_player_getTimer");
	register_native("q_kz_isStartOriginFound",		"_q_kz_isStartOriginFound");
	register_native("q_kz_getStartOrigin",			"_q_kz_getStartOrigin");
	register_native("q_kz_isStopOriginFound",		"_q_kz_isStopOriginFound");
	register_native("q_kz_getStopOrigin",			"_q_kz_getStopOrigin");
	register_native("q_kz_getStartButtonEntities",		"_q_kz_getStartButtonEntities");
	register_native("q_kz_getStopButtonEntities",		"_q_kz_getStopButtonEntities");
	register_native("q_kz_registerForward",			"_q_kz_registerForward");
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
	get_mapname(g_map_Name, charsmax(g_map_Name));
	strtolower(g_map_Name);
	
	q_getDataDirectory(g_dir_data, charsmax(g_dir_data));
	add(g_dir_data, charsmax(g_dir_data), "/kz");
	if(!dir_exists(g_dir_data)) {
		mkdir(g_dir_data);
	}
	
	formatex(g_file_buttons, charsmax(g_file_buttons), "%s/buttons.dat", g_dir_data);
	
	load_Spawns();
	register_forward(FM_KeyValue, "fwd_KeyValue", 1);
}

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	formatex(g_plugin_Name, charsmax(g_plugin_Name), "%s %s", PLUGIN, VERSION);
	
	check_Spawns();
	
	register_dictionary("q_kz.txt");
	
	get_cvar_string("hostname", g_server_Name, charsmax(g_server_Name));
	
	cvar_Checkpoints	= register_cvar("q_kz_checkpoints", "1");
	cvar_CheckpointAngles	= register_cvar("q_kz_checkpointangles", "1");
	cvar_TeleportSplash	= register_cvar("q_kz_teleport_splash", "0");
	cvar_Prefix		= register_cvar("q_kz_prefix", "QKZ");
	cvar_Pause 		= register_cvar("q_kz_pause", "1");
	cvar_GodMode 		= register_cvar("q_kz_godmode", "1");
	cvar_Noclip 		= register_cvar("q_kz_noclip", "1");
	cvar_Semiclip		= register_cvar("q_kz_semiclip", "1");
	cvar_SemiclipAlpha	= register_cvar("q_kz_semiclip_alpha", "80");
	cvar_Weapons		= register_cvar("q_kz_weapons", "1");
	cvar_WeaponsAmmo	= register_cvar("q_kz_weapons_ammo", "2");
	cvar_WeaponsSpeed	= register_cvar("q_kz_weapons_speed", "1");
	cvar_Respawn		= register_cvar("q_kz_respawn", "1");
	cvar_RespawnTime	= register_cvar("q_kz_respawn_time", "3.0");
	cvar_HPBug		= register_cvar("q_kz_hpbug", "0");
	cvar_PrintType		= register_cvar("q_kz_print_type", "0");
	cvar_PrintColor		= register_cvar("q_kz_print_color", "0 100 255");
	cvar_PrintPos		= register_cvar("q_kz_print_pos", "-1.0 0.9");
	cvar_SpawnWithMenu	= register_cvar("q_kz_spawnwithmenu", "1");
	cvar_VipFlags		= register_cvar("q_kz_vipflags", "a");
	cvar_Rewards		= register_cvar("q_kz_rewards", "0");
	g_cvar_command_save	= register_cvar("q_kz_command_save", "1");
	
	g_menu_welcome = q_menu_create("Welcome", "mh_welcome");
	q_menu_item_add(g_menu_welcome, "", _, _, _, "mf_welcome");
	q_menu_item_add(g_menu_welcome, "", _, _, _, "mf_welcome");
	q_menu_item_set_enabled(g_menu_welcome, QMenuItem_Exit, false);
	
	g_menu_chooseteam = q_menu_create("Chooseteam", "mh_chooseteam");
	q_menu_item_add(g_menu_chooseteam, "", _, _, _, "mf_chooseteam");
	q_menu_item_add(g_menu_chooseteam, "", _, _, _, "mf_chooseteam");
	q_menu_item_set_enabled(g_menu_chooseteam, QMenuItem_Exit, false);
	
	g_menu_kreedz = q_menu_create("Kreedz", "mh_kreedz");
	q_menu_item_add(g_menu_kreedz, "", _, _, _, "mf_kreedz");
	q_menu_item_add(g_menu_kreedz, "", _, _, _, "mf_kreedz");
	q_menu_item_add(g_menu_kreedz, "", _, _, _, "mf_kreedz");
	q_menu_item_add(g_menu_kreedz, "", _, _, _, "mf_kreedz");
	q_menu_item_add(g_menu_kreedz, "", _, _, _, "mf_kreedz");
	q_menu_item_add(g_menu_kreedz, "", _, _, _, "mf_kreedz");
	
	g_rewards_name = ArrayCreate(32, 4);
	g_rewards_plugin = ArrayCreate(1, 4);
	g_rewards_handler = ArrayCreate(1, 4);
	g_rewards_callback = ArrayCreate(1, 4);
	
	g_startButtonEntities = ArrayCreate(1, 1);
	g_stopButtonEntities = ArrayCreate(1, 1);
	
	forward_TimerStart_pre = ArrayCreate(1, 1);
	forward_TimerStart_post = ArrayCreate(1, 1);
	forward_TimerStop_pre = ArrayCreate(1, 1);
	forward_TimerStop_post = ArrayCreate(1, 1);
	forward_TimerPause_pre = ArrayCreate(1, 1);
	forward_TimerPause_post = ArrayCreate(1, 1);
	forward_OnCheckpoint_pre = ArrayCreate(1, 1);
	forward_OnCheckpoint_post = ArrayCreate(1, 1);
	forward_OnTeleport_pre = ArrayCreate(1, 1);
	forward_OnTeleport_post = ArrayCreate(1, 1);
	
	q_registerClcmd("q_kz_checkpoint", "clcmd_Checkpoint", _, "Save current player position.");
	q_registerClcmd("q_kz_teleport", "clcmd_Teleport", _, "Move player to last saved position.");
	q_registerClcmd("q_kz_unstuck", "clcmd_Stuck", _, "Move player to second last saved position.");
	q_registerClcmd("q_kz_start", "clcmd_Start", _, "Teleport to start button position.");
	q_registerClcmd("q_kz_end", "clcmd_End", _, "Teleoprt to end button position.");
	q_registerClcmd("q_kz_setstart", "clcmd_SetStart", _, "Set custom start position.");
	q_registerClcmd("q_kz_unsetstart", "clcmd_UnsetStart", _, "Remove cutsom start position.");
	q_registerClcmd("q_kz_pause", "clcmd_Pause", _, "Pause timer.");
	q_registerClcmd("q_kz_stop", "clcmd_Stop", _, "Stop timer.");
	q_registerClcmd("q_kz_save", "clcmd_save", _, "Save timer.");
	q_registerClcmd("q_kz_restore", "clcmd_restore", _, "Restore saved timer.");
	q_registerClcmd("q_kz_spec", "clcmd_Spectate", _, "Toggle spectate mode.");
	q_registerClcmd("q_kz_cpangles", "clcmd_cpangles", _, "Toggle saving player checkpoint orientation.");
	q_registerClcmd("q_kz_menu", "clcmd_kzmenu", _, "Open KZ menu.");
	q_registerClcmd("q_kz_maxspeed", "clcmd_MaxSpeed", _, "Toggle weapon speed notification.");
	q_registerClcmd("q_kz_godmode", "clcmd_GodMode", _, "Toggle player god mode.");
	q_registerClcmd("q_kz_noclip", "clcmd_Noclip", _, "Toggle player noclip mode.");
	
	register_clcmd("chooseteam", "clcmd_Chooseteam");
	register_clcmd("drop", "clcmd_Drop");
	register_clcmd("radio1", "clcmd_Block");
	register_clcmd("radio2", "clcmd_Block");
	register_clcmd("radio3", "clcmd_Block");
	register_clcmd("jointeam", "clcmd_Block");
	
	register_forward(FM_EmitSound, "fwd_EmitSound");
	register_forward(FM_ClientKill, "fwd_ClientKill");
	register_forward(FM_AddToFullPack, "fwd_AddToFullPack", 1);
	register_forward(FM_PlayerPreThink, "fwd_PlayerPreThink", 1);
	register_forward(FM_PlayerPostThink, "fwd_PlayerPostThink");
	register_forward(FM_GetGameDescription, "fwd_GetGameDescription");
	RegisterHam(Ham_Killed, "player", "fwd_Killed");
	RegisterHam(Ham_Use, "func_button", "fwd_Use_button");
	RegisterHam(Ham_Spawn, "player", "fwd_Spawn_player", 1);
	RegisterHam(Ham_Touch, "weaponbox", "fwd_Touch_weaponbox", 1);
	RegisterHam(Ham_Touch, "trigger_hurt", "fwd_Touch_hurt");
	
	q_kz_registerForward(Q_KZ_TimerStart, "forward_KZTimerStart", true);
	q_kz_registerForward(Q_KZ_TimerStop, "forward_KZTimerStop", true);
	q_kz_registerForward(Q_KZ_TimerStop, "psave_onTimerStop", true);
	q_kz_registerForward(Q_KZ_OnCheckpoint, "forward_KZOnCheckpoint", true);
	q_kz_registerForward(Q_KZ_OnTeleport, "forward_KZOnTeleport", true);
	
	register_event("ResetHUD", "event_ResetHUD", "b");
	register_event("SpecHealth2", "event_SpecHealth2", "bd");
	register_event("CurWeapon", "event_CurWeapon", "be", "1!0", "2!0");
	register_event("AmmoX", "event_AmmoX", "be");

	g_msg_Health = get_user_msgid("Health");
	g_msg_SayText = get_user_msgid("SayText");
	g_msg_ScoreAttrib = get_user_msgid("ScoreAttrib");
	g_msg_TeamInfo = get_user_msgid("TeamInfo");
	g_msg_AmmoPickup = get_user_msgid("AmmoPickup");
	g_msg_WeapPickup = get_user_msgid("WeapPickup");
	g_msg_HideWeapon = get_user_msgid("HideWeapon");
	g_msg_ScreenFade = get_user_msgid("ScreenFade");
	g_msg_RoundTime = get_user_msgid("RoundTime");
	g_msg_StatusIcon = get_user_msgid("StatusIcon");
	g_msg_Crosshair = get_user_msgid("Crosshair");
	g_msg_ClCorpse = get_user_msgid("ClCorpse");
	g_msg_VGUIMenu = get_user_msgid("VGUIMenu");
	g_msg_ShowMenu = get_user_msgid("ShowMenu");
	
	register_message(g_msg_Health, "message_hook_Health");
	register_message(g_msg_HideWeapon, "message_hook_HideWeapon");
	register_message(g_msg_StatusIcon, "message_hook_StatusIcon");
	register_message(g_msg_ScoreAttrib, "message_hook_ScoreAttrib");
	register_message(g_msg_VGUIMenu, "message_hook_VGUIMenu");
	register_message(g_msg_ShowMenu, "message_hook_ShowMenu");
	
	set_msg_block(g_msg_ClCorpse, BLOCK_SET);
	set_msg_block(g_msg_AmmoPickup, BLOCK_SET);
	set_msg_block(g_msg_WeapPickup, BLOCK_SET);
	
	set_cvar_num("mp_freezetime", 0);
	set_cvar_num("mp_footsteps", 1);
	set_cvar_num("mp_limitteams", 0);
	set_cvar_num("mp_autoteambalance", 0);
	set_cvar_num("edgefriction", 2);
	set_cvar_num("sv_cheats", 0);
	set_cvar_num("sv_gravity", 800);
	set_cvar_num("sv_maxspeed", 320);
	set_cvar_num("sv_stepsize", 18);
	set_cvar_num("sv_maxvelocity", 2000);
	set_cvar_num("sv_airaccelerate", 10);
	set_cvar_string("humans_join_team", "ct");
	
	RemoveJunkEntities();
	load_ButtonPositions();
	find_Buttons();
	find_Healer();
	
	psave_onPluginInit();
}

public plugin_cfg() {
	get_localinfo("amxx_configsdir", g_dir_config, charsmax(g_dir_config));
	formatex(g_file_config, charsmax(g_file_config), "%s/amxx_q_kz.cfg", g_dir_config);
	if(file_exists(g_file_config)) {
		server_cmd("exec %s", g_file_config);
	}
	
	new mfwd;
	new ret; //junk
	
	g_rewards_registering = true;
	mfwd = CreateMultiForward("QKZ_RegisterRewards", ET_IGNORE);
	ExecuteForward(mfwd, ret);
	DestroyForward(mfwd);
	g_rewards_registering = false;
	
	cvar_SpawnWithMenu	= register_cvar("q_kz_spawnwithmenu",		"1");
	cvar_VipFlags		= register_cvar("q_kz_vipflags",		"a");
	cvar_Rewards		= register_cvar("q_kz_rewards",		"0");
	
	q_registerCvar(cvar_Checkpoints, "1", "Toggle checkpoints and checkpoint related commands.");
	q_registerCvar(cvar_CheckpointAngles, "1", "Default toggle value for checkpoint angles setting.");
	q_registerCvar(cvar_TeleportSplash, "0", "Toggle teleport splash effect.");
	q_registerCvar(cvar_Prefix, "QKZ", "Prefix goes in various plugin notifications and messages.");
	q_registerCvar(cvar_Pause, "1", "Toggle pause command.");
	q_registerCvar(cvar_GodMode, "1", "Toggle god mode command.");
	q_registerCvar(cvar_Noclip, "1", "Toggle noclip command.");
	q_registerCvar(cvar_Semiclip, "1", "Toggle semiclip.");
	q_registerCvar(cvar_SemiclipAlpha, "80", "Ammount of semiclip transparency.");
	q_registerCvar(cvar_Weapons, "1", "Not used for now.");
	q_registerCvar(cvar_WeaponsAmmo, "2", "Set ammo in backpack (after spawn, starting timer, ...): 0 - regular, 1 - double the ammount of bullets, 2 - full backpack");
	q_registerCvar(cvar_WeaponsSpeed, "1", "Toggle weapon speed notification when taking a weapon.");
	q_registerCvar(cvar_Respawn, "1", "Toggle respawn.");
	q_registerCvar(cvar_RespawnTime, "3.0", "Time before respawning player.");
	q_registerCvar(cvar_HPBug, "0", "Toggle hp bug fixer.");
	q_registerCvar(cvar_PrintType, "0", "Set how to display plugin messages: 0 - HUD, 1 - chat, 2 - center screen text");
	q_registerCvar(cvar_PrintColor, "0 100 255", "If q_kz_print_type is set to 0 (HUD), this sets color of the HUD.");
	q_registerCvar(cvar_PrintPos, "-1.0 0.9", "If q_kz_print_type is to 0 (HUD), this sets messages position on the screen.");
	q_registerCvar(cvar_SpawnWithMenu, "1", "Toggle if menu should appear when player spawns.");
	q_registerCvar(cvar_VipFlags, "a", "Set flag that will treat players as VIP.");
	q_registerCvar(cvar_Rewards, "0", "Toggle rewards for finishing the map. (There are no plugins that use this. (Yet.))");
	q_registerCvar(g_cvar_command_save, "1", "Toggle /save command.");
}

public plugin_end() {
	save_ButtonPositions();
	
	ArrayDestroy(g_startButtonEntities);
	ArrayDestroy(g_stopButtonEntities);
		
	forward_TimerStart_pre ? ArrayDestroy(forward_TimerStart_pre) : 0;
	forward_TimerStart_post ? ArrayDestroy(forward_TimerStart_post) : 0;
	forward_TimerStop_pre ? ArrayDestroy(forward_TimerStop_pre) : 0;
	forward_TimerStop_post ? ArrayDestroy(forward_TimerStop_post) : 0;
	forward_TimerPause_pre ? ArrayDestroy(forward_TimerPause_pre) : 0;
	forward_TimerPause_post ? ArrayDestroy(forward_TimerPause_post) : 0;
	
	ArrayDestroy(g_rewards_name);
	ArrayDestroy(g_rewards_plugin);
	ArrayDestroy(g_rewards_handler);
	ArrayDestroy(g_rewards_callback);
	
	psave_onPluginEnd();
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* Client Events
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

public client_putinserver(id) {
	g_player_ingame[id]		= false;
	get_user_name(id, g_player_Name[id], charsmax(g_player_Name[][]));
	g_player_Connected[id] 		= true;
	g_player_Alive[id]		= false;
	g_player_Welcome[id] 		= false;
	g_player_MaxSpeed[id]		= true;
	g_player_God[id]		= false;
	g_player_Noclip[id]		= false;
	g_player_CPcounter[id]		= 0;
	g_player_TPcounter[id]		= 0;
	g_player_SpecID[id]		= 0;
	g_player_run_Running[id]	= false;
	g_player_run_Paused[id]		= false;
	g_player_run_WeaponID[id]	= 0;
	
	if(!g_cookies_failed && !is_user_bot(id)) {
		if(!q_get_cookie_num(id, "save_cp_angles", g_player_setting_CPangles[id])) {
			g_player_setting_CPangles[id] = get_pcvar_num(cvar_CheckpointAngles);
		}
	}
	
	new vipflags[28];
	get_pcvar_string(cvar_VipFlags, vipflags, charsmax(vipflags));
	if(get_user_flags(id) & read_flags(vipflags)) {
		g_player_VIP[id] = true;
	}
	
	psave_onPlayerJoin(id);
}

public client_infochanged(id) {
	get_user_info(id, "name", g_player_Name[id], charsmax(g_player_Name[]));
	
	new vipflags[28];
	get_pcvar_string(cvar_VipFlags, vipflags, charsmax(vipflags));
	if(get_user_flags(id) & read_flags(vipflags)) {
		g_player_VIP[id] = true;
	}
	else {
		g_player_VIP[id] = false;
	}
}

public client_disconnect(id) {
	g_player_ingame[id] = false;
	g_player_Name[id][0] = 0;
	g_player_VIP[id] = false;
	g_player_Connected[id] = true;
	g_player_Alive[id] = false;
	g_player_Welcome[id] = false;
	g_player_MaxSpeed[id] = true;
	g_player_God[id] = false;
	g_player_Noclip[id] = false;
	g_player_CPcounter[id] = 0;
	g_player_TPcounter[id] = 0;
	g_player_SpecID[id] = 0;
	g_player_run_Running[id] = false;
	g_player_run_Paused[id] = false;
	g_player_run_WeaponID[id] = 0;
	
	if(!g_cookies_failed && !is_user_bot(id)) {
		q_set_cookie_num(id, "save_cp_angles", g_player_setting_CPangles[id]);
	}
	
	psave_onPlayerLeave(id);
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* Forwards
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

public fwd_GetGameDescription() {
	forward_return(FMV_STRING, "Kreedz");
	
	return FMRES_SUPERCEDE;
}

public fwd_AddToFullPack(es_handle, e, ent, host, hostflags, player, pset) {
	if(player && get_pcvar_num(cvar_Semiclip)) {
		set_es(es_handle, ES_Solid, SOLID_NOT);
		set_es(es_handle, ES_RenderMode, kRenderTransAlpha);
		set_es(es_handle, ES_RenderAmt, get_pcvar_num(cvar_SemiclipAlpha));
	}
}

public fwd_PlayerPreThink(id) {
	if(get_pcvar_num(cvar_Semiclip) && g_player_Alive[id]) {
		for(new i = 1, playerCount = get_maxplayers(); i <= playerCount; i++) {
			if(g_player_Alive[i] && (id != i)) {
				set_pev(i, pev_solid, SOLID_NOT);
			}
		}
	}
	
	return FMRES_IGNORED;
}

public fwd_PlayerPostThink(id) {	
	if(get_pcvar_num(cvar_Semiclip) && g_player_Alive[id]) {
		for(new i = 1, playerCount = get_maxplayers(); i <= playerCount; i++) {
			if(g_player_Alive[i] && (id != i)) {
				set_pev(i, pev_solid, SOLID_SLIDEBOX);
			}
		}
	}
	
	return FMRES_IGNORED;
}

public fwd_Spawn_player(id) {
	if(is_user_alive(id)) {
		g_player_Alive[id] = true;
		
		if(g_map_HealerExists) {
			set_pev(id, pev_health, 50175.0);
		}
		
		set_pev(id, pev_armortype, 2.0);
		set_pev(id, pev_armorvalue, 100.0);
		message_ArmorType(id, 1);
		
		//if(g_start_bDefault)
		//	message_HostagePos(id, 1, 1, g_start_vDefault);
		//if(g_end_bDefault)
		//	message_HostagePos(id, 1, 2, g_end_vDefault);
		
		set_pdata_int(id, OFFSET_RADIO, 0, EXTRA_OFFSET);
		
		SetWeapon(id);
	}
		
	g_player_SpecID[id] = 0;
	
	return HAM_SUPERCEDE;
}

public fwd_Touch_weaponbox(wpnbox, other) {
	if(!other || (other > 32)) {
		set_pev(wpnbox, pev_nextthink, get_gametime() + 1.337);
	}
}

public fwd_Touch_hurt(hurt, player) {
	if((player > 0) && (player < 32) && !g_player_Alive[player]) {
		return HAM_SUPERCEDE;
	}
	
	return HAM_IGNORED;
}

public fwd_Killed(id, attacker, shouldgib) {
	g_player_Alive[id] = false;
	
	g_player_Noclip[id] = false;
	set_pev(id, pev_movetype, MOVETYPE_NONE);
	set_pev(id, pev_sequence, 104);
	set_pev(id, pev_gaitsequence, 0);
	set_pev(id, pev_animtime, get_gametime());
	set_pev(id, pev_framerate, 1.0);
	set_pev(id, pev_frame, 0.0);
	
	/* RESPAWN */
	if(get_pcvar_num(cvar_Respawn)) {
		new Float:rtime = get_pcvar_float(cvar_RespawnTime);
		floatclamp(rtime, 1.0, 10000.0);
		set_task(rtime, "task_Respawn", id + TASKID_RESPAWN);
		set_pcvar_float(cvar_RespawnTime, rtime);
		
		q_kz_print(id, "%L %.1fs", id, STR_RESPAWNNOTICE, rtime);
	}
	
	return HAM_SUPERCEDE;
}

public fwd_Use_button(ent, id) {
	if(!(1 <= id <= 32)) {
		return HAM_IGNORED;
	}
	
	if(GET_BITVECTOR(g_map_ent_StartButton, ent)) {
		if(!g_start_bDefault) {
			g_start_bDefault = true;
			pev(id, pev_origin, g_start_vDefault);
			save_ButtonPositions();
		}
		
		g_start_bCurrent[id] = true;
		pev(id, pev_origin, g_start_vCurrent[id]);
	
		if(g_player_run_Running[id]) {
			run_reset(id);
		}
	
		event_RunStart(id);
	}
	else if(GET_BITVECTOR(g_map_ent_EndButton, ent)) {
		if(!g_end_bDefault) {
			g_end_bDefault = true;
			pev(id, pev_origin, g_end_vDefault);
			save_ButtonPositions();
		}
		
		event_RunEnd(id);
	}
	
	return HAM_IGNORED;
}

public fwd_KeyValue(ent, kvd_handle) {
	if(pev_valid(ent)) {
		static szClassName[32];
		static szKey[8];
		static szVal[20];
		
		get_kvd(kvd_handle, KV_ClassName, szClassName, 31);
		get_kvd(kvd_handle, KV_KeyName, szKey, 7);
		get_kvd(kvd_handle, KV_Value, szVal, 19);
		
		static Float:vecOrigin[3];
		static Float:vecAngle[3];
		static x[6];
		static y[6];
		static z[6];
		
		if(equal(szClassName, "info_player_start")) {
			if(equal(szKey, "origin")) {
				parse(szVal, x, 5, y, 5, z, 5);
				vecOrigin[0] = str_to_float(x);
				vecOrigin[1] = str_to_float(y);
				vecOrigin[2] = str_to_float(z);
			}
			else {
				parse(szVal, x, 5, y, 5, z, 5);
				vecAngle[0] = str_to_float(x);
				vecAngle[1] = str_to_float(y);
				vecAngle[2] = str_to_float(z);
				
				if(g_map_SpawnsNeeded > 0) {
					for(new i = 0; i < g_map_SpawnsNeeded; ++i) {
						new spawn = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_player_start"));
						set_pev(spawn, pev_origin, vecOrigin);
						set_pev(spawn, pev_angles, vecAngle);
						--g_map_SpawnsNeeded;
					}
				}
				else {
					++g_map_SpawnCount;
				}
			}
		}
	}
	
	return FMRES_IGNORED;
}

public fwd_EmitSound(id, channel, szSound[]) {	
	if(equal(szSound, "items/gunpickup" , 15)) {
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public fwd_ClientKill(id) {
	q_kz_print(id, "%L", id, STR_CMDDISABLED);
	
	return FMRES_SUPERCEDE;
}

public forward_KZTimerStart(id) {
	if(q_menu_current(id) == g_menu_kreedz) {
		m_kreedz(id);
	}
}

public forward_KZTimerStop(id, successful) {
	if(successful && get_pcvar_num(cvar_Rewards)) {
		menu_KZRewards(id);
	}
	
	if(q_menu_current(id) == g_menu_kreedz) {
		m_kreedz(id);
	}
}

public forward_KZOnCheckpoint(id) {
	if(q_menu_current(id) == g_menu_kreedz) {
		m_kreedz(id);
	}
}

public forward_KZOnTeleport(id) {
	if(q_menu_current(id) == g_menu_kreedz) {
		m_kreedz(id);
	}
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* Events
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

public event_RunStart(id) {
	for(new i = 0, size = ArraySize(forward_TimerStart_pre); i < size; ++i) {
		new ret;
		ExecuteForward(ArrayGetCell(forward_TimerStart_pre, i), ret, id);
		if(ret == PLUGIN_HANDLED) {
			return;
		}
	}
	
	g_player_run_Running[id] = true;
	g_player_run_StartTime[id] = get_gametime();
	g_player_CPcounter[id] = 0;
	g_player_TPcounter[id] = 0;
	
	g_player_run_WeaponID[id] = get_user_weapon(id);
	if(g_player_run_WeaponID[id] == CSW_KNIFE) {
		g_player_run_WeaponID[id] = CSW_USP;
	}
	
	switch(get_pcvar_num(cvar_WeaponsAmmo)) {
	case 0: {
		q_set_weapon_ammo(fm_get_user_weapon_entity(id, g_player_run_WeaponID[id]), 0);
		q_set_user_bpammo(id, g_player_run_WeaponID[id], 0);
	}
	case 1: {
		q_set_weapon_ammo(fm_get_user_weapon_entity(id, g_player_run_WeaponID[id]), g_weapon_Ammo[g_player_run_WeaponID[id]]);
		q_set_user_bpammo(id, g_player_run_WeaponID[id], 2 * g_weapon_Ammo[g_player_run_WeaponID[id]]);
	}
	case 2: {
		q_set_weapon_ammo(fm_get_user_weapon_entity(id, g_player_run_WeaponID[id]), g_weapon_Ammo[g_player_run_WeaponID[id]]);
		q_set_user_bpammo(id, g_player_run_WeaponID[id], g_int_WeaponBPAmmo[g_player_run_WeaponID[id]]);
	}
	}
	
	set_pev(id, pev_gravity, 1.0);
	
	if(g_player_God[id]) {
		g_player_God[id] = false;
		set_pev(id, pev_takedamage, DAMAGE_AIM);
	}
	
	if(g_player_Noclip[id]) {
		g_player_Noclip[id] = false;
		set_pev(id, pev_movetype, MOVETYPE_WALK);
	}
	
	if(!g_map_HealerExists) {
		set_pev(id, pev_health, 100.0);
	}
	else {
		set_pev(id, pev_health, 50175.0);
	}
	
	set_task(1.0, "task_RoundTime", TASKID_ROUNDTIME + id, _, _, "b");
	
	message_RoundTime(id, 0);
	message_HideWeapon(id, HIDEW_MONEY);
	message_Crosshair(id, false);
	
	q_kz_print(id, "%L", id, STR_RUNSTARTED);
	
	for(new i = 0, size = ArraySize(forward_TimerStart_post); i < size; ++i) {
		new ret;
		ExecuteForward(ArrayGetCell(forward_TimerStart_post, i), ret, id);
	}
}

public event_RunEnd(id) {
	if(!g_player_run_Running[id]) {
		q_kz_print(id, "%L", id, STR_NOTINRUN);
		
		return;
	}
	
	for(new i = 0, size = ArraySize(forward_TimerStop_pre); i < size; ++i) {
		new ret;
		new callback = ArrayGetCell(forward_TimerStop_pre, i);
		ExecuteForward(callback, ret, id, true);
	}
	
	new prefix[4];
	get_pcvar_string(cvar_Prefix, prefix, 3);
	
	new Float:rtime = get_gametime() - g_player_run_StartTime[id];
	new minutes = floatround(rtime / 60, floatround_floor);
	new Float:seconds = rtime - (minutes * 60);
	
	message_SayText(0, "^x04[%s] ^x03%s ^x01has finished the map in ^x04%02d:%s%.2f ^x01(CPs: ^x04%d ^x01| TPs: ^x04%d^x01) with ^x04%s",
		prefix,
		g_player_Name[id],
		minutes,
		seconds < 10 ? "0" : "",
		seconds,
		g_player_CPcounter[id],
		g_player_TPcounter[id],
		g_sz_WeaponName[g_player_run_WeaponID[id]]);
		
	client_cmd(id, "spk buttons/bell1");
	
	for(new i = 0, size = ArraySize(forward_TimerStop_post); i < size; ++i) {
		new ret;
		new callback = ArrayGetCell(forward_TimerStop_post, i);
		ExecuteForward(callback, ret, id, true);
	}
	
	run_reset(id);
}

public event_CurWeapon(id) {
	static Float:speed;
	static iLastWeapon, iCurWeapon;
	
	if(!g_player_Alive[id]) {
		return;
	}
	
	iCurWeapon = read_data(2);
	
	if(g_player_run_Running[id] && g_player_run_WeaponID[id] == iCurWeapon) {
		g_player_ClipAmmo[id] = read_data(3);
	}
	
	if(get_pcvar_num(cvar_WeaponsSpeed) && g_player_MaxSpeed[id] && (iCurWeapon != iLastWeapon)) {
		iLastWeapon = iCurWeapon;
		
		pev(id, pev_maxspeed, speed);
		
		q_kz_print(id, "%L: %d", id, STR_WEAPONSPEED, floatround(speed));
	}
	
	if(g_player_run_Running[id]
	&& iCurWeapon != g_player_run_WeaponID[id]
	&& !((iCurWeapon == CSW_USP && g_player_run_WeaponID[id] == CSW_KNIFE) || (iCurWeapon == CSW_KNIFE && g_player_run_WeaponID[id] == CSW_USP))) {
		q_kz_player_stopTimer(id, ""); // FIX!
		//q_kz_print(id, "Run terminated because of weapon change");
		
		run_reset(id);
	}
}

public event_AmmoX(id) {
	// hax
	if(g_player_Alive[id] && g_player_run_Running[id] && !g_player_stripping[id] && (g_weapon_AmmoOffset[g_player_run_WeaponID[id]] == (read_data(1) + 376))) {
		g_player_BackAmmo[id] = read_data(2);
	}
}

public event_ResetHUD(id) {
	if(g_player_run_Running[id]) {
		message_HideWeapon(id, HIDEW_MONEY);
	}
	else {
		message_HideWeapon(id, HIDEW_TIMER | HIDEW_MONEY);
	}
}

public event_SpecHealth2(id) {
	g_player_SpecID[id] = read_data(2);
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* Message Hooks											   *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

public message_hook_HideWeapon(msg_id, msg_dest, msg_ent) {	
	if(g_player_run_Running[msg_ent]) {
		set_msg_arg_int(1, ARG_BYTE, get_msg_arg_int(1) | (1<<5));
	}
	else {
		set_msg_arg_int(1, ARG_BYTE, get_msg_arg_int(1) | (1<<4 | 1<<5));
	}
		
	return PLUGIN_CONTINUE;
}

public message_hook_StatusIcon(msg_id, msg_dest, msg_ent) {
	static sz_msg[8];
	get_msg_arg_string(2, sz_msg, charsmax(sz_msg));
	
	if(equal(sz_msg, "buyzone")) {
		set_pdata_int(msg_ent, OFFSET_BUYZONE, get_pdata_int(msg_ent, OFFSET_BUYZONE) & ~(1<<0));
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public message_hook_ScoreAttrib(msg_id, msg_dest, msg_ent) {
	new iPlayer = get_msg_arg_int(1);
	
	if(g_player_Connected[iPlayer] && g_player_VIP[iPlayer]) {
		set_msg_arg_int(2, ARG_BYTE, SCOREATTRIB_VIP);
	}
	
	return PLUGIN_CONTINUE;
}

public message_hook_Health(msg_id, msg_dest, msg_ent) {
	new iHealth;
	
	if(get_pcvar_num(cvar_HPBug)) {
		iHealth = get_msg_arg_int(1);
		
		if(iHealth > 255 && ((iHealth % 256) == 0)) {
			set_msg_arg_int(1, ARG_BYTE, iHealth + 1);
		}
	}
	
	return PLUGIN_CONTINUE;
}

public message_hook_VGUIMenu(id, dest, ent) {
	if(get_msg_arg_int(1) == 2) {
		set_task(0.1, "task_Jointeam", ent + TASKID_JOINTEAM);
	}
	else {
		set_task(0.1, "task_Joinclass", ent + TASKID_JOINCLASS);
	}
	
	return PLUGIN_HANDLED;
}

public message_hook_ShowMenu(msg_id, msg_dest, msg_ent) {
	static menu_text_code[18];
	
	get_msg_arg_string(4, menu_text_code, charsmax(menu_text_code));
	
	if(equal(menu_text_code, "#Team_Select")) {
		set_task(0.1, "task_Jointeam", msg_ent + TASKID_JOINTEAM);
	}
	else if(equal(menu_text_code, "#CT_Select") || equal(menu_text_code, "#Terrorist_Select")) {
		set_task(0.1, "task_Joinclass", msg_ent + TASKID_JOINCLASS);
	}
	else {
		return PLUGIN_CONTINUE;
	}

	return PLUGIN_HANDLED;
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* Tasks
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

public task_Jointeam(id) {
	id -= TASKID_JOINTEAM;
	
	m_welcome(id);
}

public task_Joinclass(id) {
	id -= TASKID_JOINCLASS;
	
	m_welcome(id);
}

public task_Respawn(id) {
	id -= TASKID_RESPAWN;
	
	set_pev(id, pev_deadflag, DEAD_RESPAWNABLE);
	dllfunc(DLLFunc_Spawn, id);
}

public task_RoundTime(id) {
	id -= TASKID_ROUNDTIME;
	
	if(g_player_Connected[id]) {
		if(g_player_run_Paused[id]) {
			message_RoundTime(id, floatround(g_player_run_PauseTime[ id ] - g_player_run_StartTime[ id ], floatround_floor));
		}
		else if(g_player_run_Running[id]) {
			message_RoundTime(id, floatround(get_gametime() - g_player_run_StartTime[ id ], floatround_floor));
		}
	}
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* Client Commands										   *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

public clcmd_Chooseteam(id, level, cid) {
	m_chooseteam(id);
	
	return PLUGIN_HANDLED;
}

public clcmd_Block(id) {
	return PLUGIN_HANDLED;
}

public clcmd_Checkpoint(id) {
	if(!get_pcvar_num(cvar_Checkpoints)) {
		q_kz_print(id, "%L", id, STR_CMDDISABLED);
		
		return PLUGIN_HANDLED;
	}
	
	if(!g_player_Alive[id]) {
		q_kz_print(id, "%L", id, STR_NOTALIVE);
		
		return PLUGIN_HANDLED;
	}
	
	if(!(pev(id, pev_flags) & FL_ONGROUND2)) {
		q_kz_print(id, "%L", id, STR_NOTONGROUND);
		
		return PLUGIN_HANDLED;
	}
	
	for(new i = 0, size = ArraySize(forward_OnCheckpoint_pre); i < size; ++i) {
		new ret;
		ExecuteForward(ArrayGetCell(forward_OnCheckpoint_pre, i), ret, id);
		if(ret == PLUGIN_HANDLED) {
			return PLUGIN_HANDLED;
		}
	}
	
	g_player_CPorigin[id][1] = g_player_CPorigin[id][0];
	g_player_CPangles[id][1] = g_player_CPangles[id][0];
	
	pev(id, pev_origin, g_player_CPorigin[id][0]);
	pev(id, pev_v_angle, g_player_CPangles[id][0]);
	
	++g_player_CPcounter[id];
	q_kz_print(id, "%L #%d", id, STR_CHECKPOINT, g_player_CPcounter[id]);
	
	for(new i = 0, size = ArraySize(forward_OnCheckpoint_post); i < size; ++i) {
		new ret;
		ExecuteForward(ArrayGetCell(forward_OnCheckpoint_post, i), ret, id);
		if(ret == PLUGIN_HANDLED) {
			return PLUGIN_HANDLED;
		}
	}
	
	return PLUGIN_HANDLED;
}

public clcmd_Teleport(id) {
	if(!get_pcvar_num(cvar_Checkpoints)) {
		q_kz_print(id, "%L", id, STR_CMDDISABLED);
		
		return PLUGIN_HANDLED;
	}
	
	if(!g_player_Alive[id]) {
		q_kz_print(id, "%L", id, STR_NOTALIVE);
		
		return PLUGIN_HANDLED;
	}
	
	if(g_player_CPcounter[id] == 0) {
		q_kz_print(id, "%L", id, STR_NOCHECKPOINTS);
		
		return PLUGIN_HANDLED;
	}
	
	for(new i = 0, size = ArraySize(forward_OnTeleport_pre); i < size; ++i) {
		new ret;
		ExecuteForward(ArrayGetCell(forward_OnTeleport_pre, i), ret, id);
		if(ret == PLUGIN_HANDLED) {
			return PLUGIN_HANDLED;
		}
	}
	
	set_pev(id, pev_gravity, 1.0);
	set_pev(id, pev_velocity, Float:{0.0, 0.0, 0.0});
	set_pev(id, pev_flags, pev(id, pev_flags) | FL_DUCKING);
	set_pev(id, pev_origin, g_player_CPorigin[id][0]);
	
	if(g_player_setting_CPangles[id]) {
		set_pev(id, pev_angles, g_player_CPangles[id][0]);
		set_pev(id, pev_fixangle, 1);
	}
	
	if(get_pcvar_num(cvar_TeleportSplash)) {
		message_te_teleport(id, g_player_CPorigin[id][0]);
	}

	++g_player_TPcounter[id];
	q_kz_print(id, "%L #%d", id, STR_TELEPORT, g_player_TPcounter[id]);
	
	for(new i = 0, size = ArraySize(forward_OnTeleport_post); i < size; ++i) {
		new ret;
		ExecuteForward(ArrayGetCell(forward_OnTeleport_post, i), ret, id);
		if(ret == PLUGIN_HANDLED) {
			return PLUGIN_HANDLED;
		}
	}
	
	return PLUGIN_HANDLED;
}

public clcmd_Stuck(id) {
	if(!get_pcvar_num(cvar_Checkpoints)) {
		q_kz_print(id, "%L", id, STR_CMDDISABLED);
		
		return PLUGIN_HANDLED;
	}
	
	if(!g_player_Alive[id]) {
		q_kz_print(id, "%L", id, STR_NOTALIVE);
		
		return PLUGIN_HANDLED;
	}
	
	if(g_player_CPcounter[id] < 2) {
		q_kz_print(id, "%L", id, STR_NOTENOUGHCHECKPOINTS);
		return PLUGIN_HANDLED;
	}
	
	set_pev(id, pev_gravity, 1.0);
	set_pev(id, pev_velocity, Float:{0.0, 0.0, 0.0});
	set_pev(id, pev_flags, pev(id, pev_flags) | FL_DUCKING);
	set_pev(id, pev_origin, g_player_CPorigin[id][1]);
	
	if(g_player_setting_CPangles[id]) {
		set_pev(id, pev_angles, g_player_CPangles[id][1]);
		set_pev(id, pev_fixangle, 1);
	}
	
	if(get_pcvar_num(cvar_TeleportSplash)) {
		message_te_teleport(id, g_player_CPorigin[id][1]);
	}

	++g_player_TPcounter[id];
	q_kz_print(id, "%L #%d", id, STR_TELEPORT, g_player_TPcounter[id]);
	
	return PLUGIN_HANDLED;
}

public clcmd_Start(id) {
	if(!g_player_Alive[id]) {
		q_kz_print(id, "%L", id, STR_NOTALIVE);
		
		return PLUGIN_HANDLED;
	}
	
	if(g_player_run_Paused[id]) {
		q_kz_print(id, "%L", id, STR_NOTWHILEPAUSE);
		
		return PLUGIN_HANDLED;
	}
	
	if(g_start_bCustom[id]) {
		set_pev(id, pev_gravity, Float:1.0);
		set_pev(id, pev_origin, g_start_vCustom[id]);
		set_pev(id, pev_velocity, Float:{0.0, 0.0, 0.0});
		set_pev(id, pev_flags, pev(id, pev_flags) | FL_DUCKING);
		
		q_kz_player_stopTimer(id, ""); // FIX!
		//q_kz_print(id, "Custom Start - Run Terminated");
		
		run_reset(id);
	}
	else if(g_start_bCurrent[id]) {
		set_pev(id, pev_gravity, Float:1.0);
		set_pev(id, pev_origin, g_start_vCurrent[id]);
		set_pev(id, pev_velocity, Float:{0.0, 0.0, 0.0});
		set_pev(id, pev_flags, pev(id, pev_flags) | FL_DUCKING);
	}
	else if(g_start_bDefault) {
		set_pev(id, pev_gravity, Float:1.0);
		set_pev(id, pev_origin, g_start_vDefault);
		set_pev(id, pev_velocity, Float:{0.0, 0.0, 0.0});
		set_pev(id, pev_flags, pev(id, pev_flags) | FL_DUCKING);
	}
	else {
		q_kz_print(id, "%L", id, STR_NOSTARTPOS);
		
		return PLUGIN_HANDLED;
	}
	
	q_kz_print(id, "%L", id, STR_TELEPORTTOSTART);
	
	return PLUGIN_HANDLED;
}

public clcmd_End(id) {
	if(!g_player_Alive[id]) {
		q_kz_print(id, "%L", id, STR_NOTALIVE);
		
		return PLUGIN_HANDLED;
	}
	
	if(g_player_run_Paused[id]) {
		q_kz_print(id, "%L", id, STR_NOTWHILEPAUSE);
		
		return PLUGIN_HANDLED;
	}
	
	if(g_end_bDefault) {
		run_reset(id);
		
		set_pev(id, pev_gravity, Float:1.0);
		set_pev(id, pev_origin, g_end_vDefault);
		set_pev(id, pev_velocity, Float:{0.0, 0.0, 0.0});
		set_pev(id, pev_flags, pev(id, pev_flags) | FL_DUCKING);
		
		q_kz_print(id, "%L", id, STR_TELEPORTTOEND);
	}
	else {
		q_kz_print(id, "%L", id, STR_NOENDPOS);
	}
	
	return PLUGIN_HANDLED;
}

public clcmd_SetStart(id) {
	if(!g_player_Alive[id]) {
		q_kz_print(id, "%L", id, STR_NOTALIVE);
		
		return PLUGIN_HANDLED;
	}
	
	if(!(pev(id, pev_flags) & FL_ONGROUND2)) {
		q_kz_print(id, "%L", id, STR_NOTONGROUND);
		
		return PLUGIN_HANDLED;
	}

	g_start_bCustom[id] = true;
	pev(id, pev_origin, g_start_vCustom[id]);
	
	q_kz_print(id, "%L", id, STR_CUSTOMSTARTSET);
	
	return PLUGIN_HANDLED;
}

public clcmd_UnsetStart(id) {
	if(!g_player_Alive[id]) {
		q_kz_print(id, "%L", id, STR_NOTALIVE);
		
		return PLUGIN_HANDLED;
	}
	
	g_start_bCustom[id] = false;
	
	q_kz_print(id, "%L", id, STR_CUSTOMSTARTUNSET);
	
	return PLUGIN_HANDLED;
}

public clcmd_Pause(id) {
	if(!get_pcvar_num(cvar_Pause)) {
		q_kz_print(id, "%L", id, STR_CMDDISABLED);
		
		return PLUGIN_HANDLED;
	}
	
	if(!g_player_Alive[id]) {
		q_kz_print(id, "%L", id, STR_NOTALIVE);
		
		return PLUGIN_HANDLED;
	}
	
	if(!(pev(id, pev_flags) & FL_ONGROUND2)) {
		q_kz_print(id, "%L", id, STR_NOTONGROUND);
		
		return PLUGIN_HANDLED;
	}
	
	if(!g_player_run_Running[id]) {
		q_kz_print(id, "%L", id, STR_NOTINRUN);
		
		return PLUGIN_HANDLED;
	}

	for(new i = 0, size = ArraySize(forward_TimerPause_pre); i < size; ++i) {
		new ret;
		ExecuteForward(ArrayGetCell(forward_TimerPause_pre, i), ret, id, g_player_run_Paused[id]);
	}
	
	if(g_player_run_Paused[id]) {	
		g_player_run_Paused[id] = false;
		g_player_run_StartTime[ id ] += (get_gametime() - g_player_run_PauseTime[ id ]);
		
		set_pev(id, pev_flags, pev(id, pev_flags) & ~FL_FROZEN);
		
		q_kz_print(id, "%L", id, STR_RUNPAUSED);
	}
	else {
		g_player_run_Paused[id] = true;
		g_player_run_PauseTime[ id ] = get_gametime();

		set_pev(id, pev_flags, pev(id, pev_flags) | FL_FROZEN);

		q_kz_print(id, "%L", id, STR_RUNUNPAUSED);
	}
	
	for(new i = 0, size = ArraySize(forward_TimerPause_post); i < size; ++i) {
		new ret;
		ExecuteForward(ArrayGetCell(forward_TimerPause_post, i), ret, id, g_player_run_Paused[id]);
	}
	
	return PLUGIN_HANDLED;
}

public clcmd_Stop(id) {
	if(!g_player_Alive[id]) {
		q_kz_print(id, "%L", id, STR_NOTALIVE);
		
		return PLUGIN_HANDLED;
	}
	
	if(g_player_run_Running[id]) {
		q_kz_player_stopTimer(id, "");
		
		q_kz_print(id, "%L", id, STR_RUNSTOPPED);
	}
	else {
		q_kz_print(id, "%L", id, STR_NOTINRUN);
	}
	
	return PLUGIN_HANDLED;
}

public clcmd_Spectate(id) {
	static Float:vOrigin[MAX_PLAYERS + 1][3];
	static Float:vVelocity[MAX_PLAYERS + 1][3];
	static Float:vAngle[MAX_PLAYERS + 1][3];
	
	new CsTeams:team = q_get_user_team(id);
	
	if(team == CS_TEAM_UNASSIGNED) {
		q_kz_print(id, "%L", id, STR_NOTALIVE);
	}
	else if(team == CS_TEAM_SPECTATOR) {
		g_player_run_Paused[id] = false;
		g_player_run_StartTime[id] += (get_gametime() - g_player_run_PauseTime[id]);
		
		q_set_user_team(id, CS_TEAM_CT, 0);
		
		task_Respawn(id + TASKID_RESPAWN);

		set_pev(id, pev_origin, vOrigin[id]);
		set_pev(id, pev_velocity, vVelocity[id]);
		if(g_player_setting_CPangles[id]) {
			set_pev(id, pev_angles, vAngle[id]);
			set_pev(id, pev_fixangle, 1);
		}
		
		SetWeapon(id);
	}
	else if(!g_player_run_Paused[id]) {
		g_player_Alive[id] = false;
		g_player_run_Paused[id] = true;
		g_player_run_PauseTime[id] = get_gametime();
		
		pev(id, pev_origin, vOrigin[id]);
		pev(id, pev_velocity, vVelocity[id]);
		pev(id, pev_v_angle, vAngle[id]);
		
		q_set_user_team(id, CS_TEAM_SPECTATOR);
		
		set_pev(id, pev_solid, SOLID_NOT);
		set_pev(id, pev_deadflag, DEAD_DEAD);
		set_pev(id, pev_takedamage, DAMAGE_NO);
		set_pev(id, pev_movetype, MOVETYPE_NONE);
	}
	
	return PLUGIN_HANDLED;
}

public clcmd_MaxSpeed(id) {
	g_player_MaxSpeed[id] = !g_player_MaxSpeed[id];
	
	q_kz_print(id, "%L: %L", id, STR_WEAPONSPEED, id, (g_player_MaxSpeed[id] ? STR_ON : STR_OFF));
	
	return PLUGIN_HANDLED;
}

public clcmd_kzmenu(id) {
	if(!g_player_Alive[id]) {
		q_kz_print(id, "%L", id, STR_NOTALIVE);
		
		return PLUGIN_HANDLED;
	}
	
	m_kreedz(id);
	
	return PLUGIN_HANDLED;
}

public clcmd_GodMode(id) {
	if(!get_pcvar_num(cvar_GodMode)) {
		q_kz_print(id, "%L", id, STR_CMDDISABLED);
		
		return PLUGIN_HANDLED;
	}
	
	if(!g_player_Alive[id]) {
		q_kz_print(id, "%L", id, STR_NOTALIVE);
		
		return PLUGIN_HANDLED;
	}
	
	if(g_player_run_Running[id]) {
		q_kz_print(id, "%L", id, STR_NOTWHILERUN);
		
		return PLUGIN_HANDLED;
	}
	
	
	g_player_God[id] = !g_player_God[id];
	set_pev(id, pev_takedamage, g_player_God[id] ? DAMAGE_NO : DAMAGE_AIM);
	q_kz_print(id, "Godmode: %L", id, (g_player_God[id] ? STR_ON : STR_OFF));
	
	return PLUGIN_HANDLED;
}

public clcmd_Noclip(id) {
	if(!get_pcvar_num(cvar_Noclip)) {
		q_kz_print(id, "%L", id, STR_CMDDISABLED);
		
		return PLUGIN_HANDLED;
	}
	
	if(!g_player_Alive[id]) {
		q_kz_print(id, "%L", id, STR_NOTALIVE);
		
		return PLUGIN_HANDLED;
	}
	
	if(g_player_run_Running[id]) {
		q_kz_print(id, "%L", id, STR_NOTWHILERUN);
		
		return PLUGIN_HANDLED;
	}
	
	
	g_player_Noclip[id] = !g_player_Noclip[id];
	set_pev(id, pev_movetype, g_player_Noclip[id] ? MOVETYPE_NOCLIP : MOVETYPE_WALK);
	q_kz_print(id, "Noclip: %L", id, (g_player_Noclip[id] ? STR_ON : STR_OFF));
	
	return PLUGIN_HANDLED;
}

public clcmd_Drop(id) {
	if(g_player_Alive[id]) {
		q_kz_print(id, "%L", id, STR_DROP);
	}
	
	return PLUGIN_HANDLED;
}

public clcmd_save(id, level, cid) {
	if(!get_pcvar_num(g_cvar_command_save)) {
		q_kz_print(id, "%L", id, STR_CMDDISABLED);
		return PLUGIN_HANDLED;
	}
	
	if(!g_player_Alive[id]) {
		q_kz_print(id, "%L", id, STR_NOTALIVE);
		return PLUGIN_HANDLED;
	}
	
	if(!(pev(id, pev_flags) & FL_ONGROUND2)) {
		q_kz_print(id, "%L", id, STR_NOTONGROUND);
		return PLUGIN_HANDLED;
	}
	
	if(!g_player_run_Running[id]) {
		q_kz_print(id, "%L", id, STR_NOTINRUN);
		return PLUGIN_HANDLED;
	}
	
	q_kz_print(id, "%L", id, STR_TIMERSAVED);
	
	psave_save(id);
	
	return PLUGIN_HANDLED;
}

public clcmd_restore(id, level, cid) {
	if(!get_pcvar_num(g_cvar_command_save)) {
		q_kz_print(id, "%L", id, STR_CMDDISABLED);
		return PLUGIN_HANDLED;
	}
	
	if(!g_player_Alive[id]) {
		q_kz_print(id, "%L", id, STR_NOTALIVE);
		return PLUGIN_HANDLED;
	}
	
	if(g_player_run_Running[id]) {
		q_kz_print(id, "%L", id, STR_NOTINRUN);
		return PLUGIN_HANDLED;
	}
	
	if(!g_player_psave_exists[id]) {
		q_kz_print(id, "%L", id, STR_NOSAVEDTIMER);
		return PLUGIN_HANDLED;
	}
	
	psave_restore(id);
	
	return PLUGIN_HANDLED;
}

public clcmd_cpangles(id, level, cid) {
	g_player_setting_CPangles[id] = !g_player_setting_CPangles[id];
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* Menus
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

m_welcome(id) {
	new title[32];
	formatex(title, charsmax(title), "%L", id, STR_WELCOME);
	q_menu_set_title(g_menu_welcome, title);
	
	q_menu_display(id, g_menu_welcome);
}

public mf_welcome(id, menu, item, output[64]) {
	switch(item) {
	case 0: { // play
		formatex(output, charsmax(output), "%L", id, STR_WELCOMEPLAY);
	}
	case 1: { // spec
		formatex(output, charsmax(output), "%L", id, STR_WELCOMESPEC);
	}
	}
}

public mh_welcome(id, QMenu:menu, item) {
	g_player_ingame[id] = true;
	engclient_cmd(id, "joinclass", "5");
	
	switch(item) {
	case 0: {
		if(get_pcvar_num(cvar_SpawnWithMenu)) {
			m_kreedz(id);
		}
	}
	case 1: {
		client_cmd(id, "say /spec");
	}
	}
	
	//message_SayText(id, "^x01Welcome to ^x04%s ^x01powered by ^x04%s", g_server_Name, g_plugin_Name);
	
	return PLUGIN_HANDLED;
}

m_chooseteam(id) {
	new title[32];
	formatex(title, charsmax(title), "%L", id, (g_player_Alive[id] ? STR_ENTERSPEC : STR_ENTERGAME));
	q_menu_set_title(g_menu_chooseteam, title);
	
	q_menu_display(id, g_menu_chooseteam);
}

public mf_chooseteam(id, menu, item, output[64]) {
	switch(item) {
	case 0: { // yes
		formatex(output, charsmax(output), "%L", id, "Q_YES");
	}
	case 1: { // no
		formatex(output, charsmax(output), "%L", id, "Q_NO");
	}
	}
}

public mh_chooseteam(id, menu, item) {
	if(item == 0) {
		clcmd_Spectate(id);
	}
	
	return PLUGIN_HANDLED;
}

m_kreedz(id) {
	q_menu_display(id, QMenu:g_menu_kreedz);
}

public mf_kreedz(id, menu, item, output[64]) {
	switch(item) {
	case 0: { // checkpoint
		formatex(output, charsmax(output), "%L / \y#%d", id, STR_CHECKPOINT, g_player_CPcounter[id]);
	}
	case 1: { // teleport
		formatex(output, charsmax(output), "%L / \y#%d", id, STR_TELEPORT, g_player_TPcounter[id]);
		q_menu_item_set_enabled(g_menu_kreedz, 1, g_player_CPcounter[id] > 0 ? true : false);
	}
	case 2: { // unstuck
		formatex(output, charsmax(output), "%L", id, STR_UNSTUCK);
		q_menu_item_set_enabled(g_menu_kreedz, 2, g_player_CPcounter[id] > 1 ? true : false);
	}
	case 3: { // start
		// TODO: enable if exists/found
		formatex(output, charsmax(output), "%L", id, STR_START);
	}
	case 4: { // pause
		formatex(output, charsmax(output), "%L", id, (g_player_run_Paused[id] ? STR_UNPAUSE : STR_PAUSE));
		q_menu_item_set_enabled(g_menu_kreedz, 4, g_player_run_Running[id] ? true : false);
	}
	case 5: { // stop
		formatex(output, charsmax(output), "%L", id, STR_STOP);
		q_menu_item_set_enabled(g_menu_kreedz, 5, g_player_run_Running[id] ? true : false);
	}
	}
}

public mh_kreedz(id, menu, item) {
	switch(item) {
	case QMenuItem_Exit, QMenuItem_Back, QMenuItem_Next: {
		return PLUGIN_HANDLED;
	}
	case 0: {
		clcmd_Checkpoint(id);
	}
	case 1: {
		clcmd_Teleport(id);
	}
	case 2: {
		clcmd_Stuck(id);
	}
	case 3: {
		clcmd_Start(id);
	}
	case 4: {
		clcmd_Pause(id);
	}
	case 5: {
		clcmd_Stop(id);
	}
	}
	
	m_kreedz(id);
	
	return PLUGIN_HANDLED;
}

public menu_KZRewards(id) {
	new buffer[32];
	formatex(buffer, charsmax(buffer), "QKZ %L", id, STR_REWARDS);
	new menu = menu_create(buffer, "menu_KZRewards_handler");
	
	new callback;
	new size = ArraySize(g_rewards_name);
	for(new i = 0; i < size; ++i) {
		ArrayGetString(g_rewards_name, i, buffer, charsmax(buffer));
		LookupLangKey(buffer, charsmax(buffer), buffer, id);
		
		callback = ArrayGetCell(g_rewards_callback, i);
		if(callback != -1) {
			callback = menu_makecallback("menu_KZRewards_callback");
		}
		
		menu_additem(menu, buffer, _, _, callback);
	}
	
	formatex(buffer, charsmax(buffer), "%L", id, "Q_MENU_EXIT");
	menu_setprop(menu, MPROP_EXITNAME, buffer);
	
	formatex(buffer, charsmax(buffer), "%L", id, "Q_MENU_BACK");
	menu_setprop(menu, MPROP_BACKNAME, buffer);
	
	formatex(buffer, charsmax(buffer), "%L", id, "Q_MENU_NEXT");
	menu_setprop(menu, MPROP_NEXTNAME, buffer);
	
	menu_display(id, menu);
}

public menu_KZRewards_handler(id, menu, item) {
	menu_destroy(menu);
	
	if(item != MENU_EXIT) {
		new plug = ArrayGetCell(g_rewards_plugin, item);
		new hand = ArrayGetCell(g_rewards_handler, item);
		
		if(callfunc_begin_i(hand, plug) == 1) {
			callfunc_push_int(id);
			callfunc_end();
		}
	}
	
	return PLUGIN_HANDLED;
}

public menu_KZRewards_callback(id, menu, item) {
	new plug = ArrayGetCell(g_rewards_plugin, item);
	new call = ArrayGetCell(g_rewards_callback, item);
	
	if(callfunc_begin_i(call, plug) == 1) {
		callfunc_push_int(id);
		return callfunc_end();
	}
	
	return ITEM_IGNORE;
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* Weapons'n'Ammo
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

SetWeapon(id, iWeapon = 0, bDeployAnim = false) {
	static eWeapon;		// weapon entity id
	static szWeapon[32];	// weapon entity name
	static iClipAmmo;
	static iBackAmmo;
	
	if(!g_player_Alive[id]) {
		return;
	}
	
	// If player is in run we need to save ammo before striping weapons
	if(g_player_run_Running[id]) {
		iClipAmmo = g_player_ClipAmmo[id];
		iBackAmmo = g_player_BackAmmo[id];
	}
	
	// Strip weapons because player can hold only one weapon
	// with the exception of USP/Knife standard weapons
	g_player_stripping[id] = true;
	if(!fm_strip_user_weapons(id)) {
		return;
	}
	g_player_stripping[id] = false;
	
	// If no weapon is passed as argument or someone is acting stupid
	// this block will set everything back on track
	if(iWeapon <= 0 || iWeapon > 30) {
		if(g_player_run_Running[id]) {
			iWeapon = g_player_run_WeaponID[id];
		}
		else {
			iWeapon = CSW_USP;
		}
	}
	
	formatex(szWeapon, charsmax(szWeapon), "weapon_%s", g_sz_WeaponEntName[iWeapon]);
	
	// Try to give the weapon
	if((eWeapon = fm_give_item(id, szWeapon)) <= 0) {
		return;
	}
	
	// Knife always goes with USP (standard weapons of KreedZ)
	// but if fm_give_item for knife fails, I dont give a shit. At least the player got USP.
	if(iWeapon == CSW_USP) {
		 fm_give_item(id, "weapon_knife");
	}
	
	// Set weapon animation to idle because deploy animation gets annoying after a while
	if(!bDeployAnim) {
		switch(iWeapon) {
		case CSW_USP: {
			set_pev(id, pev_weaponanim, 8);
		}
		case CSW_M4A1: {
			set_pev(id, pev_weaponanim, 7);
		}
		default: {
			set_pev(id, pev_weaponanim, 0);
		}
		}
	}
	
	// If player is in run I know that SetWeapon is only called
	// when player is spawning or returning back from spec,
	// therefore Im setting his ammo to the ammount before he
	// died or entered spec mode.
	// If NOT in run ammo is set based on WeaponsAmmo CVar:
	// 0 = 0 clip, 0 backpack
	// 1 = full clip, 2 clips in backpack
	// 2 = full clip and backpack
	if(g_player_run_Running[id]) {
		q_set_weapon_ammo(eWeapon, iClipAmmo);
		q_set_user_bpammo(id, iWeapon, iBackAmmo);
	}
	else {
		switch(get_pcvar_num(cvar_WeaponsAmmo)) {
		case 0: {
			q_set_weapon_ammo(eWeapon, 0);
			q_set_user_bpammo(id, iWeapon, 0);
		}
		case 1: {
			// no need to set clip ammo
			q_set_user_bpammo(id, iWeapon, 2 * g_weapon_Ammo[iWeapon]);
		}
		case 2: {
			// no need to set clip ammo
			q_set_user_bpammo(id, iWeapon, g_int_WeaponBPAmmo[iWeapon]);
		}
		}
	}
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* Message Stocks
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

// Beam between point and entity
stock message_te_beamentpoint(id = 0, iEnt, Float:vOrigin[3], hSprite, vColor[3], Float:iLife, iWidth) {
	if(id) {
		message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id);
	}
	else {
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	}
	
	write_byte(TE_BEAMENTPOINT);
	write_short(iEnt);			// entity ID
	write_coord(floatround(vOrigin[0]));	// X Origin
	write_coord(floatround(vOrigin[1]));	// Y Origin
	write_coord(floatround(vOrigin[2]));	// Z Origin
	write_short(hSprite);			// sprite handle
	write_byte(1); 			// starting frame
	write_byte(1); 			// frame rate in 0.1s
	write_byte(floatround(iLife * 10));	// life in 0.1s
	write_byte(iWidth); 			// line width in 0.1s
	write_byte(0); 			// noise amplitude in 0.01s
	write_byte(vColor[0]);		// red
	write_byte(vColor[1]);		// green
	write_byte(vColor[2]);		// blue
	write_byte(200);			// brigtness
	write_byte(1);			// scroll speed in 0.1s
	message_end();
}

// kills te_beamentpoint
stock message_te_killbeam(id = 0, iEnt) {
	if(id) {
		message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id);
	}
	else {
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	}
		
	write_byte(TE_KILLBEAM);
	write_short(iEnt);
	message_end();
}

stock message_HideWeapon(id, flag) {
	message_begin(MSG_ONE, g_msg_HideWeapon, _, id);
	write_byte(flag);
	message_end();
}

stock message_Crosshair(id, flag) {
	message_begin(MSG_ONE, g_msg_Crosshair, _, id);
	write_byte(flag);
	message_end();
}

stock message_RoundTime(id, roundtime) {
	message_begin(MSG_ONE, g_msg_RoundTime, _, id);
	write_short(roundtime + 1);
	message_end();
}

stock message_Flashlight(id, flag, percent) {
	message_begin(MSG_ONE_UNRELIABLE, g_msg_Flashlight, _, id);
	write_byte(flag);
	write_byte(percent);
	message_end();
}

stock message_ScreenFade(id, fadetime, holdtime, flags, red, green, blue, alpha) {
	message_begin(MSG_ONE_UNRELIABLE, g_msg_ScreenFade, _, id);
	write_short(fadetime);
	write_short(holdtime);
	write_short(flags);
	write_byte(red);
	write_byte(green);
	write_byte(blue);
	write_byte(alpha);
	message_end();
}

stock message_ScoreAttrib(id, flag) {
	message_begin(MSG_ALL, g_msg_ScoreAttrib, _, id);
	write_byte(id);
	write_byte(flag);
	message_end();
}

stock message_te_teleport(id, Float:origin[3]) {
	message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id);
	write_byte(TE_TELEPORT);
	write_coord(floatround(origin[0]));
	write_coord(floatround(origin[1]));
	write_coord(floatround(origin[2]));
	message_end();
}

stock message_TeamInfo(id, team_id) {
	if(!id) {
		return;
	}

	new const szTeamName[][] = {
		"UNASSIGNED",
		"TERRORIST",
		"CT",
		"SPECTATOR"
	};
	
	message_begin(MSG_ALL, g_msg_TeamInfo, _, id);
	write_byte(id);
	write_string(szTeamName[team_id]);
	message_end();
	
	return;
}

stock message_SayText(id, const message[], any:...) {
	static buffer[192];
	buffer = "^x01";
	vformat(buffer[1], charsmax(buffer) - 1, message, 3);
	
	replace_all(buffer, charsmax(buffer), "!n", "^x01");
	replace_all(buffer, charsmax(buffer), "!t", "^x03");
	replace_all(buffer, charsmax(buffer), "!g", "^x04");
	
	if(id == 0) { 
		for(new i = 1, playerCount = get_maxplayers(); i <= playerCount; ++i) {
			if(g_player_Connected[i]) {
				message_begin(MSG_ONE_UNRELIABLE, g_msg_SayText, _, i);
				write_byte(i);
				write_string(buffer);
				message_end();
			}
		}
	}
	else {
		if(g_player_Connected[id]) {
			message_begin(MSG_ONE_UNRELIABLE, g_msg_SayText, _, id);
			write_byte(id);
			write_string(buffer);
			message_end();
		}
	}
}

stock message_ClCorpse(id, model[], Float:origin[3], Float:angles[3], delay, sequence) {
	message_begin(MSG_ONE_UNRELIABLE, g_msg_ClCorpse, _, id);
	write_string(model);
	write_long(floatround(origin[0])<<7);
	write_long(floatround(origin[1])<<7);
	write_long(floatround(origin[2])<<7);
	write_coord(floatround(angles[0]));
	write_coord(floatround(angles[1]));
	write_coord(floatround(angles[2]));
	write_long(delay<<7); // delay
	write_byte(sequence);
	write_byte(0); // classid ???
	write_byte(2); // team id
	write_byte(id); // player id
	message_end();
}

stock message_ArmorType(id, type) {
	static msg_ArmorType;
	if(!msg_ArmorType) {
		msg_ArmorType = get_user_msgid("ArmorType");
	}
	
	message_begin(MSG_ONE_UNRELIABLE, msg_ArmorType, _, id);
	write_byte(type);
	message_end();
}

stock message_HostagePos(id, flag, hostageid, Float:origin[3]) {
	static msg_HostagePos;
	if(!msg_HostagePos) {
		msg_HostagePos = get_user_msgid("HostagePos");
	}
	
	message_begin(MSG_ONE_UNRELIABLE, msg_HostagePos, _, id);
	write_byte(flag);
	write_byte(hostageid);
	write_coord(floatround(origin[0]));
	write_coord(floatround(origin[1]));
	write_coord(floatround(origin[2]));
	message_end();
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* Natives
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

// q_kz_getVersion(version[], len)
public _q_kz_getVersion(plugin, params) {
	if(params != 2) {
		log_error(AMX_ERR_NATIVE, "Parameters do not match. Expected 2, found %d", params);
	}
	else {
		set_string(1, VERSION, get_param(2));
	}
}

// q_kz_getDataDirectory(path[], len)
public _q_kz_getDataDirectory(plugin, params) {
	if(params != 2) {
		log_error(AMX_ERR_NATIVE, "Parameters do not match. Expected 2, found %d", params);
	}
	else {
		set_string(1, g_dir_data, get_param(2));
	}
}

// q_kz_getConfigDirectory(path[], len)
public _q_kz_getConfigDirectory(plugin, params) {
	if(params != 2) {
		log_error(AMX_ERR_NATIVE, "Parameters do not match. Expected 2, found %d", params);
	}
	else {
		set_string(1, g_dir_config, get_param(2));
	}
}

// q_kz_getPrefix(output[], len)
public _q_kz_getPrefix(plugin, params) {
	if(params != 2) {
		log_error(AMX_ERR_NATIVE, "Parameters do not match. Expected 2, found %d", params);
		return;
	}
	
	new prefix[32];
	get_pcvar_string(cvar_Prefix, prefix, charsmax(prefix));
	set_string(1, prefix, get_param(2));
}

// q_kz_print(id, msg_fmt[], any:...)
public _q_kz_print(plugin, params) {
	if(params < 2) {
		log_error(AMX_ERR_NATIVE, "Parameters do not match. Expected 2 or more, found %d", params);
		return;
	}
	
	new id = get_param(1);
	if((id < 0) || (id > 32)) {
		log_error(AMX_ERR_NATIVE, "Invalid player id %d", id);
		
		return;
	}
	
	static buffer[192];
	vdformat(buffer, charsmax(buffer), 2, 3);
	
	switch(get_pcvar_num(cvar_PrintType)) {
	case 0: {
		static pos[10], x[5], y[5];
		static color[12], r[4], g[4], b[4];
		
		get_pcvar_string(cvar_PrintPos, pos, 9);
		get_pcvar_string(cvar_PrintColor, color, 11);
		
		parse(pos, x, 4, y, 4);
		parse(color, r, 3, g, 3, b, 3);
		
		set_hudmessage(str_to_num(r), str_to_num(g), str_to_num(b), str_to_float(x), str_to_float(y), 0, 0.0, 4.0, 0.0, 1.0, 1);
		show_hudmessage(id, buffer);
	}
	case 1: {
		client_print(id, print_center, buffer);
	}
	case 2: {
		new prefix[4];
		get_pcvar_string(cvar_Prefix, prefix, charsmax(prefix));
		client_print(id, print_chat, "[%s] %s", prefix, buffer);
	}
	default: {
		client_print(id, print_center, buffer);
	}
	}
}

// q_kz_player_stopTimer(id, reason_fmt[], any:...)
public _q_kz_player_stopTimer(plugin, params) {
	if(params < 2) {
		log_error(AMX_ERR_NATIVE, "Parameters do not match. Expected 2 or more, found %d", params);
		return;
	}
	
	new id = get_param(1);
	if((id < 1) || (id > 32)) {
		log_error(AMX_ERR_NATIVE, "Invalid player id %d", id);
		
		return;
	}
	
	if(g_player_run_Running[id]) {
		for(new i = 0, size = ArraySize(forward_TimerStop_pre); i < size; ++i) {
			new ret;
			ExecuteForward(ArrayGetCell(forward_TimerStop_pre, i), ret, id, false);
		}
		
		run_reset(id);
		
		new buffer[192];
		vdformat(buffer, charsmax(buffer), 2, 3);
		q_kz_print(id, buffer);
		
		for(new i = 0, size = ArraySize(forward_TimerStop_post); i < size; ++i) {
			new ret;
			ExecuteForward(ArrayGetCell(forward_TimerStop_post, i), ret, id, false);
		}
	}
}

// q_kz_saytext(id, msg_fmt[], any:...)
public _q_kz_saytext(plugin, params) {
	if(params < 2) {
		log_error(AMX_ERR_NATIVE, "Parameters do not match. Expected 3 or more, found %d", params);
		return;
	}
	
	new id = get_param(1);
	if((id < 0) || (id > 32)) {
		log_error(AMX_ERR_NATIVE, "Invalid player id %d", id);
		
		return ;
	}
	
	static buffer[192];
	vdformat(buffer, charsmax(buffer), 2, 3);
	
	message_SayText(id, buffer);
}

// q_kz_player_isTimerStarted(id)
public _q_kz_player_isTimerStarted(plugin, params) {
	if(params != 1) {
		log_error(AMX_ERR_NATIVE, "Parameters do not match. Expected 1, found %d", params);
		return 0;
	}
	
	new id = get_param(1);
	if((id < 1) || (id > 32)) {
		log_error(AMX_ERR_NATIVE, "Invalid player id %d", id);
		
		return 0;
	}
	
	return g_player_run_Running[id];
}

// Float:q_kz_player_getTimer(id)
public Float:_q_kz_player_getTimer(plugin, params) {
	if(params != 1) {
		log_error(AMX_ERR_NATIVE, "Parameters do not match. Expected 1, found %d", params);
		return 0.0;
	}
	
	new id = get_param(1);
	if((id < 1) || (id > 32)) {
		log_error(AMX_ERR_NATIVE, "Invalid player id %d", id);
		
		return 0.0;
	}
	
	if(g_player_run_Running[id]) {
		if(g_player_run_Paused[id]) {
			return (g_player_run_PauseTime[id] - g_player_run_StartTime[id]);
		}
		else {
			return (get_gametime() - g_player_run_StartTime[id]);
		}
	}
	
	return 0.0;
}

// q_kz_getHudColor(&r, &g, &b)
public _q_kz_getHudColor(plugin, params) {
	if(params != 3) {
		log_error(AMX_ERR_NATIVE, "Parameters do not match. Expected 3, found %d", params);
		return;
	}
	
	new szColor[12], red[4], green[4], blue[4];
	get_pcvar_string(cvar_PrintColor, szColor, charsmax(szColor));
	parse(szColor, red, 3, green, 3, blue, 3);
	
	set_param_byref(1, str_to_num(red));
	set_param_byref(2, str_to_num(green));
	set_param_byref(3, str_to_num(blue));
}

// q_kz_isStartOriginFound()
public _q_kz_isStartOriginFound(plugin, params) {
	return g_start_bDefault;
}

// q_kz_getStartOrigin(Float:origin[3])
public _q_kz_getStartOrigin(plugin, params) {
	if(params != 1) {
		log_error(AMX_ERR_NATIVE, "Parameters do not match. Expected 1, found %d", params);
		return 0;
	}
	
	if(g_start_bDefault) {
		set_array_f(1, g_start_vDefault, sizeof(g_start_vDefault));
		
		return 1;
	}
	
	return 0;
}

// q_kz_isStopOriginFound()
public _q_kz_isStopOriginFound(plugin, params) {
	return g_end_bDefault;
}

// q_kz_getStopOrigin(Float:origin[3])
public _q_kz_getStopOrigin(plugin, params) {
	if(params != 1) {
		log_error(AMX_ERR_NATIVE, "Parameters do not match. Expected 1, found %d", params);
		return 0;
	}
	
	if(g_end_bDefault) {
		set_array_f(1, g_end_vDefault, sizeof(g_end_vDefault));
		
		return 1;
	}
	
	return 0;
}

// q_kz_player_isVip(id)
public _q_kz_player_isVip(plugin, params) {
	if(params != 1) {
		log_error(AMX_ERR_NATIVE, "Parameters do not match. Expected 1, found %d", params);
		return 0;
	}
	
	new id = get_param(1);
	if((id < 1) || (id > 32)) {
		log_error(AMX_ERR_NATIVE, "Invalid player id %d", id);
		
		return 0;
	}
	
	return g_player_VIP[id];
}

// q_kz_player_getCheckpoints(id)
public _q_kz_player_getCheckpoints(plugin, params) {
	if(params != 1) {
		log_error(AMX_ERR_NATIVE, "Parameters do not match. Expected 1, found %d", params);
		return 0;
	}
	
	new id = get_param(1);
	if((id < 1) || (id > 32)) {
		log_error(AMX_ERR_NATIVE, "Invalid player id %d", id);
		
		return 0;
	}
	
	return g_player_CPcounter[id];
}

// q_kz_player_getTeleports(id)
public _q_kz_player_getTeleports(plugin, params) {
	if(params != 1) {
		log_error(AMX_ERR_NATIVE, "Parameters do not match. Expected 1, found %d", params);
		return 0;
	}
	
	new id = get_param(1);
	if((id < 1) || (id > 32)) {
		log_error(AMX_ERR_NATIVE, "Invalid player id %d", id);
		
		return 0;
	}
	
	return g_player_TPcounter[id];
}

// q_kz_registerReward(name[], handler[], callback[] = "")
public _q_kz_registerReward(plugin, params) {
	if((params < 2) || (params > 3)) {
		log_error(AMX_ERR_NATIVE, "Parameters do not match. Expected 2 or 3, found %d", params);
		return;
	}
	
	if(!g_rewards_registering) {
		log_error(AMX_ERR_NATIVE, "qkz_register_reward can only be called inside ^"QKZ_RegisterRewards^" forward");
		return;
	}
	
	new szhandler[32];
	get_array(2, szhandler, charsmax(szhandler));
	if(szhandler[0] == 0) {
		log_error(AMX_ERR_NATIVE, "Handler function not given");
		return;
	}
	
	new phandler = get_func_id(szhandler, plugin);
	if(phandler == -1) {
		log_error(AMX_ERR_NATIVE, "Handler function ^"%s^" not found", szhandler);
	}
	
	new name[32];
	get_string(1, name, charsmax(name));
	if(name[0] == 0) {
		log_error(AMX_ERR_NATIVE, "Reward name not given");
		return;
	}
	
	new callback[32];
	get_string(3, callback, charsmax(callback));
	
	ArrayPushString(g_rewards_name, name);
	ArrayPushCell(g_rewards_plugin, plugin);
	ArrayPushCell(g_rewards_handler, phandler);
	ArrayPushCell(g_rewards_callback, get_func_id(callback, plugin));
}

// q_kz_getStartButtonEntities()
public _q_kz_getStartButtonEntities(plugin, params) {
	return _:g_startButtonEntities;
}

public _q_kz_getStopButtonEntities(plugin, params) {
	return _:g_stopButtonEntities;
}

// q_kz_registerForward(Q_KZ_Forward, callback[], _post = 0)
public _q_kz_registerForward(plugin, params) {
	if(params != 3) {
		log_error(AMX_ERR_NATIVE, "Parameters do not match. Expected 3, found %d", params);
		return;
	}
	
	new handler[32];
	get_string(2, handler, charsmax(handler));
	if(get_func_id(handler, plugin) == -1) {
		log_error(AMX_ERR_NATIVE, "Handler function ^"%s^" not found", handler);
		return;
	}
	
	new forwardType = get_param(1);
	new isForwardPost = get_param(3);
	switch(forwardType) {
	case Q_KZ_TimerStart: {
		new phandler = CreateOneForward(plugin, handler, FP_CELL);
		ArrayPushCell(isForwardPost ? forward_TimerStart_post : forward_TimerStart_pre, phandler);
	}
	case Q_KZ_TimerStop: {
		new phandler = CreateOneForward(plugin, handler, FP_CELL, FP_CELL);
		ArrayPushCell(isForwardPost ? forward_TimerStop_post : forward_TimerStop_pre, phandler);
	}
	case Q_KZ_TimerPause: {
		new phandler = CreateOneForward(plugin, handler, FP_CELL, FP_CELL);
		ArrayPushCell(isForwardPost ? forward_TimerPause_post : forward_TimerPause_pre, phandler);
	}
	case Q_KZ_OnCheckpoint: {
		new phandler = CreateOneForward(plugin, handler, FP_CELL);
		ArrayPushCell(isForwardPost ? forward_OnCheckpoint_post : forward_OnCheckpoint_pre, phandler);
	}
	case Q_KZ_OnTeleport: {
		new phandler = CreateOneForward(plugin, handler, FP_CELL);
		ArrayPushCell(isForwardPost ? forward_OnTeleport_post : forward_OnTeleport_pre, phandler);
	}
	default: {
		log_error(AMX_ERR_NATIVE, "Unknown forward type");
	}
	}
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* CStrike to FakeMeta										   *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

stock q_set_user_team(id, {CsTeams,_}:team, {CsInternalModel,_}:model = CS_DONTCHANGE) {
	set_pdata_int(id, OFFSET_TEAM, _:team, EXTRA_OFFSET);
	if(model) {
		set_pdata_int(id, OFFSET_INTERNALMODEL, _:model, EXTRA_OFFSET);
	}
	
	dllfunc(DLLFunc_ClientUserInfoChanged, id, engfunc(EngFunc_GetInfoKeyBuffer, id));
	
	message_TeamInfo(id, _:team);
}

stock CsTeams:q_get_user_team(id, &{CsInternalModel,_}:model = CS_DONTCHANGE) {
	model = CsInternalModel:get_pdata_int(id, OFFSET_INTERNALMODEL, EXTRA_OFFSET);
	
	return CsTeams:get_pdata_int(id, OFFSET_TEAM, EXTRA_OFFSET);
}

stock q_set_weapon_ammo(wpn_ent, ammo) {
	set_pdata_int(wpn_ent, OFFSET_CLIPAMMO, ammo, EXTRA_OFFSET_WEAPONS);
}

stock q_set_user_bpammo(id, weapon, ammo) {
	set_pdata_int(id, g_weapon_AmmoOffset[weapon], ammo, EXTRA_OFFSET);
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* Misc Functions
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

load_Spawns() {
	formatex(g_file_spawns, charsmax(g_file_spawns), "%s/spawns.dat", g_dir_data);
	
	new f = fopen(g_file_spawns, "rb");
	if(!f) {
		return;
	}
	
	new iSpawns;
	new szMapName[32];
	
	new iSize = file_size(g_file_spawns);
	
	while(ftell(f) < iSize) {
		fread_blocks(f, szMapName, 32, BLOCK_BYTE);
		
		if(equal(g_map_Name, szMapName)) {
			fread(f, iSpawns, BLOCK_BYTE);
			g_map_Spawns = iSpawns;
			g_map_SpawnsNeeded = 32 - g_map_Spawns;
		}
		else {
			fseek(f, 1, SEEK_CUR);
		}
	}
	
	fclose(f);
}

check_Spawns() {
	if(g_map_Spawns) {
		return;
	}
	
	new f = fopen(g_file_spawns, "ab");
	if(!f) {
		return;
	}

	fwrite_blocks(f, g_map_Name, 32, BLOCK_BYTE);
	fwrite(f, g_map_SpawnCount, BLOCK_BYTE);
	
	fclose(f);
	
	server_cmd("restart");
}

save_ButtonPositions() {
	new f = fopen(g_file_buttons, "rb+");
	if(f) {
		new count;
		fread(f, count, BLOCK_INT);
		
		new found = false;
		new map[32];
		for(new i = 0; i < count; ++i) {
			fread_blocks(f, map, sizeof(map), BLOCK_BYTE);
			if(equal(map, g_map_Name)) {
				found = true;
				
				fseek(f, 0, SEEK_CUR);
				
				fwrite_blocks(f, _:g_start_vDefault, 3, BLOCK_INT);
				fwrite_blocks(f, _:g_end_vDefault, 3, BLOCK_INT);
				
				break;
			}
			else {
				fseek(f, 24, SEEK_CUR);
			}
		}
		
		if(!found) {
			fseek(f, 0, SEEK_CUR);
			
			fwrite_blocks(f, g_map_Name, sizeof(g_map_Name), BLOCK_BYTE);
			fwrite_blocks(f, _:g_start_vDefault, 3, BLOCK_INT);
			fwrite_blocks(f, _:g_end_vDefault, 3, BLOCK_INT);
		}
		
		fclose(f);
	}
	else {
		f = fopen(g_file_buttons, "wb");
		fwrite(f, 1, BLOCK_INT);
		fwrite_blocks(f, g_map_Name, sizeof(g_map_Name), BLOCK_BYTE);
		fwrite_blocks(f, _:g_start_vDefault, 3, BLOCK_INT);
		fwrite_blocks(f, _:g_end_vDefault, 3, BLOCK_INT);
		fclose(f);
	}
}

load_ButtonPositions() {
	new f = fopen(g_file_buttons, "rb");
	if(!f) {
		return;
	}
	
	new count;
	fread(f, count, BLOCK_INT);
	
	new map[32];
	for(new i = 0; i < count; ++i) {
		fread_blocks(f, map, sizeof(map), BLOCK_BYTE);
		if(equal(map, g_map_Name)) {
			fread_blocks(f, _:g_start_vDefault, 3, BLOCK_INT);
			fread_blocks(f, _:g_end_vDefault, 3, BLOCK_INT);
			
			if(g_start_vDefault[0] && g_start_vDefault[1] && g_start_vDefault[2]) {
				g_start_bDefault = true;
			}
			
			if(g_end_vDefault[0] && g_end_vDefault[1] && g_end_vDefault[2]) {
				g_end_bDefault = true;
			}
		}
		else {
			fseek(f, 24, SEEK_CUR);
		}
	}
	
	fclose(f);
}

find_Buttons() {
	new const szStart[][] = {"counter_start", "clockstartbutton", "firsttimerelay", "gogogo", "multi_start", "counter_start_button"};
	new Trie:tStart = TrieCreate();
	for(new i = 0; i < sizeof(szStart); i++) {
		TrieSetCell(tStart, szStart[i], 1);
	}
	
	new const szStop[][] = {"counter_off", "clockstop", "clockstopbutton", "multi_stop", "stop_counter"};
	new Trie:tStop = TrieCreate();
	for(new i = 0; i < sizeof(szStop); i++) {
		TrieSetCell(tStop, szStop[i], 1);
	}
	
	new ent = -1;
	new szTarget[32];
	while((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "func_button"))) {
		pev(ent, pev_target, szTarget, charsmax(szTarget));
		
		if(TrieKeyExists(tStart, szTarget)) {
			SET_BITVECTOR(g_map_ent_StartButton, ent);
			ArrayPushCell(g_startButtonEntities, ent);
		}
		else if(TrieKeyExists(tStop, szTarget)) {
			SET_BITVECTOR(g_map_ent_EndButton, ent);
			ArrayPushCell(g_stopButtonEntities, ent);
		}
		else {
			pev(ent, pev_targetname, szTarget, charsmax(szTarget));
			
			if(TrieKeyExists(tStart, szTarget)) {
				SET_BITVECTOR(g_map_ent_StartButton, ent);
				ArrayPushCell(g_startButtonEntities, ent);
			}
			else if(TrieKeyExists(tStop, szTarget)) {
				SET_BITVECTOR(g_map_ent_EndButton, ent);
				ArrayPushCell(g_stopButtonEntities, ent);
			}
		}
	}
	
	TrieDestroy(tStart);
	TrieDestroy(tStop);
}

RemoveJunkEntities() {
	new ent;
	
	for(new i = 0; i < sizeof(g_szRemoveEnts); ++i) {
		ent = -1;
		
		while((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", g_szRemoveEnts[i]))) {
			engfunc(EngFunc_RemoveEntity, ent);
		}
	}
}

find_Healer() {
	new const szNull[] = "common/null.wav";
	
	new ent = -1;
	while((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "func_door"))) {
		new Float:damage;
		pev(ent, pev_dmg, damage);
		
		if(damage < -999.0) {
			set_pev(ent, pev_noise1, szNull);
			set_pev(ent, pev_noise2, szNull);
			set_pev(ent, pev_noise3, szNull);
			
			g_map_HealerExists = true;
		}
	}
}

run_reset(id) {
	g_player_CPcounter[id]		 = 0;
	g_player_TPcounter[id]		 = 0;
	g_player_run_Running[id]	 = false;
	if(g_player_run_Paused[id]) {
		set_pev(id, pev_flags, pev(id, pev_flags) & ~FL_FROZEN);
	}
	g_player_run_Paused[id]		 = false;
	g_player_run_WeaponID[id]	 = 0;
	g_player_run_StartTime[id]	 = 0.0;
	g_player_run_PauseTime[id]	 = 0.0;
	
	message_HideWeapon(id, HIDEW_TIMER | HIDEW_MONEY);
	message_Crosshair(id, 0);
	
	if(task_exists(TASKID_ROUNDTIME + id)) {
		remove_task(TASKID_ROUNDTIME + id);
	}
}

psave_save(id) {
	g_player_psave_time[id] = q_kz_player_getTimer(id);
	g_player_psave_checkpoints[id] = g_player_CPcounter[id];
	g_player_psave_teleports[id] = g_player_TPcounter[id];
	g_player_psave_weapon[id] = g_player_run_WeaponID[id];
	pev(id, pev_origin, g_player_psave_origin[id]);
	
	q_kz_player_stopTimer(id, "Timer saved");
	
	g_player_psave_exists[id] = true;
}

psave_restore(id) {
	if(!g_player_psave_exists[id]) {
		return;
	}
	
	fm_give_item(id, g_sz_WeaponEntName[g_player_psave_weapon[id]]);
	event_RunStart(id);
	g_player_run_StartTime[id] = get_gametime() - g_player_psave_time[id];
	g_player_CPcounter[id] = g_player_psave_checkpoints[id];
	g_player_TPcounter[id] = g_player_psave_teleports[id];
	g_player_CPorigin[id][0] = g_player_psave_origin[id];
	g_player_CPorigin[id][1] = g_player_psave_origin[id];
	set_pev(id, pev_gravity, 1.0);
	set_pev(id, pev_velocity, Float:{0.0, 0.0, 0.0});
	set_pev(id, pev_flags, pev(id, pev_flags) | FL_DUCKING);
	set_pev(id, pev_origin, g_player_CPorigin[id][0]);
	clcmd_Pause(id);
	
	g_player_psave_exists[id] = false;
}

psave_onPlayerJoin(id) {
	g_player_psave_exists[id] = false;
	
	new filePath[128];
	formatex(filePath, charsmax(filePath), "%s/psave.dat", g_dir_data);
	new f = fopen(filePath, "r+b");
	if(!f) {
		return;
	}
	
	new authId[40];
	get_user_authid(id, authId, charsmax(authId));
	
	new headerLength;
	fread(f, headerLength, BLOCK_INT);
	fseek(f, headerLength, SEEK_CUR); // skip header content
	
	new entryCount;
	fread(f, entryCount, BLOCK_INT);
	new mapName[32];
	new playerAuthId[40];
	for(new i = 0; i < entryCount; ++i) {
		fread_blocks(f, mapName, sizeof(mapName), BLOCK_BYTE);
		if(!equali(mapName, g_map_Name)) {
			fseek(f, 68, SEEK_CUR);
			continue;
		}
		
		fread_blocks(f, playerAuthId, sizeof(playerAuthId), BLOCK_BYTE);
		if(!equali(authId, playerAuthId)) {
			fseek(f, 28, SEEK_CUR);
			continue;
		}
		
		g_player_psave_exists[id] = true;
		fread(f, _:g_player_psave_time[id], BLOCK_INT);
		fread(f, g_player_psave_checkpoints[id], BLOCK_INT);
		fread(f, g_player_psave_teleports[id], BLOCK_INT);
		fread(f, g_player_psave_weapon[id], BLOCK_INT);
		fread_blocks(f, _:g_player_psave_origin[id], sizeof(g_player_psave_origin[]), BLOCK_INT);
		
		fseek(f, -100, SEEK_CUR);
		fwrite(f, 0, BLOCK_BYTE); // nullify last entry
		
		break;
	}
	
	fclose(f);
}

psave_onPlayerLeave(id) {
	if(!g_player_psave_exists[id]) {
		return;
	}
	
	g_player_psave_exists[id] = false;
	
	new filePath[128];
	formatex(filePath, charsmax(filePath), "%s/psave.dat", g_dir_data);
	new f = fopen(filePath, "r+b");
	if(!f) {
		// log weird error?
		return;
	}
	
	// skip header
	new headerLength;
	fread(f, headerLength, BLOCK_INT);
	fseek(f, headerLength, SEEK_CUR);
	
	// increment entry count
	new entryCount;
	fread(f, entryCount, BLOCK_INT);
	fseek(f, -4, SEEK_CUR);
	fwrite(f, ++entryCount, BLOCK_INT);
	
	// goto end of the file
	fseek(f, 0, SEEK_END);
	
	new authId[40];
	get_user_authid(id, authId, charsmax(authId));
	
	// add another entry
	fwrite_blocks(f, g_map_Name, sizeof(g_map_Name), BLOCK_BYTE);
	fwrite_blocks(f, authId, sizeof(authId), BLOCK_BYTE);
	fwrite(f, _:g_player_psave_time[id], BLOCK_INT);
	fwrite(f, g_player_psave_checkpoints[id], BLOCK_INT);
	fwrite(f, g_player_psave_teleports[id], BLOCK_INT);
	fwrite(f, g_player_psave_weapon[id], BLOCK_INT);
	fwrite_blocks(f, _:g_player_psave_origin[id], sizeof(g_player_psave_origin[]), BLOCK_INT);
	
	fclose(f);
}

psave_onPluginInit() {
	new filePath[128];
	formatex(filePath, charsmax(filePath), "%s/psave.dat", g_dir_data);
	if(file_exists(filePath)) {
		return;
	}
	
	new f = fopen(filePath, "wb");
	if(!f) {
		// log weird error?
		return;
	}
	
	fwrite(f, 0, BLOCK_INT); // header length
	fwrite(f, 0, BLOCK_INT); // entry count
	
	fclose(f);
}

psave_onPluginEnd() {
	new oldFilePath[128];
	formatex(oldFilePath, charsmax(oldFilePath), "%s/psave.dat", g_dir_data);
	
	new newFilePath[128];
	formatex(newFilePath, charsmax(newFilePath), "%s/psave_temp.dat", g_dir_data);
	
	new of = fopen(oldFilePath, "rb");
	new nf = fopen(newFilePath, "w+b");
	if(!of || !nf) {
		// log weird error?
		return;
	}
	
	new headerLength;
	fread(of, headerLength, BLOCK_INT);
	fwrite(nf, headerLength, BLOCK_INT);
	new headerData;
	for(new i = 0; i < headerLength; ++i) {
		fread(of, headerData, BLOCK_BYTE);
		fwrite(nf, headerData, BLOCK_BYTE);
	}
	
	new entryCount;
	fread(of, entryCount, BLOCK_INT);
	fwrite(nf, 0, BLOCK_INT); // will be set at the end
	
	new entry[100];
	for(new i = 0, count = entryCount; i < count; ++i) {
		fread_blocks(of, entry, sizeof(entry), BLOCK_BYTE);
		if(entry[0] == 0) {
			--entryCount;
		}
		else {
			fwrite_blocks(nf, entry, sizeof(entry), BLOCK_BYTE);
		}
	}
	
	fseek(nf, 4 + headerLength, SEEK_SET);
	fwrite(nf, entryCount, BLOCK_INT);
	
	fclose(of);
	fclose(nf);
	delete_file(oldFilePath);
	rename_file(newFilePath, oldFilePath, true);
}

public psave_onTimerStop(id, bool:successful) {
	if(g_player_psave_exists[id]) {
		g_player_psave_exists[id] = false;
	}
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* Fakemeta UTIL											   *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#define fm_create_entity(%1) engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, %1))

stock fm_get_user_weapon_entity(id, wid = 0) {
	new weap = wid, clip, ammo;
	if(!weap && !(weap = get_user_weapon(id, clip, ammo))) {
		return 0;
	}
	
	new class[32];
	get_weaponname(weap, class, sizeof class - 1);

	return fm_find_ent_by_owner(-1, class, id);
}

stock fm_strip_user_weapons(index) {
	new ent = fm_create_entity("player_weaponstrip");
	if(!pev_valid(ent)) {
		return 0;
	}

	dllfunc(DLLFunc_Spawn, ent);
	dllfunc(DLLFunc_Use, ent, index);
	engfunc(EngFunc_RemoveEntity, ent);

	return 1;
}


stock fm_give_item(index, const item[]) {
	if(!equal(item, "weapon_", 7) && !equal(item, "ammo_", 5) && !equal(item, "item_", 5) && !equal(item, "tf_weapon_", 10)) {
		return 0;
	}

	new ent = fm_create_entity(item);
	if(!pev_valid(ent)) {
		return 0;
	}

	new Float:origin[3];
	pev(index, pev_origin, origin);
	set_pev(ent, pev_origin, origin);
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN);
	dllfunc(DLLFunc_Spawn, ent);

	new save = pev(ent, pev_solid);
	dllfunc(DLLFunc_Touch, ent, index);
	if(pev(ent, pev_solid) != save) {
		return ent;
	}

	engfunc(EngFunc_RemoveEntity, ent);

	return -1;
}

stock fm_find_ent_by_owner(index, const classname[], owner, jghgtype = 0) {
	new strtype[11] = "classname", ent = index;
	switch (jghgtype) {
	case 1: {
		strtype = "target";
	}
	case 2: {
		strtype = "targetname";
	}
	}

	while((ent = engfunc(EngFunc_FindEntityByString, ent, strtype, classname)) && pev(ent, pev_owner) != owner) {}

	return ent;
}
