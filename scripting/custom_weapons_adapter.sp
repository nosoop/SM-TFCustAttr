/**
 * [TF2CA] Custom Weapons Config Adapter for Custom Attributes
 * 
 * Unwieldly name for it, I know.
 * 
 * Allows attributes written for Custom Attributes (my project) to be added to weapons defined
 * through an existing Custom Weapons config (not my project).
 */
#pragma semicolon 1
#include <sourcemod>

#include <sdktools>

#pragma newdecls required
#include <tf_custom_attributes>

#define PLUGIN_VERSION "1.2.2"
public Plugin myinfo = {
	name = "[TF2CA] Custom Weapons Config Adapter for Custom Attributes",
	author = "nosoop",
	description = "Adapter to apply Custom Attributes framework attributes through "
			... "Custom Weapons configuration files.",
	version = PLUGIN_VERSION,
	url = "https://github.com/nosoop/SM-TFCustAttr"
}

/**
 * Plugin name to use in the Custom Weapons config when referring to attributes written for
 * Custom Attributes.
 */
#define CUSTOM_ATTR_ADAPTER_PLUGIN_NAME "custom-attribute-adapter"
#define CUSTOM_ATTR_ADAPTER_PLUGIN_REQUIRED_NAME CUSTOM_ATTR_ADAPTER_PLUGIN_NAME ... "/"

/**
 * Compatibility shim for Custom Weapons 2. (customweaponstf.inc)
 * 
 * Forward is called after `TF2Items_GiveNamedItem` and `EquipPlayerWeapon`
 */
public Action CustomWeaponsTF_OnAddAttribute(int weapon, int client, const char[] attrib,
		const char[] plugin, const char[] value) {
	if (!IsRegisteredForAdapterPlugin(plugin)) {
		return Plugin_Continue;
	}
	
	TF2CustAttr_SetString(weapon, attrib, value);
	return Plugin_Handled;
}

/**
 * Compatibility shim for Custom Weapons 3. (cw3-attributes.inc)
 * 
 * Forward is called in `AddAttribute`, which can be called by the `CW3_AddAttribute` native,
 * the `sm_cw3_addattribute` command, or from the `CW3_OnWeaponEntCreated` forward.
 */
public Action CW3_OnAddAttribute(int slot, int client, const char[] attrib, const char[] plugin,
		const char[] value, bool whileActive) {
	if (!IsRegisteredForAdapterPlugin(plugin)) {
		return Plugin_Continue;
	}
	
	int weapon = GetPlayerWeaponSlot(client, slot);
	if (!IsValidEntity(weapon)) {
		LogError("Could not find a weapon in slot %d to apply '%s'.  The game might not "
				... "actually consider it a proper weapon (maybe it's a watch or shield?).  "
				... "Move this attribute to the 'attributes' section to use the CW2 forward and "
				... "retry.", slot, attrib);
		return Plugin_Continue;
	}
	
	TF2CustAttr_SetString(weapon, attrib, value);
	return Plugin_Handled;
}

/**
 * Returns true if the plugin name for CW2/3 starts with the constant
 * `CUSTOM_ATTR_ADAPTER_PLUGIN_NAME`.
 * 
 * If the plugin name is in the format matching the prefix
 * `CUSTOM_ATTR_ADAPTER_PLUGIN_REQUIRED_NAME`, the string after the prefix is treated as a
 * base filename and checked to see if a plugin with the name is loaded in.  This provides
 * slightly improved troubleshooting capabilities, as Custom Attributes has no way to indicate
 * that an attribute isn't valid.
 * 
 * Provided the latter prefix isn't matched, arbitrary suffixes are allowed for weapon
 * developers to annotate which plugin actually implements the attribute.
 */
static bool IsRegisteredForAdapterPlugin(const char[] plugin) {
	if (strncmp(plugin, CUSTOM_ATTR_ADAPTER_PLUGIN_NAME,
			strlen(CUSTOM_ATTR_ADAPTER_PLUGIN_NAME), false)) {
		// fails basic prefix check, attribute event is not for the adapter
		return false;
	}
	
	if (strncmp(plugin, CUSTOM_ATTR_ADAPTER_PLUGIN_REQUIRED_NAME,
			strlen(CUSTOM_ATTR_ADAPTER_PLUGIN_REQUIRED_NAME), false)) {
		// base prefix matches, but it does not match the prefix for the loaded plugin check
		return true;
	}
	
	bool bPluginAvailable =
			PluginExistsByBaseName(plugin[strlen(CUSTOM_ATTR_ADAPTER_PLUGIN_REQUIRED_NAME)]);
	if (!bPluginAvailable) {
		LogError("Could not find required attribute plugin %s",
				plugin[strlen(CUSTOM_ATTR_ADAPTER_PLUGIN_REQUIRED_NAME)]);
	}
	return bPluginAvailable;
}

/**
 * Returns true if the plugin with the specified base name is loaded in.
 */
stock bool PluginExistsByBaseName(const char[] filename) {
	bool bFound = false;
	Handle iter = GetPluginIterator();
	while (MorePlugins(iter) && !bFound) {
		char buffer[PLATFORM_MAX_PATH];
		GetPluginFilename(ReadPlugin(iter), buffer, sizeof(buffer));
		
		// normalize windows paths
		ReplaceString(buffer, sizeof(buffer), "\\", "/");
		
		// strip plugin extension
		int iExtension = StrContains(buffer, ".smx");
		if (iExtension != -1) {
			buffer[iExtension] = '\0';
		}
		
		bFound = strcmp(buffer, filename, false) == 0;
		if (bFound) {
			continue;
		}
		
		// start from last forward slash in the loaded plugin filename
		int iBaseName = FindCharInString(buffer, '/', true);
		if (iBaseName != -1) {
			bFound = StrEqual(buffer[iBaseName + 1], filename);
		}
	}
	delete iter;
	return bFound;
}
