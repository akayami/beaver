Beaver - The Eager
======

Simple, easy and highly flexible deployment tool in BASH


### Overview

The process modeled consists of 3 basic steps:

1. Build/Archive: Code retrieval form a source (ex. git, svn), preparation and storage of the package.
2. Deployment: Transfer of the package to a target servers
3. Flip: Switching of version on target servers

### Features:

1. All steps may be executed using single command, or can be executed one by one.
2. The tool can deploy using branch/tag and/or revisions.
3. Previous versions are left on the server, and a flip can be executed if deployment revert is needed
4. Allows for abstract versioning. If version is provided it will be used, otherwise, revision number is used.
5. Deployment process uses rsync. Server side, a copy of previous version in made and it is upgraded using rsync.
6. The tool should be system agnostic, as long a bash is supported (that's the general goal anyways).

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

-a - Archive list

-i - Build info

-s - Server Status


#### Step 1: Build Examples:
`beaver.sh -p project -e stage -b trunk -v 0.0.1 -B`

`beaver.sh -p project -e stage -b branches/someBranch -r 3235 -v 2012-08-09-1 -B`

#### Step 2: Deploy Examples:
`beaver.sh -p project -e stage -v 2012-08-09-1 -d`

#### Step 3: Flip Example:
`beaver.sh -p project -e stage -v 2012-08-09-1 -f`

#### All In One Example:
`beaver.sh -p project -e stage -b branches/someBranch -r 3235 -v 2012-08-09-1 -d -f`

#### Other functions
##### Dump list of archived builds for a project
`beaver.sh -p project -a`
##### Get information about a builds
`beaver.sh -p project -v version -i`
##### What is deployed on each server
`beaver.sh -p project -e environment -s`

#### Tricks:
1. To know what projects are available: `beaver.sh -p`  
2. Check archived builds: `beaver.sh -p project -a`
3. Check deployed version: `beaver.sh -p project -e staging -s`
4. Display info about a version: `beaver.sh -p project -v version -i`

### Installation

There are multiple ways of installing the script. The following is the way the maintainer recommends setting it up. 

#### The deploy server
First you need to decide where you want to host beaver. Make sure that the server has enough disk space to hold your builds. It is possible to host beaver on your own machine.
In either case you should create a dedicated user with it's own home directory. I'll create a user `deploy` on my remote server. Connect to your remote machine using ssh as the newly created deploy user. 

`ssh deploy@my-deploy-machine.local`

In home directory clone beaver:

`git clone https://github.com/akayami/beaver.git`

This will clone beaver's repo into you home.
Next you will need to create your beaver config files. Currently, beaver expects your files to be in `$HOME/.bvrconfig`. Let's start by copying the sample config file provided in this repo:

```bash
cd ~
mkdir ~/.bvrconfig
cp -r beaver/sample-conf/* ~/.bvrconfig/
```
This should give you a starting point. 
Your config files are located inside `~/.bvrconfig/conf/`. It is a good practive to push the contents of your `~/.bvrconfig/conf/` into a  private git repo so that you can easily edit them and keep track of changes. 

We're going to start by making the Beaver tool deployable by Beaver !
First, there are two types of confing: 
`sources` and `servers`

##### Sources
Sources contain information on where the source-code is. It will usually be a git repo. You can view an example of this file by viewing the source file for beaver:

`cat ~/.bvrconfig/conf/sources/beaver/source`

You should see this self-evident configuration:

```bash
REPO_TYPE="git"
REPO_URL="git@github.com:akayami/beaver.git"
DEFAULT_BRANCH="master"
```

##### Servers
Next we shall inspect the server's config file:
`cat ~/.bvrconfig/conf/servers/beaver/prod/servers`

```
SERVERS=( deploy@akayami.com  )
SERVERS_DEPLOY_HOME=/my/apps/home/path
```

Here you can define where you will be deploying your code, and into which directory. 
Change the server string in SERVERS to match your server.
You need to also define a place where beaver shall deploy your code. In this exmaple I'll deploy it to: 

```
/home/deploy/apps
```

so my file will look like this:
```
SERVERS=( deploy@my-deploy-machine.local  )
SERVERS_DEPLOY_HOME=/home/deploy/apps
```
It is recommended to add your own key to `~/.ssh/authorized_keys` so that you can ssh on yourself without being asked for password. If you do not do this, you will be asked for your password a lot.

Now you should be able to deploy beaver using beaver:
`~/beaver/beaver.sh -p beaver -e prod -b 0.0.3 -v 0.0.3 -B -d -f`

It will appear in `~/apps/beaver/prod/0.0.3/`. There should also be a symlink called `current` pointing to `0.0.3`. The `current` symlink is how the system knows which version to currently use. 

The last thing to do is to add beaver.sh to your exec path or to create a symlink as follows (root powers needed):
```bash
cd /usr/bin
ln -s /home/deploy/apps/beaver/prod/current/beaver.sh
```

Now you should be able to run the `beaver.sh` command from you deploy user account.

```
beaver.sh -p beaver -e prod -b 0.0.3 -v 0.0.3 -B -d -f
```

Now you should be able to delete the beaver code that is in ~/beaver and only use the global command which references the copy of beaver stored in ~/apps/beaver/prod/current/

