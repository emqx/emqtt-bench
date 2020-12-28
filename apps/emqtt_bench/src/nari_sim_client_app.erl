%%%-------------------------------------------------------------------
%% @doc nari_sim_client public API
%% @end
%%%-------------------------------------------------------------------

-module(nari_sim_client_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    nari_sim_client_sup:start_link().

stop(_State) ->
    ok.

%% internal functions

