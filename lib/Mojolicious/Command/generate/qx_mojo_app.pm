package Mojolicious::Command::generate::qx_mojo_app;
use Mojo::Base 'Mojolicious::Command';

use Mojo::Util qw(class_to_file class_to_path slurp);
use POSIX qw(strftime);

our $VERSION = '0.1';

has description => 'Generate Qooxdoo Mojolicious web application directory structure.';
has usage => sub { shift->extract_usage };

sub run {
    my ($self, $class) = @_;
    $class ||= 'MyApp';

    # Prevent bad applications
    die <<EOF unless $class =~ /^[A-Z](?:\w|::)+$/;
Your application name has to be a well formed (CamelCase) Perl module name
like "MyApp".
EOF

    my $name = class_to_file $class;
    my $class_path = class_to_path $class;
    my $controller = "${class}::Controller::RpcService";
    my $controller_path = class_to_path $controller;

    # Configure Main Dir
    my $file = {
        configure => 'configure.ac',
        bootstrap => 'bootstrap',
        PERL_MODULES => 'PERL_MODULES',
        VERSION => 'VERSION',
        README => 'README',
        AUTHOR => 'AUTHOR',
        LICENSE => 'LICENSE',
        COPYRIGHT => 'COPYRIGHT',
        CHANGES => 'CHANGES',
        MakefileAm => 'Makefile.am',
        backMakefileAm => 'backend/Makefile.am',
        script => 'backend/bin/'.$name.'.pl',
        script_src => 'backend/bin/'.$name.'-source-mode.sh',
        appclass => 'backend/lib/'.$class_path,
        service => 'backend/lib/'.$controller_path,
        frontMakefileAm => 'frontend/Makefile.am',
        manifestJson => 'frontend/Manifest.json',
        configJson => 'frontend/config.json',
        applicationJs => 'frontend/source/class/'.$name.'/Application.js',
        indexHtml => 'frontend/source/index.html',
        serviceJs => 'frontend/source/class/'.$name.'/data/RpcService.js',
        test => 't/basic.t',
    };
    my ($userName,$fullName) = (getpwuid $<)[0,6];
    $fullName =~ s/,.+//g;
    chomp(my $domain = `hostname -d`);
    my $email = $userName.'@'.$domain;

    if ( -r $ENV{HOME} . '/.gitconfig' ){
        my $in = slurp $ENV{HOME} . '/.gitconfig';
        $in =~ /name\s*=\s*(\S.+\S)/ and $fullName = $1;
        $in =~ /email\s*=\s*(\S+)/ and $email = $1;
    }

    for my $key (keys %$file){
        $self->render_to_rel_file($key, $name.'/'.$file->{$key}, { 
            class => $class,
            name => $name,
            class_path => $class_path,
            controller => $controller,
            controller_path => $controller_path,
            year => (localtime time)[5]+1900,
            email => $email,
            fullName => $fullName,
            userName => $userName,
            date => strftime('%Y-%M-%D',localtime(time)),
        });
    }

    $self->chmod_rel_file("$name/bootstrap", 0755);
    $self->chmod_rel_file("$name/backend/bin/".$name.".pl", 0755);
    $self->chmod_rel_file("$name/backend/bin/".$name."-source-mode.sh", 0755);

    $self->create_rel_dir("$name/backend/log");
    $self->create_rel_dir("$name/backend/public");
    $self->create_rel_dir("$name/frontend/source/resource/$name");
    $self->create_rel_dir("$name/frontend/source/translation");
    chdir $name;
    system "./bootstrap";
}

1;
__DATA__
@@ README
% ######################################################################################
% ######################################################################################
% my $p = shift;
<%= $p->{class} %>
===========
Version: #VERSION#
Date: #DATE#

<%= $p->{class} %> is an cool web application.

Setup
-----

You are looking at a template for creating a qooxdoo application with
a mojolicious backend. It is a classic configure make install setup.
Get a copy of the qooxdoo sdk from www.qooxdoo.org

 ./configure --prefix=$HOME/opt/<%= $p->{name} %> --with-qooxdoo-sdk=$HOME/sdk/qooxdoo-4.0.1-sqk

Configure will check if the necessary items are in place and give
hints on how to fix the situation if something is missing.

Development
-----------

While developing the application it is conveniant to NOT have to install it
before runnning. You can actually server the qooxdoo source directly
using the mojo webserver.

  cd frontend && make source
  cd backend/bin
  ./<%= $p->{name} %>-source-mode.sh daemon

You can now connect to the mojolicious server with your webbrowser.

Installation
------------

To install the application, just run

   make install

You can now run <%= $p->{name} %>.pl in reverse proxy mode.

Packaging
---------

You can also package the application as a nice tar.gz file by running

   make dist

Learning
--------

To learn more about qooxdoo, go to their website. And read up on Qoodoo desktop:

  www.qooxdoo.org

Enjoy!

Tobi Oetiker <tobi@oetiker.ch>
@@ configure
% ######################################################################################
% ######################################################################################
% my $p = shift;

#  Copyright (C) <%= $p->{year} %> <%= $p->{fullName} %>

AC_INIT([extopus],m4_esyscmd([tr -d '\n' < VERSION]),[<%= $p->{email} %>])
AC_PREREQ([2.59])
AC_CONFIG_AUX_DIR(conftools)


# need this to allow long path names
AM_INIT_AUTOMAKE([1.9 tar-ustar foreign])
AM_MAINTAINER_MODE

m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])

AC_PREFIX_DEFAULT(/opt/$PACKAGE_NAME-$PACKAGE_VERSION)

AC_ARG_VAR(PERL,   [Path to local perl binary])
AC_PATH_PROG(PERL, perl, no)

ac_perl_version="5.10.1"

if test "x$PERL" != "x"; then
  AC_MSG_CHECKING(for perl version greater than or equal to $ac_perl_version)
  $PERL -e "use $ac_perl_version;" >/dev/null 2>&1
  if test $? -ne 0; then
    AC_MSG_RESULT(no);
    AC_MSG_ERROR(at least version 5.10.1 is required to run extopus)
  else
    AC_MSG_RESULT(ok);
  fi
else
  AC_MSG_ERROR(could not find perl)
fi

AC_PROG_GREP

AC_ARG_VAR(GMAKE,   [Path to local GNU Make binary])
AC_PATH_PROGS(GMAKE, [gnumake gmake make])

AC_MSG_CHECKING([checking for gnu make availablility])
if  ( $GMAKE --version 2> /dev/null | $GREP GNU  > /dev/null 2>&1 );  then
    AC_MSG_RESULT([$GMAKE is GNU make])
else
    AC_MSG_ERROR([GNU make not found. Try setting the GMAKE environment variable.])
fi

AC_ARG_ENABLE(pkgonly,
        AC_HELP_STRING([--enable-pkgonly],
                        [Skip all checking]))
AC_SUBST(enable_pkgonly)

actual_prefix=$prefix
if test x$actual_prefix = xNONE; then
    actual_prefix=$ac_default_prefix
fi

HTDOCSDIR=${actual_prefix}/htdocs
AC_ARG_WITH(htdocs-dir,AC_HELP_STRING([--with-htdocs-dir=DIR],[Where to install htdocs [PREFIX/htdocs]]), [HTDOCSDIR=$withval])
AC_SUBST(HTDOCSDIR)

QOOXDOO_PATH=
AC_ARG_WITH(qooxdoo-sdk,AC_HELP_STRING([--with-qooxdoo-sdk=DIR],[Where can we find the qooxdoo sdk (required to rebuild the web ui)]), [
        if test -d $withval/framework; then
             QOOXDOO_PATH=$withval
        else
        cat <<NOTES

** Aborting Configure *************************************
   
You specified --with-qooxdoo-sdk=DIR without pointing it
to a copy of the qooxdoo sdk. If you specify the option,
make sure there is a copy of the qooxdoo sdk present.
get your copy form www.qooxdoo.org.

NOTES
          exit 1
        fi
])

AC_SUBST(QOOXDOO_PATH)

AM_CONDITIONAL(BUILD_QOOXDOO_APP,[test x$QOOXDOO_PATH != x])

AC_ARG_VAR(PERL5LIB,   [Colon separated list of perl library directories])
AC_SUBST(PERL5LIB)

# Check the necessary Perl modules

mod_ok=1
if test "$enable_pkgonly" != yes; then
   for module in m4_esyscmd([cat PERL_MODULES | tr '\n' ' ' | sed 's/\@[^ ]*//g']); do 
     AC_MSG_CHECKING([checking for perl module '$module'])
     if ${PERL} -I$actual_prefix/thirdparty/lib/perl5 -e 'use '$module 2>/dev/null ; then
         AC_MSG_RESULT([Ok])
     else
         AC_MSG_RESULT([Failed])
         mod_ok=0
     fi
   done
fi


AC_CONFIG_FILES([
    Makefile
    backend/Makefile
    frontend/Makefile
])

AC_SUBST(VERSION)

AC_OUTPUT

if test x$QOOXDOO_PATH = x; then

    cat <<NOTES

** QOOXDOO SDK NOT INSTALLED **********************************
   
You did NOT specify the --with-qooxdoo-sdk configuration
option. This is fine if you got a packed version of this
application. If you are developping, you must have a copy
of the qooxdoo sdk installed or you will not be able to
build the javascript parts of your application.

NOTES
fi

if test x$mod_ok = x0; then
    cat <<NOTES

** SOME PERLMODULES ARE MISSING *******************************
   
If you know where perl can find the missing modules, set
the PERL5LIB environment variable accordingly.

You can also install a local copy of the perl modules by running

   $GMAKE get-thirdparty-modules

NOTES
fi

cat <<NOTES

** CONFIGRUE DONE **********************************************
   
Settings:

  PERL5LIB = ${PERL5LIB:-"not set"}
  PERL = $PERL

The Makefiles uses GNU make functionality.
Continue installation with

  $GMAKE install

NOTES

@@ CHANGES
% ######################################################################################
% ######################################################################################
% my $p = shift;
0.0.0 <%= "$p->{date}  $p->{fullName} ($p->{email})" %>

- started project

@@ bootstrap
% ######################################################################################
% ######################################################################################
#!/bin/sh
autoreconf --force --install --verbose --make
# EOF

@@ PERL_MODULES
% ######################################################################################
% ######################################################################################
Mojolicious
Mojolicious::Plugin::Qooxdoo

@@ VERSION
% ######################################################################################
% ######################################################################################
0.0.0

@@ AUTHOR
% ######################################################################################
% ######################################################################################
% my $p = shift;
<%= "$p->{fullName} <$p->{email}>" %>
@@ LICENSE
% ######################################################################################
% ######################################################################################
A COOL LICENSE FOR YOUR PROJECT

@@ COPYRIGHT
% ######################################################################################
% ######################################################################################
% my $p = shift;
<%= $p->{class} %>
a cool web app with mojolicious backend

Copyright (c) <%= $p->{year}." ".$p->{fullName} %> and the other people listed in the
AUTHORS file.

All rights reserved.

@@ MakefileAm
% ######################################################################################
% ######################################################################################
AUTOMAKE_OPTIONS =  foreign

SUBDIRS = frontend backend

EXTRA_DIST = VERSION PERL_MODULES COPYRIGHT LICENSE CHANGES AUTHORS

YEAR := $(shell date +%Y)
DATE := $(shell date +%Y-%m-%d)
THIRDPARTY := $(shell pwd)/backend/thirdparty

dist-hook:
	$(PERL) -i -p -e 's/#VERSION#/$(PACKAGE_VERSION)/g;s/#YEAR#/$(YEAR)/g;s/#DATE#/$(DATE)/g;'  $(distdir)/README $(distdir)/COPYRIGHT

get-thirdparty-modules:
	[ -e $(THIRDPARTY)/bin/cpanm ] || mkdir -p $(THIRDPARTY)/bin && wget --no-check-certificate -O $(THIRDPARTY)/bin/cpanm cpanmin.us && chmod 755 $(THIRDPARTY)/bin/cpanm
	cat PERL_MODULES | PERL_CPANM_HOME=$(THIRDPARTY) PERL_CPANM_OPT="--notest --local-lib $(THIRDPARTY)" xargs $(THIRDPARTY)/bin/cpanm

#END

@@ backMakefileAm
% ######################################################################################
% ######################################################################################
% my $p = shift;
AUTOMAKE_OPTIONS =  foreign

QX_CLASS = <%= $p->{name} %>
MJ_CLASS = <%= $p->{class} %>
MJ_SCRIPT = <%= $p->{name} %>

BIN = bin/$(MJ_SCRIPT).pl bin/$(MJ_SCRIPT)-source-mode.sh

PM :=  $(shell find lib/ thirdparty/lib/perl5 -name "*.pm")  $(shell test -f thirdparty && find thirdparty/lib/perl5 -type f) 

POD :=  $(shell find lib/ -name "*.pod")

RES :=  $(shell test -d public/resource && find public/resource -type f)        

TEMPL := $(shell test -d templates && find templates -type f)

PUB = public/script/$(QX_CLASS).js public/index.html $(RES)

EXTRA_DIST = $(wildcard t/*.t) $(ETC) $(BIN) $(PM) $(POD) $(PUB) $(TEMPL)

YEAR := $(shell date +%Y)
DATE := $(shell date +%Y-%m-%d)

datadir = $(prefix)
nobase_data_DATA = $(PM) $(POD) $(PUB) $(ETC) $(TEMPL)

dist_bin_SCRIPTS = $(BIN)

if BUILD_QOOXDOO_APP

public/script/$(QX_CLASS).js: $(shell find ../frontend/source/class/$(QX_CLASS) -name "*.js") $(QOOXDOO_PATH)/framework/config.json ../configure
	cd ../frontend && $(QOOXDOO_PATH)/tool/bin/generator.py -m QOOXDOO_PATH:$(QOOXDOO_PATH) -m CACHE:./cache -m BUILD_PATH:../backend/public build
	$(PERL) -i -p -e 's/#VERSION#/$(PACKAGE_VERSION)/g;s/#YEAR#/$(YEAR)/g;s/#DATE#/$(DATE)/g;' public/index.html public/script/$(QX_CLASS).js
         
endif
         
install-exec-hook:
	[ "$(PERL5LIB)" != "" ] && cd "$(DESTDIR)$(bindir)" && $(PERL) -i -p -e 's{.*# PERL5LIB}{use lib qw($(PERL5LIB)); # PERL5LIB}' *.pl || true
	cd "$(DESTDIR)$(bindir)" && $(PERL) -i -p -e 's{^#!.*perl.*}{#!$(PERL)};' *.pl

dist-hook:
	$(PERL) -i -p -e '"$(PACKAGE_VERSION)" =~ /(\d+)\.(\d+)\.(\d+)/ and $$v = sprintf("%d.%03d%03d",$$1,$$2,$$3) and s/^\$$VERSION\s+=\s+".+?"/\$$VERSION = "$$d"/;'  $(distdir)/lib/$(MJ_CLASS).pm


@@ script
% ######################################################################################
% ######################################################################################
% my $p = shift;
#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../thirdparty/lib/perl5";
use Mojolicious::Commands;

Mojolicious::Commands->start_app('<%= $p->{class} %>');
<%= '__END__' %>

@@ script_src
% ######################################################################################
% ######################################################################################
% my $p = shift;
#!/bin/sh
export QX_SRC_MODE=1
export MOJO_MODE=development
export MOJO_LOG_LEVEL=debug
exec ./<%= $p->{name} %>.pl prefork --listen 'http://*:<%= int(rand()*5000+3024) %>'

@@ appclass
% ######################################################################################
% ######################################################################################
% my $p = shift;
package <%= $p->{class} %>;

use Mojo::Base 'Mojolicious';

=head1 NAME

<%= $p->{class} %> - the mojolicious application class

=head1 SYNOPSIS

 use Mojolicious::Commands;
 Mojolicious::Commands->start_app('<%= $p->{class} %>');

=head1 DESCRIPTION

Configure the mojo engine to run our application logic as webrequests arrive.

=head1 ATTRIBUTES

All the attributes from L<Mojolicious>.

=cut

=head1 METHODS

All the methods of L<Mojolicious> as well as:

=cut

=head2 startup

Mojolicious calls the startup method at initialization time.

=cut

sub startup {
    my $app = shift;

    # $app->secrets(['my very own secret']);

    $app->plugin('qooxdoo',{
        path => '/jsonrpc',
        controller => 'RpcService'
    }); 
}

1;

<%= '__END__' %>

=head1 COPYRIGHT

Copyright (c) <%= $p->{year} %> by <%= $p->{fullName} %>. All rights reserved.

=head1 AUTHOR

S<<%= $p->{fullName} %> E<lt><%= $p->{email} %>E<gt>>

=cut

@@ service
% ######################################################################################
% ######################################################################################
% my $p = shift;
package <%= $p->{controller} %>;
use Mojo::Base qw(Mojolicious::Plugin::Qooxdoo::JsonRpcController);

=head1 NAME

<%= $p->{controller} %> - RPC services for <%= $p->{class} %>

=head1 SYNOPSIS

  $route->any("jsonrpc")->to(<%= $p->{controller} %>#dispatch");

=head1 DESCRIPTION

This controller handles the rpc calles from the qooxdoo frontend. 

=head1 ATTRIBUTES

All the attributes from L<Mojolicious::Plugin::Qooxdoo::JsonRpcController>.

=cut

=head1 METHODS

All the methods of L<Mojolicious::Plugin::Qooxdoo::JsonRpcController> as well as:

=cut

=head1 ATTRIBUTES

The controller the following attributes

=cut

=head2 service

the service property defines the name of the service

=cut

has service => sub { "<%= $p->{name} %>"};

has log => sub { shift->app->log };

=head1 METHODS

The controller provides the following methods

=cut

=head2 allow_rpc_access(method)

the dispatcher will call allow_rpc_access prior to handing over controll.

=cut

our %allow = (
    ping => 1,
    getUptime => 1,
    makeException => 1,
);


sub allow_rpc_access {
    my $self = shift;
    my $method = shift;
    return $allow{$method}; 
}
   

=head2 ping(text)

ping response

=cut

sub ping {
    my $self = shift;
    my $text = shift;
    $self->log->info("We got pinged");
    return 'got '.$text;
}

=head2 getUptime

return the output of uptime.

=cut  

sub getUptime {
    my $self = shift;    
    return `/usr/bin/uptime`;
}

=head2 makeException(code,message)

Create an exception.

=cut

sub makeException {
    my $self = shift;
    my $arg = shift;
    die Exception->new(code => $arg->{code}, message => $arg->{message} );
}

package Exception;

use Mojo::Base -base;
has 'code';
has 'message';
use overload ('""' => 'stringify');
sub stringify {
    my $self = shift;
    return "ERROR ".$self->code.": ".$self->message;
}

1;
<%= '__END__' %>

=head1 COPYRIGHT

Copyright (c) <%= $p->{year} %> by <%= $p->{fullName} %>. All rights reserved.

=head1 AUTHOR

S<<%= $p->{fullName} %> E<lt><%= $p->{email} %>E<gt>>

=cut

@@ frontMakefileAm
% ######################################################################################
% ######################################################################################
% my $p = shift;

AUTOMAKE_OPTIONS=foreign
CLASS=<%= $p->{name} %>

EXTRA_DIST = config.json Manifest.json source/index.html $(shell find source/class/ -name "*.js") $(wildcard source/translation/*.po source/resource/*/*.png  source/resource/*/*.gif)

if BUILD_QOOXDOO_APP

GENTARGETS := lint pretty migration translation api

.PHONY: $(GENTARGETS) source

source: source/script/$(CLASS).js

$(GENTARGETS):
	$(QOOXDOO_PATH)/tool/bin/generator.py -m QOOXDOO_PATH:$(QOOXDOO_PATH) -m CACHE:./cache $@
   
source/script/$(CLASS).js: $(shell find source/class/ -name "*.js")
	$(QOOXDOO_PATH)/tool/bin/generator.py -m QOOXDOO_PATH:$(QOOXDOO_PATH) -m CACHE:./cache source

endif

clean-local:
	test -d ./cache && rm -r ./cache || true
	test -f source/script/$(CLASS).js && rm source/script/* || true

@@ manifestJson
% ######################################################################################
% ######################################################################################
% my $p = shift;
{
  "info" : 
  {
    "name" : "<%= $p->{class} %>",

    "summary" : "<%= $p->{class} %> web app",
    "description" : "A generic qooxdoo mojo demo app.",
    
    "homepage" : "https://github.com/oetiker/qx-mojo-app",

    "license" : "???",
    "authors" : 
    [
      {
        "name" : "<%= "$p->{fullName} ($p->{userName})" %>",
        "email" : "<%= $p->{email} %>"
      }
    ],

    "version" : "#VERSION#",
    "qooxdoo-versions": ["4.0"]
  },
  
  "provides" : 
  {
    "namespace"   : "<%= $p->{name} %>",
    "encoding"    : "utf-8",
    "class"       : "source/class",
    "resource"    : "source/resource",
    "translation" : "source/translation",
    "type"        : "application"
  }
}

@@ configJson
% ######################################################################################
% ######################################################################################
% my $p = shift;
{
  "name"    : "<%= $p->{name} %>",

  "include" :
  [
    {
      "path" : "${QOOXDOO_PATH}/tool/data/config/application.json"
    }
  ],

  "let" :
  {
    "APPLICATION"  : "<%= $p->{name} %>",
    "QXTHEME"      : "qx.theme.Simple",
    "API_EXCLUDE"  : ["qx.test.*"],
    "LOCALES"      : [ "en" ],
    "CACHE"        : "./cache",
    "ROOT"         : "."
  }
}

@@ applicationJs
% ######################################################################################
% ######################################################################################
% my $p = shift;
/* ************************************************************************
   Copyright: <%= $p->{year} %> <%= $p->{fullName} %>
   License:   ???
   Authors:   <%= $p->{fullName} %> <<%= $p->{email} %>>
 *********************************************************************** */

/**
 * Main extopus application class.
 */
qx.Class.define("<%= $p->{name} %>.Application", {
    extend : qx.application.Standalone,

    members : {
        /**
         * Launch the extopus application.
         *
         * @return {void} 
         */
        main : function() {
            // Call super class
            this.base(arguments);

            // Enable logging in debug variant
            if (qx.core.Environment.get("qx.debug")) {
                // support native logging capabilities, e.g. Firebug for Firefox
                qx.log.appender.Native;

                // support additional cross-browser console. Press F7 to toggle visibility
                qx.log.appender.Console;
            }

            var root = this.getRoot();
            var layout = new qx.ui.layout.Grid(10, 20)
            var grid = new qx.ui.container.Composite(new qx.ui.layout.Grid(10, 20));
            root.add(grid, {
                left   : 20,
                top    : 20,
                right  : 20,
                bottom : 20
            });

            var rpc = <%= $p->{name} %>.data.RpcService.getInstance();
            
            /** Server Exception **************************************/
            grid.add(new qx.ui.basic.Label('Server Response:'),{ row: 0,column: 0});
            var serverException = new qx.ui.form.TextField().set({readOnly: true});
            grid.add(serverException,{row:0,column:1});

            /** Ping Button ****************************************/
            var pingButton = new qx.ui.form.Button("PingTest");
            grid.add(pingButton,{row: 1,column: 0});
            var pingText = new qx.ui.form.TextField();
            grid.add(pingText,{row: 1,column: 1});
            var pingResponse = new qx.ui.form.TextField().set({readOnly: true});
            grid.add(pingResponse,{row: 1,column: 2});

            pingButton.addListener('execute',function(){
                rpc.callAsync(function(data,exc) {
                    if (exc){
                        serverException.setValue('ERROR:' + exc.message + ' (' + exc.code +')');
                        return;
                    }
                    pingResponse.setValue(data);
                },'ping',pingText.getValue());
            });

            /** Uptime ****************************************/
            grid.add(new qx.ui.basic.Label('Uptime:'),{ row: 2,column: 0});
            var uptimeText = new qx.ui.form.TextField().set({ readOnly: true});
            grid.add(uptimeText,{row: 2,column: 1});
            var timer = new qx.event.Timer(10000);
            timer.addListener('interval',function(){
                rpc.callAsync(function(data,exc) {
                    if (exc){
                        serverException.setValue('ERROR:' + exc.message + ' (' + exc.code +')');
                        return;
                    }
                    uptimeText.setValue(data);
                },'getUptime');
            });
			timer.start();
            /** Trigger Exception ****************************************/
            var exButton = new qx.ui.form.Button("ExceptionTest");
            grid.add(exButton,{row: 3,column: 0});
            var exText = new qx.ui.form.TextField('Sample Exception');
            grid.add(exText,{row: 3,column: 1});
            var exCode = new qx.ui.form.TextField('343');
            grid.add(exCode,{row: 3,column: 2});

            exButton.addListener('execute',function(){
                rpc.callAsync(function(data,exc) {
                    if (exc){
                        serverException.setValue('ERROR:' + exc.message + ' (' + exc.code +')');
                        return;
                    }
                },'makeException',{message: exText.getValue(), code: exCode.getValue()});
            });
        }
    }
});

@@ serviceJs
% ######################################################################################
% ######################################################################################
% my $p = shift;
/* ************************************************************************
   Copyright: <%= $p->{year} %> <%= $p->{fullName} %>
   License:   ???
   Authors:   <%= $p->{fullName} %> <<%= $p->{email} %>>
************************************************************************ */
/**
 * initialize us an Rpc object with some extra thrills.
 */
qx.Class.define('<%= $p->{name} %>.data.RpcService', {
    extend : qx.io.remote.Rpc,
    type : "singleton",

    construct : function() {
        this.base(arguments);
        this.set({
            timeout     : 15000,
            url         : 'jsonrpc/',
            serviceName : '<%= $p->{name} %>'
        });
    }
});

@@ test
% ######################################################################################
% ######################################################################################
% my $p = shift;
#!/usr/bin/env perl
use FindBin;
use lib $FindBin::Bin.'/../backend/thirdparty/lib/perl5';
use lib $FindBin::Bin.'/../backend/lib';


use Test::More tests => 6;
use Test::Mojo;

use_ok '<%= $p->{class} %>';
use_ok '<%= $p->{controller} %>';

my $t = Test::Mojo->new('<%= $p->{class} %>');

$t->get_ok('/asdfasdf')->status_is(404);

$t->post_ok('/root/jsonrpc','{"id":1,"service":"<%= $p->{name} %>","method":"ping","params":["hello"]}')
  ->json_is('',{id=>1,result=>'hello'},'post request');

exit 0;

@@ indexHtml
% my $p = shift;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
  <!-- #VERSION# / #DATE# -->
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <link rel="SHORTCUT ICON" href="resource/<%= $p->{name} %>/favicon.ico"/>
  <title> Extopus </title>  
</head>
<body>
<div style="text-align: center; font-size: 30pt; right-margin: auto; margin-top: 100px">loading <%= $p->{Class} %> ...</div>
<script type="text/javascript" src="script/<%= $p->{name} %>.js?v=#VERSION#"></script>
</body>
</html>

__END__

=encoding utf8

=head1 NAME

Mojolicious::Command::generate::qx_mojo_app - App generator command

=head1 SYNOPSIS

  Usage: APPLICATION generate qx_mojo_app [NAME]

=head1 DESCRIPTION

L<Mojolicious::Command::generate::qx_mojo_app> generates application directory
structures for fully functional Qooxdoo web application with a L<Mojolicious> backend.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut

