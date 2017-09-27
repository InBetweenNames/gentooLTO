#!/usr/bin/env bash
# "Unit" test if overlay and ebuilds have basic issues
set -ex

# Disable news messages from portage and disable rsync's output
export FEATURES="-news" PORTAGE_RSYNC_EXTRA_OPTS="-q"

# Update the portage tree and install dependencies
emerge --sync
emerge -1 portage
emerge -q --buildpkg --usepkg dev-vcs/git app-portage/repoman

# Run the tests
repoman full -d
