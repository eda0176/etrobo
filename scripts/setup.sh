#!/usr/bin/env bash
# etrobo all-in-one package installer/updater
#   setup.sh 
# Author: jtFuruhata
# Copyright (c) 2020 ETロボコン実行委員会, Released under the MIT license
# See LICENSE
#

# download a file by wget and destroy installer when download error is occured
download () {
    wget "$@"
    case $? in
        0 ) return 0;;
        1 ) echo "Request error: an error occured with wget execution";;
        2 ) echo "Command parse error: invalid options for wget";;
        3 ) echo "File I/O error:";;
        4 ) echo "Network error: download failed";;
        5 ) echo "SSL verification error:";;
        6 ) echo "Username/Password authentication error:";;
        7 ) echo "Protocol error:";;
        8 ) echo "Server error: something is wrong with this file server";;
    esac
    echo
    echo "Package downloader failed. Please re-install this package later."
    exit 1
}

if [ -f "BeerHall" ]; then
    BeerHall="$BEERHALL"
else
    BeerHall=""
fi

if [ "$1" = "update" ]; then
    update="update"
    dist="$2"
    cd "$ETROBO_ROOT"
    echo "update etrobo package:"
    git pull
    rm -f ~/startetrobo
    cp -f scripts/startetrobo ~/
    if [ "$ETROBO_OS" = "mac" ]; then
        rm -f "$BEERHALL/../startetrobo_mac.command"
        cp -f scripts/startetrobo_mac.command "$BEERHALL/../"
    fi
    cd "$ETROBO_SCRIPTS"
    . "etroboenv.sh" unset
    . "etroboenv.sh"
fi

if [ -z "$ETROBO_ROOT" ]; then
    echo "run startetrobo first."
    exit 1
elif [ ! "$ETROBO_ENV" = "available" ]; then
    . "$BEERHALL/etc/profile.d/etrobo.sh"
fi
cd "$ETROBO_ROOT"

if [ -z "$update" ]; then
    echo
    echo "Install etrobo Environment: start"
    #
    # install the TOPPERS/EV3RT 1.0
    # see https://dev.toppers.jp/trac_user/ev3pf/wiki/WhatsEV3RT
    #
    if [ "$ETROBO_KERNEL" = "debian" ]; then
        #
        # EV3RT requirement from:
        # http://ev3rt-git.github.io/public/ev3rt-prepare-ubuntu.sh
        #
        echo
        echo "Remove binutils-arm-none-eabi and gcc-arm-none-eabi:"
        sudo apt remove binutils-arm-none-eabi gcc-arm-none-eabi -y
        echo
        echo "Install u-boot-tools and lib32stdc++6:"
        sudo apt install u-boot-tools lib32stdc++6 -y
    else
        #
        # EV3RT requirement from:
        # https://dev.toppers.jp/trac_user/ev3pf/wiki/DevEnvMac
        #
        echo 
        echo "Install mkimage:"
        download "https://dev.toppers.jp/trac_user/ev3pf/attachment/wiki/DevEnvMac/mkimage"
        mv mkimage "$BEERHALL/usr/local/bin"
    fi
    echo
    echo "Install GNU Arm Embedded Toolchain:"
    download "$ETROBO_HRP3_GCC_URL"
    tar -xvvf `basename $ETROBO_HRP3_GCC_URL` > /dev/null 2>&1
    rm -f `basename $ETROBO_HRP3_GCC_URL`

    echo
    echo "Install TOPPERS/EV3RT:"
    download https://www.toppers.jp/download.cgi/ev3rt-1.0-release.zip
    unzip ev3rt-1.0-release.zip > /dev/null
    cp ev3rt-1.0-release/hrp3.tar.xz ./
    tar xvf hrp3.tar.xz > /dev/null 2>&1
    rm ev3rt-1.0-release.zip
    rm hrp3.tar.xz

    ln -s hrp3/sdk/workspace workspace
    echo "include \$(ETROBO_SCRIPTS)/Makefile.fakemake" >> workspace/Makefile

    #
    # install the athrill from TOPPERS/Hakoniwa
    # see https://qiita.com/kanetugu2018/items/0e521f4779cd680dab18
    #
    echo
    echo "Install Athrill2 virtual processor powered by TOPPERS/Hakoniwa:"
    if [ "$ETROBO_KERNEL" = "debian" ]; then
        download https://github.com/toppers/athrill-gcc-v850e2m/releases/download/v1.1/athrill-gcc-package.tar.gz
        tar xzvf athrill-gcc-package.tar.gz > /dev/null
        cd athrill-gcc-package
        tar xzvf athrill-gcc.tar.gz > /dev/null
        rm athrill-gcc.tar.gz
        cd ..
        rm athrill-gcc-package.tar.gz
    else
        download http://etrobocon.github.io/etroboEV3/athrill-gcc-package-mac.tar.gz
        tar xzvf athrill-gcc-package-mac.tar.gz > /dev/null 2>&1
        rm athrill-gcc-package-mac.tar.gz
    fi
fi

if [ "$dist" != "dist" ]; then
    echo
    echo "Build Athrill2 with the ETrobo official certified commit"
    "$ETROBO_SCRIPTS/build_athrill.sh" official
    rm -f "$ETROBO_ATHRILL_SDK/common/library/libcpp-ev3/libcpp-ev3-standalone.a"
fi

#
# distrubute etrobo_tr samples
echo "update distributions"
echo 
sampleProj="sample_c4"
echo "distribute $sampleProj project"
cd "$ETROBO_HRP3_WORKSPACE"
rm -rf "$sampleProj"
mkdir "$sampleProj"
cd "$ETROBO_ROOT/dist"
rm -rf "$sampleProj"
tar xvf ${sampleProj}.tar.gz > /dev/null  2>&1
cp -f "${sampleProj}/"* "$ETROBO_HRP3_WORKSPACE/${sampleProj}"
rm -rf "$sampleProj"

#
# distribute UnityETroboSim
echo "Bundled Simulator: $ETROBO_SIM_VER"
targetSrc="etrobosim${ETROBO_SIM_VER}_${ETROBO_OS}"
tar xvf "${targetSrc}.tar.gz" > /dev/null 2>&1

if [ "$ETROBO_KERNEL" = "darwin" ]; then
    targetSrc="${targetSrc}${ETROBO_EXE_POSTFIX}"
    targetDist="/Applications/etrobosim"
else
    targetDist="$ETROBO_USERPROFILE/etrobosim"
fi

if [ -d "$targetDist" ]; then
    rm -rf "$targetDist/$targetSrc"
else
    mkdir "$targetDist"
fi
mv -f "$targetSrc" "$targetDist/"

if [ -z "$update" ]; then
    echo
    echo "Update: finish"
    echo
else
    echo
    echo "Install etrobo Environment: finish"
    echo
fi
