REBAR = $(CURDIR)/rebar3
REBAR_VERSION = 3.14.3-emqx-7

.PHONY: all
all: release

release: compile
	$(REBAR) as emqtt_bench release,tar
	@$(CURDIR)/scripts/rename-package.sh

compile: $(REBAR) unlock
	$(REBAR) compile

.PHONY: unlock
unlock:
	$(REBAR) unlock

.PHONY: clean
clean: distclean

.PHONY: distclean
distclean:
	@rm -rf _build erl_crash.dump rebar3.crashdump rebar.lock emqtt_bench

.PHONY: xref
xref: compile
	$(REBAR) xref

.PHONY: docker
docker:
	@docker build --no-cache -t emqtt_bench:$$(git describe --tags --always) .

.PHONY: ensure-rebar3
ensure-rebar3:
	@$(CURDIR)/scripts/ensure-rebar3.sh $(REBAR_VERSION)

$(REBAR): ensure-rebar3
