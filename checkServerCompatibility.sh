# check if it's root user
function isRoot () {
    if [ "$EUID" -ne 0 ]; then
        return 1
    fi
}
# tun/tap must be enabled
function tunAvailable () {
    if [ ! -e /dev/net/tun ]; then
        return 1
    fi
}
# checking operating system before the proceeding
function checkOS () {
    if [[ -e /etc/debian_version ]]; then
        OS="debian"
        # shellcheck disable=SC1091
        source /etc/os-release

        if [[ "$ID" == "debian" || "$ID" == "raspbian" ]]; then
            if [[ ! $VERSION_ID =~ (8|9|10) ]]; then
                echo "âš ï¸ Your version of Debian is not supported."
                echo ""
                echo "However, if you're using Debian >= 9 or unstable/testing then you can continue."
                echo "Keep in mind they are not supported, though."
                echo ""
                until [[ $CONTINUE =~ (y|n) ]]; do
                    read -rp "Continue? [y/n]: " -e CONTINUE
                done
                if [[ "$CONTINUE" = "n" ]]; then
                    exit 1
                fi
            fi
        elif [[ "$ID" == "ubuntu" ]];then
            OS="ubuntu"
            if [[ ! $VERSION_ID =~ (16.04|18.04|19.04) ]]; then
                echo "âš ï¸ Your version of Ubuntu is not supported."
                echo ""
                echo "However, if you're using Ubuntu > 17 or beta, then you can continue."
                echo "Keep in mind they are not supported, though."
                echo ""
                until [[ $CONTINUE =~ (y|n) ]]; do
                    read -rp "Continue? [y/n]: " -e CONTINUE
                done
                if [[ "$CONTINUE" = "n" ]]; then
                    exit 1
                fi
            fi
        fi
    elif [[ -e /etc/system-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        if [[ "$ID" = "centos" ]]; then
            OS="centos"
            if [[ ! $VERSION_ID =~ (7|8) ]]; then
                echo "âš ï¸ Your version of CentOS is not supported."
                echo ""
                echo "The script only support CentOS 7."
                echo ""
                exit 1
            fi
        fi
        if [[ "$ID" = "amzn" ]]; then
            OS="amzn"
            if [[ ! $VERSION_ID == "2" ]]; then
                echo "âš ï¸ Your version of Amazon Linux is not supported."
                echo ""
                echo "The script only support Amazon Linux 2."
                echo ""
                exit 1
            fi
        fi
    elif [[ -e /etc/fedora-release ]]; then
        OS=fedora
    elif [[ -e /etc/arch-release ]]; then
        OS=arch
    else
        echo "Looks like you aren't running this installer on a Debian, Ubuntu, Fedora, CentOS, Amazon Linux 2 or Arch Linux system"
        exit 1
    fi
}

function initialCheck () {
    if ! isRoot; then
        echo "Sorry, you need to run this as root"
        exit 1
    fi
    if ! tunAvailable; then
        echo "TUN is not available"
        exit 1
    fi
    checkOS
}
# Check for root, TUN, OS...
initialCheck
