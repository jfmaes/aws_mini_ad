#!/bin/bash
#
# Copyright (c) 2013 Nyr. Released under the MIT License.
# Copyright (c) 2019 Fabrice Triboix

set -eu


###################
# Parse arguments #
###################

HELP=no
OPERATION=none
PROTOCOL=udp
PORT=1194
IP=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
PUBLICIP=$(curl ifconfig.me)
DNS=google
FIREWALL=no
CLIENT=

ARGS=$(getopt -o hiuRa:rtp:I:P:d:f -- "$@")
eval set -- "$ARGS"
set +u  # Avoid unbound $1 at the end of the parsing
while true; do
    case "$1" in
        -h) HELP=yes; shift;;
        -i) OPERATION=install; shift;;
        -u) OPERATION=uninstall; shift;;
        -R) OPERATION=refresh; shift;;
        -a) OPERATION=adduser; CLIENT="$2"; shift; shift;;
        -r) OPERATION=rmuser; shift;;
        -t) PROTOCOL=tcp; shift;;
        -p) PORT="$2"; shift; shift;;
        -I) IP="$2"; shift; shift;;
        -P) PUBLICIP="$2"; shift; shift;;
        -d) DNS="$2"; shift; shift;;
        -f) FIREWALL=yes; shift;;
        --) shift; break;;
        *) break;;
    esac
done
set -u

if [[ $HELP == yes ]]; then
    echo "Install, configure and manage an OpenVPN server and its users"
    echo
    echo "This script automatically detects whether the OS is Debian-based"
    echo "or RedHat-based and acts accordingly."
    echo
    echo "Please note this script must be run as root."
    echo
    echo "You must specify one of -i, -u, -R, -a or -r argument. For all the"
    echo "other arguments, it is advised you leave them at their default"
    echo "values, unless you really know what you are doing."
    echo
    echo "The available arguments are:"
    echo "  -h       Print this help message"
    echo "  -i       Install and configure an OpenVPN server"
    echo "  -u       Uninstall OpenVPN"
    echo "  -R       Refresh OpenVPN (re-install the OS packages, but leave"
    echo "           the existing OpenVPN data untouched"
    echo "  -a USER  Add a user"
    echo "  -r       Remove a user"
    echo
    echo "The following arguments are only available in conjuction with -i:"
    echo "  -t         Use TCP instead of UDP"
    echo "  -p PORT    Port number to use (default: $PORT)"
    echo "  -I IP      Local IP address to bind to (default: $IP)"
    echo "  -P IP      Public IP address (i.e. NAT address, if applicable)"
    echo "             (default: $PUBLICIP)"
    echo "  -d CHOICE  DNS servers to use (default: $DNS)"
    echo "             allowed choices: current (use the current system"
    echo "             resolvers), cloudflare, google, opendns, verisign"
    echo "  -f         Configure the firewall (default: don't touch the firewall)"
    exit 1
fi

case "$DNS" in
    current|cloudflare|google|opendns|verisign) ;;
    *) echo "ERROR: Invalid DNS selection: $DNS"; exit 1;;
esac

if [[ $OPERATION == none ]]; then
    echo "ERROR: You must specify an operation"
    exit 1
fi

if [[ $OPERATION == adduser ]]; then
    if [[ -z $CLIENT ]]; then
        echo "ERROR: User name is empty"
        exit 1
    fi
fi

log() {
    echo SCRIPT "$@"
}


######################
# Run various checks #
######################

# Detect Debian users running the script with "sh" instead of bash
if readlink /proc/$$/exe | grep -q "dash"; then
    echo "ERROR: This script needs to be run with bash, not sh"
    exit 1
fi

if [[ "$EUID" -ne 0 ]]; then
    echo "ERROR: Sorry, you need to run this as root"
    exit 1
fi

if [[ ! -e /dev/net/tun ]]; then
    echo "ERROR: The TUN device is not available"
    echo "You need to enable TUN before running this script"
    exit 1
fi

if [[ -e /etc/debian_version ]]; then
    OS=debian
    GROUPNAME=nogroup
    RCLOCAL='/etc/rc.local'
    export DEBIAN_FRONTEND=noninteractive

elif [[ -e /etc/centos-release || -e /etc/redhat-release || -e /etc/system-release ]]; then
    OS=centos
    GROUPNAME=nobody
    RCLOCAL='/etc/rc.d/rc.local'

else
    echo "ERROR: Looks like you aren't running this installer on Debian,"
    echo "Ubuntu, RedHat, CentOS or Amazon Linux"
    exit 1
fi

log "Detected OS: $OS"


#################################
# Function to create a new user #
#################################

newclient () {
    # Generates the custom client.ovpn
    file="/etc/openvpn/$1.ovpn"
    cp /etc/openvpn/client-common.txt "$file"
    echo "<ca>" >> "$file"
    cat /etc/openvpn/easy-rsa/pki/ca.crt >> "$file"
    echo "</ca>" >> "$file"
    echo "<cert>" >> "$file"
    sed -ne '/BEGIN CERTIFICATE/,$ p' \
        "/etc/openvpn/easy-rsa/pki/issued/$1.crt" >> "$file"
    echo "</cert>" >> "$file"
    echo "<key>" >> "$file"
    cat "/etc/openvpn/easy-rsa/pki/private/$1.key" >> "$file"
    echo "</key>" >> "$file"
    echo "<tls-auth>" >> "$file"
    sed -ne '/BEGIN OpenVPN Static key/,$ p' /etc/openvpn/ta.key >> "$file"
    echo "</tls-auth>" >> "$file"
}


###################
# Refresh OpenVPN #
###################

if [[ $OPERATION == refresh ]]; then
    if [[ $OS == debian ]]; then
        apt-get -q -y update
        apt-get -q -y install openvpn openssl ca-certificates
        if [[ $FIREWALL == yes ]]; then
            apt-get -q -y iptables
        fi

    else
        yum -q -y install epel-release
        yum -q -y install openvpn openssl ca-certificates
        if [[ $FIREWALL == yes ]]; then
            yum -q -y install iptables
        fi
    fi

    # Enable net.ipv4.ip_forward for the system
    echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/30-openvpn-forward.conf

    # Enable without waiting for a reboot or service restart
    echo 1 > /proc/sys/net/ipv4/ip_forward

    if [[ $FIREWALL == yes ]]; then
        if pgrep firewalld; then
            # Using both permanent and not permanent rules to avoid a firewalld
            # reload.
            # We don't use --add-service=openvpn because that would only work with
            # the default port and protocol.
            firewall-cmd --zone=public --add-port=$PORT/$PROTOCOL
            firewall-cmd --zone=trusted --add-source=10.8.0.0/24
            firewall-cmd --permanent --zone=public --add-port=$PORT/$PROTOCOL
            firewall-cmd --permanent --zone=trusted --add-source=10.8.0.0/24
            # Set NAT for the VPN subnet
            firewall-cmd --direct --add-rule ipv4 nat POSTROUTING 0 -s 10.8.0.0/24 ! -d 10.8.0.0/24 -j SNAT --to $IP
            firewall-cmd --permanent --direct --add-rule ipv4 nat POSTROUTING 0 -s 10.8.0.0/24 ! -d 10.8.0.0/24 -j SNAT --to $IP

        else
            # Needed to use rc.local with some systemd distros
            if [[ "$OS" = 'debian' && ! -e $RCLOCAL ]]; then
                echo '#!/bin/sh -e
    exit 0' > $RCLOCAL
            fi
            chmod +x $RCLOCAL

            # Set NAT for the VPN subnet
            iptables -t nat -A POSTROUTING -s 10.8.0.0/24 ! -d 10.8.0.0/24 -j SNAT --to $IP
            sed -i "1 a\iptables -t nat -A POSTROUTING -s 10.8.0.0/24 ! -d 10.8.0.0/24 -j SNAT --to $IP" $RCLOCAL

            if iptables -L -n | grep -qE '^(REJECT|DROP)'; then
                # If iptables has at least one REJECT rule, we asume this is
                # needed. Not the best approach but I can't think of other
                # and this shouldn't cause problems.
                iptables -I INPUT -p $PROTOCOL --dport $PORT -j ACCEPT
                iptables -I FORWARD -s 10.8.0.0/24 -j ACCEPT
                iptables -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
                sed -i "1 a\iptables -I INPUT -p $PROTOCOL --dport $PORT -j ACCEPT" $RCLOCAL
                sed -i "1 a\iptables -I FORWARD -s 10.8.0.0/24 -j ACCEPT" $RCLOCAL
                sed -i "1 a\iptables -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT" $RCLOCAL
            fi
        fi
    else
        log "Not touching the firewall"
    fi
    echo $FIREWALL > /etc/openvpn/configure-firewall

    # If SELinux is enabled and a custom port was selected, we need this
    if sestatus 2>/dev/null | grep "Current mode" | grep -q "enforcing" && [[ "$PORT" != '1194' ]]; then
        # Install semanage if not already present
        if ! hash semanage 2>/dev/null; then
            yum install policycoreutils-python -y
        fi
        semanage port -a -t openvpn_port_t -p $PROTOCOL $PORT
    fi

    # And finally, restart OpenVPN
    if [[ "$OS" = 'debian' ]]; then
        # Little hack to check for systemd
        if pgrep systemd-journal; then
            systemctl restart openvpn@server.service
        else
            /etc/init.d/openvpn restart
        fi
    else
        if pgrep systemd-journal; then
            systemctl restart openvpn@server.service
            systemctl enable openvpn@server.service
        else
            service openvpn restart
            chkconfig openvpn on
        fi
    fi

    log "OpenVPN successfully refreshed"
    exit 0
fi


#################################
# Install and configure OpenVPN #
#################################

if [[ $OPERATION == install ]]; then
    if [[ $OS == debian ]]; then
        apt-get -q -y update
        apt-get -q -y install openvpn openssl ca-certificates
        if [[ $FIREWALL == yes ]]; then
            apt-get -q -y iptables
        fi

    else
        yum -q -y install epel-release
        yum -q -y install openvpn openssl ca-certificates
        if [[ $FIREWALL == yes ]]; then
            yum -q -y install iptables
        fi
    fi

    # Get easy-rsa
    EASYRSAURL='https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.6/EasyRSA-unix-v3.0.6.tgz'
    wget -O ~/easyrsa.tgz "$EASYRSAURL" 2>/dev/null \
        || curl -Lo ~/easyrsa.tgz "$EASYRSAURL"
    tar xzf ~/easyrsa.tgz -C ~/
    mv ~/EasyRSA-v3.0.6/ /etc/openvpn/
    mv /etc/openvpn/EasyRSA-v3.0.6/ /etc/openvpn/easy-rsa/
    chown -R root:root /etc/openvpn/easy-rsa/
    rm -f ~/easyrsa.tgz
    cd /etc/openvpn/easy-rsa/

    # Create the PKI, set up the CA and the server and client certificates
    ./easyrsa init-pki
    ./easyrsa --batch build-ca nopass
    EASYRSA_CERT_EXPIRE=3650 ./easyrsa build-server-full server nopass
    EASYRSA_CRL_DAYS=3650 ./easyrsa gen-crl

    # Move the stuff we need
    cp pki/ca.crt pki/private/ca.key pki/issued/server.crt \
        pki/private/server.key pki/crl.pem /etc/openvpn

    # CRL is read with each client connection, when OpenVPN is dropped to nobody
    chown nobody:$GROUPNAME /etc/openvpn/crl.pem

    # Generate key for tls-auth
    openvpn --genkey --secret /etc/openvpn/ta.key

    # Create the DH parameters file using the predefined ffdhe2048 group
    echo '-----BEGIN DH PARAMETERS-----
MIIBCAKCAQEA//////////+t+FRYortKmq/cViAnPTzx2LnFg84tNpWp4TZBFGQz
+8yTnc4kmz75fS/jY2MMddj2gbICrsRhetPfHtXV/WVhJDP1H18GbtCFY2VVPe0a
87VXE15/V8k1mE8McODmi3fipona8+/och3xWKE2rec1MKzKT0g6eXq8CrGCsyT7
YdEIqUuyyOP7uWrat2DX9GgdT0Kj3jlN9K5W7edjcrsZCwenyO4KbXCeAvzhzffi
7MA0BM0oNC9hkXL+nOmFg/+OTxIy7vKBg8P+OxtMb61zO7X8vC7CIAXFjvGDfRaD
ssbzSibBsu/6iGtCOGEoXJf//////////wIBAg==
-----END DH PARAMETERS-----' > /etc/openvpn/dh.pem

    # Generate server.conf
    echo "port $PORT
proto $PROTOCOL
dev tun
sndbuf 0
rcvbuf 0
ca ca.crt
cert server.crt
key server.key
dh dh.pem
auth SHA512
tls-auth ta.key 0
topology subnet
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt" > /etc/openvpn/server.conf
    echo 'push "route 10.0.0.0 255.255.0.0"' >> /etc/openvpn/server.conf
    # DNS
    case $DNS in
        current)
            # Locate the proper resolv.conf
            # Needed for systems running systemd-resolved
            if grep -q "127.0.0.53" "/etc/resolv.conf"; then
                RESOLVCONF='/run/systemd/resolve/resolv.conf'
            else
                RESOLVCONF='/etc/resolv.conf'
            fi
            # Obtain the resolvers from resolv.conf and use them for OpenVPN
            grep -v '#' $RESOLVCONF | grep 'nameserver' | grep -E -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | while read line; do
                echo "push \"dhcp-option DNS $line\"" >> /etc/openvpn/server.conf
            done
            ;;

        cloudflare)
            echo 'push "dhcp-option DNS 1.1.1.1"' >> /etc/openvpn/server.conf
            echo 'push "dhcp-option DNS 1.0.0.1"' >> /etc/openvpn/server.conf
            ;;

        google)
            echo 'push "dhcp-option DNS 8.8.8.8"' >> /etc/openvpn/server.conf
            echo 'push "dhcp-option DNS 8.8.4.4"' >> /etc/openvpn/server.conf
            ;;

        opendns)
            echo 'push "dhcp-option DNS 208.67.222.222"' >> /etc/openvpn/server.conf
            echo 'push "dhcp-option DNS 208.67.220.220"' >> /etc/openvpn/server.conf
            ;;

        verisign)
            echo 'push "dhcp-option DNS 64.6.64.6"' >> /etc/openvpn/server.conf
            echo 'push "dhcp-option DNS 64.6.65.6"' >> /etc/openvpn/server.conf
            ;;
    esac

    echo "keepalive 10 120
cipher AES-256-CBC
user nobody
group $GROUPNAME
persist-key
persist-tun
status openvpn-status.log
verb 3
crl-verify crl.pem" >> /etc/openvpn/server.conf

    # Enable net.ipv4.ip_forward for the system
    echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/30-openvpn-forward.conf

    # Enable without waiting for a reboot or service restart
    echo 1 > /proc/sys/net/ipv4/ip_forward
    if [[ $FIREWALL == yes ]]; then
        if pgrep firewalld; then
            # Using both permanent and not permanent rules to avoid a firewalld
            # reload.
            # We don't use --add-service=openvpn because that would only work with
            # the default port and protocol.
            firewall-cmd --zone=public --add-port=$PORT/$PROTOCOL
            firewall-cmd --zone=trusted --add-source=10.8.0.0/24
            firewall-cmd --permanent --zone=public --add-port=$PORT/$PROTOCOL
            firewall-cmd --permanent --zone=trusted --add-source=10.8.0.0/24
            # Set NAT for the VPN subnet
            firewall-cmd --direct --add-rule ipv4 nat POSTROUTING 0 -s 10.8.0.0/24 ! -d 10.8.0.0/24 -j SNAT --to $IP
            firewall-cmd --permanent --direct --add-rule ipv4 nat POSTROUTING 0 -s 10.8.0.0/24 ! -d 10.8.0.0/24 -j SNAT --to $IP

        else
            # Needed to use rc.local with some systemd distros
            if [[ "$OS" = 'debian' && ! -e $RCLOCAL ]]; then
                echo '#!/bin/sh -e
    exit 0' > $RCLOCAL
            fi
            chmod +x $RCLOCAL

            # Set NAT for the VPN subnet
            iptables -t nat -A POSTROUTING -s 10.8.0.0/24 ! -d 10.8.0.0/24 -j SNAT --to $IP
            sed -i "1 a\iptables -t nat -A POSTROUTING -s 10.8.0.0/24 ! -d 10.8.0.0/24 -j SNAT --to $IP" $RCLOCAL

            if iptables -L -n | grep -qE '^(REJECT|DROP)'; then
                # If iptables has at least one REJECT rule, we asume this is
                # needed. Not the best approach but I can't think of other
                # and this shouldn't cause problems.
                iptables -I INPUT -p $PROTOCOL --dport $PORT -j ACCEPT
                iptables -I FORWARD -s 10.8.0.0/24 -j ACCEPT
                iptables -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
                sed -i "1 a\iptables -I INPUT -p $PROTOCOL --dport $PORT -j ACCEPT" $RCLOCAL
                sed -i "1 a\iptables -I FORWARD -s 10.8.0.0/24 -j ACCEPT" $RCLOCAL
                sed -i "1 a\iptables -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT" $RCLOCAL
            fi
        fi
    else
        log "Not touching the firewall"
    fi
    echo $FIREWALL > /etc/openvpn/configure-firewall

    # If SELinux is enabled and a custom port was selected, we need this
    if sestatus 2>/dev/null | grep "Current mode" | grep -q "enforcing" && [[ "$PORT" != '1194' ]]; then
        # Install semanage if not already present
        if ! hash semanage 2>/dev/null; then
            yum install policycoreutils-python -y
        fi
        semanage port -a -t openvpn_port_t -p $PROTOCOL $PORT
    fi

    # And finally, restart OpenVPN
    if [[ "$OS" = 'debian' ]]; then
        # Little hack to check for systemd
        if pgrep systemd-journal; then
            systemctl restart openvpn@server.service
        else
            /etc/init.d/openvpn restart
        fi
    else
        if pgrep systemd-journal; then
            systemctl restart openvpn@server.service
            systemctl enable openvpn@server.service
        else
            service openvpn restart
            chkconfig openvpn on
        fi
    fi

# client-common.txt is created so we have a template to add further users later
echo "client
dev tun
proto $PROTOCOL
sndbuf 0
rcvbuf 0
remote $PUBLICIP $PORT
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
auth SHA512
cipher AES-256-CBC
key-direction 1
verb 3" > /etc/openvpn/client-common.txt

    log "OpenVPN successfully installed and configured"
    exit 0
fi


#####################
# Uninstall OpenVPN #
#####################

if [[ $OPERATION == uninstall ]]; then
    PORT=$(grep '^port ' /etc/openvpn/server.conf | cut -d " " -f 2)
    PROTOCOL=$(grep '^proto ' /etc/openvpn/server.conf | cut -d " " -f 2)
    FIREWALL=no
    if [[ -r /etc/openvpn/configure-firewall ]]; then
        FIREWALL=$(cat /etc/openvpn/configure-firewall)
    fi
    if [[ $FIREWALL == yes ]]; then
        if pgrep firewalld; then
            IP=$(firewall-cmd --direct --get-rules ipv4 nat POSTROUTING | grep '\-s 10.8.0.0/24 '"'"'!'"'"' -d 10.8.0.0/24 -j SNAT --to ' | cut -d " " -f 10)
            # Using both permanent and not permanent rules to avoid a firewalld reload.
            firewall-cmd --zone=public --remove-port=$PORT/$PROTOCOL
            firewall-cmd --zone=trusted --remove-source=10.8.0.0/24
            firewall-cmd --permanent --zone=public --remove-port=$PORT/$PROTOCOL
            firewall-cmd --permanent --zone=trusted --remove-source=10.8.0.0/24
            firewall-cmd --direct --remove-rule ipv4 nat POSTROUTING 0 -s 10.8.0.0/24 ! -d 10.8.0.0/24 -j SNAT --to $IP
            firewall-cmd --permanent --direct --remove-rule ipv4 nat POSTROUTING 0 -s 10.8.0.0/24 ! -d 10.8.0.0/24 -j SNAT --to $IP
        else
            IP=$(grep 'iptables -t nat -A POSTROUTING -s 10.8.0.0/24 ! -d 10.8.0.0/24 -j SNAT --to ' $RCLOCAL | cut -d " " -f 14)
            iptables -t nat -D POSTROUTING -s 10.8.0.0/24 ! -d 10.8.0.0/24 -j SNAT --to $IP
            sed -i '/iptables -t nat -A POSTROUTING -s 10.8.0.0\/24 ! -d 10.8.0.0\/24 -j SNAT --to /d' $RCLOCAL
            if iptables -L -n | grep -qE '^ACCEPT'; then
                iptables -D INPUT -p $PROTOCOL --dport $PORT -j ACCEPT
                iptables -D FORWARD -s 10.8.0.0/24 -j ACCEPT
                iptables -D FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
                sed -i "/iptables -I INPUT -p $PROTOCOL --dport $PORT -j ACCEPT/d" $RCLOCAL
                sed -i "/iptables -I FORWARD -s 10.8.0.0\/24 -j ACCEPT/d" $RCLOCAL
                sed -i "/iptables -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT/d" $RCLOCAL
            fi
        fi
    fi

    if sestatus 2>/dev/null | grep "Current mode" | grep -q "enforcing" && [[ "$PORT" != '1194' ]]; then
        semanage port -d -t openvpn_port_t -p $PROTOCOL $PORT
    fi

    if [[ "$OS" = 'debian' ]]; then
        apt-get -q -y remove --purge openvpn
    else
        yum -q -y remove openvpn
    fi

    rm -rf /etc/openvpn
    rm -f /etc/sysctl.d/30-openvpn-forward.conf

    log "OpenVPN uninstalled"
    exit 0
fi


##################
# Add a new user #
##################

if [[ $OPERATION == adduser ]]; then
    cd /etc/openvpn/easy-rsa/
    EASYRSA_CERT_EXPIRE=3650 ./easyrsa build-client-full "$CLIENT" nopass
    newclient "$CLIENT"
    echo "User $CLIENT added"
    echo "Configuration is available at: /etc/openvpn/$CLIENT.ovpn"
    exit 0
fi


#################
# Remove a user #
#################

if [[ $OPERATION == rmuser ]]; then
    # This option could be documented a bit better and maybe even be simplified
    # ...but what can I say, I want some sleep too
    NUMBEROFCLIENTS=$(tail -n +2 /etc/openvpn/easy-rsa/pki/index.txt | grep -c "^V")
    if [[ $NUMBEROFCLIENTS == 0 ]]; then
        echo "You have no existing clients!"
        exit 0
    fi
    # TODO
    echo
    echo "Select the existing client certificate you want to revoke:"
    tail -n +2 /etc/openvpn/easy-rsa/pki/index.txt | grep "^V" | cut -d '=' -f 2 | nl -s ') '
    if [[ "$NUMBEROFCLIENTS" = '1' ]]; then
        read -p "Select one client [1]: " CLIENTNUMBER
    else
        read -p "Select one client [1-$NUMBEROFCLIENTS]: " CLIENTNUMBER
    fi
    CLIENT=$(tail -n +2 /etc/openvpn/easy-rsa/pki/index.txt | grep "^V" | cut -d '=' -f 2 | sed -n "$CLIENTNUMBER"p)
    echo
    read -p "Do you really want to revoke access for client $CLIENT? [y/N]: " -e REVOKE
    if [[ "$REVOKE" = 'y' || "$REVOKE" = 'Y' ]]; then
        cd /etc/openvpn/easy-rsa/
        ./easyrsa --batch revoke $CLIENT
        EASYRSA_CRL_DAYS=3650 ./easyrsa gen-crl
        rm -f /etc/openvpn/crl.pem
        cp /etc/openvpn/easy-rsa/pki/crl.pem /etc/openvpn/crl.pem
        # CRL is read with each client connection, when OpenVPN is dropped to nobody
        chown nobody:$GROUPNAME /etc/openvpn/crl.pem
        echo
        echo "Certificate for client $CLIENT revoked!"
    else
        echo
        echo "Certificate revocation for client $CLIENT aborted!"
    fi

    log "User revoked"
    exit 0
fi

log "ERROR: Invalid operation: $OPERATION"
exit 1
