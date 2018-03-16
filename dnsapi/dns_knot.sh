#!/usr/bin/env sh

########  Public functions #####################

#Usage: dns_knot_add   _acme-challenge.www.domain.com   "XKrxpRBosdIKFzxW_CT3KLZNf6q0HG9i01zxXp5CPBs"
dns_knot_add() {
  fulldomain=$1
  txtvalue=$2
  _checkKey || return 1
  [ -n "${KNOT_SERVER}" ] || KNOT_SERVER="localhost"
  # save the dns server, key and zones to the account.conf file.
  _saveaccountconf KNOT_SERVER "${KNOT_SERVER}"
  _saveaccountconf KNOT_KEY "${KNOT_KEY}"
  _saveaccountconf KNOT_ZONES "${KNOT_ZONES}"

  if ! _get_zone "$fulldomain" "${KNOT_ZONES}"; then
    _err "Domain does not exist."
    return 1
  fi

  _info "Adding ${fulldomain}. 60 TXT \"${txtvalue}\" to zone ${_domain}"

  knsupdate -y "${KNOT_KEY}" <<EOF
server ${KNOT_SERVER}
zone ${_domain}.
update add ${fulldomain}. 60 TXT "${txtvalue}"
send
quit
EOF

  if [ $? -ne 0 ]; then
    _err "Error updating domain."
    return 1
  fi

  _info "Domain TXT record successfully added."
  return 0
}

#Usage: dns_knot_rm   _acme-challenge.www.domain.com
dns_knot_rm() {
  fulldomain=$1
  _checkKey || return 1
  [ -n "${KNOT_SERVER}" ] || KNOT_SERVER="localhost"

  if ! _get_zone "$fulldomain" "${KNOT_ZONES}"; then
    _err "Domain does not exist."
    return 1
  fi

  _info "Removing ${fulldomain}. TXT from zone ${_domain}"

  knsupdate -y "${KNOT_KEY}" <<EOF
server ${KNOT_SERVER}
zone ${_domain}.
update del ${fulldomain}. TXT
send
quit
EOF

  if [ $? -ne 0 ]; then
    _err "error updating domain"
    return 1
  fi

  _info "Domain TXT record successfully deleted."
  return 0
}

####################  Private functions below ##################################
# _acme-challenge.www.domain.com "acme.domain.com acme.example.com"
# returns
# _domain=domain.com
_get_zone() {
  domain=$1
  zones=$2
  count="$(echo "$domain" | tr '.' ' ' | wc -w)"
  i=2

  while [ $i -lt $count ]; do
    h=$(printf "%s" "$domain" | cut -d . -f "$i"-100)
    if [ -z "$h" ]; then
      return 1
    fi
    if _contains " $zones " " $h "; then
    _domain="$h"
    return 0
    fi
    i=$(_math "$i" + 1)
  done
  _domain="$h"
  return 0
}

_checkKey() {
  if [ -z "${KNOT_KEY}" ]; then
    _err "You must specify a TSIG key to authenticate the request."
    return 1
  fi
}
