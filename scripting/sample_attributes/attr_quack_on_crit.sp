/**
 * [TF2CA] Quack on Crit Check
 * 
 * Quacks at the player when the weapon performs its crit calculations.
 */
 
#pragma semicolon 1
#include <sourcemod>

#include <sdktools_sound>

#pragma newdecls required

#include <tf_custom_attributes>

public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponName,
		bool &result) {
	if (TF2CustAttr_GetInt(weapon, "quack on crit check")) {
		EmitGameSoundToClient(client, "Halloween.Quack");
	}
}
