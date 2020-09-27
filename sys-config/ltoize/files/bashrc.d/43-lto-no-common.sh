#From #484, contributed by nivedita76 and pchome, needed for some packages that have a weird libtool setup.
#Essentially, these two variables don't get set properly when `-flto` and `-fno-common` are used together.
#This is a hack to set them ourselves.  Define NOCOMMON_OVERRIDE_LIBTOOL=yes to activate it per-package or globally
#via make.conf.

nocommon_configure() {
	if [[ "${NOCOMMON_OVERRIDE_LIBTOOL}" == "yes" ]]; then
		ewarn "lto-overlay: libtool global_symbol_pipe and global_symbol_to_cdecl OVERRIDDEN"
		lt_cv_sys_global_symbol_pipe="sed -n -e 's/^.*[ ]\\([ABCDGIRSTW][ABCDGIRSTW]*\\)[ ][ ]*\\([_A-Za-z][_A-Za-z0-9]*\\)\$/\\1 \\2 \\2/p' | sed '/ __gnu_lto/d'"
		export lt_cv_sys_global_symbol_pipe
		lt_cv_sys_global_symbol_to_cdecl=""
		export lt_cv_sys_global_symbol_to_cdecl
	fi
}

BashrcdPhase configure nocommon_configure
