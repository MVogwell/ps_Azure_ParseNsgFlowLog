# Info on the log layout of NSG flow logs can be found here: https://docs.microsoft.com/en-us/azure/network-watcher/network-watcher-nsg-flow-logging-overview#faq
[CmdLetBinding()]
param (
	[Parameter(Mandatory=$True)][string]$InputFile,
	[Parameter(Mandatory=$True)][string]$Outputfile,
	[Parameter(Mandatory=$True)][switch]$AppendLog
)
Function psParseNsgFlowData() {
	param (
		[string]$InputFile,
		[string]$OutputFile,
		[bool]$Append = $False,
		[ref]$ReturnMsg
	)

	Write-Host "`n`nAzure NSG Flow Export parser" -ForegroundColor Green
	Write-Host "MVogwell - 09/06/2020 - v1.0`n" -ForegroundColor Green

	$bReturn = $True
	[string]$sTimestamp = (Get-Date -Format "yyyyMMdd-HHmmss")

	# Check the input file exists
	if ((Test-Path $InputFile) -eq $False) {
		$ReturnMsg.Value = "Failed to find the input file"
		$bReturn = $false
	}
	else {
		# Input file found - test the output file

		if ($OutputFile.Length -eq 0) {
			$OutputFile = $Env:Temp + "\" + $sTimestamp + "_ParsedNSGLog_" + (Split-Path $InputFile -Leaf)
		}
				
		Write-Host "Output file: $OutputFile" -ForegroundColor Yellow

		$arrFlowMap = @("UnixEpoch","sourceIP","destIP","sourcePort","destPort","proto","trafficFlow","action","flowState","packetsSrcToDest","bytesSrcToDest","packetsDstToSrc","bytesDestToSrc")

		$arrResults = @()

		try {
			$d = Get-Content $InputFile | convertfrom-json
		}
		catch {
			$ReturnMsg.Value = "Failed to open input file $InputFile"
			$bReturn = $False
		}

		# Only proceed if the file was successfully loaded
		if ($bReturn -eq $True) {
			Write-Host "Input file: $InputFile" -ForegroundColor Yellow
		
			$rs = $d.records
			foreach ($r in $rs) {
				$r.properties.flows.flows.flowtuples | foreach {	# Enumerate each flowtuple
					$objResult = new-object PSCustomObject
					$objResult | Add-Member -MemberType NoteProperty -Name "timestamp" -value $r.time
					
					$objResult | Add-Member -MemberType NoteProperty -Name "rulename" -value $($r.properties.flows.rule -join " ~~ ")
				
					$arrData = $($_).split(",")	# split the flowtuple into components
					
					$i = 0	# this will count the elements and map them to the arrFlowMap
					
					# Enumerate each item in the flow tuple
					foreach ($sFlowTuple in $arrData) {
						$objResult | Add-Member -MemberType NoteProperty -Name $arrFlowMap[$i] -value $sFlowTuple
						$i++
					}
					
					$arrResults += $objResult
					$objResult = $null
				}
			}

			try {
				# Export the results to csv
				if ($Append -eq $True) {
					$arrResults | export-csv $OutputFile -NoTypeInformation -NoClobber -Delimiter "|" -Append
				}
				else {
					$arrResults | export-csv $OutputFile -NoTypeInformation -Delimiter "|"
				}
			}
			catch {
				$sErrMsg = "Failed to save results. Error: " + ($Error[0].Exception.Message).Replace("`n"," :: ").Replace("`r","")
				$ReturnMsg.Value = $sErrMsg
			}
		} # End of: Only proceed if the file was successfully loaded
	} # End of: Check the input file exists - else section

	if ($bReturn -eq $True) {
		Write-Host "Successfully parsed log data." -ForegroundColor Green
		Write-Host "Results saved to $OutputFile" -ForegroundColor Green
	} 
	Else {
		Write-Host "Failed to complete successfully." -ForegroundColor Red
		Write-Host "$($ReturnMsg.Value)" -ForegroundColor Red
	}
	
	return $bReturn
} # End of: function


[string]$sReturnMsg = ""
[bool]$bReturn = psParseNsgFlowData -InputFile $InputFile -OutputFile $Outputfile -Append $AppendLog -ReturnMsg ([ref]$sReturnMsg)

If ($bReturn -eq $True) {
	Start-Process "C:\Program Files\Microsoft Office\root\Office16\EXCEL.EXE" $Outputfile
}

Write-Host "`nFinished`n`n" -ForegroundColor Green
