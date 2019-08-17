LAST_TAG := $(shell git describe --abbrev=0)
PREV_TAG := $(shell git describe --abbrev=0 $(LAST_TAG)^ 2>/dev/null || [ ])
TAGS := $(if $(PREV_TAG),$(PREV_TAG)..$(LAST_TAG),$(LAST_TAG))
NUMBER_OF_COMMITS := $(shell git rev-list --count $(TAGS))

all: clean create-zip whats-new

clean:
	rm -f hackintosh_dell_7577*.zip

create-zip:
	zip -r hackintosh_dell_7577_$(LAST_TAG).zip \
	Post-Install\ Files Scripts USB\ Files

whats-new:
	@echo "\n"
	@echo "Since the last release there have been $(NUMBER_OF_COMMITS) commit(s). \
	The descriptions for the first (at most) 10 of these are as follows"
	@echo ""
	@git --no-pager log $(TAGS) --pretty=format:'- %s' | head -n 10
	@echo ""
