These are general plans for future improvements -- basically a worksheet for guiding future development. Please submit an issue to GitHub if what you would like is not listed here. If it is listed here, honestly, feel free to submit an issue anyways.
# Core Functionality

* add Graph-based UI tab for managing states for both Transition-mode and Mood-Evaluation-Mode.
* Provide helper Debug nodes to track Mood changes, etc.
* make sure that non-integrated `MoodCondition` nodes still show up in the Condition Editor.
* finish `MoodConditionInput` integration into the Condition Editor.
* refactor the autoloads to not be autoloads, as currently nodes will break if the plugin is not enabled **because** the autoloads will not be in the Autoloads.
	* e.g. `Recursion` should be in `mood.gd` as `const Recursion = ...` and references then can go to `Mood.Recursion` instead.
	* this would be nice to be configurable directly.
# Node-Specific Functionality

* `Mood`
	* allow overriding of `target`.
	* provide a flag to prevent a machine's `fallback` mechanism from executing while in this mood.
* `MoodCondition`
	* allow overriding of `target`.
	* revisit/revamp `cache` -- the idea feels half-baked  and half-implemented.
	* allow providing an easy flag to indicate if a condition only works or makes sense in one selection mode or another.
* `MoodConditionInput`
	* support other input-handling mechanisms -- `GUIDEINput` or raw inputs instead of keypress, remove/replace `InputTracker` as it feels fragile,  etc.
* `MoodConditionTimeout`
	* feels like it needs some cleanup and refactoring.

# Configuration

* provide a flag to not hide fields from the UI.
* provide a flag when not hiding fields to hide the Condition Editor.
*  in general, it is non-intuitive how signals are handled, so some implementation which makes this configurable and manageable would be ideal.
	* perhaps signal deny/allow-lists which guard against processing those signals?
	* alternately, a basic flag that says "allow signals through when disabled" on Mood + MoodChild?
# UI

* get input from an actual designer and redo the Editor UI to be better.
	* show more icons
	* differentiate colors better.
* Redesign the icons. The current icons are placeholders.
* Add a means to "Go to this Node" in the Conditions Editor to go straight to that node.
# Developer Support

* streamline the `Editor`/`SubEditor` pattern to make it easier for people writing their own `MoodCondition` and `MoodScript` tools to integrate them into said UI.
* improve and clarify the autoload functions as they seem generally useful.