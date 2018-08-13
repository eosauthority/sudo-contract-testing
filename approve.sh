#!/bin/bash

ACCOUNTS=( testaccounta testaccountb testaccountc testaccountd testaccounte testaccountf testaccountg testaccounth testaccounti testaccountj testaccountk testaccountl testaccountm testaccountn testaccounto testaccountp testaccountq testaccountr testaccounts testaccountt testaccountu testaccountv );
proposer="$1"
proposal="$2"

for(( i=1; i<16; i++ )); do
  account=${ACCOUNTS[$i]}
  permission="{\"actor\":\"${account}\",\"permission\":\"active\"}"
  echo "$permission"
  cleos.sh multisig approve ${proposer} ${proposal} "${permission}" -p ${account}
done

