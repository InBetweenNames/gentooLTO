#!/usr/bin/env bash
# "Unit" test if overlay and ebuilds have basic issues
set -ex

# Disable news messages from portage and disable rsync's output
export FEATURES="-news" PORTAGE_RSYNC_EXTRA_OPTS="-q"

mkdir -p /etc/portage/repos.conf

# Update the portage tree and install dependencies
emerge --sync
emerge -1 portage
emerge -q --buildpkg --usepkg dev-vcs/git app-portage/repoman

#For "mv" dependency

cat << EOF >> /etc/portage/repos.conf/mv.conf
[mv]
location = /usr/local/mv
sync-type = git
sync-uri = https://github.com/vaeth/mv-overlay.git
auto-sync = Yes
clone-depth = 1
EOF

emerge --sync mv

# Run the tests
repoman full -dx
