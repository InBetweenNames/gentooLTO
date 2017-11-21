# Gentoo O3-Graphite-LTO configuration overlay

[![Build Status](https://travis-ci.org/InBetweenNames/gentooLTO.svg?branch=master)](https://travis-ci.org/InBetweenNames/gentooLTO)

> Warning: this configuration is not for the faint of heart.  It is probably not a good idea to use this on a production system!  Against my better judgement, I do anyways...

Interested in running Gentoo at (theoretically) maximum speed?  Want to have a nearly fully [LTOed](https://gcc.gnu.org/wiki/LinkTimeOptimization) system?  Read on to see how it can be done!

NEW: [Chat with us on Freenode! ##gentoolto](https://webchat.freenode.net/?url=irc://irc.freenode.net/##gentoolto)

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

Add the `mv` overlay (`layman -a mv`) and then add this overlay (`layman -a lto-overlay`) to your system and `emerge sys-config/ltoize`.  This will add in the necessary overrides to your `/etc/portage/`, but it won't modify your `make.conf`.
It will create a `make.conf.lto` in `/etc/portage` with the recommended settings for LTO.  Modify your own `make.conf` accordingly--there are comments in `make.conf.lto` to help
guide you through the process, including for enabling Graphite.

If you're building a new system, I'd recommend using glibc 2.25 since there are some packages which do not build with glibc 2.26.

When you find a problem, whether it's a package not playing nice with -O3, Graphite, or LTO, consider opening an issue here or sending a pull request with the overrides needed to get the package working.  Over time, we should be able to achieve full coverage of `/usr/portage` this way and provide a one size fits all solution, and not to mention help improve some open source software through the bug reports that will no doubt be generated! 

After you've set everything up, I recommend an `emerge -e @world` to rebuild your system with LTO and any optimizations you have chosen.


## Additional details about LTOize

`ltoize` relies heavily on the `package.cflags` functionality from the `app-portage/portage-bashrc-mv` package.  This extends the `package.env` functionality in Portage with a Bash-like syntax which is critical to making this work properly.
Originally, we were using `package.env` overrides, but it turns out that the `flag-o-matic.eclass` used in ebuilds does not "see" flags the same way GCC does--the functions contained inside simply check for the presence of a particular string or pattern inside
your `*FLAGS` variables and determines whether the flag is active based on that.  However, in GCC, later flags override previous flags, and flags can also toggle other flags not listed.  For example, `CFLAGS=-O3` toggles `-ftree-loop-distribution` on GCC 8,
but `is-flagq -ftree-loop-distribution` would return false as `-ftree-loop-distribution` is not listed in `CFLAGS` directly.  Another example: if `LDFLAGS=-flto -fno-lto`, then `is-ldflagq "-flto*"` would return true despite that GCC would have `-flto` unset due
to the later argument overriding it.  The only *real* way to know what flags are active would be to pass in `*FLAGS` to GCC itself and then ask it what flags are active.  Unfortunately, there are probably *many* packages that depend on the existing `flag-o-matic.eclass`
behaviour, and so changing this is probably not an option.  To try to work around this, we mandate that our `*FLAGS` variables contain no "redundant" flags.  If the effect of a particular flag would be "undone" by a following flag, then that flag is considered "redundant".
This doesn't solve the `-O3` problem as listed above, but it should at least allow `is-flagq` to work in the cases we need it to (which is mainly for overriding `-flto`). 

The actual `/etc/portage` modifications are in `sys-config/ltoize/files`.  This is a stripped down version of my own Portage configuration which `ltoize` uses to install into your own `/etc/portage`.  `ltoize` uses symlinks to accomplish this task so that when you do an `emerge --sync` or equivalent, you will automatically pull in the latest set of overrides.  An eselect news entry will be made when a change is made to the default recommended LTO settings in `make.conf.lto`.  That could be including some new compiler flags, or perhaps revising how LTO is done.  Any such a change would require manual intervention, so you will be notified when you update `ltoize`.

Not all packages build cleanly.  Environment overrides are used to allow packages to build that have trouble with O3, Graphite, and LTO.  These can be found in `package.cflags/ltoworkarounds.conf`.  I have tried to categorize the overrides based on the kind of failure were being exhibited, but in some cases this was difficult.
Graphite and -O3 overrides are included in that file as well, but they won't affect you if you are not using those compiler flags.

`ltoize` will also obtain patches which help certain packages build with LTO.  It installs symlinks to these patches in `/etc/portage/patches`, so that you can have your own patches alongside the ones maintained in this repository.  These aren't automatically updated.  If a modification is made to an existing match, you will transparently receive that patch in your own `/etc/portage/patches` since a symlink will be used.  However, if a patch is created for a new package, you will need to re-run `ltoize` to get the new symlink.  I'm still thinking about a good way to handle this.  `/etc/portage/patches` unfortunately can't have a subdirectory like `lto` since it is used to match against the package being installed.


### A note about the GCC LTO plugin

Binutils needs a way to obtain the LTO plugin from GCC in order to properly perform LTO and other linking tasks.  Currently `ld`, `ar`, `nm`, and `ranlib` are known to use this plugin in LTO builds.
There are two ways to do this: pass the path to the plugin manually to each of those utilities, or install a symlink to the plugin in binutils `bfd_plugins` directory and have binutils automatically load it.  Support for automatically loading the LTO plugin from this directory was added in [2014](https://sourceware.org/ml/binutils/2014-01/msg00213.html) (thanks @pchome!).
I have a patch for `gcc-config` that creates this symlink for you, which is included in the `gcc-config` contained in this repo.  A [bug report](https://bugs.gentoo.org/630066#c1) was created upstream as this should definitely be something included in the official `gcc-config`.

This is the recommended way of doing LTO.  Previously, it was required that you set your `AR`, `NM`, and `RANLIB` variables to point to GCC wrappers, which would in turn pass the linker plugin to their corresponding programs, but this causes problems in legitimate cases, such as building toolchains.

(Thanks @rx80!) If you're interested in seeing where the symlink points, you can check it as follows (on `amd64`):

~~~
ls -l /usr/x86_64-pc-linux-gnu/binutils-bin/lib/bfd-plugins/liblto_plugin.so
~~~

This should point to your active GCC's `liblto_plugin.so`.  For example, for GCC 7.2.0, it should look something like:

~~~
> ls /usr/libexec/gcc/x86_64-pc-linux-gnu/7.2.0/liblto_plugin.so -la
> lrwxrwxrwx 1 root root 22 Oct 13 09:17 /usr/libexec/gcc/x86_64-pc-linux-gnu/7.2.0/liblto_plugin.so -> liblto_plugin.so.0.0.0*
~~~

## Caveats

Expect breakages when you emerge new packages or update existing ones.  There are a number of potential ways that an emerge might not work.  My observations are as follows.

### LTO problems

Some packages don't fully respect LDFLAGS, for various reasons.  These tend to manifest around link time with unresolved symbol errors.  My first strategy for dealing with these is to try building the package with `-ffat-lto-objects` enabled (that's in `env/ltofat.conf`).  If the unresolved symbols belong to an external library, I usually rebuild that one with `-ffat-lto-objects` too, because the current package being emerged isn't properly handling the LTO flags and it wants to link against the non LTOed symbols.  Sometimes, however, the package itself just doesn't like LTO for some reason, and you have to disable it.  That's when I make it use the "no-LTO" configuration in `env/nolto.conf`.

### Graphite problems

I've never actually yet emerged a package that causes the Graphite optimizations to emit bad code with, but sometimes the Graphite optimizer itself crashes during compiletime.  If this is the case, I'll usually use the "LTO-with-no-Graphite" configuration in `env/ltonographite.conf` and this will work.

### -O3 problems

These are rare, but they do happen.  When this happens, I usually force down to `-O2` (which disables Graphite implicitly in this configuration) using the `env/O2*.conf` configs.  Some packages are sensitive to both `-O3` and `LTO`, so I've included both an LTOed and non-LTOed `-O2` configurations for this purpose.

### Patches

I do include a small patch to Firefox in the `patches` directory to allow it to build with LTO.  It's a small buildsystem patch that was on a bug report.  I usually only go through the trouble to include a patch in `patches` if one already exists.  The `ltoize` tool will automatically grab this for you.

### A special note about Perl 5

Perl 5 in general does not play nice with LTO ([see this reddit comment](https://www.reddit.com/r/Gentoo/comments/6z8s8m/a_gentoo_portage_configuration_for_building_with/dmuhohy/)).  Packages which use Perl 5 or have `perl` in their USE flags may require the `ltofat.conf` configuration, or in the worst case `nolto.conf`.  This does not appear to be something that can be fixed easily for Perl 5, so we'll have exercise caution. Perl 6 is unaffected, however.

## My own configuration

Right now I'm on glibc 2.26, so some packages fail to build because of that alone.  Notably versions of GCC < 7.0 have some problems here currently.  I also run the latest stable binutils (2.29) as well.  My compiler at this time is GCC 7.2.0.  I do have [SSP](http://wiki.osdev.org/Stack_Smashing_Protector) and [PIE](https://en.wikipedia.org/wiki/Position-independent_code#Position-independent_executables) disabled for the time being, but this is by means no requirement to run this config.

Most Gentoo-ers have `-march=native -O2` in their `CFLAGS` and `CXXFLAGS`.  Using `-march` is a good idea as it allows GCC to tune it's code generation to your specific processor.  I've enabled LTO, Graphite, and `-O3` in mine, which can be found in `make.conf.lto`.  I also pass all compiler options to the linker as well in `LDFLAGS`, which is necessary for LTO to work.


My Portage profile is `default/linux/amd64/17.0/desktop/plasma`.

## Conclusions

After running this configuration for long enough, it seems stable for personal use, and it is the configuration I use on my desktop right now.  I see no need to revert anything, but YMMV.  If anything this repository can be used as a canary to see which packages exhibit undefined behaviour in C or C++.

The packages I've found so far that don't play nice with glibc 2.26 are as follows:

* sys-devel/flex
* sys-libs/gpm
* =sys-libs/compiler-rt-sanitizers-4.0.1 (5.0.0 seems unaffected)

I have over 1500 packages installed on my system at this time, and I did an `emerge -e @world` before I uploaded my configuration to this repository.  All currently installed packages in my system, including deep dependencies, can be found in the file `worldsetdeep`.  Considering how few exceptions I have listed here, I find these results encouraging.  Perhaps we are closer than we think to an LTOed default Gentoo system?


## Goals of this project

Ideally, it should be possible to build Gentoo with LTO by default, no exceptions.  I'm not sure if we'll ever get to that point, but I think it's worthwhile trying.  At the very least, we'll help catch undefined behaviour and packages that don't respect LDFLAGS, a worthwhile endeavour in its own right.  If we could demonstrate that O3 and Graphite produce tangible benefits, perhaps we could even change the "O2-by-default" perception many people have.  The internal compiler errors produced by GCC with Graphite should make for some good bug reports.

## How to contribute

The easiest way to contribute would be to test this on your own system and contribute your LTO, Graphite, and O3 overrides here. If you want to contribute new compiler flags, understand that these must keep with the overall philosophy of this repository: allow the compiler
to make the final call as to whether a transformation should be applied or not.

If you are willing to, try investigating things on a per-package basis to see if the problem can be corrected at the ebuild level.  If not, consider sending a patch upstream to fix the problem.  This could be very difficult, but would help a lot in keeping things clean here.

If you get internal compiler errors, consider isolating the troubling code and making a GCC bug report with it.

Some packages may perform worse with these configuration options rather than straight O2.  These would also make good candidates for GCC bug reports, as it means the optimizers' cost functions may need to be adjusted.  You may be able to use a package's own test suites to measure this yourself.  I'll create a place to put these overrides when I get a PR about this.

Some users have expressed interest in seeing benchmarks to measure the effects of this configuration on their systems.  I would have performed such benchmarks myself if I had known of a good "general responsiveness" benchmark to test with.  If you know of any good benchmarks that measure this, or are willing to develop one, please let me know.  I think that this would be very useful to the Linux community as a whole.

