<#
This script automatically changes the main.mr config file depending on the selected engine file.

Dependencies:
Script has to be put in the root folder of the Engine Simulator
Folder structure needs to be the default:
    *root folder*\assets\engines\...
    *root folder*\bin\engine-sim-app.exe
    etc.
The script searches in the *engine*.mr file for the line "alias output __out: engine". So far the main public node for the engine is always directly above this line

Some third party engines may have custom main.mr settings for transmission and vehicle. 
To use these settings simply create a .txt file at the same directory with the same name as the .mr engine file and save the custom settings for the main.mr file in there.
The first time you use this script a backup of main.mr will be created, wich will be loaded every time us use this script again.  
#>


#############################################################################
#                           function declaration                            #
#############################################################################

#Run Simulator 
function StartSimulator {
cd $rootFolder"bin\"
& ".\engine-sim-app.exe"
#& $SimulatorExe
Exit}

#hide Powershell Window
function HideWindow{
hide Powershell window
$window = Add-Type -memberDefinition @"
[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
"@ -name "Win32ShowWindowAsync" -namespace Win32Functions -passThru
$window::ShowWindow((Get-Process –id $pid).MainWindowHandle, 0) 
}

#choose the engine file
function selectEngine ($initialDirectory){
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
    InitialDirectory =  $initialDirectory
    Filter = 'Engine file (*.mr)|*.mr|All files (*.*)|*.*'
    Title = "select engine"
}
$null = $FileBrowser.ShowDialog()
return($FileBrowser.FileName)
}


function isEngineFilePathValid ($config){
$a = $true
if([string]::IsNullOrEmpty($config)) {$a = $false}
if($config.LastIndexOf("engines\") -lt 0) {$a = $false}
return $a
}

function PathsExist ([string[]]$paths) {
$a = $true
 ForEach ($path in $paths){
    if([string]::IsNullOrEmpty($path)) {$a=$false} 
    elseif(-Not(Test-Path -Path $path) -and -not (Test-Path -Path $path -PathType Leaf)) {
    $a=$false
    }
}
return $a
}

function backupMain {
#always load a backup. if no backup exists, create a backup
if(-Not(Test-Path -Path $assetsPath"main.mr.bak" -PathType Leaf)){
Get-Content $assetsPath"main.mr"| Set-Content $assetsPath"main.mr.bak"
Echo "created backup main.mr"
}
Get-Content $assetsPath"main.mr.bak"| Set-Content $assetsPath"main.mr"
Echo "loaded backup main.mr"
}


function customConfig ($cConfigPath) {
    $CustomConfig=$cConfigPath | ForEach {$_.Substring(0,$_.LastIndexOf("\")+1)+$_.Substring($_.LastIndexOf("\")+1).Replace(".mr",".txt")}
    if(Test-Path -Path $CustomConfig -PathType Leaf){
        (Get-Content $CustomConfig) | Set-Content $assetsPath"main.mr"
        Echo "start with custom config"
        StartSimulator
    }
}


function normalConfig ($sEngConf, $sMainMr) {
    #Echo "Engine Config in function: "$sEngConf
    #Echo "main.mr Config in function: "$sMainMr
    #relative path to choosen engine from *.mr engine file - example: /engines/kohler/kohler_ch750.mr
    $engineFile=$sEngConf.Substring($sEngConf.LastIndexOf("engines\")).Replace("\","/")
    #search and extract the engine function from the *.mr engine file - example: kohler_ch750()
    (Select-String -Path $sEngConf -Pattern 'alias output __out: engine' -Context 1,0) | ForEach-Object {
    $mainFunction = ($_.Context.PreContext[0]).ToString().Replace("public node"," ").Trim(" ","{")+"()"
    }

    #get current import line used in main.mr - example: import "engines/kohler/kohler_ch750.mr"
    $mainImportOld=(Select-String -Path ($sMainMr) -Pattern 'engines/').Line
    #replace old with new engine in import line between quotation marks
    $mainImport=($mainImportOld) | ForEach {$_.Remove(($_.IndexOf("`"")+1),($_.LastIndexOf("`""))-($_.IndexOf("`"")+1)).Insert($_.IndexOf("`"")+1,$engineFile)}
    #get current function call in main.mr
    (Select-String -Path ($sMainMr) -Pattern 'set_engine' -Context 0,1) | ForEach-Object {
    $mainFunctionOld = $_.Context.PostContext[0].ToString()
    }

    #change "main.mr" config file 
    (Get-Content $sMainMr).Replace($mainImportOld, $mainImport).Replace($mainFunctionOld, $mainFunction) | Set-Content $sMainMr
    Echo "start with normal config"
    StartSimulator
}


#############################################################################
#                             start of script                               #
#############################################################################

#optional function to hide the powershell window
#HideWindow

### declare folder and file paths ###
$rootFolder = (Split-Path (Get-Variable MyInvocation).Value.MyCommand.Path)+"\"
#ECHO "root folder: "$rootFolder
$assetsPath = $rootFolder+"assets\"
#ECHO "assets folder: "$assetsPath
$engineFolder = $rootFolder+"assets\engines"
#ECHO "engine folder: "$engineFolder
$SimulatorExe = $rootFolder+"bin\engine-sim-app.exe"
#ECHO "Simulator Exe: "$SimulatorExe
$mainMr = $rootFolder+"assets\main.mr"
#ECHO "main.mr path: "$mainMr

#check if the declared paths are valid
if( -Not(PathsExist $rootFolder,$assetsPath,$engineFolder,$SimulatorExe,$mainMr)) {
ECHO "At least one path does not exist. Running this script in the engine sims root folder?"
return
}


#select the engine config file and check it
$engineConfig = selectEngine($engineFolder)
if( -Not(PathsExist ($engineConfig))) {
 Echo "Engine config file path is NOT valid"
 return
}

backupMain #backup main.mr and load default

#search for custom config and replace current main.mr if it exists
customConfig ($engineConfig)
#no custom Config found

#change normal main.mr config
normalConfig $engineConfig $mainMr
