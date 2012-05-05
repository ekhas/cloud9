.PHONY:    apf ext worker mode theme package test

UNAME := $(shell uname)

# don't know what the uname values are for other platforms
ifeq ($(UNAME), Darwin)
	nodeToUse := "node-darwin"
endif
ifeq ($(UNAME), SunOS)
	nodeToUse := "node-sunos"
endif

# packages apf
apf:
	cd node_modules/packager; sm update; node package.js projects/apf_cloud9.apr
	cd node_modules/packager; cat build/apf_release.js | sed 's/\(\/\*FILEHEAD(\).*\/apf\/\(.*\)/\1\2/g' > ../../plugins-client/lib.apf/www/apf-packaged/apf_release.js

# package debug version of apf
apfdebug:
	cd node_modules/packager/projects; cat apf_cloud9.apr | sed 's/<p:define name=\"__DEBUG\" value=\"0\" \/>/<p:define name=\"__DEBUG\" value=\"1\" \/>/g' > apf_cloud9_debug2.apr
	cd node_modules/packager/projects; cat apf_cloud9_debug2.apr | sed 's/apf_release/apf_debug/g' > apf_cloud9_debug.apr; rm apf_cloud9_debug2.apr
	cd node_modules/packager; sm update; node package.js projects/apf_cloud9_debug.apr
	cd node_modules/packager; cat build/apf_debug.js | sed 's/\(\/\*FILEHEAD(\).*\/apf\/\(.*\)/\1\2/g' > ../../client/js/apf_debug.js

# packages core
core:
	mkdir -p build/
	node r.js -o build/core.build.js

# generates packed template
helper: 
	mkdir -p build/
	node build/packed_helper.js

# packages ext
ext: 
	node r.js -o build/app.build.js
	echo "module = {exports: undefined};" | cat - plugins-client/lib.packed/www/packed.js > temp_file && mv temp_file plugins-client/lib.packed/www/packed.js

# calls dryice on worker & packages it
worker:
	mkdir -p client/js/worker
	./Makefile.dryice.js worker
	cp support/ace/build/src/worker* client/js/worker/
	node r.js -o name=./client/js/worker/worker.js out=./client/js/worker.js baseUrl=.

# copies built ace modes
mode:
	mkdir -p client/js/mode
	cp `find support/ace/build/src | grep -E "mode-[a-zA-Z_]+.js"`  client/js/mode

# copies built ace themes
theme:
	mkdir -p client/js/theme
	cp `find support/ace/build/src | grep -E "theme-[a-zA-Z_]+.js"` client/js/theme

package: apf ext worker mode theme

test:
	$(MAKE) -C test



package:
	node support/packager/package.js apf_cloud9.apr
	#git add client/js/apf_release.js
	#git commit -m "new apf_release.js"

worker2:
	mkdir -p plugins-client/cloud9.core/www/js/worker
	rm -rf /tmp/c9_worker_build
	mkdir -p /tmp/c9_worker_build/ext
	ln -s `pwd`/plugins-client/ext.language /tmp/c9_worker_build/ext/language
	ln -s `pwd`/plugins-client/ext.codecomplete /tmp/c9_worker_build/ext/codecomplete
	ln -s `pwd`/plugins-client/ext.jslanguage /tmp/c9_worker_build/ext/jslanguage
	./Makefile.dryice.js worker
	cp support/ace/build/src/worker* plugins-client/cloud9.core/www/js/worker
