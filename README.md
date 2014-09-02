Qooxdoo&Mojolicious App Generator
=================================

[![Build Status](https://travis-ci.org/oetiker/qx-mojo-app.svg?branch=master)](https://travis-ci.org/oetiker/qx-mojo-app)
[![Coverage Status](https://img.shields.io/coveralls/oetiker/qx-mojo-app.svg)](https://coveralls.io/r/oetiker/qx-mojo-app?branch=master)

A Mojolicious generator template for creating JavaScript webapplications.

With qx-mojo-app you can create web app with a server part written in perl
and a client part written in javascript using the qooxdoo framework.

The app comes complete with an automake configure system, ready for distribution.

Quickstart
----------

```
PREFIX=$HOME/opt/mojolicious
export PERL_CPANM_HOME=$PREFIX
export PERL_CPANM_OPT="--local-lib $PREFIX"
export PERL5LIB=$PREFIX/lib/perl5
export PATH=$PREFIX/bin:$PATH
curl -L cpanmin.us \
  | perl - -n https://github.com/oetiker/qx-mojo-app/archive/master.tar.gz
mkdir -p ~/src
cd ~/src
mojo generate qx_mojo_app Demo
cd demo
```

Et voilà, you are looking at your first Qooxdoo/Mojolicious app. Have a look
at the README in the demo directory for further instructions.


Enjoy

Tobi Oetiker <tobi@oetiker.ch>
