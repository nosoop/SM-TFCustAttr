# TF2 Custom Attributes

A custom attribute plugin for Team Fortress 2.

This is alpha quality software, intended as a proof-of-concept.  It may be leaking handles.
It uses deprecated SourceMod functionality.  It could mangle things I never expected it to.

## What does this do?

The core plugin (`tf_custom_attributes`) provides an extremely simple interface for other
plugins to access some internal storage on each weapon, being able to assign custom key/value
data (mainly for plugin-based attributes).

For server operators that want to use attributes written for this framework, there are a few
options:

* Server operators that want attributes applied by item definition index can use the bundled
Custom Attribute Basic Manager.
* Server operators currently using any version of [Custom Weapons] can use the bundled
Custom Weapons Adapter.

[Custom Weapons]: https://forums.alliedmods.net/showthread.php?t=285258

## Why another API for custom weapon attributes?

To put it bluntly, I don't like the existing approach as an attribute developer.

In every iteration of Custom Weapons that I'm aware of, you get one forward that tells you when
a weapon requests an attribute:  `CustomWeaponsTF_OnAddAttribute` (or `CW3_OnAddAttribute`).

This is an event-based approach to adding attributes, which means the burden is put on
developers to listen to that forward and write boilerplate to keep track of what entities have
their attributes and what values they have.

I've done a fair bit of work in the guts of the server code, and I've written my API in such a
way that handles it similar to how the game does it:  you instead check for your desired
attributes at runtime, when the game is doing something you might be interested in, and the
attribute system handles storing the values for you.

## How it works

The current implementation leverages the existing attributes system (using TF2Attributes),
packing a KeyValues handle into a benign, unused attribute.  This allows attributes to persist
through weapon drops.

The particular implementation details may change in the future, as long as we can get
information out of an entity in a persistent manner.

## Writing attribute plugins

Custom attributes are standard SourceMod plugins, so standard stuff applies.  However, there is
one principle to keep in mind:

Attributes are generally unknown until they matter.  This means that:

* Attribute plugins shouldn't care about the attribute / entity mapping and lifecycle.
That is the job of this framework.
* Hooks should effectively be detours.  All entities that support the attribute should be
checked if the attribute is present at runtime.
* Attributes are potentially mutable.  Another plugin may remove or modify their value.
