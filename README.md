# Gentoo O3-Graphite-LTO configuration

> Warning: this configuration is not for the faint of heart.  It is probably not a good idea to use this on a production system!  Against my better judgement, I do anyways...

Interested in running Gentoo at (theoretically) maximum speed?  Want to have a nearly fully [LTOed](https://gcc.gnu.org/wiki/LinkTimeOptimization) system?  Read on to see how it can be done!

## Introduction

This repository is a snapshot of my Gentoo Portage configuration.  Earlier in 2017, I set out to do an experiment
in building Gentoo using the `-O3` gcc compiler option.  It is well documented on the Gentoo wiki that this is not
a recommended configuration, but I wanted to see to what extent things would break.  As it turns out, most packages
that cannot be built with `-O3` are already forced to build with `-O2` anyways, so I experienced very few failures.  With the success I had using -`O3`, I decided to make things a little more complicated and toss the [Graphite](https://gcc.gnu.org/wiki/Graphite) optimizations in the mix.  Then I went a bit more daring and tossed in LTO.  After about 8 months of doing this, I feel good enough about my configuration that I decided to publish it for interested parties to see.  This repository will be actively updated and tested, as it is the basis for my own Portage configuration.

My original LTO and Graphite experiments were based on [this helpful blog post](http://yuguangzhang.com/blog/enabling-gcc-graphite-and-lto-on-gentoo/).  What this experiment does is expand on the content in that post with an active and updated configuration.

## A brief note about compiler optimizations

> All optimizations are transformations, but not all transformations are optimizations.

It is important to note that just because something is compiled with `-O3` and Graphite does not mean that the compiler will necessarily perform more optimizations than it would otherwise.  I only include flags that allow the compiler to perform a transformation if it is deemed profitable--any "optimization" that doesn't actually optimize, after all, is just a transformation.  The philosophy behind this configuration is to allow the compiler to optimize as it sees fit, without the restrictions normally imposed by `-O2` and friends.  **You won't ever find a flag that intentionally overrides the compiler's judgement in this configuration**.   If you do find a flag in this configuration that does, please file a bug report!  An example of a flag that overrides the compiler's judgement is `-funroll-loops`.

The biggest gotcha with `-O3` is that it does not play nice with Undefined Behaviour.  UB is far more prevalent in C and C++ programs than anyone would like to admit, so the default advice with any source distribution is to build with `-O2` and be done with it.  If `-O3` produces non-working code, that is more often than not the code's fault and not the compiler's.

## The configuration

Right now I'm on glibc 2.26, so some packages fail to build because of that alone.  Notably versions of GCC < 7.0 have some problems here currently.  I also run the latest stable binutils (2.29) as well.  My compiler at this time is GCC 7.2.0.  I do have [SSP](http://wiki.osdev.org/Stack_Smashing_Protector) and [PIE](https://en.wikipedia.org/wiki/Position-independent_code#Position-independent_executables) disabled for the time being, but this is by means no requirement to run this config.

Most Gentoo-ers have `-march=native -O2` in their `CFLAGS` and `CXXFLAGS`.  Using `-march=native` alone is a good idea as it allows GCC to tune it's code generation to your specific processor.  I've enabled LTO, Graphite, and `-O3` in mine, which can be found in `make.conf`.  I also pass all compiler options to the linker as well in `LDFLAGS`, which is necessary for LTO to work.

Not all packages build cleanly.  I have a number of environment overrides which are used to override the default settings on a per-package basis.  The configurations are in `env/`, and the per-package overrides are in `package.env/`.  I have tried to categorize the overrides based on the kind of failure were being exhibited, but in some cases this was difficult.  LTO overrides can be found in `package.env/ltoworkarounds.conf`.  Graphite and -O3 failures can be found in `package.env/nooptimize.conf`.  You'll also find some other environment overrides in there, which aren't relevant to this project, such as crossdev configurations for my Haskell-on-ARM projects and some overrides for Python.

My Portage profile is `default/linux/amd64/17.0/desktop/plasma`.

## Caveats

Expect breakages when you emerge new packages or update existing ones.  There are a number of potential ways that an emerge might not work.  My observations are as follows.

### LTO problems

Some packages don't fully respect LDFLAGS, for various reasons.  These tend to manifest around link time with unresolved symbol errors.  My first strategy for dealing with these is to try building the package with `-ffat-lto-objects` enabled (that's in `env/ltofat.conf`).  If the unresolved symbols belong to an external library, I usually rebuild that one with `-ffat-lto-objects` too, because the current package being emerged isn't properly handling the LTO flags and it wants to link against the non LTOed symbols.  Sometimes, however, the package itself just doesn't like LTO for some reason, and you have to disable it.  That's when I make it use the "no-LTO" configuration in `env/nolto.conf`.

### Graphite problems

I've never actually yet emerged a package that causes the Graphite optimizations to emit bad code with, but sometimes the Graphite optimizer itself crashes during compiletime.  If this is the case, I'll usually use the "LTO-with-no-Graphite" configuration in `env/ltonographite.conf` and this will work.

### -O3 problems

These are rare, but they do happen.  When this happens, I usually force down to `-O2` (which disables Graphite implicitly in this configuration) using the `env/O2*.conf` configs.  Some packages are sensitive to both `-O3` and `LTO`, so I've included both an LTOed and non-LTOed `-O2` configurations for this purpose.

### Patches

I do include a small patch to Firefox in the `patches` directory to allow it to build with LTO.  It's a small buildsystem patch that was on a bug report.  I usually only go through the trouble to include a patch in `patches` if one already exists.

## Conclusions

After running this configuration for long enough, it seems stable for personal use, and it is the configuration I use on my desktop right now.  I see no need to revert anything, but YMMV.  If anything this repository can be used as a canary to see which packages exhibit undefined behaviour in C or C++.

The packages I've found so far that don't play nice with glibc 2.26 are as follows:

* sys-devel/flex
* sys-libs/gpm
* =sys-libs/compiler-rt-sanitizers-4.0.1 (5.0.0 seems unaffected)

I have over 1500 packages installed on my system at this time, and I did an `emerge -e @world` before I uploaded my configuration to this repository.  All currently installed packages in my system, including deep dependencies, can be found in the file `worldsetdeep`.  Considering how few exceptions I have listed here, I find these results encouraging.  Perhaps we are closer than we think to an LTOed default Gentoo system?

## How to use this configuration

If you're building a new system, I'd recommend using glibc 2.25 since there are some packages which do not build with it.  I wouldn't recommend just taking this repository as-is and using it as your portage--instead you should cherry pick the parts that are useful to you.  A good start would be to take the `make.conf`, `env`, and `package.env` directories and leave out `python.conf` and `cross-armv7a-hardfloat-linux-gnueabi.conf`, and perhaps use GCC 7.2.0.  In `make.conf`, make sure you set `-march` appropriately, as I have it set to Haswell currently and that may not be suitable for your system.  You can set it to `native` if you are unsure what it should be.
I would recommend taking the `patches` directory, too, if you are planning to build Firefox, as it needs a small buildsystem patch in order to handle LTO arguments correctly.

## Goals of this project

Ideally, it should be possible to build Gentoo with LTO by default, no exceptions.  I'm not sure if we'll ever get to that point, but I think it's worthwhile trying.  At the very least, we'll help catch undefined behaviour and packages that don't respect LDFLAGS, a worthwhile endeavour in its own right.  If we could demonstrate that O3 and Graphite produce tangible benefits, perhaps we could even change the "O2-by-default" perception many people have.  The internal compiler errors produced by GCC with Graphite should make for some good bug reports.

## How to contribute

The easiest way to contribute would be to test this on your own system and contribute your LTO, Graphite, and O3 overrides here. If you want to contribute new compiler flags, understand that these must keep with the overall philosophy of this repository: allow the compiler
to make the final call as to whether a transformation should be applied or not.

If you are willing to, try investigating things on a per-package basis to see if the problem can be corrected at the ebuild level.  If not, consider sending a patch upstream to fix the problem.  This could be very difficult, but would help a lot in keeping things clean here.

If you get internal compiler errors, consider isolating the troubling code and making a GCC bug report with it.

Some packages may perform worse with these configuration options rather than straight O2.  These would also make good candidates for GCC bug reports, as it means the optimizers' cost functions may need to be adjusted.  You may be able to use a package's own test suites to measure this yourself.  I'll create a place to put these overrides when I get a PR about this.

Some users have expressed interest in seeing benchmarks to measure the effects of this configuration on their systems.  I would have performed such benchmarks myself if I had known of a good "general responsiveness" benchmark to test with.  If you know of any good benchmarks that measure this, or are willing to develop one, please let me know.  I think that this would be very useful to the Linux community as a whole.

