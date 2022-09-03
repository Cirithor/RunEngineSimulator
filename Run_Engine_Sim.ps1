<#
This script automatically changes the main.mr config file depending on the selected engine file.

Dependencies:
Script has to be put in the root folder of the Engine Simulator
Folder structure needs to be *root folder*\assets\engines\...
                             *root folder*\bin\engine-sim-app.exe
The script searches in the *engine*.mr file for the line "alias output __out: engine". So far the main public node for the engine is always directly above this line   
#>


#hide Powershell window
$window = Add-Type -memberDefinition @"
[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
"@ -name "Win32ShowWindowAsync" -namespace Win32Functions -passThru
$window::ShowWindow((Get-Process –id $pid).MainWindowHandle, 0) 


#choose the engine file
$invocation = (Get-Variable MyInvocation).Value
$directorypath = Split-Path $invocation.MyCommand.Path
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
    InitialDirectory =  $directorypath+"\assets\engines"
    Filter = 'Engine file (*.mr)|*.mr|All files (*.*)|*.*'
    Title = "select engine"
}
$null = $FileBrowser.ShowDialog()
$engineFilePath = $FileBrowser.FileName


#return if no file was choosen
if([string]::IsNullOrEmpty($engineFilePath)) {return}
#return if wrong file was choosen
if($engineFilePath.LastIndexOf("engines\") -lt 0) {return}


$assetsPath=$engineFilePath.Substring(0,$engineFilePath.LastIndexOf("engines\"))
$rootFolder=$engineFilePath.Substring(0,$engineFilePath.LastIndexOf("assets\"))


#relative path to choosen engine from *.mr engine file - example: /engines/kohler/kohler_ch750.mr
$engineFile=$engineFilePath.Substring($engineFilePath.LastIndexOf("engines\")).Replace("\","/")
#search and extract the engine function from the *.mr engine file - example: kohler_ch750()
(Select-String -Path $engineFilePath -Pattern 'alias output __out: engine' -Context 1,0) | ForEach-Object {
$mainFunction = ($_.Context.PreContext[0]).ToString().Replace("public node"," ").Trim(" ","{")+"()"
}

#get current import line used in main.mr - example: import "engines/kohler/kohler_ch750.mr"
$mainImportOld=(Select-String -Path ($assetsPath+"main.mr") -Pattern 'engines/').Line
#replace old with new engine in import line between quotation marks
$mainImport=($mainImportOld) | ForEach {$_.Remove(($_.IndexOf("`"")+1),($_.LastIndexOf("`""))-($_.IndexOf("`"")+1)).Insert($_.IndexOf("`"")+1,$engineFile)}
#get current function call in main.mr
(Select-String -Path ($assetsPath+"main.mr") -Pattern 'set_engine' -Context 0,1) | ForEach-Object {
   $mainFunctionOld = $_.Context.PostContext[0].ToString()
}

#change "main.mr" config file 
(Get-Content $assetsPath"main.mr").Replace($mainImportOld, $mainImport).Replace($mainFunctionOld, $mainFunction) | Set-Content $assetsPath"main.mr"

#Run Simulator 
cd $rootFolder"bin\"
& ".\engine-sim-app.exe"