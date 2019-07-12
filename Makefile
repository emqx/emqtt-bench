REBAR := rebar3

.PHONY: all
all: compile

compile: unlock
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
xref:
	$(REBAR) xref

