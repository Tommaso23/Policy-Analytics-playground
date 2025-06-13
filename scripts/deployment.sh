#!/bin/bash

rg="rg-spoke1-poly-itn"
vmName="vm-lnx-1-poly-itn"


az vm extension set \
  --resource-group $rg \
  --vm-name $vmName \
  --name cronjobsScript \
  --publisher Microsoft.Azure.Extensions \
  --version 2.1 \
  --settings '{
    "fileUris": ["https://raw.githubusercontent.com/Tommaso23/Policy-Analytics-playground/main/scripts/cronjobs.sh"],
    "commandToExecute": "bash cronjobs.sh"
  }'
