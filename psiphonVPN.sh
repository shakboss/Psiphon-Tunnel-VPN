#!/usr/bin/env bash

## Troubleshooting
#set -e -u -x

#
# Psiphon Labs 
# https://github.com/Psiphon-Labs/psiphon-labs.github.io
#
#
# Script auto install Psiphon Tunnel VPN (Only linux version) version Release Candidate binaries
#
# System Required: Debian9+, Ubuntu20+, Trisquel9+
#
# https://github.com/MisterTowelie/Psiphon-Tunnel-VPN
#
# Author scripts: MisterTowelie

############################################################################
#   VERSION HISTORY   ######################################################
############################################################################

# v1.0
# - Initial version.

## Add alias to file .bashrc
# echo "alias psiphon='./psiphonVPN.sh'" >> ~/.bashrc
# source ~/.bashrc

psiphon_name="Psiphon Tunnel VPN"
psiphon_dir="$HOME/PsiphonVPN"
psiphon_file="$psiphon_dir/psiphon-tunnel-core-x86_64"
psiphon_config="$psiphon_dir/config.json"
psiphon_log="$psiphon_dir/psiphon-tunnel.log"
script_version="1.0"
psiphon_url="https://github.com/Psiphon-Labs/psiphon-tunnel-core-binaries/raw/master/linux/psiphon-tunnel-core-x86_64"
level_msg=("[ERROR]:" "[WARNING]:" "[INFO]:" "[HELP]:")
msg_DB=("The file $psiphon_name or its configuration file was not found."
        "Usage: ./$(basename "$0") [install|uninstall|update|start|port|help]")

function check_psiphon(){
    if [ -f "${psiphon_file}" ] && [ -f "${psiphon_config}" ]; then
        return 0
    else
        return 1
    fi
}

function check_dependencies(){
	if ! hash wget 2>/dev/null && ! hash curl 2>/dev/null; then
        echo
		echo "${level_msg[0]}" "[Wget] or [Curl] is required to use this installer."
        echo
		IFS= read -n1 -rp "Press any key to install Wget or Curl and continue..."
		sudo apt update || (echo "${level_msg[0]}" "Failed to update repositories, check your internet connection." && exit)
		sudo apt install -y wget curl || (echo "${level_msg[0]}" "Failed to install missing packages [wget] and [curl]." && exit)
	fi
}

function download_files(){
    curl "${psiphon_url}" -L -o "${psiphon_file}"
    if [ $? -ne 0 ]; then
        echo
        echo "${level_msg[0]}" "Download $psiphon_name failed."
        echo
        exit
    fi
    chmod +x "${psiphon_file}"
}

function download_psiphon(){
    [[ ! -d "$psiphon_dir" ]] && mkdir -p "$psiphon_dir"
    download_files
}

function conf_psiphon(){
    echo
    echo "${level_msg[2]}" "What port (HttpProxy) should $psiphon_name listen to?"
	IFS= read -rp "Port [8080]: " httpport
	until [[ -z "$httpport" || "$httpport" =~ ^[0-9]+$ && "$httpport" -le 65535 ]]; do
		echo "$httpport: invalid port."
		IFS= read -rp "Port [8080]: " httpport
	done
	[[ -z "$httpport" ]] && httpport="8080"
    echo
    echo "${level_msg[2]}" "What port (SocksProxy) should $psiphon_name listen to?"
	IFS= read -rp "Port [1080]: " socksport
	until [[ -z "$socksport" || "$socksport" =~ ^[0-9]+$ && "$socksport" -le 65535 && "$socksport" != "$httpport" ]]; do
		echo "$socksport: invalid port."
		IFS= read -rp "Port [1080]: " socksport
	done
	[[ -z "$socksport" ]] && socksport="1080"
    #"UpstreamProxyURL":"socks5://192.168.1.2:9050",    -- config socks5 port (for tor)
    cat > "${psiphon_config}"<<-EOF
        {
        "LocalHttpProxyPort":$httpport,
        "LocalSocksProxyPort":$socksport,
        "PropagationChannelId":"FFFFFFFFFFFFFFFF",
        "RemoteServerListDownloadFilename":"remote_server_list",
        "RemoteServerListSignaturePublicKey":"MIICIDANBgkqhkiG9w0BAQEFAAOCAg0AMIICCAKCAgEAt7Ls+/39r+T6zNW7GiVpJfzq/xvL9SBH5rIFnk0RXYEYavax3WS6HOD35eTAqn8AniOwiH+DOkvgSKF2caqk/y1dfq47Pdymtwzp9ikpB1C5OfAysXzBiwVJlCdajBKvBZDerV1cMvRzCKvKwRmvDmHgphQQ7WfXIGbRbmmk6opMBh3roE42KcotLFtqp0RRwLtcBRNtCdsrVsjiI1Lqz/lH+T61sGjSjQ3CHMuZYSQJZo/KrvzgQXpkaCTdbObxHqb6/+i1qaVOfEsvjoiyzTxJADvSytVtcTjijhPEV6XskJVHE1Zgl+7rATr/pDQkw6DPCNBS1+Y6fy7GstZALQXwEDN/qhQI9kWkHijT8ns+i1vGg00Mk/6J75arLhqcodWsdeG/M/moWgqQAnlZAGVtJI1OgeF5fsPpXu4kctOfuZlGjVZXQNW34aOzm8r8S0eVZitPlbhcPiR4gT/aSMz/wd8lZlzZYsje/Jr8u/YtlwjjreZrGRmG8KMOzukV3lLmMppXFMvl4bxv6YFEmIuTsOhbLTwFgh7KYNjodLj/LsqRVfwz31PgWQFTEPICV7GCvgVlPRxnofqKSjgTWI4mxDhBpVcATvaoBl1L/6WLbFvBsoAUBItWwctO2xalKxF5szhGm8lccoc5MZr8kfE0uxMgsxz4er68iCID+rsCAQM=",
        "RemoteServerListUrl":"https://s3.amazonaws.com//psiphon/web/mjr4-p23r-puwl/server_list_compressed",
        "SponsorId":"FFFFFFFFFFFFFFFF",
        "UseIndistinguishableTLS":true
        }
EOF
}

function run_psiphon(){
        echo
        echo "${level_msg[2]}" "Run $psiphon_name." 2>"$psiphon_log"
        "$psiphon_file" -config "$psiphon_config" 2>>"$psiphon_log"
}

function remove_psiphon(){
    if [ -f "${psiphon_file}" ] || [ -f "${psiphon_config}" ]; then
        echo
        echo "${level_msg[2]}" "Deleting all $psiphon_name files successfully."
        rm -Rf "${psiphon_dir}"
    else
        echo
        echo "${level_msg[0]}" "${msg_DB[0]}"
        echo
    fi
}

function install_psiphon(){
    if check_psiphon; then
        echo
        echo "${level_msg[2]}" "Download the latest version of the $psiphon_name binary file from github."
        download_files
    else
        echo
        echo "${level_msg[2]}" "Installation and configuration of $psiphon_name has begun. Wait..."
        echo
        check_dependencies
        download_psiphon
        touch "${psiphon_config}"
        conf_psiphon
        echo
        echo "${level_msg[2]}" "Installation and configuration of $psiphon_name completed successfully."
        echo
    fi
}

function uninstall_psiphon(){
    remove_psiphon
}

function update_psiphon(){
    if check_psiphon; then
        download_files
    else
        echo
        echo "${level_msg[1]}" "${msg_DB[0]}"
        echo
    fi
}

function start_psiphon(){
    if check_psiphon; then
        if [ "$(wc -l < "${psiphon_config}")" -ge 10  ]; then
        # if [ -s "${psiphon_config}" ]; then
            echo "Start $psiphon_name."
            run_psiphon
        else
            echo
            echo "${level_msg[0]}" "The configuration file is probably incorrect. Trying to fix."
            echo
            conf_psiphon
        fi
    else
        echo
        echo "${level_msg[1]}" "${msg_DB[0]}"
        echo
    fi
}

function port_psiphon(){
    if check_psiphon; then
        conf_psiphon
    else
        echo
        echo "${level_msg[1]}" "${msg_DB[0]}"
        echo
    fi
}

function help_psiphon(){
    echo
    echo "${level_msg[3]}" "Auto install $psiphon_name (Linux version). Script ver.$script_version"
    echo "${level_msg[3]}" "${msg_DB[1]}"
    echo
}

action="$1"
[ -z "$1" ] && action="start"
case "${action}" in
    install|uninstall|update|start|port|help)
        "${action}"_psiphon
        ;;
    *)
        echo
        echo "${level_msg[0]}" "Invalid argument: [${action}]"
        echo "${level_msg[3]}" "${msg_DB[1]}"
        echo
        ;;
esac
