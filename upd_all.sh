#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-
SELFFILE="$(readlink -m "$0")"; SELFPATH="$(dirname "$SELFFILE")"


function upd_all () {
  local NSM_RAW='https://github.com/nodesource/distributions/raw/master/'
  local DEB_BASEURL='https://deb.nodesource.com/'
  local LOGFN_TMPL=logs/%.txt
  local HOOKS_DIR=./hooks

  local RUN_AS="$(whoami)"
  if [ "$RUN_AS" == root ]; then
    echo "W: Running as $RUN_AS! Trying to drop privileges:"
    RUN_AS="$(stat -c %U:%G "$SELFFILE" | tr -s '\n\r\t ' :)"
    RUN_AS="${RUN_AS%:}"
    if [ "${RUN_AS%:*}" == root ]; then
      echo "E: chown webuser:webgroup '$SELFFILE'" >&2
      return 4
    fi
    if <<<"$RUN_AS" grep -qxPe '[a-z][a-z0-9_\-]*:[a-z][a-z0-9_\-]*'; then
      echo "I: Will try to re-exec with sudo $RUN_AS."
    else
      echo "E: Unable to detect appropriate user/group." >&2
      echo "H: If '$RUN_AS' is a valid user:group, it's too fancy."
      return 7
    fi
    local SUDO_CMD=(
      sudo
      --non-interactive
      --preserve-env
      --user "${RUN_AS%:*}" --group "${RUN_AS#*:}"
      -- "$SELFFILE" "$@"
      )
    cd / || return $?   # sudo might be unable to cd $PWD (e.g. fuse.sshfs)
    [ "${DEBUGLEVEL:-0}" -ge 2 ] && echo "D: sudo cmd: ${SUDO_CMD[*]}"
    exec "${SUDO_CMD[@]}"
    return $?
  fi

  cd "$SELFPATH" || return $?

  local EXCLUDE_PRODS="$(grep -hFe _ -- exclude{,.*}.txt 2>/dev/null)"
  # ^-- grep: because "cat" would merge lines if a file didn't have a
  #     final EOL.

  echo -n 'I: Update products list: '
  local PRODS=()
  local CACHE_BFN="products.cache.$(date +%F).$$"
  dwnl "$NSM_RAW"deb/src/build.sh -O "$CACHE_BFN".tmp >"$CACHE_BFN".log 2>&1
  readarray -t PRODS < <(sed -nre '
    s~^(\S+\(|)\s*"([a-z]+)_([0-9][0-9x.]*):.*$~\2\t\3~p
    /\)/q
    ' -- "$CACHE_BFN".tmp | sort --version-sort --unique --key=2 \
    | tr '\t' '_' | grep -xFve "$EXCLUDE_PRODS")
  echo "found ${#PRODS[@]}."
  if [ -n "${PRODS[*]}" ]; then
    rm -- "$CACHE_BFN".{tmp,log}
  else
    echo 'W: Unable to detect any products.' >&2
  fi
  [ -x "$HOOKS_DIR"/products_filter ] && readarray -t PRODS < <(
    "$HOOKS_DIR"/products_filter "${PRODS[@]}")
  local PROD=
  for PROD in "${PRODS[@]}"; do
    [ -n "$PROD" ] || continue
    [ -e "$PROD" ] || mkdir "$PROD"
  done

  PRODS=()
  echo -n 'I: Determine which products to mirror: '
  for PROD in [a-z]*_[0-9]*; do
    if [ -d "$PROD" ]; then
      echo -n "+$PROD "
      PRODS+=( "$PROD" )
    else
      echo -n "($PROD) "
      continue
      # ^-- Another way to exclude some products: make an empty file with
      #     their name, or a symlink to (probably nonexistent) "exclude.me".
    fi
  done
  echo "-> found ${#PRODS[@]}"
  if [ -z "${PRODS[*]}" ]; then
    echo 'W: Nothing to do.' >&2
    return 0
  fi

  echo -n "I: Start mirror processes: "
  for PROD in "${PRODS[@]}"; do
    echo -n "$PROD "
    mirror_product "$PROD" &
  done
  echo "-> running. @ $(date +'%F %T')"
  local HINT=
  case "$SHELL" in
    */bash ) HINT=' (in case you forgot "&": ctrl-z, "bg".)';;
  esac
  echo "I: Wait for them to finish...$HINT"
  wait
  echo "I: Done. @ $(date +'%F %T')"

  return 0
}


function mirror_product () {
  local PROD="$1"
  local LOGFN="${LOGFN_TMPL:-%/mirror.log}"
  LOGFN="${LOGFN//%/$PROD}"
  mkdir -p "$(dirname "$LOGFN")"

  sleep 2   # let the launcher finish its output

  if [ -x "$HOOKS_DIR"/check-rotate-log ]; then
    "$HOOKS_DIR"/check-rotate-log "$LOGFN"
  else
    [ -f "$LOGFN" ] && rm -- "$LOGFN"
  fi

  local UTF8_BOM=$'\xEF\xBB\xBF'
  if [ -s "$LOGFN" ]; then
    echo >>"$LOGFN"
  elif [[ "$LANG" =~ \.UTF-?8 ]]; then
    echo -n "$UTF8_BOM" >>"$LOGFN"
  fi

  echo "I: $(date +%F_%T) start mirroring $PROD." >>"$LOGFN" || return $?
  dwnl "$DEB_BASEURL$PROD/" --mirror >>"$LOGFN" 2>&1
  local M_RV="$?"
  <<<"I: $(date +%F_%T) finished mirroring $PROD, rv=$M_RV." tee -a "$LOGFN"
  return 0
}


function dwnl () {
  local DL_URL="$1"; shift
  local DL_MODE="$1"; shift
  local DL_CMD=(
    wget
    --continue
    --user-agent "${MIRROR_UAGENT:-nodesource-mirror-bash-wget v0.2}"
    )
  case "$DL_MODE" in
    -O ) ;;
    --mirror ) DL_CMD+=(
      --no-parent
      --no-host-directories
      #--cut-dirs=1
      --default-page=_dirlist.html
      );;
    * ) echo "E: $0: ${FUNCNAME[0]}: invalid download mode" >&2; return 2;;
  esac
  "${DL_CMD[@]}" "$DL_MODE" "$@" "$DL_URL"
  return $?
}










upd_all "$@"; exit $?
