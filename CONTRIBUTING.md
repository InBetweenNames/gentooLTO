Contributions are welcome.  Due to the nature of Portage, merging changes could prove difficult, especially as users are expected to only take from this configuration what they find useful.  USE flag changes, for example, are likely not to be accepted.  New compiler flags however could be, particularly if they give the compiler more freedom to make decisions.  Contributions must keep in the philosophy stated in the README.  No contributions will be accepted that override the compiler's better judgement.

#Pull Request Guidelines

When creating a PR, the title of the commit should be:

~~~
<category>/<package>: <executive summary>
~~~

If the PR is to add something to `ltoworkarounds.conf`, make sure there is a comment next to the relevant lines
that explains the specific LTO-related error encountered.

If the PR is to remove an override, make sure it is moved to the `fixed` section of the file.

If the PR contains a patch that allows an LTO program to build, prefer to keep the patch as a user-patch
in the `patches` directory.  If this is not possible (perhaps the `EAPI` is too old, for example), then duplicate
the ebuild in this repo and add your patch to the `PATCHES` variable, incrementing the `EAPI` as necessary.

For all other PRs, it is recommended that you make an issue on the issue tracker first so we can discuss the problem being solved
and the approach taken.  This repo has been ultimately shaped by this philosophy, such that the best solution emerges.
If you don't want to create an issue, you can also email me directly.
