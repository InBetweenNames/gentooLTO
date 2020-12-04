LTOPatch() {
	# Lifted straight from the Portage sources
	# Working directory is set to ${HOME} by default
	# Set it properly for patch application

	if [[ -d $S ]] ; then
		cd "${S}"
	elif ___eapi_has_S_WORKDIR_fallback; then
		cd "${WORKDIR}"
	elif [[ -z ${A} ]] && ! __has_phase_defined_up_to prepare; then
		cd "${WORKDIR}"
	else
		die "The source directory '${S}' doesn't exist"
	fi

	# keep path in __dyn_prepare in sync!
	local tagfile=${T}/.portage_lto_patches_applied
	[[ -f ${tagfile} ]] && return
	>> "${tagfile}"

	local lto_overlay_dir="$(portageq get_repo_path ${PORTAGE_CONFIGROOT} lto-overlay)"		
	local basedir="${lto_overlay_dir%/}/sys-config/ltoize/files/patches"

	local applied d f
	local -A _eapply_lto_patches
	local prev_shopt=$(shopt -p nullglob)
	shopt -s nullglob

	# Patches from all matched directories are combined into a
	# sorted (POSIX order) list of the patch basenames. Patches
	# in more-specific directories override patches of the same
	# basename found in less-specific directories. An empty patch
	# (or /dev/null symlink) negates a patch with the same
	# basename found in a less-specific directory.
	#
	# order of specificity:
	# 1. ${CATEGORY}/${P}-${PR} (note: -r0 desired to avoid applying
	#    ${P} twice)
	# 2. ${CATEGORY}/${P}
	# 3. ${CATEGORY}/${PN}
	# all of the above may be optionally followed by a slot
	for d in "${basedir}"/${CATEGORY}/{${P}-${PR},${P},${PN}}{:${SLOT%/*},}; do
		for f in "${d}"/*; do
			if [[ ( ${f} == *.diff || ${f} == *.patch ) &&
				-z ${_eapply_lto_patches[${f##*/}]} ]]; then
				_eapply_lto_patches[${f##*/}]=${f}
			fi
		done
	done

	local lto_patch_cmd
	if [[ "${EAPI}" -ge 6 ]]; then
		lto_patch_cmd=eapply
	else
		lto_patch_cmd=epatch
	fi

	if [[ ${#_eapply_lto_patches[@]} -gt 0 ]]; then
		while read -r -d '' f; do
			f=${_eapply_lto_patches[${f}]}
			if [[ -s ${f} ]]; then
				${lto_patch_cmd} "${f}"
				applied=1
			fi
		done < <(printf -- '%s\0' "${!_eapply_lto_patches[@]}" |
			LC_ALL=C sort -z)
	fi

	${prev_shopt}

	[[ -n ${applied} ]] && ewarn "lto-overlay: LTO patches applied."

}

BashrcdPhase configure LTOPatch
