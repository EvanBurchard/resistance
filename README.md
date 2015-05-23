# Towards Optimal Play For The Resistance

It's probable that the play style of the spies is not optimal.  But if
it is, this program could be a solution to always beating them.

Currently, it seems that the resistance has a dominant strategy (with
100% wins) based on a trust system with a minimal set of weighted features.

These features are:
* SUCCESSFUL_MISSION = 8
* FAILED_MISSION = 7
* SUCCEEDED_AS_LEADER = 8
* FAILED_AS_LEADER = 8
* AVERAGE_REP_THRESHOLD = 6
* LOWEST_REP_THRESHOLD = 1

There are many many combinations that would work here, and it would be
nice to have a generalized system for eliciting them.

# BASICS AND ASSUMPTIONS
* 5 player game
* Spies play conservatively and hide most info (might not be optimal)
* Spies and resistance make decisions based on reputation of players
* algorithms to decide teams (by resistance) are called "team_rejection_criteria"
* leaders (resistance and spies) always choose themselves + highest reputation others for missions called

# TODO
* more reputation factors/features (voting record)
* generalized modeling of turns (right now, only edge cases are handled)
* more spy strategies
* more leader/voting strategies
* variations of the game (6+ players, etc.)
* self balancing feature weights
