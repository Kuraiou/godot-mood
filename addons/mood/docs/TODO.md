# Blockers for "Launch"

## Style

* different icon for each transition type

## Bugs Needing Fixing

## Plugin Functionality

* setting to hide/show meta fields
* setting to skip the "draft" meta stuff around adding/removing nodes (or maybe toss it entirely?)

## Graph Functionality

* on connecting two moods:
	* popup asking what kind of transition
	* auto create transition node
		* if there is no selector node, auto-creating one
* "add transition" popup menu function
* deleting transition(s)
* asking for confirmation before deleting graph nodes

## Node Functionality

* remove the automated naming of transitions, it's too silly

## MoodGraphNode

* get_titlebar_hbox -- add icon for mood
* fix style when selected

### TransitionGraphNode

* get_titlebar_hbox -- add icon for transition type
* fix style when selected

### Condition-Based Transition

* allow for Callable (method) selection as well as property
* add Vec2 and Vec3 property support type

### Signal-Based Transition

* in the popup only show signals with no arguments

### Input Action Transition
* implement in its entirety :(
	* node
	* UI scene
	* inspector plugin
	* MoodTransitionGraphNode integration

## Documentation

* write docblocks for all methods, signals, properties, classes
* rewrite readme

## Code Cleanup

remove class names for UI elements so they don't show up in the node selector
redo icons

# Nice-to-Haves

* add `popup` text where appropriate for the various UI elements
* hide/show button for transition detail
* improve lame from/to labels on mood nodes
* rename the Transition classes to Change

## Graph Functionality

* improve style differentiation of transitions vs moods

# Post Launch

## Node Functionality

### Signal-Based Transition
* allow for all signals and just bind dummy arguments to ignore them
* add a "clear" button next to "select" button

### Condition-Based Transition
* allow for a different target for each condition
* add "distance" operator for Vec2/Vec3 property which uses a float param
