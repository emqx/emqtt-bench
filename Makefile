.PHONY: test

ERL=erl
BEAMDIR=./deps/*/ebin ./ebin
REBAR=./rebar

all: get-deps compile xref

get-deps:
	@$(REBAR) get-deps

update-deps:
	@$(REBAR) update-deps

compile:
	@$(REBAR) compile

xref:
	@$(REBAR) xref skip_deps=true

clean:
	@$(REBAR) clean
