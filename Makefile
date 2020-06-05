build:
	./node_modules/.bin/watchify \
		-t coffeeify \
  	-g uglifyify \
  	--extension=".coffee" \
  	--detect-globals 0 \
  	--no-builtins \
		src/main.coffee \
		-o build/main.js

build-css:
	./node_modules/.bin/stylus \
		-w -o build \
		src/styles.styl

build-debug:
	./node_modules/.bin/watchify \
		-t coffeeify \
  	--extension=".coffee" \
  	--detect-globals 0 \
		src/main.coffee \
		-d \
		-o build/main.js

build-css-debug:
	./node_modules/.bin/stylus \
		-w -o build \
		-m \
		src/styles.styl

.PHONY: build
