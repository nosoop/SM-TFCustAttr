#pragma semicolon 1
#include <sourcemod>

#pragma newdecls required

#include <tf2_stocks>
#include <tf_custom_attributes>

#undef REQUIRE_PLUGIN
#tryinclude <tf2wearables>
#tryinclude <tf_econ_data>
#define REQUIRE_PLUGIN

#define PLUGIN_VERSION "1.0.0"
public Plugin myinfo = {
	name = "[TF2] Custom Attribute Debugger",
	author = "nosoop",
	description = "Dumps / adds custom attributes for self-testing",
	version = PLUGIN_VERSION,
	url = "https://github.com/nosoop/SM-TFCustAttr"
}

#if defined __tf_econ_data_included
bool g_bEconDataLoaded;
#endif

#if defined _tf2wearables_included_
bool g_bWearablesLoaded;
#endif

public void OnPluginStart() {
	RegAdminCmd("sm_custattr_show", ShowCustomAttributes, ADMFLAG_ROOT);
	RegAdminCmd("sm_custattr_add", AddAttributeToWeapon, ADMFLAG_ROOT);
}

public Action ShowCustomAttributes(int client, int argc) {
	if (!client) {
		ReplyToCommand(client, "This command can only be used on players.");
		return Plugin_Handled;
	}
	
	int target = client;
	if (argc > 0) {
		char targetString[64];
		GetCmdArg(1, targetString, sizeof(targetString));
		
		target = FindTarget(client, targetString, .immunity = false);
		
		if (!IsValidEntity(target)) {
			ReplyToCommand(client, "Invalid target string '%s'.", targetString);
			return Plugin_Handled;
		}
	}
	
	ListAttributes(client, target);

#if defined _tf2wearables_included_
	if (g_bWearablesLoaded) {
		for (TF2LoadoutSlot i; i < TF2_LOADOUT_SLOT_COUNT; i++) {
			ListAttributes(client, TF2_GetPlayerLoadoutSlot(target, i));
		}
	} else
#endif
	{
		for (int i; i < TFWeaponSlot_Item2 + 1; i++) {
			ListAttributes(client, GetPlayerWeaponSlot(target, i));
		}
	}
	
	return Plugin_Handled;
}

public Action AddAttributeToWeapon(int client, int argc) {
	if (argc < 2) {
		ReplyToCommand(client, "Usage: sm_custattr_add [name] [value]");
		return Plugin_Handled;
	}
	
	if (!client) {
		ReplyToCommand(client, "This command can only be used on players.");
		return Plugin_Handled;
	}
	
	int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (!IsValidEntity(activeWeapon)) {
		ReplyToCommand(client, "Not holding any weapon.");
		return Plugin_Handled;
	}
	
	// There's no hard limit for these internally, but these should be fine in a practical sense
	char name[128], value[256];
	GetCmdArg(1, name, sizeof(name));
	GetCmdArg(2, value, sizeof(value));
	
	SetRuntimeCustomAttribute(activeWeapon, name, value);
	ReplyToCommand(client, "Set attribute \"%s\" to value \"%s\" on active weapon.",
			name, value);
	return Plugin_Handled;
}

void ListAttributes(int client, int entity) {
	if (entity == -1) {
		return;
	}
	
	// Try to get an appropriate name for identification
	char name[64];
	if (entity <= MaxClients) {
		GetClientName(entity, name, sizeof(name));
#if defined __tf_econ_data_included
	} else if (g_bEconDataLoaded) {
		int itemdef = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
		TF2Econ_GetItemName(itemdef, name, sizeof(name));
#endif
	} else {
		GetEntityClassname(entity, name, sizeof(name));
	}
	
	// Access raw KV for iteration
	KeyValues kv = TF2CustAttr_GetAttributeKeyValues(entity);
	if (!kv || !kv.GotoFirstSubKey(false)) {
		delete kv;
		return;
	}
	
	char outbuf[4096];
	
	FormatAppend(outbuf, sizeof(outbuf), "---- Attributes for entity %d (%s)\n", entity, name);
	
	// Iterate over subsections at the same nesting level
	// Not too concerned about truncated values here
	char key[128], value[128];
	do {
		kv.GetSectionName(key, sizeof(key));
		kv.GetString(NULL_STRING, value, sizeof(value));
		
		FormatAppend(outbuf, sizeof(outbuf), "%s = '%s'\n", key, value);
	} while (kv.GotoNextKey(false));
	delete kv;
	
	ReplyToCommand(client, outbuf);
}

/**
 * Appends a format string to the end of a given buffer.
 */
void FormatAppend(char[] buffer, int maxlen, const char[] fmt, any...) {
	char[] concat = new char[maxlen];
	VFormat(concat, maxlen, fmt, 4);
	
	StrCat(buffer, maxlen, concat);
}

/**
 * Applies a custom attribute to the specified entity, creating a new handle if it doesn't
 * exist.
 * 
 * Might be a native in a future iteration of the Custom Attribute core plugin, but for now,
 * this will have to do.
 */
static void SetRuntimeCustomAttribute(int entity, const char[] attrib, const char[] value) {
	KeyValues attributes = TF2CustAttr_GetAttributeKeyValues(entity);
	if (!attributes) {
		attributes = new KeyValues("CustomAttributes");
	}
	
	attributes.SetString(attrib, value);
	TF2CustAttr_UseKeyValues(entity, attributes);
	delete attributes;
}

public void OnLibraryAdded(const char[] name) {
#if defined __tf_econ_data_included
	if (StrEqual(name, "tf_econ_data")) {
		g_bEconDataLoaded = true;
	}
#endif
#if defined _tf2wearables_included_
	if (StrEqual(name, "tf2wearables")) {
		g_bWearablesLoaded = true;
	}
#endif
}

public void OnLibraryRemoved(const char[] name) {
#if defined __tf_econ_data_included
	if (StrEqual(name, "tf_econ_data")) {
		g_bEconDataLoaded = false;
	}
#endif
#if defined _tf2wearables_included_
	if (StrEqual(name, "tf2wearables")) {
		g_bWearablesLoaded = false;
	}
#endif
}
