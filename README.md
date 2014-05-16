# Helium

Happy Haskell Hacking With [Atom](http://atom.io)

Helium is a tiny plugin that connects Atom to [ghc-mod](https://github.com/kazu-yamamoto/ghc-mod).
ghc-mod can check syntax, inspect the types of sub expressions and a bunch of other things.

Helium can show you errors in your code: (use `helium:check`)

![Compiler feedback](https://github.com/andyfriesen/Helium/raw/master/img/helium.png)

It can also fill in type annotations sometimes with `helium:insert-type`:

![Insert Type](https://github.com/andyfriesen/Helium/raw/master/img/helium-demo.gif)

You can also use the `helium:insert-import` command to insert an import into the top of the current document without
losing your current place.

# New in 0.3

* I fudged the version on an import.  Fixed.

# New in 0.2

* helium:insert-import can insert an import at the top of the currently open document.
* helium:check works on Literate Haskell.
* heilum:check does a better job of displaying errors that occur in files imported by the checked file.
* Do a better job of finding ghc-mod and running it from the correct working directory.

# Status

This project is very roughshod right now.  It is simultaneously a work in progress and a sort of dumping ground for me
to experiment with Atom's customization APIs.  It is stable enough to be useful for simple tasks, though.

# Installation

```shell
apm install helium
```

If you want to get the source directly (eg to hack on it (please, hack on it!)), you can just check it out into your
`~/.atom/packages` directory.  Then, start atom and run the `update-package-dependencies:update` command to pull in npm
dependencies.
