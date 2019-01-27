/**
 * Sourcemod 1.7 Plugin Template
 */
#pragma semicolon 1
#include <sourcemod>

#include <tf2_stocks>
#include <dhooks>

#pragma newdecls required

#include <tf_custom_attributes>

Handle g_DHookMinigunWindDown;

public void OnPluginStart() {
	Handle hGameConf = LoadGameConfigFile("tf2.custattr.sample");
	if (!hGameConf) {
		SetFailState("Failed to load gamedata (tf2.custattr.sample).");
	}
	
	g_DHookMinigunWindDown = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Void,
			ThisPointer_CBaseEntity);
	DHookSetFromConf(g_DHookMinigunWindDown, hGameConf, SDKConf_Signature,
			"CTFMinigun::WindDown()");
	DHookEnableDetour(g_DHookMinigunWindDown, true, OnMinigunWindDownPost);
	
	delete hGameConf;
}

public MRESReturn OnMinigunWindDownPost(int minigun) {
	int owner = GetEntPropEnt(minigun, Prop_Send, "m_hOwnerEntity");
	if (owner < 1 || owner > MaxClients) {
		return MRES_Ignored;
	}
	
	KeyValues kv = TF2CustAttr_GetAttributeKeyValues(minigun);
	if (!kv) {
		return MRES_Ignored;
	}
	
	float flBoostDuration = kv.GetFloat("minigun winddown boost duration");
	if (flBoostDuration) {
		TF2_AddCondition(owner, TFCond_SpeedBuffAlly, flBoostDuration, owner);
	}
	delete kv;
	return MRES_Ignored;
}
