all: clean build

clean:
	test -d output && rm -rf output && mkdir output

build:
	bin/build
