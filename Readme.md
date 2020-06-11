# ps_Azure_ParseNsgFlowLog.ps1

## Purpose
The purpose of this script is to parse Azure NSG flow logs from the hierarchical JSON structure to csv for easier analysis in Excel.  

The fields extracted from the original data are:

* timestamp
* rulename
* UnixEpoch
* sourceIP
* destIP
* sourcePort
* destPort
* proto
* trafficFlow
* action
* flowState
* packetsSrcToDest (only available on NSG Flow v2 captures)
* bytesSrcToDest (only available on NSG Flow v2 captures)
* packetsDstToSrc (only available on NSG Flow v2 captures)
* bytesDestToSrc (only available on NSG Flow v2 captures)


## How to use this script
* Get the MAC address of the source or destination server. You'll need it in the next step

* Download the NSG flow log from Azure Storage Explorer. Depending on your confiuration the NSG files could be stored in Storage container \ Blob containers \ insights-logs-networksecuritygroupflowevent \ resourceId= \ SUBSCRIPTIONS \ "Your subscription id" \ ResourceGroups \ Select the Resource group \ PROVIDERS \ MICROSOFT.NETWORK \ NETWORKSECURITYGROUPS \ Select the NSG you want to view data from \ year \ month \ day \ hour \ minute (normally 0) \ macAddress="The MAC address you found in the previous step" \ PT1H.json

* Run the ps_Azure_ParseNsgFlowLog.ps1 script with the following arguments:

** .\ps_Azure_ParseNsgFlowLog.ps1 -InputFile "full path to the NSG flow json log" -OutputFile "full path of where you want to save the csv results to"

Or optionally (appending to an existing csv log rather than adding headers to the file and overwriting any existing files):

** .\ps_Azure_ParseNsgFlowLog.ps1 -InputFile "full path to the NSG flow json log" -OutputFile "full path of where you want to save the csv results to".txt -Append


## How to read the resulting .txt file
Open the OutputFile in Excel or similar and delimit the fields by the | (pipe) character. Use the Filter function to limit the results.


## Disclaimer
You run this completely at your own risk! No responsibility is taken for anything that happens from you running it including Nuclear Armageddon, Plagues of locusts or Dinosaurs eating your nearest and dearest!
