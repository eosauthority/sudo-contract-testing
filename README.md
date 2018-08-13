# eosio.sudo contract tests with multisig eosio account
This will show how to setup eosio.sudo contract and then document a test case for it.

## 1. Chain setup
[EOS-Test-Cave](https://github.com/EOS-BP-Developers/EOS-Test-Cave) was used to setup an environment for testing. Follow installation instructions there and then run the tests. After the tests are finished, nodeos and keosd instances are left running which we'll use in these tests.

## 2. eosio.sudo setup
In order to properly deploy eosio.sudo contract, we need to do these things:
1. Create eosio.sudo account with permissions set so that eosio controls it
2. Make it a privileged account
3. Set contract for this account

First two steps can be done in a single transaction. The last one has to be done in a separate transaction, because account has to be created before you an set contract to it.

Both of these transactions will be done by eosio, which means 15/21 signatures of active block producers will be required to execute them. eosio.multisig will be used to achieve it.


### 2.1. Create eosio.sudo account
The content in this section is a bit condensed and modified version of guide here: https://github.com/eosio/eosio.contracts/tree/master/eosio.sudo#21-create-the-eosiosudo-account. Some changes were made to commands so that it works with environment setup created by EOS-Test-Cave.
#### 2.1.1 Generate the transaction to create the eosio.sudo account

First, generate a transaction to capture the necessary actions involved in creating a new account:
```
$ ./cleos.sh system newaccount -s -j -d --transfer --stake-net "1.000 EOS" --stake-cpu "1.000 EOS" --buy-ram-kbytes 38 eosio eosio.sudo EOS8MMUW11TAdTDxqdSwSqJodefSoZbFhcprndomgLi9MeR2o8MT4 > generated_account_creation_trx.json
2018-08-10T06:50:13.252 thread-0   main.cpp:438                  create_action        ] result: {"binargs":"0000000000ea305500004d1a03ea305500980000"} arg: {"code":"eosio","action":"buyrambytes","args":{"payer":"eosio","receiver":"eosio.sudo","bytes":38912}} 
2018-08-10T06:50:13.258 thread-0   main.cpp:438                  create_action        ] result: {"binargs":"0000000000ea305500004d1a03ea3055102700000000000004454f5300000000102700000000000004454f530000000001"} arg: {"code":"eosio","action":"delegatebw","args":{"from":"eosio","receiver":"eosio.sudo","stake_net_quantity":"1.0000 EOS","stake_cpu_quantity":"1.0000 EOS","transfer":true}} 
```
Adjust the amount of delegated tokens and the amount of RAM bytes to gift as necessary. The actual public key used is not important since that data is only encoded into the `eosio::newaccount` action which will be replaced soon anyway.

Second, create a file (e.g. newaccount_payload.json) with the JSON payload for the real `eosio::newaccount` action. It should look like:
```
$ cat newaccount_payload.json
{
   "creator": "eosio",
   "name": "eosio.sudo",
   "owner": {
      "threshold": 1,
      "keys": [],
      "accounts": [{
         "permission": {"actor": "eosio", "permission": "active"},
         "weight": 1
      }],
      "waits": []
   },
   "active": {
      "threshold": 1,
      "keys": [],
      "accounts": [{
         "permission": {"actor": "eosio", "permission": "active"},
         "weight": 1
      }],
      "waits": []
   }
}
```

Third, generate a transaction containing the actual `eosio::newaccount` action that will be used in the final transaction:
```
$ ./cleos.sh push action -s -j -d eosio newaccount newaccount_payload.json -p eosio > generated_newaccount_trx.json
```

Fourth, generate a transaction containing the `eosio::setpriv` action which will make the `eosio.sudo` account privileged:
```
$ ./cleos.sh push action -s -j -d eosio setpriv '{"account": "eosio.sudo", "is_priv": 1}' -p eosio > generated_setpriv_trx.json
```

Next, the action JSONs of the previously generated transactions will be used to construct a unified transaction which will eventually be proposed with the eosio.msig contract. A good way to get started is to make a copy of the generated_newaccount_trx.json file (call the copied file create_sudo_account_trx.json) and edit the first three fields so it looks something like the following:
```
$ cat create_sudo_account_trx.json
{
  "expiration": "2018-09-10T06:53:36",
  "ref_block_num": 0,
  "ref_block_prefix": 0,
  "max_net_usage_words": 0,
  "max_cpu_usage_ms": 0,
  "delay_sec": 0,
  "context_free_actions": [],
  "actions": [{
      "account": "eosio",
      "name": "newaccount",
      "authorization": [{
          "actor": "eosio",
          "permission": "active"
        }
      ],
      "data": "0000000000ea305500004d1a03ea30550100000000010000000000ea305500000000a8ed32320100000100000000010000000000ea305500000000a8ed3232010000"
    }
  ],
  "transaction_extensions": [],
  "signatures": [],
  "context_free_data": []
}
```
The `ref_block_num` and `ref_block_prefix` fields were set 0 zero, because they don't matter for transactions used with eosio.msig. Then expiration field was set more into the future. You need to set this field far enough into the future, so that BPs can review, approve and then execute this transaction before this expires.

Then, all but the first action JSON object of generated_account_creation_trx.json should be appended to the `actions` array of create_sudo_account_trx.json, and then the single action JSON object of generated_setpriv_trx.json should be appended to the `actions` array of create_sudo_account_trx.json. The final result is a create_sudo_account_trx.json file that looks like the following:
```
$ cat create_sudo_account_trx.json
{
  "expiration": "2018-09-10T06:53:36",
  "ref_block_num": 0,
  "ref_block_prefix": 0,
  "max_net_usage_words": 0,
  "max_cpu_usage_ms": 0,
  "delay_sec": 0,
  "context_free_actions": [],
  "actions": [{
      "account": "eosio",
      "name": "newaccount",
      "authorization": [{
          "actor": "eosio",
          "permission": "active"
        }
      ],
      "data": "0000000000ea305500004d1a03ea30550100000000010000000000ea305500000000a8ed32320100000100000000010000000000ea305500000000a8ed3232010000"
    },{
      "account": "eosio",
      "name": "buyrambytes",
      "authorization": [{
          "actor": "eosio",
          "permission": "active"
        }
      ],
      "data": "0000000000ea305500004d1a03ea305500980000"
    },{
      "account": "eosio",
      "name": "delegatebw",
      "authorization": [{
          "actor": "eosio",
          "permission": "active"
        }
      ],
      "data": "0000000000ea305500004d1a03ea3055102700000000000004454f5300000000102700000000000004454f530000000001"
    },{
      "account": "eosio",
      "name": "setpriv",
      "authorization": [{
          "actor": "eosio",
          "permission": "active"
        }
      ],
      "data": "00004d1a03ea305501"
    }
  ],
  "transaction_extensions": [],
  "signatures": [],
  "context_free_data": []
}
```
The transaction in create_sudo_account_trx.json is now ready to be proposed.

It will be useful to have a JSON of the active permissions of each of the active block producers for later when proposing transactions using the eosio.msig contract.

If you're using EOS-Test-Cave as described in 1 section, you can just use the file generated by it:

```
$ cp <eos-test-cave-root-folder>/log/tmp_msig.json ./bp-permissions.json
$ cat bp-permissions.json 
[
  {"actor":"testaccountb","permission":"active"},
  {"actor":"testaccountc","permission":"active"},
  {"actor":"testaccountd","permission":"active"},
  {"actor":"testaccounte","permission":"active"},
  {"actor":"testaccountf","permission":"active"},
  {"actor":"testaccountg","permission":"active"},
  {"actor":"testaccounth","permission":"active"},
  {"actor":"testaccounti","permission":"active"},
  {"actor":"testaccountj","permission":"active"},
  {"actor":"testaccountk","permission":"active"},
  {"actor":"testaccountl","permission":"active"},
  {"actor":"testaccountm","permission":"active"},
  {"actor":"testaccountn","permission":"active"},
  {"actor":"testaccounto","permission":"active"},
  {"actor":"testaccountp","permission":"active"},
  {"actor":"testaccountq","permission":"active"},
  {"actor":"testaccountr","permission":"active"},
  {"actor":"testaccounts","permission":"active"},
  {"actor":"testaccountt","permission":"active"},
  {"actor":"testaccountu","permission":"active"},
  {"actor":"testaccountv","permission":"active"}]```
```

#### 2.1.2 Propose transaction to create the eosio.sudo account

Only one of the potential approvers will need to propose the transaction that was created in the previous sub-section. 

The approvers are typically going to be the active block producers of the chain, so it makes sense that one of the block producers is elected as the leader to propose the actual transaction. Note that this lead block producer will need to incur the temporary RAM cost of proposing the transaction, but they will get the RAM back when the proposal has executed or has been canceled (which only the proposer can do prior to expiration).

The guide will assume that `testaccountb` was chosen as the lead block producer to propose the transaction.

You might need to unlock the wallet first:
```
$ ./cleos.sh wallet open -n testmultisig
$ cat <eos-test-cave-root-folder>/log/wallet_name_testmultisig_password.dat 
PW5K7a14PMFK9MAV3qqQsBSCWzrKonHhRpH6zaqjqqLDcCJByRwEQ
$ ./cleos.sh wallet unlock -n testmultisig --password PW5K7a14PMFK9MAV3qqQsBSCWzrKonHhRpH6zaqjqqLDcCJByRwEQ
Unlocked: testmultisig
```

The lead block producer (`testaccountb`) should propose the transaction stored in create_sudo_account_trx.json:
```
$ ./cleos.sh multisig propose_trx createsudo bp-permissions.json create_sudo_account_trx.json testaccountb
executed transaction: 4cd551c333bca0e39a9fbfbdeba7d5683b1b1e3df13345dea49e99e70f65c0c2  744 bytes  4085 us
#    eosio.msig <= eosio.msig::propose          {"proposer":"testaccountb","proposal_name":"createsudo","requested":[{"actor":"testaccountb","permis...
warning: transaction executed locally, but may not be confirmed by the network yet    ]
```

#### 2.1.3 Review and approve the transaction to create the eosio.sudo account

Each of the potential approvers of the proposed transaction (i.e. the active block producers) should first review the proposed transaction to make sure they are not approving anything that they do not agree to.

The proposed transaction can be reviewed using the `cleos multisig review` command:
```
$ ./cleos.sh multisig review testaccountb createsudo > create_sudo_account_trx_to_review.json
$ head -n 30 create_sudo_account_trx_to_review.json
{
  "proposal_name": "createsudo",
  "packed_transaction": "f014965b00000000000000000000040000000000ea305500409e9a2264b89a010000000000ea305500000000a8ed3232420000000000ea305500004d1a03ea30550100000000010000000000ea305500000000a8ed32320100000100000000010000000000ea305500000000a8ed32320100000000000000ea305500b0cafe4873bd3e010000000000ea305500000000a8ed3232140000000000ea305500004d1a03ea3055009800000000000000ea305500003f2a1ba6a24a010000000000ea305500000000a8ed3232310000000000ea305500004d1a03ea3055102700000000000004454f5300000000102700000000000004454f5300000000010000000000ea305500000060bb5bb3c2010000000000ea305500000000a8ed32320900004d1a03ea30550100",
  "transaction": {
    "expiration": "2018-09-10T06:53:36",
    "ref_block_num": 0,
    "ref_block_prefix": 0,
    "max_net_usage_words": 0,
    "max_cpu_usage_ms": 0,
    "delay_sec": 0,
    "context_free_actions": [],
    "actions": [{
        "account": "eosio",
        "name": "newaccount",
        "authorization": [{
            "actor": "eosio",
            "permission": "active"
          }
        ],
        "data": {
          "creator": "eosio",
          "name": "eosio.sudo",
          "owner": {
            "threshold": 1,
            "keys": [],
            "accounts": [{
                "permission": {
                  "actor": "eosio",
                  "permission": "active"
                },
```

When an approver (e.g. `testaccountc`) is satisfied with the proposed transaction, they can approve it:
```
$ ./cleos.sh multisig approve testaccountb createsudo '{"actor": "testaccountc", "permission": "active"}' -p testaccountc
executed transaction: fcead341ff8da2001b767edabf481d9b10edf41a686404627e1be434bf4cc1ce  128 bytes  2807 us
#    eosio.msig <= eosio.msig::approve          {"proposer":"testaccountb","proposal_name":"createsudo","level":{"actor":"testaccountc","permission"...
warning: transaction executed locally, but may not be confirmed by the network yet    ] 
```

We need 14 more approvals, you can execute this script to automate that while testing:
```
$ ./approve.sh testaccountb createsudo

```

#### 2.1.4 Execute the transaction to create the eosio.sudo account

When the necessary approvals are collected anyone can push eosio.msig::exec action to execute the proposed transaction:
```
 $ ./cleos.sh multisig exec testaccountb createsudo testaccounta
executed transaction: 59c3a394b547952ff57bede22e1afaffde2d5ff6e539720d9c7aabb1eefb8c95  160 bytes  3937 us
#    eosio.msig <= eosio.msig::exec             {"proposer":"testaccountb","proposal_name":"createsudo","executer":"testaccounta"}
warning: transaction executed locally, but may not be confirmed by the network yet    ] 
```

Anyone can now verify that the `eosio.sudo` was created:
```
$ ./cleos.sh get account eosio.sudo
privileged: true
permissions: 
     owner     1:    1 eosio@active, 
        active     1:    1 eosio@active, 
memory: 
     quota:     37.81 KiB    used:      3.33 KiB  

net bandwidth: 
     staked:          1.0000 EOS           (total stake delegated from account to self)
     delegated:       0.0000 EOS           (total staked delegated to account from others)
     used:                 0 bytes
     available:        1.283 MiB  
     limit:            1.283 MiB  

cpu bandwidth:
     staked:          1.0000 EOS           (total stake delegated from account to self)
     delegated:       0.0000 EOS           (total staked delegated to account from others)
     used:                 0 us   
     available:        256.1 ms   
     limit:            256.1 ms   

producers:     <not voted>
```

### 2.2. Set contract for eosio.sudo
Now we need to create, propose and execute a transaction which would set code and abi for eosio.sudo contract.

First generate a transaction:
```
./cleos.sh set contract -j -d -s eosio.sudo <path-to-sudo-build-dir> > gen_set_contract_trx.json
```

Change TaPOS and expiration fields like for all msig transactions:
```
$ head -n 10 gen_set_contract_trx.json 
{
  "expiration": "2018-09-10T07:44:43",
  "ref_block_num": 0,
  "ref_block_prefix": 0,
  "max_net_usage_words": 0,
  "max_cpu_usage_ms": 0,
  "delay_sec": 0,
  "context_free_actions": [],
  "actions": [{
      "account": "eosio",
```

Propose this transaction:
```
./cleos.sh multisig propose_trx deploysudo bp-permissions.json gen_set_contract_trx.json testaccountb
executed transaction: e08526e54637e699564759b1d4c9bc9227bd592b6f9746f2cf090523b093aea5  4312 bytes  4549 us
#    eosio.msig <= eosio.msig::propose          {"proposer":"testaccountb","proposal_name":"deploysudo","requested":[{"actor":"testaccountb","permis...
warning: transaction executed locally, but may not be confirmed by the network yet    ] 
```

Now other BPs should review it:
```
$ ./cleos.sh multisig review testaccountb deploysudo > deploysudo_proposal.json
$ cat deploysudo_proposal.json
```

And aprove it:
```
$ ./cleos.sh multisig approve testaccountb deploysudo '{"actor": "testaccountc", "permission": "active"}' -p testaccountc
executed transaction: 1aff050bcbb27b3a9e43974ce47d80f7f994e36508cd6079f0e04325d6402958  128 bytes  2745 us
#    eosio.msig <= eosio.msig::approve          {"proposer":"testaccountb","proposal_name":"deploysudo","level":{"actor":"testaccountc","permission"...
warning: transaction executed locally, but may not be confirmed by the network yet    ] 
```

Make other BPs approve as well:
```
$ ./approve.sh testaccountb deploysudo
```

Finally we can execute:
```
./cleos.sh multisig exec testaccountb deploysudo testaccounta
executed transaction: 04cafc1f0834dc82f1f1c43e82452eb1c5393a932f966dc8c0fe10188d856f54  160 bytes  12075 us
#    eosio.msig <= eosio.msig::exec             {"proposer":"testaccountb","proposal_name":"deploysudo","executer":"testaccounta"}
warning: transaction executed locally, but may not be confirmed by the network yet    ]
```

## 3. Test usage of eosio.sudo
eosio.sudo requires authority of eosio to execute transactions through it. This means that we will have to use eosio.msig to propose and execute transactions, which will call eosio.sudo, with transaction that we really want to execute. This implies the following steps:

1. Generate a transaction we want to execute bypassing permissions
2. Generate a transaction which calls sudo with transaction we just generated in the first step
3. Send a multisig proposal for the transaction we generated in the second step
4. Approve and execute multisig proposal as usual

### 3.1. Transfer funds out of someones account
We will try to transfer EOS from `testaccount1` into `eosio` account. Note the balance that `testaccount1` has now:
```
$ ./cleos.sh get currency balance eosio.token testaccount1 "EOS"
1079411.0647 EOS
```

First generate the transfer action:
```
$ ./cleos.sh transfer -j -d -s testaccount1 eosio "100.0000 EOS" > gen_transfer_trx.json
```
Generate a transaction which calls eosio.sudo::exec with the transaction we just generated:
```
$ ./cleos.sh sudo exec -j -d -s testaccountb gen_transfer_trx.json > gen_transfer_msig_trx.json
```

Modify TaPos headers to 0, and expiration field far enough into the future so that block producers can approve and execute in time. It should look something like this (except change expiration field so that it works for you):
```
$ cat gen_transfer_msig_trx.json 
{
  "expiration": "2018-09-10T08:32:52",
  "ref_block_num": 0,
  "ref_block_prefix": 0,
  "max_net_usage_words": 0,
  "max_cpu_usage_ms": 0,
  "delay_sec": 0,
  "context_free_actions": [],
  "actions": [{
      "account": "eosio.sudo",
      "name": "exec",
      "authorization": [{
          "actor": "testaccountb",
          "permission": "active"
        },{
          "actor": "eosio.sudo",
          "permission": "active"
        }
      ],
      "data": "70f2d4142193b1ca3c4d6d5bbd3040ba109e000000000100a6823403ea3055000000572d3ccdcd0120f2d4142193b1ca00000000a8ed32322120f2d4142193b1ca0000000000ea305540420f000000000004454f53000000000000"
    }
  ],
  "transaction_extensions": [],
  "signatures": [],
  "context_free_data": []
}
```

Now propose this transaction:
```
$ ./cleos.sh multisig propose_trx transfer1 bp-permissions.json gen_transfer_msig_trx.json testaccountc
executed transaction: e468af846d677b727f6bc20bf589804ef52c6e98128f5bd9ef89cf810c9cc9ce  608 bytes  4244 us
#    eosio.msig <= eosio.msig::propose          {"proposer":"testaccountc","proposal_name":"transfer1","requested":[{"actor":"testaccountb","permiss...
warning: transaction executed locally, but may not be confirmed by the network yet    ] 
```

Review it:
```
$ ./cleos.sh multisig review testaccountc transfer1 > transfer_proposal.json
$ cat transfer_proposal.json
```

Approve:
```
$ ./approve.sh testaccountc transfer1
```

And execute it:
```
./cleos.sh multisig exec testaccountc transfer1 testaccountc
executed transaction: abe996178eb5526850e23688c05d9adfcdd8ccdf92cdf9fd3ea2a7cce1521dd3  160 bytes  4158 us
#    eosio.msig <= eosio.msig::exec             {"proposer":"testaccountc","proposal_name":"transfer1","executer":"testaccountc"}
warning: transaction executed locally, but may not be confirmed by the network yet    ]
```

The transfer transaction out of `testaccount1` into `eosio` account should have been executed. Check `testaccount1` balance:
```
$ ./cleos.sh get currency balance eosio.token testaccount1 "EOS"
1079311.0647 EOS
```

Note that it's 100.0000 EOS less, which means the transfer has been executed.



