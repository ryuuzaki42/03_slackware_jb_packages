#!/bin/bash
# Create a txz from opera-stable-version.rpm

if [ "$USER" != "root" ]; then
    echo -e "\nNeed to be superuser (root)\nExiting\n"
else
    progName="opera-stable"
    tag="JB"

    linkGetVersion="http://www.opera.com/blogs/desktop/"
    version="43.0.2442.1144"

    installedVersion=`ls /var/log/packages/$progName* | cut -d '_' -f2`
    echo -e "\n   Latest version: $version\nVersion installed: $installedVersion\n"
    if [ "$installedVersion" != '' ]; then
        if [ "$version" == "$installedVersion" ]; then
            echo -e "Version installed ($installedVersion) is equal to latest version ($version)"
            echo -n "Want continue? (y)es - (n)o (hit enter to no): "

            continue=$1
            if [ "$continue" == '' ]; then
                read continue
            fi

            if [ "$continue" != 'y' ]; then
                echo -e "\nJust exiting\n"
                exit 0
            fi
        fi
    fi
    linkDl="http://download4.operacdn.com/pub/opera/desktop/$version/linux"

    if [ -z "$ARCH" ]; then
        case "$( uname -m )" in
            i?86) ARCH=i386 ;;
            arm*) ARCH=arm ;;
            x86_64) ARCH=amd64 ;;
            *) ARCH=$( uname -m ) ;;
        esac
    fi

    if [ "$ARCH" == "amd64" ] ||[ "$ARCH" == "i386" ] ; then
        wget -c "$linkDl/"$progName"_"$version"_$ARCH.rpm"
    else
        echo -e "\nError: ARCH $ARCH not configured\n"
        exit 1
    fi

    rpm2txz "$progName"_"$version"_$ARCH.rpm

    rm "$progName"_"$version"_$ARCH.rpm

    mv "$progName"_"$version"_$ARCH.txz "$progName"_"$version"_$ARCH-$tag.txz
fi
