LTOOverrideFlagOMatic()
{
	strip-flags()
	{
		ewarn "lto-overlay: strip-flags OVERRIDDEN"
	}

	replace-flags()
	{
		ewarn "lto-overlay: replace-flags OVERRIDDEN"
	}
}

BashrcdPhase prepare LTOOverrideFlagOMatic
BashrcdPhase configure LTOOverrideFlagOMatic
BashrcdPhase compile LTOOverrideFlagOMatic
