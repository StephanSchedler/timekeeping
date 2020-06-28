$writeToDiskDelay = 15 # sec.
$logfileBaseDirectory = "C:\timekeeping"

Write-Host("Detect current user")
$user = $null
$user = gwmi -Class win32_computersystem | select -ExpandProperty username -ErrorAction Stop

Write-Host("Current user: $($user)")
while($true)
{
    # Generate logfile name
    $yearStr = Get-Date -Format 'yyyy'
    $monthStr = Get-Date -Format 'MM'
    $dateStr = Get-Date -Format 'yyyy/MM/dd'
    $logfileDirectory = "$($logfileBaseDirectory)\$($user)\$($yearStr)-$($monthStr)"
    $logfilePath = "$($logfileDirectory)\$($dateStr).log"
   
    # Create logfile directory
    if (!(Test-Path -Path $logfileDirectory))
    {
        Write-Host("Create directory: $($logfileDirectory)")
        New-Item -ItemType Directory -Force -Path $logfileDirectory;
    }
 
    # Check if logfile exists
    if ([System.IO.File]::Exists($logfilePath))
    {
        # Parse content of existing logfile (get previous counter value)
        $logfileContent = Get-Content -Path $logfilePath
        $counter = [convert]::ToInt32($logfileContent, 10)
    }
    else
    {
        # Reset counter
        Write-Host("Reset Counter")
        $counter = 0
    }
   
    # Increment counter
       for ($i=1; $i -le $writeToDiskDelay; $i++)
       {
			Start-Sleep -Seconds 1
			$counterTimestamp =  [timespan]::fromseconds($counter)
			$counterString = ("{0:hh\:mm\:ss}" -f $counterTimestamp)

			# Check if login screen (logonui.exe) is running
			try
			{
				if ((Get-Process logonui -ErrorAction Stop))
				{
					Write-Host("$($user): $($counterString) (locked)")
				}
			}
			catch
			{
				Write-Host("$($user): $($counterString) (logged on)")
				$counter = $counter + 1
			}
    }
   
    # Write to disk (counter value)
    Set-Content -Path $logfilePath -Value "$($counter)"
 
    # Write to disk (readable)
    Set-Content -Path "$($logfilePath).txt" -Value "$($counterString)"
}
