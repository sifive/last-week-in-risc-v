#!/bin/sh

FOLDER="$HOME/work/last-week-in-risc-v"

date="this friday"
from="si"
to=()
title="(Draft) Last Week in RISC-V"
while [[ "$1" != "" ]]
do
  case "$1" in
  --to)
    to+=("$2")
    shift 2
    ;;
  --final)
    to=("last-week-in-risc-v@sifive.com")
    title="Last Week in RISC-V"
    date="now"
    shift 1
    ;;
  -*)
    echo "Unknown argument $1"
    exit 1
    ;;
  *)
    date="$@"
    while [[ "$1" != "" ]]
    do
        shift
    done
    ;;
  esac
done

note=lwirv-"$(date -d "$date" "+%Y-%m-%d")".md

cd "$FOLDER" || exit 1

git checkout master || exit 1
git pull --ff-only origin master || exit 1

if test ! -f "$note"
then
  echo "$note does not exist"
  exit 1
fi

tempdir="$(mktemp -d)"
trap "rm -rf $tempdir" EXIT

pandoc "$note" -o "$tempdir"/lwirv-"$(date -d "$date" "+%Y-%m-%d")".html || exit 1
chromium "$tempdir"/lwirv-"$(date -d "$date" "+%Y-%m-%d")".html

cat >>"$tempdir"/mail <<EOF
From: $from
To: $(echo "${to[*]}" | sed 's/ /,/g')
Subject: $title: $(date -d "$date" "+%A %B %e, %Y")
MIME-Version: 1.0
Content-Type: multipart/alternative; boundary="----=__lwirv_MIME"
Message-ID: <lwirv-$(date +%s)-$(uuidgen)@$HOSTNAME>

------=__lwirv_MIME
Content-Type: text/plain; charset=utf-8
Content-Transfer-Encoding: 8bit

$(cat "$note")
------=__lwirv_MIME
Content-Type: text/html; charset=utf-8
Content-Transfer-Encoding: base64

$(base64 "$tempdir"/lwirv-"$(date -d "$date" "+%Y-%m-%d")".html)
------=__lwirv_MIME--

EOF

cat "$tempdir"/mail | mhng-pipe-comp_stdin

rm -rf "$tempdir"
