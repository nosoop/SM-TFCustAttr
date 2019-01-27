# TF2 Custom Attributes

A custom attribute plugin for Team Fortress 2.

This is alpha quality software, intended as a proof-of-concept.  It may be leaking handles.
It uses deprecated SourceMod functionality.  It could mangle things I never expected it to.

## What does this do?

The core plugin (`tf_custom_attributes`) provides an extremely simple interface for other
plugins to access some internal storage on each weapon, being able to assign custom key/value
data (mainly for plugin-based attributes).

This is not a drop-in replacement for the [Custom Weapons] project.  However, the tooling is
there for plugin authors to spawn and attach their own custom attributes structure on weapons
&mdash; someone just needs to build it.

[Custom Weapons]: https://forums.alliedmods.net/showthread.php?t=285258

## How it works

The current implementation leverages the existing attributes system (using TF2Attributes),
packing a KeyValues handle into a benign, unused attribute.  This allows attributes to persist
through weapon drops.

The particular implementation details may change in the future, as long as we can get
information out of an entity in a persistent manner.

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
