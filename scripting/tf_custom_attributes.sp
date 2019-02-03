/**
 * [TF2] Custom Attributes
 * 
 * Attribute management in a way that feels natural.
 */
#pragma semicolon 1
#include <sourcemod>

#include <sdkhooks>
#include <sdktools>
#include <tf2attributes>

#pragma newdecls required

#define PLUGIN_VERSION "0.1.0"
public Plugin myinfo = {
	name = "[TF2] Custom Attributes",
	author = "nosoop",
	description = "Minimalistic attribute handling.",
	version = PLUGIN_VERSION,
	url = "https://github.com/nosoop/SM-TFCustAttr"
}

#define CUSTOMATTRIBUTE_STORAGE "referenced item id low"

Handle g_OnAttributeKVAdded;

ArrayList g_AttributeKVRefs;

public APLRes AskPluginLoad2(Handle self, bool late, char[] error, int maxlen) {
	RegPluginLibrary("tf2custattr");
	
	CreateNative("TF2CustAttr_GetAttributeKeyValues", Native_GetAttributeKV);
	CreateNative("TF2CustAttr_UseKeyValues", Native_UseCustomKV);
	
	return APLRes_Success;
}

public void OnPluginStart() {
	g_OnAttributeKVAdded = CreateGlobalForward("TF2CustAttr_OnKeyValuesAdded",
			ET_Event, Param_Cell, Param_Cell);
	
	g_AttributeKVRefs = new ArrayList();
}

/**
 * Remove custom attribute references on existing attributes.
 */
public void OnPluginEnd() {
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "*")) != -1) {
		if (!HasEntProp(entity, Prop_Send, "m_AttributeList")) {
			continue;
		}
		
		Address pAttrib = TF2Attrib_GetByName(entity, CUSTOMATTRIBUTE_STORAGE);
		if (pAttrib) {
			TF2Attrib_RemoveByName(entity, CUSTOMATTRIBUTE_STORAGE);
		}
	}
}

/**
 * Schedule a garbage collection routine.
 */
public void OnMapStart() {
	CreateTimer(60.0, GarbageCollectAttribute, .flags = TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public void OnMapEnd() {
	EraseAttributeStructure();
}

public void OnEntityCreated(int entity, const char[] className) {
	if (HasEntProp(entity, Prop_Send, "m_AttributeList")) {
		SDKHook(entity, SDKHook_SpawnPost, OnItemAttributeSpawnPost);
	}
}

/**
 * An entity has been spawned.  Check if any custom attributes should be added.
 * If no custom attributes are present on an entity after the forward, the KeyValues handle is
 * cleaned up.
 */
public void OnItemAttributeSpawnPost(int entity) {
	Address pCustomAttrib = TF2Attrib_GetByName(entity, CUSTOMATTRIBUTE_STORAGE);
	
	if (!pCustomAttrib) {
		KeyValues customAttributes = new KeyValues("CustomAttributes");
		
		Action result;
		
		Call_StartForward(g_OnAttributeKVAdded);
		Call_PushCell(entity);
		Call_PushCell(customAttributes);
		Call_Finish(result);
		
		if (result > Plugin_Continue) {
			// convention expects that all immutable KVs have been added here.
			TF2Attrib_SetByName(entity, CUSTOMATTRIBUTE_STORAGE,
					view_as<float>(customAttributes));
			
			g_AttributeKVRefs.Push(customAttributes);
		} else {
			delete customAttributes;
		}
	}
}

/**
 * Garbage collection routine.  Scans all items and checks against its local list to see which
 * handles are unused and can be deleted.
 * 
 * We can't just keep a reference to entities because dropped weapons exist, invalidating those
 * references but still keeping the KV handle accessible.
 */
public Action GarbageCollectAttribute(Handle timer) {
	if (!g_AttributeKVRefs.Length) {
		return Plugin_Continue;
	}
	
	// any found handles are moved to the `savedAttributes` list
	ArrayList savedAttributes = new ArrayList();
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "*")) != -1) {
		if (!HasEntProp(entity, Prop_Send, "m_AttributeList")) {
			continue;
		}
		
		KeyValues kv = GetCustomAttributeStruct(entity);
		if (kv) {
			savedAttributes.Push(kv);
			
			int index;
			while ((index = g_AttributeKVRefs.FindValue(kv)) != -1) {
				g_AttributeKVRefs.Erase(index);
			}
		}
	}
	
	EraseAttributeStructure();
	
	for (int i = 0; i < savedAttributes.Length; i++) {
		g_AttributeKVRefs.Push(savedAttributes.Get(i));
	}
	delete savedAttributes;
	
	return Plugin_Continue;
}

/** 
 * Returns the KeyValues handle associated with an entity, if one exists.
 */
KeyValues GetCustomAttributeStruct(int entity) {
	Address pCustomAttr = TF2Attrib_GetByName(entity, CUSTOMATTRIBUTE_STORAGE);
	if (pCustomAttr != Address_Null) {
		return view_as<KeyValues>(TF2Attrib_GetValue(pCustomAttr));
	}
	return null;
}

public int Native_GetAttributeKV(Handle caller, int argc) {
	int entity = GetNativeCell(1);
	
	KeyValues result = GetCustomAttributeStruct(entity);
	if (result && IsValidHandle(result)) {
		return MoveHandleImmediate(KeyValuesCopyView(result, "CustomAttributes"), caller);
	}
	return 0;
}

public int Native_UseCustomKV(Handle caller, int argc) {
	int entity = GetNativeCell(1);
	KeyValues kv = GetNativeCell(2);
	
	KeyValues customAttributes = KeyValuesCopyView(kv, "CustomAttributes");
	
	TF2Attrib_SetByName(entity, CUSTOMATTRIBUTE_STORAGE,
			view_as<float>(customAttributes));
	
	g_AttributeKVRefs.Push(customAttributes);
	
	return 1;
}

/**
 * Returns a clone of a handle with a new owner, deleting the existing one in the process.
 * 
 * This function is used for cases where the `hndl` argument is the return value of another
 * function call, in which case attempting to use `MoveHandle` results in an argument type
 * mismatch compile error.
 * 
 * The return type is `any` to allow assignment without retagging.
 */
stock any MoveHandleImmediate(Handle hndl, Handle plugin = INVALID_HANDLE) {
	Handle moved = CloneHandle(hndl, plugin);
	CloseHandle(hndl);
	return moved;
}

/**
 * Returns a new KeyValues handle containing the contents of the given KeyValues handle at its
 * current position.
 */
KeyValues KeyValuesCopyView(KeyValues kv, const char[] section = "") {
	KeyValues copy = new KeyValues(section);
	copy.Import(kv);
	return copy;
}

/**
 * Disposes all KeyValues handles and empties the reference list.
 */
void EraseAttributeStructure() {
	for (int i = 0; i < g_AttributeKVRefs.Length; i++) {
		KeyValues kv = g_AttributeKVRefs.Get(i);
		
		if (IsValidHandle(kv)) {
			delete kv;
		}
	}
	g_AttributeKVRefs.Clear();
}
