LTOOverrideFlagOMatic()
{
	if [[ "${LTO_ENABLE_FLAGOMATIC}" != "yes" ]]; then
		strip-flags()
		{
			ewarn "lto-overlay: strip-flags OVERRIDDEN"
		}

		replace-flags()
		{
			ewarn "lto-overlay: replace-flags OVERRIDDEN"
		}

		append-flags()
		{
			ewarn "lto-overlay: append-flags OVERRIDDEN"
		}

		filter-flags()
		{
			ewarn "lto-overlay: filter-flags OVERRIDDEN"
		}
	fi
}


BashrcdPhase all LTOOverrideFlagOMatic
