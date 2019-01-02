======================================================================
                        yaml sucks^Wdoes not rock
======================================================================
----------------------------------------------------------------------
                 a picture is worth a thousand curses
----------------------------------------------------------------------


YAML is an instance of *inner platform*: a YAML file is a picture of
a directory tree...

... minus all the directory and file manipulation utilities that come
bundled with virtually every unix system.

let's say you have a directory with a few thousands of files like this
one (a hypothetical package description)::

  # (C) 2018 Random Linux Vendor
  pkg:
    name: fake
    version: 0.3
    maintainer: rn+fake@sigpipe.cz
    homepage: https://github.com/roman-neuhauser/fake
    licenses:
      - MIT
    group: Development/Tools
    sources:
      - v0.3.tar.gz
    archs:
      - noarch
    blurb:
      A small tool to create test doubles for commandline utilities.
    depends:
      build:
        - basexy
        - make
      check:
        - basexy
        - cram
        - make
      run:
        - basexy
    steps:
      prep: |
        tar -xzf ...
      build: |
        ./configure
        make
      check: |
        make check
      install: |
        make install DESTDIR=$DESTDIR

now let's say you want to remove `make` from build dependencies
of every package (because it's part of the base building environment).
what will you do?  will you reach for a YAML parsing library and use
that to rewrite the files?  (you'll need one which preserves
comments!)

i doubt it.  my experience suggests most people would use
``sed '/- make/d'`` *at "best"*, and  doing so would remove ``make``
from unrelated places like run dependencies which means broken
packages.  maybe you'd spend the time and energy to review the diff
and bring back the deletions that are outside build dependencies.
in doing so, you would flip the purported roles of computer and human:
the former is supposed to do repetitive labor for the latter.

or maybe you want to permit different interpreters used in the
``steps`` scripts and want to add a shebang to each script that
does not have one already.  quick, what is your solution?

this is XML all over again: for every use of XSLT to manipulate XML
files there's hundreds of brittle hacks employing the standard
line-oriented tools like `cut(1)`, `grep(1)`, `sed(1)`.

the only use made easier by having it all in a single structured file
is viewing the information in a web browser (github, etc), and i claim
that this is a *bad deal*: breakage is introduced by poorly performed
modifications, not by reduced comfort in viewing the contents.

what is the alternative?  let's represent the information as a tree
of directories and files.  ``tree -F`` output gives us partial
information already, no effort there either::

  pkg/
  ├── archs/
  │   └── noarch
  ├── blurb
  ├── depends/
  │   ├── build/
  │   │   ├── basexy
  │   │   └── make
  │   ├── check/
  │   │   ├── basexy
  │   │   ├── cram
  │   │   └── make
  │   └── run/
  │       └── basexy
  ├── group
  ├── homepage
  ├── licenses/
  │   └── MIT
  ├── maintainer
  ├── name
  ├── sources/
  │   └── v0.3.tar.gz
  ├── steps/
  │   ├── build
  │   ├── check
  │   ├── install
  │   └── prep
  └── version

recreating the YAML representation is as "difficult" as spending
fifteen minutes to write this viewer::

  #!/bin/sh

  heading()
  {
    local i=$1 n=$2
    printf "%*s:\n" $i "$n"
  }

  scalar()
  {
    local i=$1 n=$2 f=$3
    printf "%*s%s: %s\n" $i '' $n "$(cat $f)"
  }

  literal()
  {
    local i=$1 n=$2 f=$3 l=
    printf "%*s%s: |\n" $i '' $n
    cat $f | while read l; do
      printf "%*s%s\n" $(($i + 2)) '' "$l"
    done
  }

  list()
  {
    local i=$1 n=$2 f=$3
    local ii=$(printf '%*s' $(($i + 2)) '')
    printf "%*s%s:\n" $i '' $n
    ls $f | sed "s/^/$ii- /"
  }

  heading 0 pkg
    scalar 2 name $1/name
    scalar 2 version $1/version
    scalar 2 maintainer $1/maintainer
    scalar 2 homepage $1/homepage
    list 2 licenses $1/licenses
    scalar 2 group $1/group
    list 2 sources $1/sources
    list 2 archs $1/archs
    literal 2 blurb $1/blurb
    heading 2 depends
      for s in build check run; do
        [ -e $1/depends/$s ] || continue
        list 4 $s $1/depends/$s
      done
    heading 2 steps
      for s in prep build check install; do
        [ -e $1/steps/$s ] || continue
        literal 4 $s $1/steps/$s
      done

what about the changes we've had to do to the package descriptions?
to introduce shebangs where they're not already present::

  find */steps/ | while read s; do
    [ "#!" != "$(head -c 2 $s)" ]] || continue
    { printf "#!/bin/sh\n"; cat $s; } > $s.tmp
    mv $s.tmp $s
  done

and removing make from build dependencies of all packages? ::

   rm */depends/build/make


the quip that "computers are good at solving problems that wouldn't
exist if we didn't have computers" misses the point: we're good at
creating problems and makework for ourselves by misusing computers.
