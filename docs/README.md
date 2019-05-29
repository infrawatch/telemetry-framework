# Telemetry Framework Documentation

You can build the documentation locally by running `make` in the docs
directory.

If you're hacking on the documentation, you can also run a local, live
(auto-refreshing) host using `sphinx-autobuild`. First install
`sphinx-autobuild` through `pip` or your local package management system.

    sudo dnf install python2-sphinx_rtd_theme python2-sphinx python2-sphinx-autobuild

Then run this from the top level directory (root repository, not from the
`docs/` subdirectory)

    sphinx-autobuild docs/ docs/_build/html/

