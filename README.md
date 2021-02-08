## mix petal.new

Provides `petal.new` installer as an archive.

To install from hex, run:

    $ mix archive.install hex petal_new 1.5.0

To build and install it locally,
ensure any previous archive versions are removed:

    $ mix archive.uninstall petal_new

Then run:

    $ cd installer
    $ MIX_ENV=prod mix do archive.build, archive.install
