#!/bin/bash
#
# Slackware build script for teamviewer
# Copyright 2010-2012  Binh Nguyen <binhvng@gmail.com>
# Copyright 2013-2016 Willy Sudiarto Raharjo <willysr@slackbuilds.org>
# Copyright 2017-2017 João Batista Ribeiro <joao42lbatista@gmail.com>
# All rights reserved.
#
# Redistribution and use of this script, with or without modification, is
# permitted provided that the following conditions are met:
#
# 1. Redistributions of this script must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
#  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
#  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO
#  EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
#  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
#  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
#  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Last update: 17/12/2017
#
echo "This script create a txz version from teamviewer_arch.deb"
if [ "$USER" != "root" ]; then
    echo -e "\\nNeed to be superuser (root)\\nExiting\\n"
else
    progName="teamviewer" # Last version tested: "13.0.5693"
    tag="1_JB"

    if [ -z "$ARCH" ]; then
        case "$(uname -m)" in
            i?86) ARCH=i586 ;;
            arm*) ARCH=arm ;;
            *) ARCH=$(uname -m) ;;
        esac
    fi

    CWD=$(pwd)
    TMP="/tmp/SBo"
    PKG="$TMP/package-$progName"
    OUTPUT="/tmp"

    # Sanity check, we make sure resulting package will work on users system.
    case "$ARCH" in
        i?86)
            DEBARCHTmp="i386" ;;
        x86_64)
            ARCH="x86_64"
            DEBARCHTmp="amd64" ;;
        *)
            echo "$ARCH is not supported."
            exit 1 ;;
    esac

    set -e

    linkVersion="https://www.teamviewer.com/pt/download/linux/"
    wget "$linkVersion" -O "${progName}-latest"

    version=$(grep "deb package" "${progName}-latest" | head -n 1 | cut -d 'v' -f2 | cut -d '<' -f1)
    rm "${progName}-latest"

    DEBARCH="${version}_$DEBARCHTmp"

    installedVersion=$(find /var/log/packages/$progName* | cut -d '-' -f2)
    echo -e "\\n   Latest version: $version\\nVersion installed: $installedVersion\\n"
    if [ "$installedVersion" != '' ]; then
        if [ "$version" == "$installedVersion" ]; then
            echo -e "Version installed ($installedVersion) is equal to latest version ($version)"

            continue=$1
            if [ "$continue" == '' ]; then
                echo -n "Want continue? (y)es - (n)o (hit enter to no): "
                read -r continue
            fi

            if [ "$continue" != 'y' ]; then
                echo -e "\\nJust exiting\\n"
                exit 0
            fi
        fi
    fi

    linkDl="https://download.teamviewer.com/download/linux"
    fileDl="teamviewer_${DEBARCHTmp}.deb"

    wget -c "$linkDl/$fileDl"

    rm -rf "$PKG"
    mkdir -p "$TMP" "$PKG" "$OUTPUT"
    cd "$PKG"

    if [ -f "$CWD/teamviewer_${DEBARCH}.deb" ]; then
        # Get the real version
        REAL_VER=$(ar p "$CWD/teamviewer_${DEBARCH}.deb" control.tar.gz | tar xzO ./control | grep Version | cut -d\  -f2 | cut -d- -f1)
        if [ "$version" != "$REAL_VER" ]; then
            echo "Version of downloaded source [$REAL_VER] does not match version of SlackBuild [$version]"
            exit 1
        fi

        ar p "$CWD/teamviewer_${DEBARCH}.deb" data.tar.xz | tar -xvJ
    else
        ar p "$CWD/teamviewer_${version}_${DEBARCH}.deb" data.tar.xz | tar xjv
    fi

    chown -R root:root .
    find -L . \
    \( -perm 777 -o -perm 775 -o -perm 750 -o -perm 711 -o -perm 555 \
    -o -perm 511 \) -exec chmod 755 {} \; -o \
    \( -perm 666 -o -perm 664 -o -perm 640 -o -perm 600 -o -perm 444 \
    -o -perm 440 -o -perm 400 \) -exec chmod 644 {} \;

    find "$PKG" -print0 | xargs -0 file | grep -e "executable" -e "shared object" | grep ELF \
    | cut -f 1 -d : | xargs strip --strip-unneeded 2> /dev/null || true

    # Make a .desktop file
    mkdir -p "$PKG/usr/share/applications"
    cat "$PKG/opt/teamviewer/tv_bin/desktop/com.teamviewer.TeamViewer.desktop" \
    | sed -e 's/EXEC/teamviewer/' -e 's/ICON/teamviewer/' \
    > "$PKG/usr/share/applications/teamviewer.desktop"

    # Remove the dangling symlink first
    rm -f "$PKG/usr/bin/teamviewer"

    # Re-create the generic executable
    ( cd "$PKG/usr/bin"; ln -s /opt/teamviewer/tv_bin/script/teamviewer teamviewer )

    # Link icon to /usr/share/pixmaps
    mkdir -p "$PKG/usr/share/pixmaps"
    ( ln -sf /opt/teamviewer/tv_bin/desktop/teamviewer.png  "$PKG/usr/share/pixmaps/teamviewer.png" )

    mkdir -p "$PKG/usr/doc/$progName-$version"
    cat "$CWD/$progName.SlackBuild" > "$PKG/usr/doc/$progName-$version/$progName.SlackBuild"

    # Move docs to official place
    mv "$PKG/opt/teamviewer/doc/*.txt" "$PKG/usr/doc/$progName-$version"
    rm -rf "$PKG/opt/teamviewer/doc/"

    #mkdir -p $PKG/etc/init.d/
    ( ln -sf /opt/teamviewer/tv_bin/teamviewerd "$PKG/etc/init.d/" )

    mkdir -p "$PKG/etc/rc.d/"
    install -m 0644 "$CWD/rc.teamviewerd" "$PKG/etc/rc.d/rc.teamviewerd.new"

    mkdir -p "$PKG/install"
    echo "# HOW TO EDIT THIS FILE:
# The \"handy ruler\" below makes it easier to edit a package description.
# Line up the first '|' above the ':' following the base package name, and
# the '|' on the right side marks the last column you can put a character in.
# You must make exactly 11 lines for the formatting to be correct.  It's also
# customary to leave one space after the ':' except on otherwise blank lines.

          |-----handy-ruler------------------------------------------------------|
teamviewer: teamviewer (remote control application)
teamviewer:
teamviewer: TeamViewer is a remote control application. TeamViewer provides easy,
teamviewer: fast, and secure remote access to Linux, Windows PCs, and Macs.
teamviewer:
teamviewer: TeamViewer is free for personal use. You can use TeamViewer completely
teamviewer: free of charge to access your private computers or to help your
teamviewer: friends with their computer problems.
teamviewer:
teamviewer: Homepage: https://www.teamviewer.com/
teamviewer:" > "$PKG/install/slack-desc"

    cat "$CWD/doinst.sh" > "$PKG/install/doinst.sh"

    cd "$PKG" || exit
    /sbin/makepkg -l y -c n "$OUTPUT/$progName-$version-$ARCH-$tag.txz"
fi
