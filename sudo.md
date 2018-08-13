# eosio.sudo contract tests
Here a test case is documented for eosio.sudo contract, where eosio is *not* multisig account.

## Prerequisites
* Test chain setup with usual system contracts
* System token: `SYS`

You can try the same tests with different configuration, but
you might need to make some modifications to commands here.

## Setup sudo contract
Create account for eosio.sudo contract.
```
cleos.sh system newaccount --transfer --stake-net "1.000 SYS" --stake-cpu "1.000 SYS" --buy-ram-kbytes 50 eosio eosio.sudo EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV
```
Make eosio.sudo a privileged account
```
cleos.sh push action eosio setpriv '{"account": "eosio.sudo", "is_priv": 1}' -p eosio
```
Set contract for this account:
```
cleos.sh set contract eosio.sudo ./ eosio.sudo.wast eosio.sudo.abi
```

## Setup test account
```
cleos.sh system newaccount --transfer --stake-net "1.000 SYS" --stake-cpu "1.000 SYS" --buy-ram-kbytes 50 eosio acca EOS6eejBtUXfd2cVEXL4KFxsaLo3R8bpD91R7r1SK4oa8UKQdhPL1
cleos.sh push action eosio.token issue '["acca" "100.0000 SYS"]' -p eosio
```

## Tests
### 1. Without sudo
First let's try to execute some actions with eosio, without the right authorizations to see that it fails:
```
$ cleos.sh transfer acca eosio "10.0000 SYS" -p eosio
Error 3090004: Missing required authority
Ensure that you have the related authority inside your transaction!;
If you are currently using 'cleos push action' command, try to add the relevant authority using -p option.

$ cleos.sh set account permission acca owner EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV -p eosio
Error 3090005: Irrelevant authority included
Please remove the unnecessary authority from your action!
```

### 2. Transfer funds from account
Check the balance of `acca` account initially:
```
cleos.sh get currency balance eosio.token acca "SYS"
100.0000 SYS
```
Generate a transaction with which we transfer from `acca` to `eosio`:
```
cleos.sh transfer -j -d -s acca eosio "10.0000 SYS" > transfer-tx.json
```
Now send this transaction to sudo:
```
cleos.sh sudo exec eosio transfer-tx.json
```
See that `acca` now has 10.000 SYS less:
```
cleos.sh get currency balance eosio.token acca "SYS"
90.0000 SYS
```

### 3. Replace owner key of some account
First, check keys of `acca` before we do this:
```
cleos.sh get account acca
permissions: 
     owner     1:    1 EOS6eejBtUXfd2cVEXL4KFxsaLo3R8bpD91R7r1SK4oa8UKQdhPL1
        active     1:    1 EOS6eejBtUXfd2cVEXL4KFxsaLo3R8bpD91R7r1SK4oa8UKQdhPL1
memory: 
     quota:     49.74 KiB    used:     3.475 KiB  

net bandwidth: 
     staked:          1.0000 SYS           (total stake delegated from account to self)
     delegated:       0.0000 SYS           (total staked delegated to account from others)
     used:                 0 bytes
     available:        180.1 GiB  
     limit:            180.1 GiB  

cpu bandwidth:
     staked:          1.0000 SYS           (total stake delegated from account to self)
     delegated:       0.0000 SYS           (total staked delegated to account from others)
     used:                 0 us   
     available:        10.24 hr   
     limit:            10.24 hr   

SYS balances: 
     liquid:          100.0000 SYS
     staked:            2.0000 SYS
     unstaking:         0.0000 SYS
     total:           102.0000 SYS

producers:     <not voted>
   ```
Now generate a transaction we want to execute with sudo:
```
cleos.sh set account permission -s -j -d acca owner EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV > set-permissions-tx.jsoncle
```
Now send it to sudo contract:
```
cleos.sh sudo exec eosio ./set-permissions-tx.json -p eosio.sudo -p eosio
```
Verify that it worked (note the owner key):
```
cleos.sh get account acca
permissions: 
     owner     1:    1 EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV
        active     1:    1 EOS6eejBtUXfd2cVEXL4KFxsaLo3R8bpD91R7r1SK4oa8UKQdhPL1
memory: 
     quota:     49.74 KiB    used:     3.475 KiB  

net bandwidth: 
     staked:          1.0000 SYS           (total stake delegated from account to self)
     delegated:       0.0000 SYS           (total staked delegated to account from others)
     used:                 0 bytes
     available:        211.8 GiB  
     limit:            211.8 GiB  

cpu bandwidth:
     staked:          1.0000 SYS           (total stake delegated from account to self)
     delegated:       0.0000 SYS           (total staked delegated to account from others)
     used:             5.267 ms   
     available:        12.03 hr   
     limit:            12.03 hr   

SYS balances: 
     liquid:          100.0000 SYS
     staked:            2.0000 SYS
     unstaking:         0.0000 SYS
     total:           102.0000 SYS

producers:     <not voted>
```






