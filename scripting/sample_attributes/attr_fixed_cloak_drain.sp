/**
 * [TF2CA] Cloak Drain
 * 
 * Basic implementation of a plugin that fixed forced cloak drain on invisibility watches.
 */
#pragma semicolon 1
#include <sourcemod>

#include <sdkhooks>
#include <tf2_stocks>

#pragma newdecls required

#include <tf_custom_attributes>

public void OnMapStart() {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			OnClientPutInServer(i);
		}
	}
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_PostThinkPost, OnClientCloakThinkPost);
}

public void OnClientCloakThinkPost(int client) {
	if (!TF2_IsPlayerInCondition(client, TFCond_Cloaked)) {
		return;
	}
	
	int watch = GetPlayerWeaponSlot(client, 4);
	
	KeyValues attributes = TF2CustAttr_GetAttributeKeyValues(watch);
	if (!attributes) {
		return;
	}
	
	if (attributes.GetNum("cloak decrease")) {
		float flCloakMeter = GetEntPropFloat(client, Prop_Send, "m_flCloakMeter");
		flCloakMeter -= (100.0 / 5.0) * GetGameFrameTime();
		
		SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", flCloakMeter);
	}
	delete attributes;
}
