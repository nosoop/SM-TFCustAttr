# TF2 Custom Attributes

A custom attribute plugin for Team Fortress 2.

This is alpha quality software, intended as a proof-of-concept.  It may be leaking handles.
It uses deprecated SourceMod functionality.  It could mangle things I never expected it to.

## What does this do?

The core plugin (`tf_custom_attributes`) provides an extremely simple interface for other
plugins to access some internal storage on each weapon, being able to assign custom key/value
data (mainly for plugin-based attributes).

## Installation

Install the core `tf_custom_attributes.smx` plugin file.  You'll also need [TF2Attributes][]

There are a number of plugins available that decide how to assign custom attributes to weapons
and/or integrate with existing plugins; the [Applying Custom Attributes wiki page][apply]
provides instructions on known compatible setups.

If you're a developer, the [Creating Custom Attributes wiki page][create] provides some info on
how to write your own attributes.  There are a few toy attribute examples in the project
repository, and the [Public Custom Attribute Sets page][sets] has the source of more.

[TF2Attributes]: https://github.com/nosoop/tf2attributes/releases
[apply]: https://github.com/nosoop/SM-TFCustAttr/wiki/Applying-Custom-Attributes
[create]: https://github.com/nosoop/SM-TFCustAttr/wiki/Creating-Custom-Attributes
[sets]: https://github.com/nosoop/SM-TFCustAttr/wiki/Public-Custom-Attribute-Sets

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
