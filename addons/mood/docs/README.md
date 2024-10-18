# Mood

# Overview

Mood is an opinionated godotic way to manage the Finite State Machine pattern.

## What do you mean by "opinionated"?

I mean it in two ways: first, in some ways I intentionally break from the godotic way of doing things
to rely on less error-prone patterns (for instance, relying on quack-typing to arbitrarily call
methods in children instead of either emitting a signal that children have to  connect to). Second,
I implemented the code presuming that you're going to use it correctly so that I don't have to waste
CPU cycles testing the validity of everything at all times. Caveat emptor, as they say.

## You've said it a few times now, but what do you mean by "godotic"?

I mean that it's all nodes, baby! Nodes all the way down!

## Explain.

A Finite State Machine is a node -- a MoodMachine, specifically.

A state is a node -- a Mood.

The abstraction mechanism for determining which state a machine should be in -- that's a whole
tree of nodes! A [MoodSelector] allows you to configure when and how you identify the next state,
and [MoodTransition] (and child) nodes let you specify the actual connections.

Behaviors tied to states? You guessed it: nodes! [MoodScript] has all you want and need.

## Why would you do this to me?

Because:

* With all due respect to all the authors of all the hundreds of other state machine implementations 
	in Godot that I've looked at, I don't like them.
* Do I need another reason?
	* Oh, I do? okay. So when I say "I don't like them", what I mean is that every implementation either:
		* is just plain poorly written and too difficult to grok;
		* or has a bunch of processing conditionals and logic which hurt at my most-loved child (Performance);
		* or needlessly overcomplicates things by providing alternate paths/mechanisms to Godot built-ins;
		* or has an abstraction model which _requires_ extending the state scripts which I _really_ dislike
			because I feel like there should be a separation between "state" and "things that happen in a state"
			so that the things that happen are reusable little widgets of logic divorced from the idea of "state"
			and doing this breaks the entire goddamn concept in two;
		* or it's so featureful and powerful that it's intimidating to use,
* Also, I'm obsessed with reinventing the wheel. It's just a personal problem.
	* that I'm choosing to inflict on you.
	
## Okay, but how do you use it? [OVERVIEW]

1. Add a `MoodMachine` (FSM) node. This machine is meant to represent *a grouping of moods which are
	mutually exclusive from each other.* That is the definition of "Finite State Machine".
2. Under that FSM, add one or more `Mood` nodes. If you add one the entire exercise has been a waste,
	but you do you.
	* each node must have a different name from other `Mood`s in that FSM. It can have the same name as a
		mood in another FSM, who even cares about that.
	* the name of the node is also the name of the mood.
3. Under that mood, add zero or more nodes which extend `MoodScript`. Each `MoodScript` is where you put your
	functional widgets. Things like "clamp to position", "update rotation", "send a signal", etc. **Note** here
	that we should be **extending** `MoodScript`; this is where logic is so this is where code is. Don't use
	`MoodScript` directly, it doesn't do anything on its own.
	* Because I'm insane, I built it so `MoodScript`s can have `MoodScript` children which also will perform
	  as expected, which allows you to do things like have `MoodTransitionGate` nodes which let you customize
	  your enter/exit behavior based on which mood you came from/are going to while still having it all
	  visible in the tree.
4. Optionally, if you want to use automation to determine state, under the FSM add a `MoodSelector` node.
	If you do so, put `MoodTransition` nodes under that `MoodSelector` to describe the rules for those
	transitions between states.

Or, if you want to be fancy, you can use the complex Graphical UI widget I added to the bottom window :)

## What are some features you did not include that other systems have?

I've seen a few FSM implementations that track history. That's cute but I think you can implement that
entirely in parallel to the actual FSM by just connecting to signals so it doesn't need to be core.

One of the fancier ones had this really, really cool widget for connecting states visually in a graph.
I really disliked the way that all the functionality was entirely hidden inside the "player" though.

That same FSM determined its state via conditional booleans and logic wired into the transitions
between states; I think that's really neat, but it has some legibility issues, and I think lots of
people would prefer multiple mechanisms to determine state that are opt-in instead of core, which is
why I went with the `FiniteStateSelector` pattern which is similar-but-different.

# Class Overview

## `FiniteStateMachine`

To use this node, assign a `Target Node`. If you do not, the parent will be presumed to be the target.

The "target" is used as the reference in `FiniteStateScript`s; if your scripts don't use a target, don't worry about it.

If you need to manually change the machine's state, you can call `change_state` on it, and pass it either
a string representing the target state or the state node itself (as long as it's a child of the machine!).

## `FiniteState`

`FiniteState` nodes must be children of a `FiniteStateMachine` node.

The name of a `FiniteState` is used as its string representation in the machine,

The state itself exists mostly as a container for `FiniteStateScript` entries; don't extend it unless
you absolutely have to.

## `FiniteStateScript`

These are meant to be reusable pieces of behavior. You can implement anything in a script that `extends`
a `FiniteStateScript` with the standard Godot hooks (e.g. `_process`, `_input`). The state machine itself
ensures that only scripts under "current" states run those behaviors.
	
* `target`, which gives you a direct reference handle to the node you want to do thing with in your script;
* `_on_enter_state`, which triggers when you enter the state (duh); and
* `_on_exit_state`, which triggers when you exit the state.

## `FiniteStateSelector`

This is where the magic happens. Depending on the configured process mode (idle, physics, or manual),
a function runs which determines what the next state is, and then sets its parent machine to that state.
