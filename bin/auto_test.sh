#!/bin/bash

set -e

# = Usage =
echo "
Usage: $0 {SWIFT_VER}
"

# = Path/Var =
WORK_HOME=$(readlink -f `dirname $0`)
SWIFT_VER=${1:-'1.7.4'}
SWIFT_HOME="SWIFT-${SWIFT_VER}"
VENV_HOME="VENV"

                                                                            
#  = Color =
# Reset
Color_Off='\e[0m'       # Text Reset
# Regular Colors
Black='\e[0;30m'        # Black
Red='\e[0;31m'          # Red
Green='\e[0;32m'        # Green
Yellow='\e[0;33m'       # Yellow
Blue='\e[0;34m'         # Blue
Purple='\e[0;35m'       # Purple
Cyan='\e[0;36m'         # Cyan
White='\e[0;37m'        # White
# Bold
BBlack='\e[1;30m'       # Black
BRed='\e[1;31m'         # Red
BGreen='\e[1;32m'       # Green
BYellow='\e[1;33m'      # Yellow
BBlue='\e[1;34m'        # Blue
BPurple='\e[1;35m'      # Purple
BCyan='\e[1;36m'        # Cyan
BWhite='\e[1;37m'       # White

# = Fun =
wr(){
echo -e ${Yellow}"[Info] $@"${Color_Off}
}
 
cmd(){
echo -e ${Blue}"[CMD] $@"${Color_Off}
eval $@
}

install_dep_pkgs(){
PKG_GIT='git-core git-doc git-gui gitk'
PKG_PYHON='python-virtualenv'
PKG_DEP_SWIFT='curl gcc git-core memcached python-coverage python-dev python-nose python-setuptools python-simplejson python-xattr sqlite3 xfsprogs python-eventlet python-greenlet python-pastedeploy python-netifaces python-pip python-mock'

cmd aptitude update
cmd apt-get -y --force-yes install $PKG_GIT $PKG_PYHON $PKG_DEP_SWIFT
}

# = Init =
rm -fr $SWIFT_HOME
pkill -9 -f "swift" || true

# = Main =
wr 'Install dep pkgs'
install_dep_pkgs

wr 'Get Swift Code'
cmd git clone https://github.com/openstack/swift.git $SWIFT_HOME
cmd cd $SWIFT_HOME
cmd git checkout $SWIFT_VER

wr 'Gen Virtualenv'
cmd virtualenv  --no-site-packages $VENV_HOME
cmd source ./$VENV_HOME/bin/activate
cmd pip install -r ./tools/pip-requires
cmd "pip install -r ./tools/test-requires"

wr 'Run Unit Test'
mkdir -p /etc/swift/
cmd cp -f test/sample.conf /etc/swift/test.conf
cmd ./.unittests

wr 'Install swfit $SWIFT_VER'
cmd python setup.py develop

wr 'Build Swift All in One'
cd $WORK_HOME
cmd ./saio_build.sh ${WORK_HOME}/$SWIFT_HOME/

wr 'Run Swift Service'
cmd ${WORK_HOME}/$SWIFT_HOME/VENV/bin/swift-init main stop || true
cmd ${WORK_HOME}/$SWIFT_HOME/VENV/bin/swift-init main start || true
cmd ${WORK_HOME}/$SWIFT_HOME/VENV/bin/swift-init main status

wr 'Run Functional Test'
cd ${WORK_HOME}/$SWIFT_HOME/
cmd ./.functests

#wr 'Run Probe Test'
