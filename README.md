# TF2 Custom Attributes

A custom attribute plugin for Team Fortress 2.

## What does this do?

The core plugin (`tf_custom_attributes` provides an extremely simple interface that adds an
internal `KeyValues` storage to each weapon, which can be used for custom key / value pairs
(mainly for attributes).

This is not a drop-in replacement for the [Custom Weapons] project.  There is yet to be decent
tooling that supports equipping custom weapons.

[Custom Weapons]: https://forums.alliedmods.net/showthread.php?t=285258

## How it works

This plugin leverages the existing attributes system (using TF2Attributes), packing a KeyValues
handle into an unused attribute.  This allows attributes to persist through weapon drops.

## Writing attribute plugins

Custom attributes are standard SourceMod plugins, so standard stuff applies.  However, there are
a few things I'd recommend and keep in mind:

* Attributes are generally immutable.  The only time plugins should add attributes is during the
`TF2CustAttr_OnKeyValuesAdded` forward (or if a plugin does a full replacement in
`TF2CustAttr_UseKeyValues`).
* Hooks should effectively be detours, if they aren't already (that is, if you need to hook some
specific client / weapon function, make sure it's applied to all supported entities).  If you
need to check the value of an attribute, do it at runtime, when the hook is called.  Weapons
*can* be picked up by other players or equipped dynamically; doing conditional hooks complicates
things, making it difficult to keep track of whether it's just not hooked or if there's another
issue somewhere along the chain.
