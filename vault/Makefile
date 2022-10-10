## Vault RISKS Makefile ##

SHELL=/bin/bash
VERSION = $(shell git describe --abbrev=0 --tags --always)

default:
	# Update the version line string
	sed -i 's#^.*\bversion\b.*$$#version: $(VERSION)#' src/bashly.yml
	
	# First generate the risk script from our source
	bashly generate
	
	# Remove set -e from the generated script
	# since we handle our errors ourselves
	sed -i 's/set -e//g' risks
