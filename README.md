 Hello everyone,

I created a short script to address a need in my community, and I believe it can be useful for all of you MP mission makers.

**Latest version**: 1.1 (27/01/2025)

**What does it do:**

The script will dynamically activate pre-placed ME groups based on given parameters.

The idea is to manage the dynamic spawn of Opfor AI interceptors during the mission in a way that will keep the mission interesting and ensure that CAP flights are not bored, but without overwhelming the players in situations where too many AI are wiping out the players. It works for CO-OP (PvE), PvP, PvPvE, or any other combination of Player and/or/versus AI coalitions (as long as you want AI to be a part of the mission).

This is a standalone script and does not require Mist, MOOSE, or any other framework.

**How to use:**
1. Download the file and place it anywhere (I usually go with Saved Games\DCS\Scripts)
2. in the ME, create a trigger that will activate at mission start. In the "Actions" section, select "Do script file" and choose the file you downloaded.
   Place as many AI aircraft groups as you want, anywhere you want. Those are all of your interceptors. Call them whatever you want, just remember the GROUP name (unit names won't matter). They can be jets of helicopters, singles/pairs/multiple, starting in the air, from a parking cold/hot, or from a runway. Make sure you set "Late Activation"!  
   **Note**: I recommend using "takeoff from runway" because there is already a time delay built into the script. Taxi can take anywhere from 10 seconds to 15 minutes, depending on airbase, parking, weather, and more - which can, and will, ruin your precise timing).  
   you may use a prefix for all your groups (for example, "red-") for an easier time later on.  

3. Create another trigger. This is the modular part - initializing the function:
   Conditions - whatever you want - to decide when the interceptors to trigger. This condition will be your "stuff is happening now" moment (units spawning and starting to move, SAMs going online, messages being sent).  
   **Note**: this can also be on mission start if you want interceptors to launch after a set time in the mission and not based on what is going on.  
   Actions - "Do script", in the box - use the following format:  
   `randomReds(groups [, maxJets, maxHelicopters,firstSpawn, randMin, randMax])`  
     * **groups** = defines which groups the script will control. can be one of the following:
       * A list of group names from the mission editors.  
             **Note** - This is case sensitive, each name must be in single or double quotemarks (' or "), and the list must be inside curly brackets { }.  
             Example:  
             `randomReds({'Red-1','Red-2','Red-3','Red-4'})`
         
       * if you decided to use a prefix - just write it down. the script will automatically recognize any group with the defined prefix.  
             **Note** - This is case sensitive, must be in single or double quotemarks (' or ").  
              Example:  
             `randomReds('red-')`  

    * maxJets (optional) = This is the largest amount of fixed-wing fighters that are allowed to be active at once. The script will stop spawning groups once this number is reached (or if spawning another group will cross this amount, for groups with more than 1 aircraft).  
        **Default value** - the difference in amount between blue players and red players. So if you run the mission with 10 players on the blue side, and none on the red side - the max will be 10. If you run the mission again with 20 blue players and 5 red players - there will be up to 15 AI jets. This updates in real-time, so if players join or leave mid-mission - the max amount will change accordingly (it will not de-spawn active groups, but will hold new ones until enough are destroyed.
        **This works for both sides**, even if your players are mostly on the red side.  
        Use one of the following formats:  
      * A number - a hard-set amount. Must be bigger than 0.  
        In the example below, there will be up to 8 fixed-wing aircraft active at any time:  
        `randomReds('red-',8)`  
        
      * A relative number - this will use the player count (default value as explained above) and add or subtract that number. Must be within quotemarks, and include a + or -.  
          Say you have 10 players online. In the example below, there will be up to 13 fixed-wing aircraft active at any time:  
        `randomReds('red-','+3')`  
              
          Say you have 20 players online. In the example below, there will be up to 15 fixed-wing aircraft active at any time:  
        `randomReds('red-','-5')`  
  
      * A relative percentage - this will use the player count (default value as explained above) and add or subtract the defined percentage. Must be within quotemarks, include a + or -, and include a percentage % sign.  
        Say you have 10 players online. In the example below, there will be up to 12 fixed-wing aircraft active at any time:  
        `randomReds('red-','+20%')`  
        if you have 20 players for the next run of the mission - there will be up to 24 AI.  

    * maxHelicopters (optional) = a number. This is used to differentiate fixed-wing and Helicopters if you want to. Since most helicopters are not a threat to jets, you may want to use a different count (so have up to 10 jets, and 4 helicopters at once, without limiting one because of the other).  
        **Note** - You may leave this as 0 to keep a single count. maxJets will be used for all aircraft types and everything will be included in it's count. Example:  
        `randomReds('red-',8,2)`
              
    * firstSpawn (optional) = delay (in seconds) from the time the function is activated to the launch of the first group. This is meant to simulate the time it takes pilots on alert to get to their aircraft, get ready, and take off. If the function is activated at mission start, this will define the time delay from start until the first group is activated.  
        **Default value** - 5 minutes.  
        In this example, the first group will activate 2 minutes after the conditions of the trigger are met:  
        `randomReds('red-',8,2,120)`
              
    * **randMin** and **randMax** (optional) = defines the timeframe (in seconds) between each group activation. The script will launch another group after a random time delay, between the defined minimum and maximum limits.  
        **Default values** - 1 to 5 minutes. You may define one or both of the parameters, just make sure max is bigger or equal to min, or they will return to the default values.  
        In this example, the groups will activate every 1 to 3 minutes:  
        `randomReds('red-',8,2,120,60,180)`

**Debugging the script:**  
If you wish to debug the script yourself, simply add 'Debug' to the activation line in "Do Script":  
`randomRedsDebug('red-',8,2,120,60,180)`  
This will enable real-time in-game messages with information about the script's operation - varifying parameters, different function status updates, actions taken, and more. If you run this on a multiplayer server, the log will be visible to everyone.  
  
**Additional notes:**
* Feel free to use this in your missions and copy parts of the code if it helps you.
* If you have more ideas, suggestions, comments, or feedback - I'd appreciate it!
* More features I might add in the future if I feel like it:
  * Auto creation of groups from random/defined coalition bases, with preset/custom unit types.
  * Check airfield status and skip groups at destroyed airfields when choosing a group to activate.

**Changelog:**
* V1.1
  * Added the option to activate the script on either coalition.
  * Added option to use a prefix for auto-recognition of editor groups based on name format so you don't have to give it all of the groups.
  * Added a check for combat ineffective units. Removes landed or retreating units (due to fuel, damage, ammo, tasks or anything else) from the count.

Cheers! 
