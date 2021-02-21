## PETAL Stack

Provides a convinient `mix petal.new` command to create a new Phoenix project configured with Phoenix LiveView, AlpineJS and TailwindCSS.

## Installation
To install from hex, run:

    $ mix archive.install hex petal_new 1.5.7

To build and install it locally,
ensure any previous archive versions are removed:

    $ mix archive.uninstall petal_new

Then run:

    $ MIX_ENV=prod mix do archive.build, archive.install
