/**
 * [TF2] Custom Attributes
 * Framework to store / retrieve custom attributes on weapons.
 */

#if defined __tf_custom_attributes_included
	#endinput
#endif

#define __tf_custom_attributes_included

/**
 * Called after an entity has finished spawning.  Any manager plugins should add attribute
 * names / values to the provided KeyValues handle, and should return Plugin_Changed if they
 * have done so.
 */
forward Action TF2CustAttr_OnKeyValuesAdded(int entity, KeyValues kv);

/** 
 * Returns a read-only KeyValues handle containing the entity's attributes (if any), or
 * `INVALID_HANDLE` if the entity does not have any backing storage.
 * 
 * The handle returned by this function must be freed.
 */
native KeyValues TF2CustAttr_GetAttributeKeyValues(int entity);

/**
 * Copies the contents of a given KeyValues handle and attaches it to an entity, replacing any
 * custom attributes it previously had.
 * 
 * This is for advanced users only; this bypasses the OnKeyValuesAdded forward.
 */
native bool TF2CustAttr_UseKeyValues(int entity, KeyValues kv);

public SharedPlugin __pl_tf_custom_attributes = {
	name = "tf2custattr",
	file = "tf_custom_attributes.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};
