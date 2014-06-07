#include <amxmodx>

#define PLUGIN "Q"
#define VERSION "1.0"
#define AUTHOR "Quaker"

new g_dir_data[128];

new Array:g_cvar_plugin;
new Array:g_cvar_pluginCvarIndices;
new Array:g_cvar_pointer;
new Array:g_cvar_name;
new Array:g_cvar_defaultValue;
new Array:g_cvar_description;

public plugin_natives( )
{
	register_library( "q" );
	
	register_native( "q_get_datadir", "_q_get_datadir" );
	register_native("q_registerCvar", "_q_registerCvar");
	
	g_cvar_plugin = ArrayCreate(1, 8);
	g_cvar_pluginCvarIndices = ArrayCreate(1, 8);
	g_cvar_pointer = ArrayCreate(1, 8);
	g_cvar_name = ArrayCreate(32, 8);
	g_cvar_defaultValue = ArrayCreate(128, 8);
	g_cvar_description = ArrayCreate(256, 8);
}

public plugin_precache( )
{
	get_localinfo( "amxx_datadir", g_dir_data, charsmax(g_dir_data) );
	add( g_dir_data, charsmax(g_dir_data), "/q" );
	if( !dir_exists( g_dir_data ) ) mkdir( g_dir_data );
}

public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, AUTHOR );
}

public plugin_end() {
	writeConfig();
}

writeConfig() {
	new path[256];
	get_localinfo("amxx_configsdir", path, charsmax(path));
	add(path[strlen(path)-1], charsmax(path), "/q.cfg", 6);
	
	if(file_exists(path)) {
		delete_file(path);
	}
	
	new f = fopen(path, "wt");
	if(!f) {
		return;
	}
	
	for(new i = 0, pluginCount = ArraySize(g_cvar_plugin); i < pluginCount; ++i) {
		new pluginName[32];
		get_plugin(ArrayGetCell(g_cvar_plugin, i), _, _, pluginName, charsmax(pluginName), _, _, _, _, _, _);
		new Array:cvarIndices = ArrayGetCell(g_cvar_pluginCvarIndices, i);
		fprintf(f, "//-------------^n// %s^n//-------------^n", pluginName);
		for(new j = 0, cvarCount = ArraySize(cvarIndices); j < cvarCount; ++j) {
			new cvarIndex = ArrayGetCell(cvarIndices, j);
			new cvarName[32];
			ArrayGetString(g_cvar_name, cvarIndex, cvarName, charsmax(cvarName));
			new cvarPointer = ArrayGetCell(g_cvar_pointer, cvarIndex);
			new cvarValue[128];
			get_pcvar_string(cvarPointer, cvarValue, charsmax(cvarValue));
			new cvarDefaultValue[128];
			ArrayGetString(g_cvar_defaultValue, cvarIndex, cvarDefaultValue, charsmax(cvarDefaultValue));
			new cvarDescription[256];
			ArrayGetString(g_cvar_description, cvarIndex, cvarDescription, charsmax(cvarDescription));
			
			fprintf(f, "// %s (Default: %s)^n%s %s^n^n", cvarDescription, cvarDefaultValue, cvarName, cvarValue);
		}
	}
	
	fclose(f);
}

public _q_get_datadir( plugin, params )
{
	if( params != 2 )
	{
		log_error( AMX_ERR_NATIVE, "error" );
	}
	
	set_string( 1, g_dir_data, get_param( 2 ) );
}

// q_registerCvar(cvarPointer, defaultValue[], description[])
public _q_registerCvar(plugin, params) {
	if(params != 3) {
		log_error(AMX_ERR_NATIVE, "Parameters do not match. Expected 3, found %d", params);
		return;
	}
	
	new pluginIndex = -1;
	for(new i = 0, size = ArraySize(g_cvar_plugin); i < size; ++i) {
		if(ArrayGetCell(g_cvar_plugin, i) == plugin) {
			pluginIndex = i;
			break;
		}
	}
	new Array:pluginIndices;
	if(pluginIndex == -1) {
		pluginIndex = ArraySize(g_cvar_plugin);
		ArrayPushCell(g_cvar_plugin, plugin);
		pluginIndices = ArrayCreate(1, 1);
		ArrayPushCell(g_cvar_pluginCvarIndices, pluginIndices);
	}
	else {
		pluginIndices = ArrayGetCell(g_cvar_pluginCvarIndices, pluginIndex);
	}
	
	new cvarPointer = get_param(1);
	for(new i = 0, size = ArraySize(g_cvar_pointer); i < size; ++i) {
		if(cvarPointer == ArrayGetCell(g_cvar_pointer, i)) {
			return;
		}
	}
	new cvarIndex = ArraySize(g_cvar_pointer);
	ArrayPushCell(pluginIndices, cvarIndex);
	
	new defaultValue[128];
	get_string(2, defaultValue, charsmax(defaultValue));
	new description[256];
	get_string(3, description, charsmax(description));
	
	new name[32];
	new tempPointer;
	for(new i = 0, size = get_plugins_cvarsnum(); i < size; ++i) {
		get_plugins_cvar(i, name, charsmax(name), _, _, tempPointer);
		if(cvarPointer == tempPointer) {
			break;
		}
	}
	
	ArrayPushCell(g_cvar_pointer, cvarPointer);
	ArrayPushString(g_cvar_name, name);
	ArrayPushString(g_cvar_defaultValue, defaultValue);
	ArrayPushString(g_cvar_description, description);
}