#!/bin/bash
#
# Script for creating a ad blocking hosts file
# Sources:
#	https://hosts-file.net/ad_servers.txt
#	https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext
#	https://adaway.org/hosts.txt
#

##############################################
# Directory where to save the hosts file
DIR="/home/pi/adaway"

# Name of hosts file
HOSTSFILE="$DIR/hosts"

# hosts files to add to the complete list
ORIGINAL_HOSTS="/etc/hosts"

# URLS to download from
URLS=("https://hosts-file.net/ad_servers.txt" \
      "https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext" \
      "https://adaway.org/hosts.txt")
###############################################

create_temp_file() {
	local TMPFILE="$(mktemp)"

	if [ -z "$TMPFILE" ]; then
		echo "Could not create temporary file" 1>&2
		return 1
	fi

	echo "$TMPFILE"
}


download_hosts_file() {
	local URL=$1

	local TMP=$(create_temp_file) || return 1
	echo "$TMP"


	curl -s -o "$TMP" "$URL" && return 0

	echo "Download of $URL failed" 1>&2
	rm "$TMP" &> /dev/null

	return 1
}

TMPHOSTS=$(create_temp_file) || exit 1

for URL in ${URLS[@]}; do
	TMPDL=$(download_hosts_file "$URL") || continue
	cat "$TMPDL" >> "$TMPHOSTS"
	rm $TMPDL &> /dev/null
done

# clean hosts data
sed -i 's/\r//g' "$TMPHOSTS"
sed -i 's/\t/ /g' "$TMPHOSTS"
sed -i 's/127.0.0.1/0.0.0.0/g' "$TMPHOSTS"
sed -i '/ localhost$/d' "$TMPHOSTS"
sed -i '/^#/d' "$TMPHOSTS"

sort -u -o "$TMPHOSTS" "$TMPHOSTS"

# create complete hosts file
cat "$ORIGINAL_HOSTS" "$TMPHOSTS" > $HOSTSFILE

rm "$TMPHOSTS" &> /dev/null

