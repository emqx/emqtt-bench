.PHONY: test

ERL=erl
REBAR ?= rebar3
DIALYZER=dialyzer

#update-deps 
all: compile

compile:
	@$(REBAR) compile

xref:
	@$(REBAR) xref skip_deps=true

clean:
	@$(REBAR) clean

test:
	@$(REBAR) skip_deps=true eunit

edoc:
	@$(REBAR) doc

dialyzer: compile
	@$(DIALYZER) ebin deps/ossp_uuid/ebin

setup-dialyzer:
	@$(DIALYZER) --build_plt --apps kernel stdlib mnesia eunit erts crypto
