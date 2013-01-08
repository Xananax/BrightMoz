MXMLC = ~/opt/flex/bin/mxmlc -static-link-runtime-shared-libraries=true -library-path+=src/libs -target-player=11.5.0 -swf-version=17
DEBUG = -debug=true -define=CONFIG::debug,true -define=CONFIG::domain,"'*'" -define=CONFIG::insecure,true
NODEBUG = -debug=false -define=CONFIG::debug,false -define=CONFIG::domain,"'brightcove.com'" -define=CONFIG::insecure,false


all: noDebug debug

noDebug:
	$(MXMLC)  $(NODEBUG) src/Player.as -output bin/moz.swf

debug:
	$(MXMLC)  $(DEBUG) src/Player.as -output bin/moz_debug.swf
