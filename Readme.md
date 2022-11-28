# ps_Azure_ParseNsgFlowLog.ps1

## Purpose
The purpose of this script is to parse Azure Network Security Group (NSG) flow logs from the hierarchical JSON structure to csv for easier analysis in Excel or LibreOffice Calc.

For more information about Network Security Group flow logs and setting up logging please visit: https://martinvogwell.medium.com/the-problem-with-reading-azure-network-security-group-flow-logs-6fd1290bc12d

## What does this script do?
This script will parse an NSG flow log from the native Json format (very difficult to read!) to csv providing the following fields:

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

For more information about the fields found in the json data and extracted by this script see https://docs.microsoft.com/en-us/azure/network-watcher/network-watcher-nsg-flow-logging-overview#log-format

<br>

## How to use this script
* Get the MAC address of the source or destination server. You'll need it in the next step

* Download the NSG flow log from Azure Storage Explorer. Depending on your confiuration the NSG files could be stored in Storage container \ Blob containers \ insights-logs-networksecuritygroupflowevent \ resourceId= \ SUBSCRIPTIONS \ "Your subscription id" \ ResourceGroups \ Select the Resource group \ PROVIDERS \ MICROSOFT.NETWORK \ NETWORKSECURITYGROUPS \ Select the NSG you want to view data from \ year \ month \ day \ hour \ minute (normally 0) \ macAddress="The MAC address you found in the previous step" \ PT1H.json

* Run the ps_Azure_ParseNsgFlowLog.ps1 script with the following arguments:

`.\ps_Azure_ParseNsgFlowLog.ps1 -InputFile "full path to the NSG flow json log" -OutputFile "full path of where you want to save the csv results to"`

Or optionally (appending to an existing csv log rather than adding headers to the file and overwriting any existing files):

** .\ps_Azure_ParseNsgFlowLog.ps1 -InputFile "full path to the NSG flow json log" -OutputFile "full path of where you want to save the csv results to".txt -Append

<br>

## How to read the resulting .txt file
Open the OutputFile in Excel or similar and delimit the fields by the | (pipe) character. Use the Filter function to limit the results.

The fields are pretty self explanatory, but;

* Proto: 
  * T = TCP
  * U = UDP
* trafficFlow: 
  * O = OutBound
  * I = InBound
* action
  * A = Allowed
  * D = Denied

<br>


## Disclaimer
You run this completely at your own risk! No responsibility is taken for anything that happens from you running it including Nuclear Armageddon, Plagues of locusts or Dinosaurs eating your nearest and dearest!
