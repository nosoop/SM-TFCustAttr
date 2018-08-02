/**
 * [TF2] Custom Attributes
 */

#if defined __tf_custom_attributes_included
	#endinput
#endif

#define __tf_custom_attributes_included

/**
 * Called when the custom attribute manager is present on the entity.  Attributes should be set
 * here.
 */
forward Action TF2CustAttr_OnKeyValuesAdded(int entity, KeyValues kv);

/** 
 * Returns a KeyValues handle containing the entity's attributes.  The handle returned by this
 * function is cloned and must be freed.
 */
native KeyValues TF2CustAttr_GetAttributeKeyValues(int entity);

/**
 * Copies the contents of a given KeyValues handle and attaches it to an entity, replacing any
 * custom attribute KV handles it previously had.
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
