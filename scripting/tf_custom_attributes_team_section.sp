/**
 * [TF2] Custom Attribute Team Subsection
 * 
 * Recognizes nested team subsections and moves the attributes to the top level to be applied.
 * All the attributes that may be applied need to be present before they are equipped on a
 * player (so you will need to switch loadouts and back to force regeneration).
 */
#pragma semicolon 1
#include <sourcemod>

#pragma newdecls required

#include <sdkhooks>
#include <tf2_stocks>
#include <tf_custom_attributes>

#define PLUGIN_VERSION "1.0.0"
public Plugin myinfo = {
	name = "[TF2] Custom Attribute Team Subsection Handler",
	author = "nosoop",
	description = "Allows for embedding team-specific subsections for Custom Attributes.",
	version = PLUGIN_VERSION,
	url = "https://github.com/nosoop/SM-TFCustAttr"
}

public void OnMapStart() {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			OnClientPutInServer(i);
		}
	}
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquipPre);
}

Action OnWeaponEquipPre(int client, int weapon) {
	KeyValues weaponKV = TF2CustAttr_GetAttributeKeyValues(weapon);
	if (!weaponKV) {
		PrintToServer("no weapon KV for %N / %d", client, weapon);
		return Plugin_Continue;
	}
	
	KeyValues mergeKV = new KeyValues("merging");
	
	PrintToServer("has");
	
	// look through nested sections
	weaponKV.GotoFirstSubKey(false);
	bool hasNext;
	do {
		char key[32];
		weaponKV.GetSectionName(key, sizeof(key));
		
		// look into nested section
		if (weaponKV.GetDataType(NULL_STRING) == KvData_None) {
			bool recognized;
			if (IsSectionNameValidForClient(client, key, recognized)) {
				//use a merge instead of Import in case we have `n > 1` matching sections
				KvMergeSubKeys(weaponKV, mergeKV);
			}
			// only remove sections that we've handled
			hasNext = recognized? weaponKV.DeleteThis() == 1 : weaponKV.GotoNextKey(false);
		} else {
			hasNext = weaponKV.GotoNextKey(false);
		}
	} while (hasNext);
	weaponKV.GoBack();
	
	KvMergeSubKeys(mergeKV, weaponKV);
	
	TF2CustAttr_UseKeyValues(weapon, weaponKV);
	
	delete mergeKV;
	delete weaponKV;
	
	return Plugin_Continue;
}

/**
 * Return `true` if the nested KV should be merged into the top level entry.
 * Set `recognized` to true if the section was handled and we can safely delete.
 */
bool IsSectionNameValidForClient(int client, const char[] section, bool &recognized) {
	TFTeam team = TF2_GetClientTeam(client);
	if (StrEqual(section, "red")) {
		recognized = true;
		return team == TFTeam_Red;
	} else if (StrEqual(section, "blue")) {
		recognized = true;
		return team == TFTeam_Blue;
	}
	recognized = false;
	return false;
}

/**
 * Copies the subkeys in the origin KeyValues to the destination KeyValues.
 * Any subkeys in the destination that are not overwritten are preserved.
 * 
 * @param recursive      If true, subsections are merged.  Otherwise, only the top-level subkeys
 *                       from the origin are copied to the destination.
 */
stock void KvMergeSubKeys(KeyValues origin, KeyValues dest, bool recursive = false,
		int keysize = 1024, int valuesize = 1024) {
	char[] key = new char[keysize];
	char[] value = new char[valuesize];
	
	origin.GotoFirstSubKey(false);
	do {
		origin.GetSectionName(key, keysize);
		if (origin.GetDataType(NULL_STRING) == KvData_None) {
			// subsection
			if (!recursive) {
				continue;
			}
			if (dest.JumpToKey(key)) {
				// merge with existing child
				KvMergeSubKeys(origin, dest, recursive, keysize, valuesize);
			} else {
				// import new child and don't traverse
				dest.JumpToKey(key, true);
				dest.Import(origin);
			}
			dest.GoBack();
		} else {
			// plain key / value pair
			origin.GetString(NULL_STRING, value, valuesize);
			dest.SetString(key, value);
		}
	} while (origin.GotoNextKey(false));
	origin.GoBack();
}
