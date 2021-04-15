<#
    VERSION: 1.0
    
    Usage: .\Convert-RDCtoRDB "rdcman.rdg"

    This script will take as input a RDG (Remote Desktop Connection Manager)
     file and convert to a RDB (Remote Control) file.
     RDB is limited in that sub-groups are not available. Therefore all 
     sub-groups configured in a RDG file will be ignored, any hosts, will appear 
     under parent group
#>
$file = $args[0]
$fileName = get-item $file | Select Name -ExpandProperty Name
$fileName = $fileName -replace ".rdg",""
$outputName = ($fileName + ".rdb")

try 
{
    $content = Get-Content -Path $file
    $name = $content | Select-String -Pattern "<name>","</name>"
    $name = $name -replace "<name>","" -replace "</name>","" -replace " ",""
    [xml]$content2 = Get-Content $file
}
catch 
{ 
    Write-Error "Err reading from input file"; 
    break; 
}

# recursive function to retrieve a group
function Get-GroupServerList 
{
    param ($group)

    $svrListArray = @()
    foreach ($i in $group.server.properties)
    {
        $svrListArray += $i.name
    }

    if ($group.ChildNodes.Count -gt 0)
    {
        $svrListArray += Get-GroupServerList $group.group
    }

    $svrListArray
}

$groupListArray = @()
foreach ($g in $content2.RDCMan.file.group)
{
    $guid = [guid]::NewGuid()
    $svrListArray = @()

    # drill into group > sub-groups to retrieve a server list
    $svrListArray = Get-GroupServerList $g
    
    $groupListArray += New-Object -TypeName psobject -Property @{GroupName=$g.properties.name; GroupGuid=$guid; ServerList=$svrListArray}
}

# create Groups & Connection entries
[string]$groupListOutput = ""
[string]$connectListOutput = ""

foreach ($g in $groupListArray)
{
    $gstring = @"
    {
      "Name": "$($g.GroupName)",
      "PersistentModelId": "$($g.GroupGuid)"
    }
"@

    $groupListOutput += $gstring + ","

    foreach ($c in $g.ServerList)
    {
        $cstring = @"
        {
            "HostName": "$($c)",
            "GroupId": "$($g.GroupGuid)",
            "FriendlyName": "",
            "LocalResourcesSettings": {
                "RedirectClipboard": true,
                "PersistentModelId": "00000000-0000-0000-0000-000000000000"
            },
                "PersistentModelId": "49cab540-22f1-4c2d-b9a9-0d307cee677c"
        }
"@
        $connectListOutput += $cstring + ","
    }
}

try 
{
    $groupListOutput = $groupListOutput.Substring(0, $groupListOutput.Length-1)
    $connectListOutput = $connectListOutput.Substring(0, $connectListOutput.Length-1)
}
catch 
{ 
    Write-Error "Err getting list of Groups/Connections"; 
    break;
}

$output = 
@"
{
  "Version": 0.2,
  "GeneralSettings": {
    "UseThumbnails": true,
    "SendFeedback": true,
    "DisableInSessionLockScreen": false,
    "KeyboardInterceptorMode": 0,
    "ConnectFullscreen": true,
    "StartInNewWindow": true,
    "SessionResizeMode": 0,
    "LastShownConnectionCenterTab": 0,
    "PreferredTheme": 2,
    "ResizeOnFullscreen": false,
    "PersistentModelId": "00000000-0000-0000-0000-000000000000"
  },
  "Credentials": [],
  "Groups": [##Groups##],
  "Gateways": [],
  "Connections": [##Connections##]
}
"@

$output = $output.Replace("##Groups##", $groupListOutput)
$output = $output.Replace("##Connections##", $connectListOutput)
write-output -InputObject $output | Out-File ./$outputName -Force
