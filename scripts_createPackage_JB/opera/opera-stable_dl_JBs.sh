#!/bin/bash
#
# Autor= João Batista Ribeiro
# Bugs, Agradecimentos, Críticas "construtivas"
# Mande me um e-mail. Ficarei Grato!
# e-mail: joao42lbatista@gmail.com
#
# Este programa é um software livre; você pode redistribui-lo e/ou
# modifica-lo dentro dos termos da Licença Pública Geral GNU como
# publicada pela Fundação do Software Livre (FSF); na versão 2 da
# Licença, ou (na sua opinião) qualquer versão.
#
# Este programa é distribuído na esperança que possa ser útil,
# mas SEM NENHUMA GARANTIA; sem uma garantia implícita de ADEQUAÇÃO a
# qualquer MERCADO ou APLICAÇÃO EM PARTICULAR.
#
# Veja a Licença Pública Geral GNU para mais detalhes.
# Você deve ter recebido uma cópia da Licença Pública Geral GNU
# junto com este programa, se não, escreva para a Fundação do Software
#
# Livre(FSF) Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
#
# Script: Create a txz from opera-stable-version.rpm
#
# Last update: 15/12/2022
#
echo -e "\\n# Create a txz from opera-stable-version.rpm #\\n"

if [ "$USER" != "root" ]; then
    echo -e "\\nNeed to be superuser (root)\\nExiting\\n"
else
    progName="opera-stable" # last tested: "94.0.4606.26"
    tag="1_JB"

    linkGetVersion="http://ftp.opera.com/ftp/pub/opera/desktop"

    tailNumber='1'
    continue='0'
    while [ "$continue" == '0' ]; do
        wget "$linkGetVersion" -O "${progName}-latest"

        version=$(grep "href" ${progName}-latest | grep -v "Index" | sort -V -t '.' | tail -n $tailNumber | head -n 1 | cut -d '"' -f2 | cut -d '/' -f1)
        if [ "$version" == '' ]; then
            echo -e "\\nNot found any more version\\nJust exiting"
            exit 0
        fi

        echo -e "\\n Version test: $version\\n"
        linkGetVersionLinux="$linkGetVersion/$version/"
        wget "$linkGetVersionLinux" -O "${progName}-latest"

        if grep -q "linux" "${progName}-latest"; then
            wget "$linkGetVersion/$version/linux" -O "${progName}-latest"
            if grep -q "rpm" "${progName}-latest"; then
                continue='1'
            else
                echo -e "\\t# The version \"$version\" don't have rpm version yet\\n"
            fi
        else
            echo -e "\\t# The version \"$version\" don't have GNU/Linux version yet\\n"
        fi

        ((tailNumber++))
    done
    rm "${progName}-latest"

    installedVersion=$(find /var/log/packages/$progName* | rev | cut -d '-' -f3 | rev)
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
    linkDl="$linkGetVersion/$version/linux"

    ARCH=$(uname -m)
    if [ "$ARCH" == "x86_64" ]; then
        wget -c "$linkDl/${progName}_${version}_amd64.rpm"
    else
        echo -e "\\nError: arch: $ARCH - This package is currently only available for 64bit.\\n"
        exit 1
    fi

    mv "${progName}_${version}_amd64.rpm" "${progName}-${version}-${ARCH}-${tag}.rpm"

    rpm2txz -d -c -s -r "${progName}-${version}-${ARCH}-${tag}.rpm"

    rm "${progName}-${version}-${ARCH}-${tag}.rpm"
fi
