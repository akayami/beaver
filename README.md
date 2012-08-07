Beaver - The Eager
======

Simple, easy and highly flexible deployment tool in BASH


### Overview

The process modeled consists of 3 basic steps:

1. Build: Code retrival form a source (ex. git, svn), preparation and storage of the package.
2. Deployment: Transfer of the package to a target servers
3. Flip: Switching of version on target servers

### Features:

1. All steps may be executed using single command, or can be executed one by one.
2. The tool can deploy using branch/tag and/or revisions.
3. Previous versions are left on the server, and a Flip can be executed in case of faulty deployment
4. Allows for abstract versioning. If version is provided it will be used, otherwise, revision number is used. 
5. The whole deployment process is pushed through ssh/scp. 
6. The tool should be system agnostic, as long a bash is suppored (that's the general goal anyways).

### Usage:
bvrctl.sh - This is the main control through which most commands are executed. 

#### Build Examples:
`bvrctl.sh -p webcams -e stage -b trunk -v 0.0.1`

`bvrctl.sh -p webcams -e stage -b branches/someBranch -r 3235 -v 2012-08-09-1`

#### Tricks:
1. To know what projects are available: `bvrctl.sh -p`  