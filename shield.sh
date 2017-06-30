#!/bin/bash
#
# Support default action.
#

# http://stackoverflow.com/a/10784612/288089
function chain_exists() {
    [ $# -lt 1 -o $# -gt 2 ] && {
        echo "Usage: chain_exists <chain_name> [table]" >&2
        return 1
    }
    local chain_name="$1" ; shift
    [ $# -eq 1 ] && local table="--table $1"
    iptables $table -n --list "$chain_name" >/dev/null 2>&1
}

function chain_in_input() {
    local chain=$1
    iptables -t filter -n --list INPUT | grep "$chain" &> /dev/null
}

function exit_with_status() {
    local exit_code="$1"
    local msg="$2"
    echo "$(date '+%s') $exit_code $msg"
    exit $exit_code
}

function try_run() {
    echo $@  
    $@  
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        exit_with_status $exit_code "cmd '$@' failed"
    fi  
}

function teardown_chain() {
    local chain=$1
    if chain_in_input $chain; then
        echo "INFO: remove $chain from INPUT"
        try_run iptables -D INPUT -j $chain
    fi
    if chain_exists $chain; then
        echo "INFO: remove $chain"
        try_run iptables -F $chain
        try_run iptables -X $chain
    fi
}

function setup_chain() {
    local chain=$1
    local file=$2

    # create chain
    try_run iptables --new-chain $chain
    # allow already established connections
    try_run iptables -A $chain -m state --state RELATED,ESTABLISHED -j ACCEPT
    # lo is always allowed
    try_run iptables -A $chain -i lo -j ACCEPT
    # icmp is allowed
    try_run iptables -A $chain -p icmp --icmp-type 8 -j ACCEPT

    while read -r line; do
        if test -z "$line"; then
            continue
        fi
        local opts_action="ACCEPT" # required (default: ACCEPT)
        local opts_port="" # optional
        local opts_src=""  # optional
        local opts_dst=""  # optional
        for o in $line; do
            if [[ $o =~ ^dport:([0-9]+)?$ ]]; then
                opts_port="-p tcp --dport $(echo "$o" | cut -d ':' -f 2)"
            elif [[ $o =~ ^dst:.*$ ]]; then
                opts_dst="--dst $(echo "$o" | cut -d ':' -f 2)"
            elif [[ $o =~ ^src:.*$ ]]; then
                opts_src="--src $(echo "$o" | cut -d ':' -f 2)"
            elif [[ $o =~ ^allow|deny$ ]]; then
                if [[ $o == "allow" ]]; then
                    opts_action="ACCEPT"
                else
                    opts_action="DROP"
                fi
            fi
        done
        if test -z "$opts_action"; then
            exit_with_status 1 "no action specified: $line"
        fi
        try_run iptables -A $chain $opts_port $opts_src $opts_dst -j $opts_action
    done <<< "$(cat $file | sed -e 's/#.*$//' -e '/^$/d')"

    # Always append chain in filter table's INPUT chain.
    # Any other rules have higher precedence.
    try_run iptables -A INPUT -j $chain
}

exec 9> /var/run/iptables-shield.lock
flock -n 9 || { echo "Already an instance running, exit."; exit 1; }

(

flush=false

function usage() {
    echo "Usage: $0  firewall.acl"
    exit
}

while getopts "h?f" opt; do
    case "$opt" in
    h|\?)
        usage
        exit 0
        ;;  
    f)  
	flush=true
        ;;  
    esac
done

shift $((OPTIND-1))
acl=$1

chain=SHIELD-CHAIN

if $flush; then
    teardown_chain $chain
else
    teardown_chain $chain
    setup_chain $chain $acl
fi

) 9<&- # close fd to prevent lock propagation
