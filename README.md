Mojolicious::Command::generator::qx_mojo_app
============================================

A Mojlicious generator template for creating JavaScript webapplications.

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
