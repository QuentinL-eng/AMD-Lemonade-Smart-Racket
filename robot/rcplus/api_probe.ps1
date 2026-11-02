$ErrorActionPreference = 'Stop'
try {
    Add-Type -Path 'D:\EpsonRC70\exe\RCAPINet.dll'
    $rc = New-Object RCAPINet.Spel
    $rc.Initialize()
    $rc.Connect('Simulator')
    'API connected to Simulator'
    $rc.Project = 'D:\EpsonRC70\Projects\TennisBuddyDayOne_20261029\TennisBuddyDayOne_20261029.sprj'
    'Project loaded'
    $rc.Robot = 1
    'Robot selected'
} catch {
    $_.Exception.ToString()
} finally {
    if ($null -ne $rc) { $rc.Dispose() }
}
