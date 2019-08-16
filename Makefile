LAST_TAG := $(shell git describe --abbrev=0)

all: clean create-zip

clean:
	rm -f hackintosh_dell_7577*.zip

create-zip:
	zip -r hackintosh_dell_7577_$(LAST_TAG).zip \
	Post-Install\ Files Scripts USB\ Files
