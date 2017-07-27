======================================================================
                               durable
======================================================================
----------------------------------------------------------------------
                               the what
----------------------------------------------------------------------

Homebrew documentation on permissible software:

  The software in question must:

  - be maintained (e.g. upstream is still making new releases)
  - be known
  - be stable (e.g. not declared “unstable” or “beta” by upstream)
  - be used
  - have a homepage

conflates *done* with *dead*; favors software requiring maintenance
over that which *just works*.  there's two kinds: author's and
user's maintenance.  both should be as low as possible: none.

software needs either author's or user's maintenance if:

- it is missing necessary features, or
- it has defects, or
- it builds on an unstable foundation

all three can be mitigated through focus on simplicity and execution.

software like Dan Bernstein's djbdns or libtai is maintenance-free
because it's complete and self-contained.  it builds [*]_ and runs
today as well as it did 16 years ago (and counting).  it is used.
i've been using it since 2002.  it does not fail, it does not change.

Homebrew has it backwards, we should promote such software rather than
shun it.  if releases represent improvements, then software which
"*is still making new releases*" is worse than that which has those
releases in its past.

i've been using the same email client, shell, and text editor [*]_ for
the past 15 years.  neither is a paragon of maintenance-free in either
sense: they all keep releasing, and i was forced to tweak my dotfiles
two or three times after an upgrade.  still, three maintenance
incidents over 45 years of steady function combined is pretty good.

as an author, i want software i write to serve for years with no
maintenance required from me.  for that it needs to be bug-free,
complete, with minimal buildtime and runtime dependencies.  i want to
create tools with years of maintenance-free lifespan so i can move on
and create more.

as a user, i want no updates: i never asked for defects or absence of
features in the first place, i have better things to do than pamper
shitty software through updates.  i want stable tools with years of
maintenance-free lifespan so i can focus on actually using them for
my own purposes.

is my own software *durable*?  i know that some of my tools have been
running in a certain bank for 8 years now, no maintenance apart from
occasional recompilation.  that's quite good already, and it should
get better still. [*]_  it's time to be explicit:

  my software for others should be good for at least ten years.
  my software for myself should be good for fifteen years or more.

lofty goals.


.. [*] djbdns needed one update after its ultimate release in 2001:
    when SUSv2_ won over POSIX.1_ and `extern int errno` stopped
    being a thing.  cf. `dns/djbdns`_ package in FreeBSD: its history
    is dominated by churn.

.. [*] mutt, zsh, and vim

.. [*] there's way more perishable shit than durable gems in my past.
    it gets better.  i know which choices turned out wrong.

.. _SUSv2: https://archive.is/4daOX
.. _POSIX.1: https://archive.fo/WaBNL
.. _dns/djbdns: https://archive.is/TI1LP


.. the how
.. =======
