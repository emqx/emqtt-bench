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

-exprot([ start_nari_client/1
        , start_client/1 ]).

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
         {ws, undefined, "ws", {boolean, false},
          "websocket transport"},
         {ifaddr, undefined, "ifaddr", string,
          "local ipaddress or interface address"},
         {file, $f, "file", string,
          "payload json file"}
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
         {ws, undefined, "ws", {boolean, false},
          "websocket transport"},
         {ifaddr, undefined, "ifaddr", string,
          "local ipaddress or interface address"}
        %  {sim_cli, undefined, "sim_client", {boolean, false},
        %   "nari simulation client"}
        ]).

-define(CONN_OPTS, [
         {help, undefined, "help", boolean,
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
         {username, $u, "username", string,
          "username for connecting to server"},
         {password, $P, "password", string,
          "password for connecting to server"},
         {keepalive, $k, "keepalive", {integer, 300},
          "keep alive in seconds"},
         {clean, $C, "clean", {boolean, true},
          "clean session"},
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

main(["nari_client"| Argv]) ->
    start_nari_client(Argv);

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

main(["conn"|Argv]) ->
    {ok, {Opts, _Args}} = getopt:parse(?CONN_OPTS, Argv),
    ok = maybe_help(conn, Opts),
    ok = check_required_args(conn, [count], Opts),
    main(conn, Opts);

main(_Argv) ->
    ScriptPath = escript:script_name(),
    Script = filename:basename(ScriptPath),
    io:format("Usage: ~s pub | sub | conn [--help]~n", [Script]).

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
               sub -> ?SUB_OPTS;
               conn -> ?CONN_OPTS
           end,
    getopt:usage(Opts, Script ++ " " ++ atom_to_list(PubSub)).

main(sub, Opts) ->
    start(sub, Opts);

main(pub, Opts) ->
%%    FileName = proplists:get_value(file, Opts),
%%    {ok, Bin} = file:read_file(FileName),
%%    Payload = Bin,
    Payload = <<>>,
    start(pub, [{payload, Payload} | Opts]);

main(conn, Opts) ->
    start(conn, Opts).

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
            return_print("connected: ~w", [Count]),
            main_loop(Uptime, Count+1);
        stats ->
            print_stats(Uptime),
            main_loop(Uptime, Count);
        Msg ->
            print("~p~n", [Msg]),
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
            print("~s(~w): total=~w, rate=~w(msg/sec)~n",
                  [Name, Tdiff, CurVal, CurVal - LastVal]),
            put({stats, Name}, CurVal);
        true -> ok
    end.

%% this is only used for main loop
return_print(Fmt, Args) ->
    print(return, Fmt, Args).

print(Fmt, Args) ->
    print(feed, Fmt, Args).

print(ReturnMaybeFeed, Fmt, Args) ->
    % print the return
    io:format("\r"),
    maybe_feed(ReturnMaybeFeed),
    io:format(Fmt, Args).

maybe_feed(ReturnMaybeFeed) ->
    Last = get(?FUNCTION_NAME),
    maybe_feed(Last, ReturnMaybeFeed),
    put(?FUNCTION_NAME, ReturnMaybeFeed).

maybe_feed(return, feed) -> io:format("\n");
maybe_feed(_, _) -> ok.

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
    ConnRet = case proplists:get_bool(ws, Opts) of
                  true  ->
                      emqtt:ws_connect(Client);
                  false -> emqtt:connect(Client)
              end,
    case ConnRet of
        {ok, _Props} ->
            Parent ! {connected, N, Client},
            case PubSub of
                conn -> ok;
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
%%    Payload = proplists:get_value(payload, Opts),
    Payload = make_payload1(),
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
mqtt_opts([{clean, Bool}|Opts], Acc) ->
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
    [{ciphers, ssl:cipher_suites(all)} | Acc];
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

make_payload1() ->
    Resp = #{
        <<"mId">> => 87691023,
        <<"devSn">> => <<"0537369409">>,
        <<"productCode">> => null
    },
    Objective = #{
        <<"devSn">> => <<"0343278630">>,
        <<"productCode">> => <<"METER">>,
        <<"sourceType">> => <<"TERMINAL">>,
        <<"cmdType">> => <<"REPORT_DATA">>
    },
    DataItem = #{
        <<"dataItemId">> => <<"2004-10201-000">>,
        <<"dataItemName">> => <<"当前有功总功率">>
    },
    DataItem1 = DataItem#{<<"dataReturnTime">> => get_datetime(), <<"dataValue">> => get_date_value()},
    Objective1 = Objective#{<<"dataItemList">> => [DataItem1]},
    Resp1 = Resp#{<<"objectiveList">> => [Objective1]},
    jsx:encode(Resp1).

strftime({{Y,M,D}, {H,MM,S}}) ->
    lists:flatten(
        io_lib:format(
            "~4..0w-~2..0w-~2..0w ~2..0w:~2..0w:~2..0w", [Y, M, D, H, MM, S])).

get_datetime() ->
    list_to_binary(strftime(calendar:local_time())).

get_date_value() ->
    rand:uniform(100).


%% Nari simulation client

-record(sim_opts, {
    username,
    password,
    host,
    port,
    sub_topics,
    pub_topic
}).


start_nari_client([Username, Password, Host, Port, SubTopics, PubTopic]) ->
    Opts = #sim_opts{
        username = Username,
        password = Password,
        host = Host,
        port = Port,
        sub_topics = SubTopics,
        pub_topic = PubTopic
    },
    spawn(?MODULE, start_client, [Opts]).

start_client(Opts = #sim_opts{}) ->
    Parent = erlang:self(),
    Handlers = get_handlers(Parent),
    ClientConfig = #{msg_handler => Handlers,
        host => Opts#sim_opts.host,
        port => Opts#sim_opts.port,
        username => Opts#sim_opts.username,
        password => Opts#sim_opts.password,
        force_ping => true
    },
    case emqtt:start_link(ClientConfig) of
        {ok, ConnPid} ->
            case emqtt:connect(ConnPid) of
                {ok, _} ->
                    try
                        subscribe_topics(ConnPid,  Opts#sim_opts.sub_topics),
                        loop(ConnPid, Opts#sim_opts.pub_topic),
                        {ok, ConnPid}
                    catch
                        throw : Reason ->
                            ok = stop(#{client_pid => ConnPid}),
                            {error, Reason}
                    end;
                {error, Reason} ->
                    io:format("Reason: ~p~n", Reason),
                    ok = stop(#{client_pid => ConnPid}),
                    {error, Reason}
            end;
        {error, Reason} ->
            {error, Reason}
    end.

loop(ConnPid, PubTopic) ->
    receive
        {ConnPid, data_call} ->
            Payload = make_payload2(),
            ok = emqtt:publish(ConnPid, list_to_binary(PubTopic), #{}, Payload, [{qos, 0}]);
        _ ->
            ok
    end,
    loop(ConnPid, PubTopic).

stop(Pid) ->
    safe_stop(Pid, fun() -> emqtt:stop(Pid) end, 1000),
    ok.

safe_stop(Pid, StopF, Timeout) ->
    MRef = monitor(process, Pid),
    unlink(Pid),
    try
        StopF()
    catch
        _ : _ ->
            ok
    end,
    receive
        {'DOWN', MRef, _, _, _} ->
            ok
    after
        Timeout ->
            exit(Pid, kill)
    end.

handle_puback(Ack) ->
    io:format("Recv a PUBACK packet - Ack: ~p~n", [Ack]).

handle_disconnected(Reason) ->
    io:format("Recv a DISONNECT packet - Reason: ~p~n", [Reason]).

handle_publish(Parent, Msg) ->
    io:format("Recv a PUBLISH packet - Msg: ~p~n", [Msg]),
    Parent ! {self(), data_call}.

get_handlers(Parent) ->
    #{
        puback => fun(Ack) -> handle_puback(Ack) end,
        publish => fun(Msg) -> handle_publish(Parent, Msg) end,
        disconnected => fun(Reason) -> handle_disconnected(Reason) end
    }.

subscribe_topics(ClientPid, Subscriptions) ->
    lists:foreach(fun({Topic, Qos}) ->
        case emqtt:subscribe(ClientPid, Topic, Qos) of
            {ok, _, _} -> ok;
            Error ->
                throw(Error)
        end
                  end, Subscriptions).

make_payload2() ->
    Resp = #{
        <<"mId">> => 74837483,
        <<"devSn">> => <<"0537369409">>,
        <<"productCode">> => null
    },
    Objective = #{
        <<"devSn">> => <<"0291203302">>,
        <<"productCode">> => <<"METER">>,
        <<"sourceType">> => <<"TERMINAL">>,
        <<"cmdType">> => <<"GET_RESPONSE">>
    },
    DataItem1 = #{
        <<"dataItemId">> => <<"2001-10200-000">>,
        <<"dataItemName">> => <<"当前电流">>
    },
    DataItem2 = #{
        <<"dataItemId">> => <<"0010-10201-400">>,
        <<"dataItemName">> => <<"日冻结正向有功总电能">>
    },
    NewDataItem1 = DataItem1#{<<"dataReturnTime">> => get_datetime(), <<"dataValue">> => get_date_value1()},
    NewDataItem2 = DataItem2#{<<"dataReturnTime">> => get_datetime(), <<"dataValue">> => get_date_value2()},
    Objective1 = Objective#{<<"dataItemList">> => [NewDataItem1, NewDataItem2]},
    Resp1 = Resp#{<<"objectiveList">> => [Objective1]},
%%    jiffy:encode(Resp1, [force_utf8]).
    jsx:encode(Resp1).

get_date_value1() ->
    lists:map(fun(_) -> list_to_float(float_to_list(rand:uniform(), [{decimals,1}])) end,
        lists:seq(1, 3)).

get_date_value2() ->
    rand:uniform(100).
