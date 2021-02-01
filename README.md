# GentooLTO overlay

[![Build Status](https://github.com/InBetweenNames/gentooLTO/workflows/GentooLTO/badge.svg?branch=master)](https://github.com/InBetweenNames/gentooLTO/actions)
[![Gitter](https://badges.gitter.im/gentooLTO/community.svg)](https://gitter.im/gentooLTO/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

[Bosnian, Cyrillic (Босански)](.github/README_bs-Cyril.md) | [Bosnian, Latin (Bosanski)](.github/README_bs-Latn.md) | [Serbian (Српски)](.github/README_sr.md) | [Croatian (Hrvatski)](.github/README_hr.md)

---

This is a living document. It will be kept in sync with the project as it grows.

> Warning: this configuration is not for the faint of heart. It is probably not a good idea to use this on a production system! Against my better judgement, I do anyways...

Interested in running Gentoo at (theoretically) maximum speed? Want to have a nearly fully [LTO-ized](https://gcc.gnu.org/wiki/LinkTimeOptimization) system? Read on to see how it can be done!

---

**This documentation is being migrated over to the [GentooLTO Wiki](https://github.com/InBetweenNames/gentooLTO/wiki)**

---

## NEW: Coverage report as of April 17 2019

Based on the submissions from the survey that has been running since October 27 2018, we came to the following findings:

* ~27.4% of Gentoo's main repository is confirmed to be working with GentooLTO's default configuration
* ~27% of Gentoo's main repository is confirmed to be working with GentooLTO's default configuration without the need for any workarounds from GentooLTO

The rest of the packages are untested and their support is unknown! They may or may not work. It would be great to eventually achieve full coverage! In any case, I find these results quite encouraging.

You can view the full report in the accompanying [Gentoo news item.](metadata/news/2019-04-17-results/2019-04-17-results.en.txt) Thanks to everyone who contributed! Credits are at the end of the news item.

If you haven't had a chance to submit anything, don't worry, you still can, but your results will only be included in the next report. I figure that it makes sense to have these on an ongoing (perhaps yearly) basis.

## Introduction

This overlay contains a set of configuration files based on my own Gentoo Portage configuration to enable system-wide LTO. It is intended to be used with aggressive compiler optimizations to help catch bugs in programs, including GCC. However, it can also be used for plain LTO without any aggressive compiler optimizations. Read on to find out how to use it.

### The history

Earlier in 2017, I set out to do an experiment, building Gentoo using the `-O3` GCC compiler flag. It is well documented on the Gentoo wiki that this is not a recommended configuration, but I wanted to see to what extent things would break. As it turns out, most packages that cannot be built with `-O3` are already forced to build with `-O2` anyways in the ebuilds themselves, so I experienced very few failures. Because of the success I had using `-O3`, I decided to make things a little more complicated, so I tossed the [Graphite](https://gcc.gnu.org/wiki/Graphite) optimizations into the mix. Then I became a bit more daring and tossed LTO in. After about eight months of doing this, I felt good enough about my configuration that I decided to publish it so that those who are interested can see it. This overlay will be actively updated and tested, as it is based off of my own Portage configuration.

---

My original LTO and Graphite experiments were based on [this helpful blog post.](http://yuguangzhang.com/blog/enabling-gcc-graphite-and-lto-on-gentoo/) What this overlay does is expand on the content in that post with an active and updated configuration.

---

## The philosophy behind this overlay

> All optimizations are transformations, but not all transformations are optimizations.

It is important to note that just because something is compiled with `-O3` and Graphite does not mean that the compiler will necessarily perform more optimizations than it would otherwise. I only include flags in `make.conf.lto` that allow the compiler to perform a transformation if it is deemed profitable. After all, any "optimization" that doesn't actually optimize is just a transformation. The philosophy behind this configuration is to allow the compiler to perform optimizations as it sees fit, without the restrictions normally imposed by `-O2` and friends. **You will never find a flag that intentionally overrides the compiler's judgement in this configuration**. If you do find a flag in this configuration that does so, please file a bug report! An example of a flag that overrides the compiler's judgement is `-funroll-loops`.

The biggest gotcha with `-O3` is that it does not play nice at all with Undefined Behaviour. UB is far more prevalent in C and C++ programs than anyone would like to admit, so the default advice with any source distribution is to build with `-O2` and be done with it. If `-O3` produces non-working code, that is more often than not the code's fault and not the compiler's.

## How to use this configuration

Add the `mv` and `lto-overlay` overlays to your system with either `layman` or `eselect repository` and run `emerge sys-config/ltoize`. Add the `ltoize` package to your `/etc/portage/package.accept_keywords` if necessary.

This will add the necessary overrides to `/etc/portage/`, but it won't modify your `make.conf`. It will create a `make.conf.lto` symlink in `/etc/portage` with the default GentooLTO configuration. To use the default configuration, define a variable `NTHREADS` with the number of threads you want to use for LTO. Then, source the file in your own `make.conf` like in this example:

~~~ bash
#Set this to "auto" to have gcc determine optimal number of cores (GCC 10+)
NTHREADS="12"

source /etc/portage/make.conf.lto

CFLAGS="-march=native ${CFLAGS} -pipe" #NOTE: Consider using -falign-functions=32 if you use an Intel processor.  See issue #164.
CXXFLAGS="${CFLAGS}"
#If you modify LDFLAGS, source the original first to respect your profile's LDFLAGS:
#LDFLAGS="${LDFLAGS} -Wl,--your-modifications=here"

#Obtained from app-portage/cpuid2cpuflags utility
#Highly recommended to add these
CPU_FLAGS_X86="aes avx avx2 f16c fma3 mmx mmxext pclmul popcnt sse sse2 sse3 sse4_1 sse4_2 ssse3"

***
~~~

As shown, your own `CFLAGS` inherit the `CFLAGS` defined by GentooLTO in `make.conf.lto`. The advantage of this approach is that you will receive new optimization flag updates as part of the standard `ltoize` update process.

The default configuration of GentooLTO enables the following:

* O3
* Graphite ( requires gcc to be built with the `graphite` use flag )
* -fno-semantic-interposition
* -fipa-pta
* -fdevirtualize-at-ltrans
* LTO

---

**GentooLTO with GCC uses `ld.bfd` as the default linker**

**If you have the `sys-config/ltoize` `clang` USE flag enabled, certain overrides assume you are using the `ld.lld` linker and Thin LTO**

---

GentooLTO was previously using `ld.gold` as the default linker, but it appears that it is not being maintained upstream anymore, except for minor bugfixes. `ld.gold` is still supported by GentooLTO and workarounds are still being accepted, but going forward the recommended linker will be `ld.bfd`.

If you'd like to override the default configuration, you can source `make.conf.lto.defines` instead. This file contains the definitions for the variables that `sys-config/ltoize` uses for the optimization flags. Using this file directly, you can cherry-pick and define your own config.  For example:

~~~ bash
NTHREADS="12"

source /etc/portage/make.conf.lto.defines

CFLAGS="-march=native -O3 ${SEMINTERPOS} ${GRAPHITE} ${IPA} ${FLTO} -fuse-linker-plugin -pipe" #NOTE: consider using -falign-functions=32 if you use an Intel processor (Sandy Bridge or later).  See issue #164.
CXXFLAGS="${CFLAGS}"

***
~~~

In addition to this, if you use an Intel processor (Sandy Bridge or later), you may want to enable `-falign-functions=32` in your `CFLAGS`. See issue [#164](https://github.com/InBetweenNames/gentooLTO/issues/164) for a discussion on default function alignment. This flag is optional and appears to be Intel-specific.

For more details, there are extensive comments in both files.
Regardless of which approach you choose, you should ensure that `CXXFLAGS` is set to `CFLAGS`, and your Portage profile's `LDFLAGS` are respected. That is, if you modify `LDFLAGS`, source the original first as in the following:

~~~ bash
***
LDFLAGS="${LDFLAGS} -Wl,--your-modifications=here"
***
~~~

Previously we set `-Wl,--hash-style=gnu` in `LDFLAGS`, but this is not necessary anymore as it is the Gentoo default except on MIPS, where it's not supported, and could cause issues in some cases. See issue #362 for details.

It is strongly recommended to use the latest GCC (10.2.0 at the time of writing), the latest binutils (2.34 currently), and the latest glibc (2.31 currently). Other compilers and C libraries may be supported in the future.

When you find a problem, whether it's a package not playing nice with `-O3`, Graphite, or LTO, consider opening an issue here or sending a pull request with the overrides needed to get the package working.  Over time, we should be able to achieve full coverage of Gentoo's main repository this way and provide a one size fits all solution, and not to mention help improve some open source software through the bug reports that will no doubt be generated!

---

**After you've set everything up, run an `emerge -e --keep-going @world` to rebuild your system with LTO and any optimizations you have chosen, or alternatively use [lto-rebuild](https://github.com/InBetweenNames/gentooLTO/wiki/lto-rebuild) to gradually convert your system over to GentooLTO.**

---

## Conclusions

After running this configuration for a long time, it seems stable enough for personal use, as it is the configuration I use on my desktop right now. I see no need to revert anything, but your milage may vary. If anything, this repository can be used as a canary to see which packages exhibit undefined behaviour in C or C++.

I have over 1600 packages installed on my system at this time, and I did an `emerge -e @world` before I uploaded my configuration to this repository.  Considering how few exceptions there are listed here, I find these results encouraging.  Perhaps we are closer to an LTO-ed default Gentoo system than we think?

## Goals of this project

Ideally, it should be possible to build Gentoo with LTO by default, no exceptions. I'm not sure if we'll ever get to that point, but I think it's worthwhile trying. At the very least, we'll help catch undefined behaviour and packages that don't respect LDFLAGS, a worthwhile endeavour in its own right. If we could demonstrate that `-O3` and Graphite produce tangible benefits, perhaps we could even change the "`-O2`-by-default" perception many people have. The internal compiler errors produced by GCC with the GentooLTO optimization settings should make for some good bug reports.

## How to contribute

The easiest way to contribute is to try it out! Then contribute your package overrides here. If you want to contribute new compiler flags, understand that these must keep with the overall philosophy of this repository: allow the compiler to make the final call as to whether a transformation should be applied or not.

If you are willing to, try investigating things on a per-package basis to see if the problem can be corrected at the ebuild level. If not, consider sending a patch upstream to fix the problem. This could be very difficult, but would help a lot in keeping things clean here.

If you get internal compiler errors, consider isolating the troubling code and making a GCC bug report with it.

Some packages may perform worse with these configuration options rather than plain `-O2`. These would also make good candidates for GCC bug reports, as it means the optimizers' cost functions may need to be adjusted. You may be able to use a package's own test suites to measure this yourself. I'll create a place to put these overrides when I get a PR about this.

Some users have expressed interest in seeing benchmarks to measure the effects of this configuration on their systems. I would have already performed such benchmarks myself if I knew of a good "general responsiveness" benchmark to test with. If you know of any good benchmarks that measure this, or are willing to develop one, please let me know. I think that this would be very useful to the Linux community as a whole.

When contributing workarounds, you can actually modify the overlay directly in your system and commit to it, as it's just a git repository. You can then push your commits to your own fork on GitHub and create a pull request, or email your patches to me. Either way, I'll make sure your workarounds get tested and added to the repository.
