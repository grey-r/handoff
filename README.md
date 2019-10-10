# GM_HOff
## Separate animations for your off-hand in Garry's Mod

This project uses custom netcode, a finite state machine, and a limited amount of matrix math to implement off-hand animations in Garry's Mod. Under normal circumstances, the game simply merges the skeleton of an arms model onto the view model. This addon injects an intermediate model, animated using Lua, which can blend and merge between two separate models.
