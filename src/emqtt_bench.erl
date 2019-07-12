%%--------------------------------------------------------------------
%% Copyright (c) 2019 EMQ Technologies Co., Ltd. All Rights Reserved.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%--------------------------------------------------------------------

-module(emqtt_bench).

-export([ main/1
        , main/2
        , start/2
        , run/3
        , connect/4
        , loop/4
        ]).

-define(PUB_OPTS,
        [{help, undefined, "help", boolean,
          "help information"},
         {host, $h, "host", {string, "localhost"},
          "mqtt server hostname or IP address"},
         {port, $p, "port", {integer, 1883},
          "mqtt server port number"},
         {version, $V, "version", {integer, 5},
          "mqtt protocol version: 3 | 4 | 5"},
         {count, $c, "count", {integer, 200},
          "max count of clients"},
         {startnumber, $n, "startnumber", {integer, 0}, "start number"},
         {interval, $i, "interval", {integer, 10},
          "interval of connecting to the broker"},
         {interval_of_msg, $I, "interval_of_msg", {integer, 1000},
          "interval of publishing message(ms)"},
         {username, $u, "username", string,
          "username for connecting to server"},
         {password, $P, "password", string,
          "password for connecting to server"},
         {topic, $t, "topic", string,
          "topic subscribe, support %u, %c, %i variables"},
         {size, $s, "size", {integer, 256},
          "payload size"},
         {qos, $q, "qos", {integer, 0},
          "subscribe qos"},
         {retain, $r, "retain", {boolean, false},
          "retain message"},
         {keepalive, $k, "keepalive", {integer, 300},
          "keep alive in seconds"},
         {clean, $C, "clean", {boolean, true},
          "clean start"},
         {ssl, $S, "ssl", {boolean, false},
          "ssl socoket for connecting to server"},
         {certfile, undefined, "certfile", string,
          "client certificate for authentication, if required by server"},
         {keyfile, undefined, "keyfile", string,
          "client private key for authentication, if required by server"},
         {ifaddr, undefined, "ifaddr", string,
          "local ipaddress or interface address"}
        ]).

-define(SUB_OPTS,
        [{help, undefined, "help", boolean,
          "help information"},
         {host, $h, "host", {string, "localhost"},
          "mqtt server hostname or IP address"},
         {port, $p, "port", {integer, 1883},
          "mqtt server port number"},
         {version, $V, "version", {integer, 5},
          "mqtt protocol version: 3 | 4 | 5"},
         {count, $c, "count", {integer, 200},
          "max count of clients"},
         {startnumber, $n, "startnumber", {integer, 0}, "start number"},
         {interval, $i, "interval", {integer, 10},
          "interval of connecting to the broker"},
         {topic, $t, "topic", string,
          "topic subscribe, support %u, %c, %i variables"},
         {qos, $q, "qos", {integer, 0},
          "subscribe qos"},
         {username, $u, "username", string,
          "username for connecting to server"},
         {password, $P, "password", string,
          "password for connecting to server"},
         {keepalive, $k, "keepalive", {integer, 300},
          "keep alive in seconds"},
         {clean, $C, "clean", {boolean, true},
          "clean start"},
         {ssl, $S, "ssl", {boolean, false},
          "ssl socoket for connecting to server"},
         {certfile, undefined, "certfile", string,
          "client certificate for authentication, if required by server"},
         {keyfile, undefined, "keyfile", string,
          "client private key for authentication, if required by server"},
         {ifaddr, undefined, "ifaddr", string,
          "local ipaddress or interface address"}
        ]).

-define(TAB, ?MODULE).
-define(IDX_SENT, 1).
-define(IDX_RECV, 2).

main(["sub"|Argv]) ->
    {ok, {Opts, _Args}} = getopt:parse(?SUB_OPTS, Argv),
    ok = maybe_help(sub, Opts),
    ok = check_required_args(sub, [count, topic], Opts),
    main(sub, Opts);

main(["pub"|Argv]) ->
    {ok, {Opts, _Args}} = getopt:parse(?PUB_OPTS, Argv),
    ok = maybe_help(pub, Opts),
    ok = check_required_args(pub, [count, topic], Opts),
    main(pub, Opts);

main(_Argv) ->
    ScriptPath = escript:script_name(),
    Script = filename:basename(ScriptPath),
    io:format("Usage: ~s pub | sub [--help]~n", [Script]).

maybe_help(PubSub, Opts) ->
    case proplists:get_value(help, Opts) of
        true ->
            usage(PubSub),
            halt(0);
        _ -> ok
    end.

check_required_args(PubSub, Keys, Opts) ->
    lists:foreach(fun(Key) ->
        case lists:keyfind(Key, 1, Opts) of
            false ->
                io:format("Error: '~s' required~n", [Key]),
                usage(PubSub),
                halt(1);
            _ -> ok
        end
    end, Keys).

usage(PubSub) ->
    ScriptPath = escript:script_name(),
    Script = filename:basename(ScriptPath),
    Opts = case PubSub of
               pub -> ?PUB_OPTS;
               sub -> ?SUB_OPTS
           end,
    getopt:usage(Opts, Script ++ " " ++ atom_to_list(PubSub)).

main(sub, Opts) ->
    start(sub, Opts);

main(pub, Opts) ->
    Size    = proplists:get_value(size, Opts),
    Payload = iolist_to_binary([O || O <- lists:duplicate(Size, 0)]),
    start(pub, [{payload, Payload} | Opts]).

start(PubSub, Opts) ->
    prepare(), init(),
    spawn(?MODULE, run, [self(), PubSub, Opts]),
    timer:send_interval(1000, stats),
    main_loop(os:timestamp(), 1+proplists:get_value(startnumber, Opts)).

prepare() ->
    application:ensure_all_started(emqtt_bench).

init() ->
    CRef = counters:new(4, [write_concurrency]),
    ok = persistent_term:put(?MODULE, CRef),
    put({stats, recv}, 0),
    put({stats, sent}, 0).

main_loop(Uptime, Count) ->
	receive
		{connected, _N, _Client} ->
			io:format("connected: ~w~n", [Count]),
			main_loop(Uptime, Count+1);
        stats ->
            print_stats(Uptime),
			main_loop(Uptime, Count);
        Msg ->
            io:format("~p~n", [Msg]),
            main_loop(Uptime, Count)
	end.

print_stats(Uptime) ->
    print_stats(Uptime, recv),
    print_stats(Uptime, sent).

print_stats(Uptime, Name) ->
    CurVal = get_counter(Name),
    LastVal = get({stats, Name}),
    case CurVal == LastVal of
        false ->
            Tdiff = timer:now_diff(os:timestamp(), Uptime) div 1000,
            io:format("~s(~w): total=~w, rate=~w(msg/sec)~n",
                        [Name, Tdiff, CurVal, CurVal - LastVal]),
            put({stats, Name}, CurVal);
        true -> ok
    end.

get_counter(sent) ->
    counters:get(cnt_ref(), ?IDX_SENT);
get_counter(recv) ->
    counters:get(cnt_ref(), ?IDX_RECV).

inc_counter(sent) ->
    counters:add(cnt_ref(), ?IDX_SENT, 1);
inc_counter(recv) ->
    counters:add(cnt_ref(), ?IDX_RECV, 1).

-compile({inline, [cnt_ref/0]}).
cnt_ref() -> persistent_term:get(?MODULE).

run(Parent, PubSub, Opts) ->
    run(Parent, proplists:get_value(count, Opts), PubSub, Opts).

run(_Parent, 0, _PubSub, _Opts) ->
    done;
run(Parent, N, PubSub, Opts) ->
    spawn(?MODULE, connect, [Parent, N+proplists:get_value(startnumber, Opts), PubSub, Opts]),
	timer:sleep(proplists:get_value(interval, Opts)),
	run(Parent, N-1, PubSub, Opts).
    
connect(Parent, N, PubSub, Opts) ->
    process_flag(trap_exit, true),
    rand:seed(exsplus, erlang:timestamp()),
    ClientId = client_id(PubSub, N, Opts),
    MqttOpts = [{client_id, ClientId},
                {tcp_opts, tcp_opts(Opts)},
                {ssl_opts, ssl_opts(Opts)}
               | mqtt_opts(Opts)],
    AllOpts  = [{seq, N}, {client_id, ClientId} | Opts],
	{ok, Client} = emqtt:start_link(MqttOpts),
    case emqtt:connect(Client) of
        {ok, _Props} ->
            Parent ! {connected, N, Client},
            case PubSub of
                sub ->
                    subscribe(Client, AllOpts);
                pub ->
                   Interval = proplists:get_value(interval_of_msg, Opts),
                   timer:send_interval(Interval, publish)
            end,
            loop(N, Client, PubSub, AllOpts);
        {error, Error} ->
            io:format("client(~w): connect error - ~p~n", [N, Error])
    end.

loop(N, Client, PubSub, Opts) ->
    receive
        publish ->
            case publish(Client, Opts) of
                ok -> inc_counter(sent);
                {ok, _} ->
                    inc_counter(sent);
                {error, Reason} ->
                    io:format("client(~w): publish error - ~p~n", [N, Reason])
            end,
            loop(N, Client, PubSub, Opts);
        {publish, _Publish} ->
            inc_counter(recv),
            loop(N, Client, PubSub, Opts);
        {'EXIT', Client, Reason} ->
            io:format("client(~w): EXIT for ~p~n", [N, Reason])
	end.

subscribe(Client, Opts) ->
    Qos = proplists:get_value(qos, Opts),
    emqtt:subscribe(Client, [{Topic, Qos} || Topic <- topics_opt(Opts)]).

publish(Client, Opts) ->
    Flags   = [{qos, proplists:get_value(qos, Opts)},
               {retain, proplists:get_value(retain, Opts)}],
    Payload = proplists:get_value(payload, Opts),
    emqtt:publish(Client, topic_opt(Opts), Payload, Flags).

mqtt_opts(Opts) ->
    mqtt_opts(Opts, []).

mqtt_opts([], Acc) ->
    Acc;
mqtt_opts([{host, Host}|Opts], Acc) ->
    mqtt_opts(Opts, [{host, Host}|Acc]);
mqtt_opts([{port, Port}|Opts], Acc) ->
    mqtt_opts(Opts, [{port, Port}|Acc]);
mqtt_opts([{version, 3}|Opts], Acc) ->
    mqtt_opts(Opts, [{proto_ver, v3}|Acc]);
mqtt_opts([{version, 4}|Opts], Acc) ->
    mqtt_opts(Opts, [{proto_ver, v4}|Acc]);
mqtt_opts([{version, 5}|Opts], Acc) ->
    mqtt_opts(Opts, [{proto_ver, v5}|Acc]);
mqtt_opts([{username, Username}|Opts], Acc) ->
    mqtt_opts(Opts, [{username, list_to_binary(Username)}|Acc]);
mqtt_opts([{password, Password}|Opts], Acc) ->
    mqtt_opts(Opts, [{password, list_to_binary(Password)}|Acc]);
mqtt_opts([{keepalive, I}|Opts], Acc) ->
    mqtt_opts(Opts, [{keepalive, I}|Acc]);
mqtt_opts([{clean_start, Bool}|Opts], Acc) ->
    mqtt_opts(Opts, [{clean_start, Bool}|Acc]);
mqtt_opts([ssl|Opts], Acc) ->
    mqtt_opts(Opts, [{ssl, true}|Acc]);
mqtt_opts([{ssl, Bool}|Opts], Acc) ->
    mqtt_opts(Opts, [{ssl, Bool}|Acc]);
mqtt_opts([_|Opts], Acc) ->
    mqtt_opts(Opts, Acc).

tcp_opts(Opts) ->
    tcp_opts(Opts, []).
tcp_opts([], Acc) ->
    Acc;
tcp_opts([{ifaddr, IfAddr} | Opts], Acc) ->
    {ok, IpAddr} = inet_parse:address(IfAddr),
    tcp_opts(Opts, [{ip, IpAddr}|Acc]);
tcp_opts([_|Opts], Acc) ->
    tcp_opts(Opts, Acc).

ssl_opts(Opts) ->
    ssl_opts(Opts, []).
ssl_opts([], Acc) ->
    {ssl, Acc};
ssl_opts([{keyfile, KeyFile} | Opts], Acc) ->
    ssl_opts(Opts, [{keyfile, KeyFile}|Acc]);
ssl_opts([{certfile, CertFile} | Opts], Acc) ->
    ssl_opts(Opts, [{certfile, CertFile}|Acc]);
ssl_opts([_|Opts], Acc) ->
    ssl_opts(Opts, Acc).

client_id(PubSub, N, Opts) ->
    Prefix =
    case proplists:get_value(ifaddr, Opts) of
        undefined ->
            {ok, Host} = inet:gethostname(), Host;
        IfAddr    ->
            IfAddr
    end,
    list_to_binary(lists:concat([Prefix, "_bench_", atom_to_list(PubSub),
                                    "_", N, "_", rand:uniform(16#FFFFFFFF)])).

topics_opt(Opts) ->
    Topics = topics_opt(Opts, []),
    io:format("Topics: ~p~n", [Topics]),
    [feed_var(bin(Topic), Opts) || Topic <- Topics].

topics_opt([], Acc) ->
    Acc;
topics_opt([{topic, Topic}|Topics], Acc) ->
    topics_opt(Topics, [Topic | Acc]);
topics_opt([_Opt|Topics], Acc) ->
    topics_opt(Topics, Acc).

topic_opt(Opts) ->
    feed_var(bin(proplists:get_value(topic, Opts)), Opts).

feed_var(Topic, Opts) when is_binary(Topic) ->
    Props = [{Var, bin(proplists:get_value(Key, Opts))} || {Key, Var} <-
                [{seq, <<"%i">>}, {client_id, <<"%c">>}, {username, <<"%u">>}]],
    lists:foldl(fun({_Var, undefined}, Acc) -> Acc;
                   ({Var, Val}, Acc) -> feed_var(Var, Val, Acc)
        end, Topic, Props).

feed_var(Var, Val, Topic) ->
    feed_var(Var, Val, words(Topic), []).
feed_var(_Var, _Val, [], Acc) ->
    join(lists:reverse(Acc));
feed_var(Var, Val, [Var|Words], Acc) ->
    feed_var(Var, Val, Words, [Val|Acc]);
feed_var(Var, Val, [W|Words], Acc) ->
    feed_var(Var, Val, Words, [W|Acc]).

words(Topic) when is_binary(Topic) ->
    [word(W) || W <- binary:split(Topic, <<"/">>, [global])].

word(<<>>)    -> '';
word(<<"+">>) -> '+';
word(<<"#">>) -> '#';
word(Bin)     -> Bin.

join([]) ->
    <<>>;
join([W]) ->
    bin(W);
join(Words) ->
    {_, Bin} =
    lists:foldr(fun(W, {true, Tail}) ->
                        {false, <<W/binary, Tail/binary>>};
                   (W, {false, Tail}) ->
                        {false, <<W/binary, "/", Tail/binary>>}
                end, {true, <<>>}, [bin(W) || W <- Words]),
    Bin.

bin(A) when is_atom(A)   -> bin(atom_to_list(A));
bin(I) when is_integer(I)-> bin(integer_to_list(I));
bin(S) when is_list(S)   -> list_to_binary(S);
bin(B) when is_binary(B) -> B;
bin(undefined)           -> undefined.

