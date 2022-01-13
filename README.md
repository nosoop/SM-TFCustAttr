# Custom Attribute Framework

A custom attribute system for Team Fortress 2.

This is alpha quality software, intended as a proof-of-concept.  It may be leaking handles.
It uses deprecated SourceMod functionality.  It could mangle things I never expected it to.

## What does this do?

The core plugin (`tf_custom_attributes`) provides an extremely simple interface for other
plugins to access some internal storage on each item, being able to assign custom key/value
data, mainly for CAF-based attributes (that is, plugins using this framework to implement
attributes).

Attributes are automatically copied across dropped items and item pickups, making it compatible
with the changes introduced in the Gun Mettle update.

## Installation

Install the core `tf_custom_attributes.smx` plugin file.  You'll also need [TF2Attributes][].

You will also want some attribute plugins written for the framework; see the
[Public Custom Attribute Sets page][sets] for various CAF-based attributes.

If you're a server operator, there are a number of plugins available that can apply custom
attributes to items and/or integrate with existing plugins; the
[Applying Custom Attributes wiki page][apply] provides instructions on known compatible setups.

If you're a developer, the [Creating Custom Attributes wiki page][create] provides some info on
how to write your own CAF-based attributes.  There are a few toy attribute examples in the
project repository, and the [Public Custom Attribute Sets page][sets] has the source of more.

[TF2Attributes]: https://github.com/nosoop/tf2attributes/releases
[apply]: https://github.com/nosoop/SM-TFCustAttr/wiki/Applying-Custom-Attributes
[create]: https://github.com/nosoop/SM-TFCustAttr/wiki/Creating-Custom-Attributes
[sets]: https://github.com/nosoop/SM-TFCustAttr/wiki/Public-Custom-Attribute-Sets

## Why another API for custom weapon attributes?

I disliked the existing approach as an attribute developer.

In every iteration of Custom Weapons that I'm aware of, you get one forward that tells you when
a weapon requests an attribute:  `CustomWeaponsTF_OnAddAttribute` (or `CW3_OnAddAttribute`).

This is an event-based approach to adding attributes, which means the burden is put on
developers to listen to that forward and write boilerplate to keep track of what entities have
their attributes and what values they have.

When the plugin is reloaded, it forgets what weapon has its attributes, so developers have to
spend time reequipping the item every time they need to make a change.

This API handles attributes similar to how the game does:  you instead check for your desired
attributes at runtime, when the game is doing something you might be interested in, and the
attribute system handles storing the values for you.

## How does this compare to the Hidden Dev Attributes plugin?

The [hidden dev attributes plugin][] (or similar schema injection methods!) is *much* more
optimal &mdash; I'd highly recommend taking advantage of the native attributes system if you
can.  You can specify your own unique attribute classes and the game won't know the difference.

The primary difference between the two is that the Custom Attribute Framework core has no
concept of "known" attributes, so you can insert arbitrary keys into items without external
configuration (whereas native attributes need to exist in the in-memory schema, hence the
injection process).

The Custom Attribute Framework was started before extensive research was done on the in-memory
schema, hence the "surrogate" method of installing a `KeyValues` handle into an existing
attribute.

In the future, the Custom Attributes Framework core may be a simple wrapper for native
attributes, or just deprecated entirely (likely once string attribute support lands in
TF2Attributes proper).

Porting CAF-based attributes to native ones is a fairly easy transition.  It's a few native
function swaps with the TF2Attributes equivalent, plus defining the attribute classes to be
added to the schema.

[hidden dev attributes plugin]: https://forums.alliedmods.net/showthread.php?t=326853

## How it works

The current implementation leverages the existing attributes system (using TF2Attributes),
packing a KeyValues handle into a benign, unused attribute.  This allows attributes to persist
through weapon drops.

The particular implementation details may change in the future, as long as we can get
information out of an entity in a persistent manner.
