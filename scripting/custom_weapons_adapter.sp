/**
 * [TF2CA] Custom Weaponns Config Adapter for Custom Attributes
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

#define PLUGIN_VERSION "1.1.0"
public Plugin myinfo = {
	name = "[TF2CA] Custom Weaponns Config Adapter for Custom Attributes",
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
	
	SetRuntimeCustomAttribute(weapon, attrib, value);
	
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
	SetRuntimeCustomAttribute(weapon, attrib, value);
	
	return Plugin_Handled;
}

/**
 * Returns true if the plugin name for CW2/3 starts with `CUSTOM_ATTR_ADAPTER_PLUGIN_NAME`.
 * 
 * Arbitrary suffixes are allowed for weapon developers to annotate which plugin actually
 * implements the attribute, but it's never checked in any way.
 */
static bool IsRegisteredForAdapterPlugin(const char[] plugin) {
	return strncmp(plugin, CUSTOM_ATTR_ADAPTER_PLUGIN_NAME,
			strlen(CUSTOM_ATTR_ADAPTER_PLUGIN_NAME), false) == 0;
}

/**
 * Applies a custom attribute to the specified entity, creating a new handle if it doesn't
 * exist.
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
