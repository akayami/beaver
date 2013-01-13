Beaver 0.1 - The Eager 
======

Simple, easy and highly flexible deployment tool in BASH


### Overview

The process modeled consists of 3 basic steps:

1. Build/Archive: Code retrival form a source (ex. git, svn), preparation and storage of the package.
2. Deployment: Transfer of the package to a target servers
3. Flip: Switching of version on target servers

### Features:

1. All steps may be executed using single command, or can be executed one by one.
2. The tool can deploy using branch/tag and/or revisions.
3. Previous versions are left on the server, and a flip can be executed if deployment revert is needed
4. Allows for abstract versioning. If version is provided it will be used, otherwise, revision number is used. 
5. Deployment process uses rsync. Server side, a copy of previous version in made and it is upgraded using rsync.
6. The tool should be system agnostic, as long a bash is suppored (that's the general goal anyways).

### Usage:

beaver.sh - This is the main control through which most commands are executed. 

##### Options:

-p *project_name* - A project name preconfigured in the deployment tool

-e *enviorment_name* - The deployment target enviroment. Ex. prod, dev, stage. You can configure any number of ENVs and there is no implied flow between them.

-v *version_name* - A name by which you would like to refer to this build.

-r *revision_name* - A revision form which you would like to build (default: HEAD). If revision name is set, it will also set version, unless a version is also set separetly.

-b *branch_name* - Branch from which you would like to checkout. By default, it is trunk/master, but any other can be specified

-B - Build a new package

-d - Deploy a specific version of a package on a specific enviroment

-f - Flip a specific version of a package on a specific enviroment


#### Step 1: Build Examples:
`beaver.sh -p project -e stage -b trunk -v 0.0.1 -B`

`beaver.sh -p project -e stage -b branches/someBranch -r 3235 -v 2012-08-09-1 -B`

#### Step 2: Deploy Examples:
`beaver.sh -p project -e stage -v 2012-08-09-1 -d`

#### Step 3: Flip Example:
`beaver.sh -p project -e stage -v 2012-08-09-1 -f`

#### All In One Example:
`beaver.sh -p project -e stage -b branches/someBranch -r 3235 -v 2012-08-09-1 -d -f`



#### Tricks:
1. To know what projects are available: `beaver.sh -p`  
2. Check archived builds: `beaver.sh -p project -a`
3. Check deployed version: `beaver.sh -p project -e staging -s`
4. Display info about a version: `beaver.sh -p project -v version -i`

