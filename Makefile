#
# For profiling/debug builds use:
#
# make CFLAGS="" STRIP=touch JCFLAGS="-Xlint:all"
# JFLAGS="-Xrunhprof:heap=sites,cpu=samples,monitor=y,thread=y,doe=y -classic" check
#

# Variables controlling compilation. May be overridden on the command line for
# debug builds etc

# Programs
JAVAC?=javac
JAVA?=java
JAVAH?=javah
JAVADOC?=javadoc
JAR?=jar
MAKE?=make
CC?=gcc
LD?=ld
STRIP?=strip

# Program parameters
INCLUDES?=`pkg-config --cflags dbus-1` -I${JAVA_HOME}/include -I${JAVA_HOME}/include/linux
CFLAGS?= -Os -Wall -Werror -pedantic -std=c99
CFLAGS+=$(INCLUDES)
CFLAGS+=$(call cc-option,-fno-stack-protector,)
LIBS?=`pkg-config --libs dbus-1`
CPFLAG?=-classpath
JCFLAGS?=-Xlint:all -O -g:none
JCFLAGS+=-cp classes:$(CLASSPATH)
JFLAGS+=-Djava.library.path=.:$(DBUSLIBDIR)

# Source/Class locations
SRCDIR=org/freedesktop
CLASSDIR=classes/org/freedesktop/dbus

# Installation variables. Controls the location of make install.  May be
# overridden in the make command line to install to different locations
#
PREFIX?=/usr/local
JARPREFIX?=$(PREFIX)/share/java
LIBPREFIX?=$(PREFIX)/lib/jni
BINPREFIX?=$(PREFIX)/bin
DOCPREFIX?=$(PREFIX)/share/doc/libdbus-java
MANPREFIX?=$(PREFIX)/share/man/man1

# Installation directory of the D-Bus libraries
DBUSLIBDIR?=/usr/lib

# Version numbering
VERSION = 1.13
RELEASEVERSION = 1.12

# Usage: cflags-y += $(call cc-option, -march=winchip-c6, -march=i586)
cc-option = $(shell if $(CC) $(1) -S -o /dev/null -xc /dev/null \
> /dev/null 2>&1; then echo "$(1)"; else echo "$(2)"; fi ;)
 
all: libdbus-java.so libdbus-java-$(VERSION).jar dbus-java-viewer-$(VERSION).jar bin/ListDBus bin/CreateInterface bin/DBusViewer

clean:
	rm -rf doc bin classes
	rm -f *.1 *.o *.so *.h .dist .classes .testclasses .doc *.jar *.log pid address tmp-session-bus *.gz .viewerclasses .bin
	rm -rf libdbus-$(VERSION)
	rm -rf libdbus-$(RELEASEVERSION)
	
classes: .classes
testclasses: .testclasses
viewerclasses: .viewerclasses
.testclasses: $(SRCDIR)/dbus/test/*.java .classes
	mkdir -p classes
	$(JAVAC) -d classes $(JCFLAGS) $(SRCDIR)/dbus/test/*.java
	touch .testclasses 
.viewerclasses: $(SRCDIR)/dbus/viewer/*.java .classes
	mkdir -p classes
	$(JAVAC) -d classes $(JCFLAGS) $(SRCDIR)/dbus/viewer/*.java
	touch .viewerclasses 
.classes: $(SRCDIR)/*.java $(SRCDIR)/dbus/*.java  
	mkdir -p classes
	$(JAVAC) -d classes $(JCFLAGS) $^
	touch .classes

org_freedesktop_dbus_DBusConnection.h: .classes
	$(JAVAH) -classpath classes:$(CLASSPATH) -d . org.freedesktop.dbus.DBusConnection
	touch $@
org_freedesktop_dbus_DBusErrorMessage.h: .classes
	$(JAVAH) -classpath classes:$(CLASSPATH) -d . org.freedesktop.dbus.DBusErrorMessage
	touch $@
org_freedesktop_dbus_MethodCall.h: .classes
	$(JAVAH) -classpath classes:$(CLASSPATH) -d . org.freedesktop.dbus.MethodCall
	touch $@
dbus-java.o: dbus-java.c org_freedesktop_dbus_DBusConnection.h org_freedesktop_dbus_DBusErrorMessage.h org_freedesktop_dbus_MethodCall.h
	$(CC) $(CFLAGS) -fpic -c $< -o $@

libdbus-java.so: dbus-java.o
	$(LD) $(LDFLAGS) -fpic -shared -o $@ $^ $(LIBS)
	$(STRIP) $@
libdbus-java-$(VERSION).jar: .classes
	(cd classes; $(JAR) -cf ../$@ org/freedesktop/dbus/*.class org/freedesktop/*.class)
dbus-java-test-$(VERSION).jar: .testclasses
	(cd classes; $(JAR) -cf ../$@ org/freedesktop/dbus/test/*.class)
dbus-java-viewer-$(VERSION).jar: .viewerclasses
	(cd classes; $(JAR) -cf ../$@ org/freedesktop/dbus/viewer/*.class)
	
jar: libdbus-java-$(VERSION).jar
doc: doc/dbus-java.dvi doc/dbus-java.ps doc/dbus-java.pdf doc/dbus-java/index.html doc/api/index.html
.doc:
	mkdir -p doc
	mkdir -p doc/dbus-java
	touch .doc
.bin:
	mkdir -p bin
	touch .bin
doc/dbus-java.dvi: dbus-java.tex .doc
	(cd doc; latex ../dbus-java.tex)
	(cd doc; latex ../dbus-java.tex)
	(cd doc; latex ../dbus-java.tex)
doc/dbus-java.ps: doc/dbus-java.dvi .doc
	(cd doc; dvips -o dbus-java.ps dbus-java.dvi)
doc/dbus-java.pdf: doc/dbus-java.dvi .doc
	(cd doc; pdflatex ../dbus-java.tex)
doc/dbus-java/index.html: dbus-java.tex .doc
	mkdir -p doc/dbus-java/
	(cd doc/dbus-java; TEX4HTENV=/etc/tex4ht/tex4ht.env htlatex ../../dbus-java.tex "xhtml,2" "" "-cvalidate")
	rm -f doc/dbus-java/*{4ct,4tc,aux,dvi,idv,lg,log,tmp,xref}
	cp doc/dbus-java/dbus-java.html doc/dbus-java/index.html
doc/api/index.html: $(SRCDIR)/*.java $(SRCDIR)/dbus/*.java .doc
	$(JAVADOC) -quiet -author -link http://java.sun.com/j2se/1.5.0/docs/api/  -d doc/api $(SRCDIR)/*.java $(SRCDIR)/dbus/*.java 

%.1: %.sgml
	docbook-to-man $< > $@
	
bin/%: %.sh .bin
	sed 's,\%JARPATH\%,$(JARPREFIX),;s,\%LIBPATH\%,$(LIBPREFIX),;s,\%DBUSLIBPATH\%,$(DBUSLIBDIR),' < $< > $@

testrun: libdbus-java.so libdbus-java-$(VERSION).jar dbus-java-test-$(VERSION).jar
	$(JAVA) $(JFLAGS) $(CPFLAG) $(CLASSPATH):libdbus-java-$(VERSION).jar:dbus-java-test-$(VERSION).jar org.freedesktop.dbus.test.test

cross-test-server: libdbus-java.so libdbus-java-$(VERSION).jar dbus-java-test-$(VERSION).jar
	$(JAVA) $(JFLAGS) $(CPFLAG) $(CLASSPATH):libdbus-java-$(VERSION).jar:dbus-java-test-$(VERSION).jar org.freedesktop.dbus.test.cross_test_server

cross-test-client: libdbus-java.so libdbus-java-$(VERSION).jar dbus-java-test-$(VERSION).jar
	$(JAVA) $(JFLAGS) $(CPFLAG) $(CLASSPATH):libdbus-java-$(VERSION).jar:dbus-java-test-$(VERSION).jar org.freedesktop.dbus.test.cross_test_client

two-part-server: libdbus-java.so libdbus-java-$(VERSION).jar dbus-java-test-$(VERSION).jar
	$(JAVA) $(JFLAGS) $(CPFLAG) $(CLASSPATH):libdbus-java-$(VERSION).jar:dbus-java-test-$(VERSION).jar org.freedesktop.dbus.test.two_part_test_server

two-part-client: libdbus-java.so libdbus-java-$(VERSION).jar dbus-java-test-$(VERSION).jar
	$(JAVA) $(JFLAGS) $(CPFLAG) $(CLASSPATH):libdbus-java-$(VERSION).jar:dbus-java-test-$(VERSION).jar org.freedesktop.dbus.test.two_part_test_client

profilerun: libdbus-java.so libdbus-java-$(VERSION).jar dbus-java-test-$(VERSION).jar
	$(JAVA) $(JFLAGS) $(CPFLAG) $(CLASSPATH):libdbus-java-$(VERSION).jar:dbus-java-test-$(VERSION).jar org.freedesktop.dbus.test.profile $(PROFILE)

viewer: libdbus-java.so libdbus-java-$(VERSION).jar dbus-java-viewer-$(VERSION).jar
	$(JAVA) $(JFLAGS) $(CPFLAG) $(CLASSPATH):libdbus-java-$(VERSION).jar:dbus-java-viewer-$(VERSION).jar org.freedesktop.dbus.viewer.DBusViewer

check:
	( PASS=false; \
	  dbus-daemon --config-file=tmp-session.conf --print-pid --print-address=5 --fork >pid 5>address ; \
	  export DBUS_SESSION_BUS_ADDRESS=$$(cat address) ;\
	  dbus-monitor &> monitor.log & \
	  if $(MAKE) testrun ; then export PASS=true; fi  ; \
	  kill $$(cat pid) ; \
	  if [[ "$$PASS" == "true" ]]; then exit 0; else exit 1; fi )

cross-test-compile: libdbus-java.so libdbus-java-$(VERSION).jar dbus-java-test-$(VERSION).jar

internal-cross-test: libdbus-java.so libdbus-java-$(VERSION).jar dbus-java-test-$(VERSION).jar
	( dbus-daemon --config-file=tmp-session.conf --print-pid --print-address=5 --fork >pid 5>address ; \
	  export DBUS_SESSION_BUS_ADDRESS=$$(cat address) ;\
	  $(MAKE) -s cross-test-server > server.log &\
	  $(MAKE) -s cross-test-client > client.log ;\
	  kill $$(cat pid) ; )

two-part-test: libdbus-java.so libdbus-java-$(VERSION).jar dbus-java-test-$(VERSION).jar
	( dbus-daemon --config-file=tmp-session.conf --print-pid --print-address=5 --fork >pid 5>address ; \
	  export DBUS_SESSION_BUS_ADDRESS=$$(cat address) ;\
	  $(MAKE) -s two-part-server | tee server.log &\
	  sleep 1;\
	  $(MAKE) -s two-part-client | tee client.log ;\
	  kill $$(cat pid) ; )

profile:
	( PASS=false; \
	  dbus-daemon --config-file=tmp-session.conf --print-pid --print-address=5 --fork >pid 5>address ; \
	  export DBUS_SESSION_BUS_ADDRESS=$$(cat address) ;\
	  if $(MAKE) profilerun ; then export PASS=true; fi  ; \
	  kill $$(cat pid) ; \
	  if [[ "$$PASS" == "true" ]]; then exit 0; else exit 1; fi )

uninstall: 
	rm -f $(DESTDIR)$(JARPREFIX)/dbus.jar $(DESTDIR)$(JARPREFIX)/dbus-$(VERSION).jar $(DESTDIR)$(JARPREFIX)/dbus-viewer.jar $(DESTDIR)$(JARPREFIX)/dbus-viewer-$(VERSION).jar
	rm -f $(DESTDIR)$(LIBPREFIX)/libdbus-java.so
	rm -rf $(DESTDIR)$(DOCPREFIX)
	rm -f $(DESTDIR)$(MANPREFIX)/CreateInterface.1 $(DESTDIR)$(MANPREFIX)/ListDBus.1  $(DESTDIR)$(MANPREFIX)/DBusViewer.1
	rm -f $(DESTDIR)$(BINPREFIX)/CreateInterface $(DESTDIR)$(BINPREFIX)/ListDBus  $(DESTDIR)$(BINPREFIX)/DBusViewer

install: dbus-java-viewer-$(VERSION).jar libdbus-java-$(VERSION).jar libdbus-java.so bin/CreateInterface bin/ListDBus bin/DBusViewer 
	install -d $(DESTDIR)$(JARPREFIX)
	install -m 644 libdbus-java-$(VERSION).jar $(DESTDIR)$(JARPREFIX)/dbus-$(VERSION).jar
	install -m 644 dbus-java-viewer-$(VERSION).jar $(DESTDIR)$(JARPREFIX)/dbus-viewer-$(VERSION).jar
	ln -sf dbus-$(VERSION).jar $(DESTDIR)$(JARPREFIX)/dbus.jar
	ln -sf dbus-viewer-$(VERSION).jar $(DESTDIR)$(JARPREFIX)/dbus-viewer.jar
	install -d $(DESTDIR)$(LIBPREFIX)
	install libdbus-java.so $(DESTDIR)$(LIBPREFIX)
	install -d $(DESTDIR)$(BINPREFIX)
	install bin/DBusViewer $(DESTDIR)$(BINPREFIX)
	install bin/CreateInterface $(DESTDIR)$(BINPREFIX)
	install bin/ListDBus $(DESTDIR)$(BINPREFIX)

install-man: CreateInterface.1 ListDBus.1 DBusViewer.1 changelog AUTHORS COPYING README INSTALL
	install -d $(DESTDIR)$(DOCPREFIX)
	install -m 644 changelog $(DESTDIR)$(DOCPREFIX)
	install -m 644 COPYING $(DESTDIR)$(DOCPREFIX)
	install -m 644 AUTHORS $(DESTDIR)$(DOCPREFIX)
	install -m 644 README $(DESTDIR)$(DOCPREFIX)
	install -m 644 INSTALL $(DESTDIR)$(DOCPREFIX)
	install -d $(DESTDIR)$(MANPREFIX)
	install -m 644 CreateInterface.1 $(DESTDIR)$(MANPREFIX)/CreateInterface.1
	install -m 644 ListDBus.1 $(DESTDIR)$(MANPREFIX)/ListDBus.1
	install -m 644 DBusViewer.1 $(DESTDIR)$(MANPREFIX)/DBusViewer.1

install-doc: doc 
	install -d $(DESTDIR)$(DOCPREFIX)
	install -m 644 doc/dbus-java.dvi $(DESTDIR)$(DOCPREFIX)
	install -m 644 doc/dbus-java.ps $(DESTDIR)$(DOCPREFIX)
	install -m 644 doc/dbus-java.pdf $(DESTDIR)$(DOCPREFIX)
	install -d $(DESTDIR)$(DOCPREFIX)/dbus-java
	install -m 644 doc/dbus-java/*.html $(DESTDIR)$(DOCPREFIX)/dbus-java
	install -m 644 doc/dbus-java/*.css $(DESTDIR)$(DOCPREFIX)/dbus-java
	install -d $(DESTDIR)$(DOCPREFIX)/api
	cp -a doc/api/* $(DESTDIR)$(DOCPREFIX)/api

dist: .dist
.dist: bin dbus-java.c dbus-java.tex Makefile org tmp-session.conf CreateInterface.sgml ListDBus.sgml DBusViewer.sgml changelog AUTHORS COPYING README INSTALL
	mkdir -p libdbus-java-$(VERSION)
	cp -fa $^ libdbus-java-$(VERSION)
	touch .dist
tar: libdbus-java-$(VERSION).tar.gz

distclean:
	rm -rf libdbus-java-$(VERSION)
	rm -rf libdbus-java-$(VERSION).tar.gz
	rm -f .dist

libdbus-java-$(VERSION): .dist

libdbus-java-$(VERSION).tar.gz: .dist
	tar zcf $@ libdbus-java-$(VERSION)
	
libdbus-java-$(RELEASEVERSION).tar.gz: bin dbus-java.c dbus-java.tex Makefile org tmp-session.conf CreateInterface.sgml ListDBus.sgml DBusViewer.sgml changelog AUTHORS COPYING README INSTALL
	mkdir -p libdbus-java-$(RELEASEVERSION)/
	cp -fa $^ libdbus-java-$(RELEASEVERSION)/
	tar zcf $@ libdbus-java-$(RELEASEVERSION)

