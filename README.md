# Gentoo O3-Graphite-LTO configuration overlay

This is a living document -- it will be kept in sync with the project as it grows.

[![Build Status](https://travis-ci.org/InBetweenNames/gentooLTO.svg?branch=master)](https://travis-ci.org/InBetweenNames/gentooLTO)

> Warning: this configuration is not for the faint of heart.  It is probably not a good idea to use this on a production system!  Against my better judgement, I do anyways...

Interested in running Gentoo at (theoretically) maximum speed?  Want to have a nearly fully [LTOed](https://gcc.gnu.org/wiki/LinkTimeOptimization) system?  Read on to see how it can be done!

## Introduction

This overlay contains a set of configuration files extracted from my own Gentoo Portage configuration to enable system-wide LTO.  It is intended to be used with aggressive compiler optimizations to help catch bugs in programs, including GCC.  However, it can also be used for plain LTO without any aggressive compiler optimizations.  Read on to see how to use it.

The history: earlier in 2017, I set out to do an experiment in building Gentoo using the `-O3` gcc compiler option.  It is well documented on the Gentoo wiki that this is not
a recommended configuration, but I wanted to see to what extent things would break.  As it turns out, most packages that cannot be built with `-O3` are already forced to build with `-O2` anyways in the ebuilds themselves, so I experienced very few failures.  With the success I had using -`O3`, I decided to make things a little more complicated and toss the [Graphite](https://gcc.gnu.org/wiki/Graphite) optimizations in the mix.  Then I went a bit more daring and tossed in LTO.  After about 8 months of doing this, I feel good enough about my configuration that I decided to publish it for interested parties to see.  This repository will be actively updated and tested, as it is the basis for my own Portage configuration.

My original LTO and Graphite experiments were based on [this helpful blog post](http://yuguangzhang.com/blog/enabling-gcc-graphite-and-lto-on-gentoo/).  What this experiment does is expand on the content in that post with an active and updated configuration.

## The philosophy behind this overlay

> All optimizations are transformations, but not all transformations are optimizations.

It is important to note that just because something is compiled with `-O3` and Graphite does not mean that the compiler will necessarily perform more optimizations than it would otherwise.  I only include flags in `make.conf.lto` that allow the compiler to perform a transformation if it is deemed profitable--any "optimization" that doesn't actually optimize, after all, is just a transformation.  The philosophy behind this configuration is to allow the compiler to optimize as it sees fit, without the restrictions normally imposed by `-O2` and friends.  **You won't ever find a flag that intentionally overrides the compiler's judgement in this configuration**.   If you do find a flag in this configuration that does, please file a bug report!  An example of a flag that overrides the compiler's judgement is `-funroll-loops`.

The biggest gotcha with `-O3` is that it does not play nice at all with Undefined Behaviour.  UB is far more prevalent in C and C++ programs than anyone would like to admit, so the default advice with any source distribution is to build with `-O2` and be done with it.  If `-O3` produces non-working code, that is more often than not the code's fault and not the compiler's.

## How to use this configuration

Add the `mv` overlay (`layman -a mv`) and then add this overlay (`layman -a lto-overlay`) to your system and `emerge sys-config/ltoize`, adding it to your `/etc/portage/package.accept_keywords` if necessary.  This will add in the necessary overrides to your `/etc/portage/`, but it won't modify your `make.conf`.
It will create a `make.conf.lto` symlink in `/etc/portage` with the default GentooLTO configuration.
To use the default configuration, define a variable `NTHREADS` with the number of threads you want to use for LTO.
Then, source the file in your own `make.conf` like in this example:

~~~
NTHREADS="12"

source make.conf.lto

CFLAGS="-march=native ${CFLAGS} -pipe"
CXXFLAGS="${CFLAGS}"
LDFLAGS="${LDFLAGS} -Wl,--hash-style=gnu"

#Obtained from app-portage/cpuid2cpuflags utility
CPU_FLAGS_X86="aes avx avx2 f16c fma3 mmx mmxext pclmul popcnt sse sse2 sse3 sse4_1 sse4_2 ssse3"
...
~~~

As shown, your own `CFLAGS` inherit the `CFLAGS` defined by GentooLTO in `make.conf.lto`.
The advantage of this approach is that you will receive new optimization flag updates as part of the standard ltoize
update process.

The default configuration of GentooLTO enables the following:
* O3
* Graphite
* -fipa-pta
* LTO

If you'd like to override the default configuration, you can source another file, `make.conf.lto.defines` instead.
This file contains the definitions for the variables that `sys-config/ltoize` uses for the optimization flags.
Using this file directly, you can cherry-pick and define your own config.  For example:

~~~
NTHREADS="12"

source make.conf.lto.defines

CFLAGS="-march=native -O3 ${FLTO} ${GRAPHITE} ${IPA} -fuse-linker-plugin -pipe"
CXXFLAGS="${CFLAGS}"
LDFLAGS="${LDFLAGS} -Wl,--hash-style=gnu"

...
~~~

For more details, there are extensive comments in both files.
Regardless of which approach you choose, you should ensure that `CXXFLAGS` is set to `CFLAGS`,
and your Portage profile's `LDFLAGS` are respected.  I also enable `-Wl,--hash-style=gnu` as it
can help catch packages that don't respect `LDFLAGS`, but this is optional.

It is strongly recommended to use the latest GCC (8.2.0 at the time of writing), latest binutils (2.31.1 currently), and latest glibc (2.28 currently).

When you find a problem, whether it's a package not playing nice with -O3, Graphite, or LTO, consider opening an issue here or sending a pull request with the overrides needed to get the package working.  Over time, we should be able to achieve full coverage of `/usr/portage` this way and provide a one size fits all solution, and not to mention help improve some open source software through the bug reports that will no doubt be generated! 

**After you've set everything up, run an `emerge -e @world` to rebuild your system with LTO and any optimizations you have chosen.**

Note: if you upgrade compilers, a world rebuild is **required** because compiler object files are generally NOT backwards or forwards compatible.
This means you **will** get LTO linker errors eventually if you don't do a world rebuild!

## Additional details about LTOize

`ltoize` relies heavily on the `package.cflags` functionality from the `app-portage/portage-bashrc-mv` package.  This extends the `package.env` functionality in Portage with a Bash-like syntax which is critical to making this work properly.
Originally, we were using `package.env` overrides, but it turns out that the `flag-o-matic.eclass` used in ebuilds does not "see" flags the same way GCC does--the functions contained inside simply check for the presence of a particular string or pattern inside
your `*FLAGS` variables and determines whether the flag is active based on that.  However, in GCC, later flags override previous flags, and flags can also toggle other flags not listed.  For example, `CFLAGS=-O3` toggles `-ftree-loop-distribution` on GCC 8,
but `is-flagq -ftree-loop-distribution` would return false as `-ftree-loop-distribution` is not listed in `CFLAGS` directly.  Another example: if `LDFLAGS=-flto -fno-lto`, then `is-ldflagq "-flto*"` would return true despite that GCC would have `-flto` unset due
to the later argument overriding it.  The only *real* way to know what flags are active would be to pass in `*FLAGS` to GCC itself and then ask it what flags are active.  Unfortunately, there are probably *many* packages that depend on the existing `flag-o-matic.eclass`
behaviour, and so changing this is probably not an option.  To try to work around this, we mandate that our `*FLAGS` variables contain no "redundant" flags.  If the effect of a particular flag would be "undone" by a following flag, then that flag is considered "redundant".
This doesn't solve the `-O3` problem as listed above, but it should at least allow `is-flagq` to work in the cases we need it to (which is mainly for overriding `-flto`). 

The actual `/etc/portage` modifications are in `sys-config/ltoize/files`.  This is a stripped down version of my own Portage configuration which `ltoize` uses to install into your own `/etc/portage`.  `ltoize` uses symlinks to accomplish this task so that when you do an `emerge --sync` or equivalent, you will automatically pull in the latest set of overrides.  An eselect news entry will be made when a change is made to the default recommended LTO settings in `make.conf.lto`.  That could be including some new compiler flags, or perhaps revising how LTO is done.  Any such a change will require manual intervention if you are not using the default configuration.  We'll do our best to ensure breaking changes are opt-in, rather than opt-out.

Not all packages build cleanly.  Environment overrides are used to allow packages to build that have trouble with O3, Graphite, and LTO.  These can be found in `package.cflags/ltoworkarounds.conf`.  I have tried to categorize the overrides based on the kind of failure were being exhibited, but in some cases this was difficult.
All optimization flag overrides are included in that file as well, but they won't affect you if you are not using those compiler flags, as potentially in the case of using a custom configuration.

### Flag-O-Matic flag manipulation

In addition to the above, a number of packages call `strip-flags`, `replace-flags`, `filter-flags`, and `append-flags` to manipulate the `*FLAGS` variables.
LTOize has an experimental `USE` flag `override-flagomatic` to override these functions globally to turn these functions into no-ops.  `override-flagomatic` is disabled by default.  Users who use this 
functionality should report breakages as issues, so they can be manually resolved.  To enable flag-o-matic for a package, set the variable `LTO_ENABLE_FLAGOMATIC=yes` for
that package in `package.cflags`.

The relevant issue for this work is [#57](https://github.com/InBetweenNames/gentooLTO/issues/57).  Any ideas/suggestions, please post!

### LTO patches

This overlay also contains patches to help certain packages build under LTO that have not been accepted upstream yet.  A script, `41-lto-patch.sh`, is symlinked to your portage `bashrc.d` directory
to apply these patches automatically in the same way user patches do.  Previously, we installed these patches as symlinkes in the `/etc/portage/patches` directory, but this caused problems for
some users and required a version bump whenever the patch set changed.

The relevant issue in the issue tracker is [#105](https://github.com/InBetweenNames/gentooLTO/issues/105).  Please post here
if you are having trouble with the new patch application system.

### The GCC LTO linker plugin

Binutils needs a way to obtain the LTO plugin from GCC in order to properly perform LTO and other linking tasks.  Currently `ld`, `ar`, `nm`, and `ranlib` are known to use this plugin in LTO builds.
There are two ways to do this: pass the path to the plugin manually to each of those utilities, or install a symlink to the plugin in binutils `bfd_plugins` directory and have binutils automatically load it.  Support for automatically loading the LTO plugin from this directory was added in [2014](https://sourceware.org/ml/binutils/2014-01/msg00213.html) (thanks @pchome!).
In this overlay, we choose the automatic approach because passing in the path manually (i.e., setting your `AR`, `NM`, and `RANLIB` variables to point to GCC wrappers) causes problems in legitimate cases, such as building toolchains. 
To facilitate this, I created a patch for `gcc-config` that creates this symlink for you, which thankfully has been merged upstream as of December 17 2017.  Therefore, no action is required on the user's part -- `sys-config/ltoize` depends on a recent enough version of `sys-devel/gcc-config` that is guaranteed to have LTO linker plugin support.

(Thanks @rx80!) If you're interested in seeing where the symlink points, you can check it as follows (on `amd64`):

~~~
ls -l /usr/x86_64-pc-linux-gnu/binutils-bin/lib/bfd-plugins/liblto_plugin.so
~~~

This should point to your active GCC's `liblto_plugin.so`.  For example, for GCC 8.2.0, it should look something like:

~~~
> ls /usr/libexec/gcc/x86_64-pc-linux-gnu/8.2.0/liblto_plugin.so -la
> lrwxrwxrwx 1 root root 22 Oct 13 09:17 /usr/libexec/gcc/x86_64-pc-linux-gnu/8.2.0/liblto_plugin.so -> liblto_plugin.so.0.0.0*
~~~

### Static archives and LTO

Static library archives (`*.a` files) are tricky right now due to a bug in the GNU strip utility found in `sys-devel/binutils` that mangles archives containing LTO symbols.
This is because unlike other binutils programs (such as `ar`, `nm`, and `ranlib`), `strip` doesn't support the LTO linker plugin necessary for processing these symbols.
The result is an archive with all of the same symbols, but with a mangled index.
To work around this, `ltoize` contains a patch for Portage that automatically restores the index of any static archive built that has been subsequently stripped using
the `ranlib` utility.  Additional details about this can be found in [issue #49](https://github.com/InBetweenNames/gentooLTO/issues/49).  If you have a better solution, please let us know!

Previously, we used `STRIP_MASK` to simply avoid stripping any static archives, however this functionality has been removed in EAPI version 7, so a more intrusive
solution is necessary.

Existing users of `sys-config/ltoize` can migrate to the new configuration by:

* Removing STRIP_MASK="*.a" from `make.conf`
* Updating `sys-config/ltoize` to the latest version
* Re-emerging `sys-apps/portage` (`emerge -1 sys-apps/portage`) to ensure the patch is applied

Please report any issues with the new configuration in [issue #49](https://github.com/InBetweenNames/gentooLTO/issues/49).

The portage patch applies only to `sys-apps/portage`, not `sys-apps/portage-mgorny`.  If you are using `sys-apps/portage-mgorny`,
ensure you are on `sys-apps/portage-mgorny-9999`, as the patch was accepted upstream there.

## Caveats

Expect breakages when you emerge new packages or update existing ones.  There are a number of potential ways that an emerge might not work.  My observations are as follows.

### LTO problems

Some packages don't fully respect LDFLAGS, for various reasons.  These tend to manifest around link time with unresolved symbol errors.  My first strategy for dealing with these is to try building the package with `-ffat-lto-objects` enabled (`*FLAGS+=-ffat-lto-objects`).  If the unresolved symbols belong to an external library, I usually rebuild that one with `-ffat-lto-objects` too, because the current package being emerged isn't properly handling the LTO flags and it wants to link against the non LTOed symbols.  Sometimes, however, the package itself just doesn't like LTO for some reason, and you have to disable it entirely (`*FLAGS-=-flto*`)

### Graphite problems

I've never actually yet emerged a package that causes the Graphite optimizations to emit bad code with, but sometimes the Graphite optimizer itself crashes during compilation.  If this is the case, I'll usually use the "LTO-with-no-Graphite" configuration: `*FLAGS-="${GRAPHITE}"`.  Please consider making a bug report in GCC if you get an ICE.

### -O3 problems

These are rare, but they do happen.  When this happens, I usually force down to `-O2` (which disables Graphite implicitly in this configuration) using `package.cflags`.

### -fipa-pta problems

This is a newer optimization I've started including by default, which sometimes causes ICEs in the same way Graphite does.
These make great candidates for bug reports.

### Workflow for debugging a build failure

* First try adding `-ffat-lto-flags`
* If that doesn't work, try removing Graphite: `*FLAGS-="${GRAPHITE}"`
* If that doesn't work, try removing -fipa-pta: `*FLAGS-="${IPA}"`
* If that doesn't work, try removing -O3: `/-O3/-O2`
* If that doesn't work, try removing LTO: `*FLAGS-=-flto*`
* If that doesn't work, try switching linkers (from ld.bfd to ld.gold or backwards)
* If that doesn't work, it's probably not an LTO error, but submit it anyway and we'll take a look.

Once you get a package building with one or more of the above workarounds, work backwards and try and see what the minimum
number of workarounds are for the package.  If you're having trouble, don't hesitate to file an issue.

### A special note about Perl 5

Perl 5 in general does not play nice with LTO ([see this reddit comment](https://www.reddit.com/r/Gentoo/comments/6z8s8m/a_gentoo_portage_configuration_for_building_with/dmuhohy/)).  Packages which use Perl 5 or have `perl` in their USE flags may require the `-ffat-lto-objects` configuration, or in the worst case no LTO at all.  This does not appear to be something that can be fixed easily for Perl 5, so we'll have exercise caution. Perl 6 is unaffected, however.

## My own configuration

I follow the posted recommended configuration in this repo.  I also have [SSP](http://wiki.osdev.org/Stack_Smashing_Protector) and [PIE](https://en.wikipedia.org/wiki/Position-independent_code#Position-independent_executables) disabled for the time being, but this is by means no requirement to run this config.

Most Gentoo-ers have `-march=native -O2` in their `CFLAGS` and `CXXFLAGS`.  Using `-march` is a good idea as it allows GCC to tune it's code generation to your specific processor.  I've enabled all of the GentooLTO default flags in mine, which can be found in `make.conf.lto`.

My Portage profile is `default/linux/amd64/17.1/desktop/plasma`.

## PGO support

### GCC

One result of this project has been upstreamed PGO support in the GCC ebuilds.  It is highly recommended that you compile GCC with PGO, as it really helps with compile times.  Simply add `pgo` to your `sys-devel/gcc` USE flags and emerge and you're all set.
The initial GCC compilation time will increase, however all subsequent compilations will be much faster.

### Python

This repository also contains PGO-enabled ebuilds of the Python interpreters.  PGO is off by default, but can be enabled by adding `pgo` to your `dev-lang/python` USE flags.
The initial Python interpreter builds will take much longer to complete, however the interpreters that are built will run much faster than otherwise.  This is the default on many binary distributions, including Debian and Arch Linux. The actual PGO training set differs between different Python versions. I rely heavily on the community to test these ebuilds.

Python PGO builds should now be parallelized, which should really help with the build times. The number of parallel jobs is taken from `MAKEOPTS` in Portage.

## Conclusions

After running this configuration for long enough, it seems stable for personal use, and it is the configuration I use on my desktop right now.  I see no need to revert anything, but YMMV.  If anything this repository can be used as a canary to see which packages exhibit undefined behaviour in C or C++.

I have over 1600 packages installed on my system at this time, and I did an `emerge -e @world` before I uploaded my configuration to this repository.  Considering how few exceptions there are listed here, I find these results encouraging.  Perhaps we are closer than we think to an LTOed default Gentoo system?


## Goals of this project

Ideally, it should be possible to build Gentoo with LTO by default, no exceptions.  I'm not sure if we'll ever get to that point, but I think it's worthwhile trying.  At the very least, we'll help catch undefined behaviour and packages that don't respect LDFLAGS, a worthwhile endeavour in its own right.  If we could demonstrate that O3 and Graphite produce tangible benefits, perhaps we could even change the "O2-by-default" perception many people have.  The internal compiler errors produced by GCC with the GentooLTO optimization settings should make for some good bug reports.

## How to contribute

The easiest way to contribute is to try it out!  Then contribute your package overrides here. If you want to contribute new compiler flags, understand that these must keep with the overall philosophy of this repository: allow the compiler
to make the final call as to whether a transformation should be applied or not.

If you are willing to, try investigating things on a per-package basis to see if the problem can be corrected at the ebuild level.  If not, consider sending a patch upstream to fix the problem.  This could be very difficult, but would help a lot in keeping things clean here.

If you get internal compiler errors, consider isolating the troubling code and making a GCC bug report with it.

Some packages may perform worse with these configuration options rather than straight O2.  These would also make good candidates for GCC bug reports, as it means the optimizers' cost functions may need to be adjusted.  You may be able to use a package's own test suites to measure this yourself.  I'll create a place to put these overrides when I get a PR about this.

Some users have expressed interest in seeing benchmarks to measure the effects of this configuration on their systems.  I would have performed such benchmarks myself if I had known of a good "general responsiveness" benchmark to test with.  If you know of any good benchmarks that measure this, or are willing to develop one, please let me know.  I think that this would be very useful to the Linux community as a whole.

When contributing workarounds, you can actually modify the overlay directly in your system and commit to it, as it's just a git repository.
You can then push your commits to your own fork on GitHub and create a pull request, or email your patches to me.  Either way, I'll make sure your workarounds
get tested and added to the repository.
