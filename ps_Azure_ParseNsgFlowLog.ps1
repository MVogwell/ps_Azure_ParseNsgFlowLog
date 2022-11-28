# Info on the log layout of NSG flow logs can be found here: https://docs.microsoft.com/en-us/azure/network-watcher/network-watcher-nsg-flow-logging-overview#faq
[CmdLetBinding()]
param (
	[Parameter(Mandatory=$True)][string]$InputFile,
	[Parameter(Mandatory=$True)][string]$Outputfile,
	[Parameter(Mandatory=$False)][switch]$AppendLog
)
Function psParseNsgFlowData() {
	param (
		[string]$InputFile,
		[string]$OutputFile,
		[bool]$Append = $False,
		[ref]$ReturnMsg
	)

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
				
		$arrFlowMap = @("UnixEpoch","sourceIP","destIP","sourcePort","destPort","proto","trafficFlow","action","flowState","packetsSrcToDest","bytesSrcToDest","packetsDstToSrc","bytesDestToSrc")

		$arrResults = @()

		try {
			$d = Get-Content $InputFile | ConvertFrom-Json
		}
		catch {
			$ReturnMsg.Value = "Failed to open input file $InputFile"
			$bReturn = $False
		}

		# Only proceed if the file was successfully loaded
		if ($bReturn -eq $True) {
			Write-Information "Input file: $InputFile"
			Write-Information "Output file: $OutputFile `n"
		
			$rs = $d.records
			$iCounter = 0
			$iTotal = $rs.count

			foreach ($r in $rs) {
				try {
					$iPercent = $iCounter / $iTotal * 100
					Write-Progress -Activity "Analysing log data" -PercentComplete $iPercent
				}
				catch { 
					Write-Progress -Activity "Analysing log data"
				}
				finally {
					$iCounter ++
				}

				$r.properties.flows.flows.flowtuples | ForEach-Object {	# Enumerate each flowtuple
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
					$arrResults | Export-Csv $OutputFile -NoTypeInformation -NoClobber -Delimiter "|" -Append
				}
				else {
					$arrResults | Export-Csv $OutputFile -NoTypeInformation -Delimiter "|"
				}
			}
			catch {
				$sErrMsg = "Failed to save results. Error: " + ($Error[0].Exception.Message).Replace("`n"," :: ").Replace("`r","")
				$ReturnMsg.Value = $sErrMsg
				
				$bReturn = $false
			}
		} # End of: Only proceed if the file was successfully loaded
	} # End of: Check the input file exists - else section

	if ($bReturn -eq $True) {
		Write-Information "Successfully parsed log data.`n"
		Write-Information "Results saved to $OutputFile `n"
	} 
	Else {
		Write-Information "Failed to complete successfully. `n"
		Write-Information "$($ReturnMsg.Value)"
	}
	
	return $bReturn
} # End of: function


#@# Main

# Save the preference for displaying Write-Information
$objInfoPref = $InformationPreference
$InformationPreference = "Continue"

Write-Information "`n`nAzure NSG Flow Export parser"
Write-Information "MVogwell - 24/11/2022 - v1.2`n"

# Remove quotes around the file path
$InputFile = $InputFile.Replace("`"","")

[string]$sReturnMsg = ""
[bool]$bReturn = psParseNsgFlowData -InputFile $InputFile -OutputFile $Outputfile -Append $AppendLog -ReturnMsg ([ref]$sReturnMsg)

If ($bReturn -eq $True) {
	try {
		Write-Information "Opening results in Excel (if available)"

		Start-Process EXCEL.EXE $Outputfile

		Write-Output "`t+++ Success`n"
	}
	catch {
		Write-Information "`t--- Failed. Please open the file $Outputfile"
	}
}

Write-Information "Finished`n`n"

$InformationPreference = $objInfoPref
