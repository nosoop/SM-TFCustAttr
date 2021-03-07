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
#include <tf2utils>

#define PLUGIN_VERSION "1.1.0"
public Plugin myinfo = {
	name = "[TF2] Custom Attribute Team Subsection Handler",
	author = "nosoop",
	description = "Allows for embedding team-specific subsections for Custom Attributes.",
	version = PLUGIN_VERSION,
	url = "https://github.com/nosoop/SM-TFCustAttr"
}

public void OnPluginStart() {
	HookUserMessage(GetUserMessageId("PlayerLoadoutUpdated"), OnPlayerLoadoutUpdated);
}

public void OnMapStart() {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			OnClientPutInServer(i);
		}
	}
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_WeaponEquip, OnEconItemEquipPre);
}

/**
 * Refresh player loadouts in case we've switched teams.
 * 
 * Ideally we could hook CTFWeaponBase::ChangeTeam() instead, but I don't feel like bringing in
 * DHooks today.
 */
Action OnPlayerLoadoutUpdated(UserMsg msg_id, BfRead msg, const int[] players,
		int playersNum, bool reliable, bool init) {
	int client = msg.ReadByte();
	
	int numWeapons = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");
	for (int i; i < numWeapons; i++) {
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
		if (!IsValidEntity(weapon)) {
			continue;
		}
		
		OnEconItemEquipPre(client, weapon);
	}
	
	int numWearables = TF2Util_GetPlayerWearableCount(client);
	for (int i; i < numWearables; i++) {
		int wearable = TF2Util_GetPlayerWearable(client, i);
		if (!IsValidEntity(wearable)) {
			continue;
		}
		
		OnEconItemEquipPre(client, wearable);
	}
}

Action OnEconItemEquipPre(int client, int weapon) {
	KeyValues weaponKV = TF2CustAttr_GetAttributeKeyValues(weapon);
	if (!weaponKV) {
		return Plugin_Continue;
	}
	
	KeyValues mergeKV = new KeyValues("merging");
	
	// look through nested sections
	weaponKV.GotoFirstSubKey(false);
	do {
		char key[32];
		weaponKV.GetSectionName(key, sizeof(key));
		
		// look into nested section
		if (weaponKV.GetDataType(NULL_STRING) == KvData_None) {
			if (IsSectionNameValidForClient(client, key)) {
				//use a merge instead of Import in case we have `n > 1` matching sections
				KvMergeSubKeys(weaponKV, mergeKV);
			}
		}
	} while (weaponKV.GotoNextKey(false));
	weaponKV.GoBack();
	
	KvMergeSubKeys(mergeKV, weaponKV);
	
	TF2CustAttr_UseKeyValues(weapon, weaponKV);
	
	delete mergeKV;
	delete weaponKV;
	
	return Plugin_Continue;
}

/**
 * Return `true` if the nested KV should be merged into the top level entry.
 */
bool IsSectionNameValidForClient(int client, const char[] section) {
	switch (TF2_GetClientTeam(client)) {
		case TFTeam_Red: {
			return StrEqual(section, "red");
		}
		case TFTeam_Blue: {
			return StrEqual(section, "blue");
		}
	}
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
