# couchdb-shard-utils

![CI](https://github.com/ecraft/couchdb-shard-utils/workflows/CI/badge.svg)


An utility for working with the shards of a CouchDB database.

Here be dragons, you probably want to know what you are doing. Blindly running this without thinking will probably result in tears.
The scripts are provided as they might be useful to someone, but we do not take any responsibility for potential data loss.
You will want to read **and understand**: `https://docs.couchdb.org/en/2.3.1/cluster/sharding.html`

Currently this has been tested against CouchDB 2.3.1, and then it will use the administrative port 5986 that you should not have accessible but from the actual CouchDB machine. On 3.x it uses the normal port 5984.

The script is a self-contained ruby script.

Limitations:
- At the moment it supports CouchDB 2.3 and 3.x
- Currently this util does not take `n` into consideration in any way.
- Adding / Removing a node currently is an all or nothing.


## Adding a node to a cluster

`ruby shard_utils.rb add couchdb@ecvaawsdah3.local --couch-url http://user:pass@localhost --template couchdb@localhost --database fieldops_task`

This adds the same shards to `couchdb@ecvaawsdah3.local` as `couchdb@localhost` currently have. This tool does not take `n` into consideration.

This will output the JSON patch that will be applied:
```json
[
  {
    "op": "add",
    "path": "/changelog/2",
    "value": [
      "add",
      "00000000-7fffffff",
      "couchdb@ecvaawsdah3.local"
    ]
  },
  {
    "op": "add",
    "path": "/changelog/3",
    "value": [
      "add",
      "80000000-ffffffff",
      "couchdb@ecvaawsdah3.local"
    ]
  },
  {
    "op": "add",
    "path": "/by_node/couchdb@ecvaawsdah3.local",
    "value": [
      "00000000-7fffffff",
      "80000000-ffffffff"
    ]
  },
  {
    "op": "add",
    "path": "/by_range/00000000-7fffffff/1",
    "value": "couchdb@ecvaawsdah3.local"
  },
  {
    "op": "add",
    "path": "/by_range/80000000-ffffffff/1",
    "value": "couchdb@ecvaawsdah3.local"
  }
]
```
and ask you to confirm:
> Applying to fieldops_task, type 'yes' to confirm

If the changes have already been applied:

> Database fieldops_task is already up to date.

## Decomissioning a node

`ruby shard_utils.rb remove couchdb@localhost --couch-url http://user:pass@localhost  --database fieldops_task`


This will output the JSON patch that will be applied:
```json
[
  {
    "op": "add",
    "path": "/changelog/4",
    "value": [
      "remove",
      "00000000-7fffffff",
      "couchdb@localhost"
    ]
  },
  {
    "op": "add",
    "path": "/changelog/5",
    "value": [
      "remove",
      "80000000-ffffffff",
      "couchdb@localhost"
    ]
  },
  {
    "op": "remove",
    "path": "/by_node/couchdb@localhost"
  },
  {
    "op": "remove",
    "path": "/by_range/00000000-7fffffff/1"
  },
  {
    "op": "replace",
    "path": "/by_range/00000000-7fffffff/0",
    "value": "couchdb@ecvaawsdah3.local"
  },
  {
    "op": "remove",
    "path": "/by_range/80000000-ffffffff/1"
  },
  {
    "op": "replace",
    "path": "/by_range/80000000-ffffffff/0",
    "value": "couchdb@ecvaawsdah3.local"
  }
]
```
and ask you to confirm:
> Applying to fieldops_task, type 'yes' to confirm

If the changes have already been applied:

> Database fieldops_task is already up to date.


## Changing the -name of a node

In the example the old name was `-name couchdb@localhost`, the new `-name couchdb@ecvaawsdah3.local`

If you just change the -name in `vm.args`, all databases in fauxton vill fail to load due to the name change.

Since the shards are keyed by name, you need to add the new name:

`ruby shard_utils.rb add couchdb@ecvaawsdah3.local --couch-url http://user:pass@localhost --template couchdb@localhost --database fieldops_task`

Then you can remove the old name:

`ruby shard_utils.rb remove couchdb@localhost --couch-url http://user:pass@localhost  --database fieldops_task`

## Developing

Based on the assumption that you will need to copy this script to the node that needs modification and
run it there, the script is intentionally kept as a single file that does not need anything apart from
a ruby installation.

This means that the info in Gemfile is duplicated both inline and as a normal Gemfile, this is at least for the moment considered to be an acceptable tradeoff.


Run the unittests:

`bundle exec rake spec`



