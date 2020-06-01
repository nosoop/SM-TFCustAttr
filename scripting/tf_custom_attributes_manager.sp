/**
 * [TF2] Custom Attribute Manager
 * 
 * Companion plugin for the main Custom Attributes plugin.
 * 
 * This plugin allows loading of a basic key / value configuration file that applies custom
 * attributes by definition index.
 */
#pragma semicolon 1
#include <sourcemod>

#pragma newdecls required

#define PLUGIN_VERSION "1.0.0"
public Plugin myinfo = {
	name = "[TF2] Custom Attribute Manager",
	author = "nosoop",
	description = "Exposes a configuration file for custom attributes.",
	version = PLUGIN_VERSION,
	url = "localhost"
}

KeyValues g_PresetAttributes;

public void OnPluginStart() {
	if (LoadConfigurationFile()) {
		LogMessage("Successfully loaded configuration file.");
	}
	
	RegAdminCmd("tf2custattrman_reload", ReloadAttributeConfiguration, ADMFLAG_ROOT);
}

/** 
 * Checks if there is a corresponding defindex section in the configuration file, and then
 * imports the entire section into the forward's KeyValues handle.
 */
public Action TF2CustAttr_OnKeyValuesAdded(int entity, KeyValues kv) {
	if (HasEntProp(entity, Prop_Send, "m_iItemDefinitionIndex")) {
		g_PresetAttributes.Rewind();
		
		char defString[16];
		IntToString(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), defString,
				sizeof(defString));
		
		if (g_PresetAttributes.JumpToKey(defString, false)) {
			kv.Import(g_PresetAttributes);
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

/**
 * Reloads the configuration file.
 */
public Action ReloadAttributeConfiguration(int client, int argc) {
	if (LoadConfigurationFile()) {
		ReplyToCommand(client, "Successfully reloaded attribute configuration.");
	} else {
		ReplyToCommand(client, "Failed to reload attribute configuration.");
	}
	return Plugin_Handled;
}

bool LoadConfigurationFile() {
	char attributeFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, attributeFile, sizeof(attributeFile), "%s",
			"configs/tf_custom_attributes.txt");
	
	g_PresetAttributes = new KeyValues("Custom Attributes");
	
	if (FileExists(attributeFile)) {
		g_PresetAttributes.ImportFromFile(attributeFile);
		return true;
	}
	return false;
}
