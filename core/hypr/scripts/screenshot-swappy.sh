#!/bin/bash

# 1. Close the Pilot HUD so it doesn't block the shot
swaync-client -cp > /dev/null 2>&1
sleep 0.5

# 2. Take the screenshot and open Swappy
# We REMOVED the "&& wl-copy < find..." part. 
# Now, relies entirely on you clicking "Copy" or "Save" inside the app.
grim -g "$(slurp)" - | swappy -f -