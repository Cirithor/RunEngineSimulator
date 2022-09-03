# RunEngineSimulator
Powershell script for AngeTheGreat's Engine Simulator: https://github.com/ange-yaghi/engine-sim
Let's you select a engine and changes the main.mr config accordingly before starting the engine sim.

Usage:
- Put the script in the main directory of the engine sim and run it
- select the engines .mr config you want to simulate
- enjoy!

Some third party engines may have custom main.mr settings for transmission and vehicle. 
To use these settings simply create a .txt file at the same directory with the same name as the .mr engine file and save the custom settings for the main.mr file in there.
The first time you use this script a backup of main.mr will be created, wich will be loaded every time us use this script again.  
