%%%-------------------------------------------------------------------
%% @doc nari_sim_client top level supervisor.
%% @end
%%%-------------------------------------------------------------------

-module(nari_sim_client_sup).
-behaviour(supervisor).

-include("nari_sim_client.hrl").

-export([start_link/0]).

-export([init/1]).

-define(SERVER, ?MODULE).

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

init([]) ->
    Opts = get_opts(),

    SupFlags = #{strategy => one_for_one,
        intensity => 10,
        period => 100},
    ChildSpecs = [
        #{id => worker, start => {nari_sim_client, start_link, [{Opts}]}}
    ],
    {ok, {SupFlags, ChildSpecs}}.

%% internal functions

get_opts() ->
    {ok, Username} = application:get_env(?APP, username),
    {ok, Password} = application:get_env(?APP, password),
    {ok, Host} = application:get_env(?APP, host),
    {ok, Port} = application:get_env(?APP, port),
    {ok, SubTopics} = application:get_env(?APP, sub_topics),
    {ok, PubTopic} = application:get_env(?APP, pub_topic),
    #sim_opts{
        username = Username,
        password = Password,
        host = Host,
        port = Port,
        sub_topics = SubTopics,
        pub_topic = PubTopic
    }.
