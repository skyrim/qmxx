#include <amxmodx>
#include <amxmisc>
#include <fun>

#pragma semicolon 1

#define PLUGIN "Quaker's Weapons Menu"
#define VERSION "1.0"
#define AUTHOR "Quaker"

new const g_keys_main = MENU_KEY_0 | MENU_KEY_1 | MENU_KEY_2 | MENU_KEY_3 | MENU_KEY_4 | MENU_KEY_5 | MENU_KEY_6;
new const g_keys_pistols = MENU_KEY_0 | MENU_KEY_1 | MENU_KEY_2 | MENU_KEY_3 | MENU_KEY_4 | MENU_KEY_5 | MENU_KEY_6;
new const g_keys_shotguns = MENU_KEY_0 | MENU_KEY_1 | MENU_KEY_2;
new const g_keys_smg = MENU_KEY_0 | MENU_KEY_1 | MENU_KEY_2 | MENU_KEY_3 | MENU_KEY_4 | MENU_KEY_5;
new const g_keys_rifles = MENU_KEY_0 | MENU_KEY_1 | MENU_KEY_2 | MENU_KEY_3 | MENU_KEY_4 | MENU_KEY_5 | MENU_KEY_6 | MENU_KEY_7;
new const g_keys_machinegun = MENU_KEY_0 | MENU_KEY_1;
new const g_keys_sniperrifles = MENU_KEY_0 | MENU_KEY_1 | MENU_KEY_2 | MENU_KEY_3 | MENU_KEY_4;

public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
	
	register_menucmd( register_menuid( "\rQWeapons^n^n" ), g_keys_main, "menu_weapons_hnd" );
	register_menucmd( register_menuid( "\rQWeapons \ Pistols^n^n" ), g_keys_pistols, "menu_pistols_hnd" );
	register_menucmd( register_menuid( "\rQWeapons \ Shotguns^n^n" ), g_keys_shotguns, "menu_shotguns_hnd" );
	register_menucmd( register_menuid( "\rQWeapons \ SMG^n^n" ), g_keys_smg, "menu_smg_hnd" );
	register_menucmd( register_menuid( "\rQWeapons \ Rifles^n^n" ), g_keys_rifles, "menu_rifles_hnd" );
	register_menucmd( register_menuid( "\rQWeapons \ Machine Gun^n^n" ), g_keys_machinegun, "menu_machinegun_hnd" );
	register_menucmd( register_menuid( "\rQWeapons \ Sniper Rifles^n^n" ), g_keys_sniperrifles, "menu_sniperrifles_hnd" );
	
	register_clcmd( "say /w", "clcmd_weapons" );
}

public clcmd_weapons( id, level, cid )
{
	menu_weapons( id );
	
	return PLUGIN_HANDLED;
}

public menu_weapons( id )
{
	show_menu( id, g_keys_main, "\rQWeapons^n^n\r1. \wPistols^n\r2. \wShotguns^n\r3. \wSMG^n\r4. \wRifles^n\r5. \wMachine Gun^n\r6. \wSniper Rifles^n^n^n^n\r0. \yExit" );
}

public menu_weapons_hnd( id, item )
{
	switch( item )
	{
		case 0:
		{
			menu_pistols( id );
		}
		case 1:
		{
			menu_shotguns( id );
		}
		case 2:
		{
			menu_smg( id );
		}
		case 3:
		{
			menu_rifles( id );
		}
		case 4:
		{
			menu_machinegun( id );
		}
		case 5:
		{
			menu_sniperrifles( id );
		}
	}
}

public menu_pistols( id )
{
	show_menu( id, g_keys_pistols, "\rQWeapons \ Pistols^n^n\r1. \wUSP^n\r2. \wGlock^n\r3. \wDeagle^n\r4. \wFive-Seven^n\r5. \wP228 Compact^n\r6. \wDual-Elites^n^n^n^n\r0. \yBack" );
}

public menu_pistols_hnd( id, item )
{
	switch( item )
	{
		case 0:
		{
			give_item( id, "weapon_usp" );
		}
		case 1:
		{
			give_item( id, "weapon_glock18" );
		}
		case 2:
		{
			give_item( id, "weapon_deagle" );
		}
		case 3:
		{
			give_item( id, "weapon_fiveseven" );
		}
		case 4:
		{
			give_item( id, "weapon_p228" );
		}
		case 5:
		{
			give_item( id, "weapon_elite" );
		}
		case 9:
		{
			menu_weapons( id );
		}
	}
}

public menu_shotguns( id )
{
	show_menu( id, g_keys_shotguns, "\rQWeapons \ Shotguns^n^n\r1. \wM3^n\r2. \wXM1014^n^n^n^n^n^n^n^n\r0. \yBack" );
}

public menu_shotguns_hnd( id, item )
{
	switch( item )
	{
		case 9:
		{
			menu_weapons( id );
		}
	}
}

public menu_smg( id )
{
	show_menu( id, g_keys_smg, "\rQWeapons \ SMG^n^n\r1. \wTMP^n\r2. \wMP5 Navy^n\r3. \wMac-10^n\r4. \wP90^n\r5. \wUMP45^n^n^n^n^n\r0. \yBack" );
}

public menu_smg_hnd( id, item )
{
	switch( item )
	{
		case 9:
		{
			menu_weapons( id );
		}
	}
}

public menu_rifles( id )
{
	show_menu( id, g_keys_rifles, "\rQWeapons \ Rifles^n^n\r1. \wFamas^n\r2. \wAK47^n\r3. \wM4A1^n\r4. \wGalil^n\r5. \wSteyr Aug^n\r6. \wKrieg SG-552^n^n^n^n\r0. \yBack" );
}

public menu_rifles_hnd( id, item )
{
	switch( item )
	{
		case 9:
		{
			menu_weapons( id );
		}
	}
}

public menu_machinegun( id )
{
	show_menu( id, g_keys_machinegun, "\rQWeapons \ Machine Gun^n^n\r1. \wM249^n^n^n^n^n^n^n^n^n\r0. \yBack" );
}

public menu_machinegun_hnd( id, item )
{
	switch( item )
	{
		case 9:
		{
			menu_weapons( id );
		}
	}
}

public menu_sniperrifles( id )
{
	show_menu( id, g_keys_sniperrifles, "\rQWeapons \ Sniper Rifles^n^n\r1. \wScout^n\r2. \wAWP^n\r3. \wG3/SG-1^n\r4. \wSG-550^n^n^n^n^n^n\r0. \y Back" );
}

public menu_sniperrifles_hnd( id, item )
{
	switch( item )
	{
		case 9:
		{
			menu_weapons( id );
		}
	}
}
