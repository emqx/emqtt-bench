
REBAR = $(CURDIR)/rebar3

REBAR_URL := https://github.com/emqx/rebar3/releases/download/3.14.3-emqx-7/rebar3

.PHONY: all
all: compile

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

$(REBAR):
ifneq ($(wildcard rebar3),rebar3)
	@curl -Lo rebar3 $(REBAR_URL) || wget $(REBAR_URL)
endif
	@chmod a+x rebar3
