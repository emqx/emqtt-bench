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

-include_lib("emqtt/include/emqtt.hrl").

-export([ main/1
        , main/2
        , start/2
        , run/5
        , connect/4
        , loop/5
        ]).

-define(PUB_OPTS,
        [{help, undefined, "help", boolean,
          "help information"},
         {dist, $d, "dist", boolean,
          "enable distribution port"},
         {host, $h, "host", {string, "localhost"},
          "mqtt server hostname or comma-separated hostnames"},
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
         {message, $m, "message", string,
          "set the message content for publish"},
         {qos, $q, "qos", {integer, 0},
          "subscribe qos"},
         {retain, $r, "retain", {boolean, false},
          "retain message"},
         {keepalive, $k, "keepalive", {integer, 300},
          "keep alive in seconds"},
         {clean, $C, "clean", {boolean, true},
          "clean start"},
         {expiry, $x, "session-expiry", {integer, 0},
          "Set 'Session-Expiry' for persistent sessions (seconds)"},
         {limit, $L, "limit", {integer, 0},
          "The max message count to publish, 0 means unlimited"},
         {ssl, $S, "ssl", {boolean, false},
          "ssl socoket for connecting to server"},
         {certfile, undefined, "certfile", string,
          "client certificate for authentication, if required by server"},
         {keyfile, undefined, "keyfile", string,
          "client private key for authentication, if required by server"},
         {ws, undefined, "ws", {boolean, false},
          "websocket transport"},
         {quic, undefined, "quic", {boolean, false},
          "QUIC transport"},
         {ifaddr, undefined, "ifaddr", string,
          "One or multiple (comma-separated) source IP addresses"},
         {prefix, undefined, "prefix", string, "client id prefix"},
         {shortids, $s, "shortids", {boolean, false},
          "use short ids for client ids"},
         {lowmem, $l, "lowmem", boolean, "enable low mem mode, but use more CPU"},
         {inflight, $F,"inflight", {integer, 1},
          "maximum inflight messages for QoS 1 an 2, value 0 for 'infinity'"},
         {wait_before_publishing, $w, "wait-before-publishing", {boolean, false},
          "wait for all publishers to have (at least tried to) connected "
          "before starting publishing"},
         {max_random_wait, undefined,"max-random-wait", {integer, 0},
          "maximum randomized period in ms that each publisher will wait before "
          "starting to publish (uniform distribution)"},
         {min_random_wait, undefined,"min-random-wait", {integer, 0},
          "minimum randomized period in ms that each publisher will wait before "
          "starting to publish (uniform distribution)"},
         {num_retry_connect, undefined, "num-retry-connect", {integer, 0},
          "number of times to retry estabilishing a connection before giving up"},
         {force_major_gc_interval, undefined, "force-major-gc-interval", {integer, 0},
          "interval in milliseconds in which a major GC will be forced on the "
          "bench processes.  a value of 0 means disabled (default).  this only "
          "takes effect when used together with --lowmem."},
         {conn_rate, $R, "connrate", {integer, 0}, "connection rate(/s), default: 0, fallback to use --interval"}
        ]).

-define(SUB_OPTS,
        [{help, undefined, "help", boolean,
          "help information"},
         {dist, $d, "dist", boolean,
          "enable distribution port"},
         {host, $h, "host", {string, "localhost"},
          "mqtt server hostname or comma-separated hostnames"},
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
         {expiry, $x, "session-expiry", {integer, 0},
          "Set 'Session-Expiry' for persistent sessions (seconds)"},
         {ssl, $S, "ssl", {boolean, false},
          "ssl socoket for connecting to server"},
         {certfile, undefined, "certfile", string,
          "client certificate for authentication, if required by server"},
         {keyfile, undefined, "keyfile", string,
          "client private key for authentication, if required by server"},
         {ws, undefined, "ws", {boolean, false},
          "websocket transport"},
         {quic, undefined, "quic", {boolean, false},
          "QUIC transport"},
         {ifaddr, undefined, "ifaddr", string,
          "local ipaddress or interface address"},
         {prefix, undefined, "prefix", string, "client id prefix"},
         {shortids, $s, "shortids", {boolean, false},
          "use short ids for client ids"},
         {lowmem, $l, "lowmem", boolean, "enable low mem mode, but use more CPU"},
         {num_retry_connect, undefined, "num-retry-connect", {integer, 0},
          "number of times to retry estabilishing a connection before giving up"},
         {force_major_gc_interval, undefined, "force-major-gc-interval", {integer, 0},
          "interval in milliseconds in which a major GC will be forced on the "
          "bench processes.  a value of 0 means disabled (default).  this only "
          "takes effect when used together with --lowmem."},
         {conn_rate, $R, "connrate", {integer, 0}, "connection rate(/s), default: 0, fallback to use --interval"}
        ]).

-define(CONN_OPTS, [
         {help, undefined, "help", boolean,
          "help information"},
         {dist, $d, "dist", boolean,
          "enable distribution port"},
         {host, $h, "host", {string, "localhost"},
          "mqtt server hostname or comma-separated hostnames"},
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
         {expiry, $x, "session-expiry", {integer, 0},
          "Set 'Session-Expiry' for persistent sessions (seconds)"},
         {ssl, $S, "ssl", {boolean, false},
          "ssl socoket for connecting to server"},
         {certfile, undefined, "certfile", string,
          "client certificate for authentication, if required by server"},
         {keyfile, undefined, "keyfile", string,
          "client private key for authentication, if required by server"},
         {quic, undefined, "quic", {boolean, false},
          "QUIC transport"},
         {ifaddr, undefined, "ifaddr", string,
          "local ipaddress or interface address"},
         {prefix, undefined, "prefix", string, "client id prefix"},
         {shortids, $s, "shortids", {boolean, false},
          "use short ids for client ids"},
         {lowmem, $l, "lowmem", boolean, "enable low mem mode, but use more CPU"},
         {num_retry_connect, undefined, "num-retry-connect", {integer, 0},
          "number of times to retry estabilishing a connection before giving up"},
         {force_major_gc_interval, undefined, "force-major-gc-interval", {integer, 0},
          "interval in milliseconds in which a major GC will be forced on the "
          "bench processes.  a value of 0 means disabled (default).  this only "
          "takes effect when used together with --lowmem."},
         {conn_rate, $R, "connrate", {integer, 0}, "connection rate(/s), default: 0, fallback to use --interval"}
        ]).

-define(COUNTERS, 16).
-define(IDX_RECV, 2).
-define(IDX_SUB, 3).
-define(IDX_SUB_FAIL, 4).
-define(IDX_PUB, 5).
-define(IDX_PUB_FAIL, 6).
-define(IDX_PUB_OVERRUN, 7).
-define(IDX_PUB_SUCCESS, 8).
-define(IDX_CONN_SUCCESS, 9).
-define(IDX_CONN_FAIL, 10).

-define(PUBLISH(C, S), {publish, C, S}).

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
    Size    = proplists:get_value(size, Opts),
    Payload = case proplists:get_value(message, Opts) of
                  undefined ->
                    iolist_to_binary([O || O <- lists:duplicate(Size, $a)]);
                  StrPayload -> StrPayload
              end,
    MsgLimit = consumer_pub_msg_fun_init(proplists:get_value(limit, Opts)),
    PublishSignalPid =
        case proplists:get_value(wait_before_publishing, Opts) of
            true ->
                spawn(fun() -> receive go -> exit(start_publishing) end end);
            false ->
                undefined
        end,
    start(pub, [ {payload, Payload}
               , {limit_fun, MsgLimit}
               , {publish_signal_pid, PublishSignalPid}
               | Opts]);

main(conn, Opts) ->
    start(conn, Opts).

start(PubSub, Opts) ->
    prepare(PubSub, Opts), init(),
    IfAddr = proplists:get_value(ifaddr, Opts),
    Host = proplists:get_value(host, Opts),
    Rate = proplists:get_value(conn_rate, Opts),
    HostList = addr_to_list(Host),
    AddrList = addr_to_list(IfAddr),
    NoAddrs = length(AddrList),
    NoWorkers = max(erlang:system_info(schedulers_online), ceil(Rate / 1000)),
    Count = proplists:get_value(count, Opts),
    CntPerWorker = Count div NoWorkers,
    Rem = Count rem NoWorkers,
    Interval = case Rate of
                   0 -> %% conn_rate is not set
                       proplists:get_value(interval, Opts) * NoWorkers;
                   ConnRate ->
                       1000 * NoWorkers div ConnRate
               end,

    io:format("Start with ~p workers, addrs pool size: ~p and req interval: ~p ms ~n~n",
              [NoWorkers, NoAddrs, Interval]),
    true = (Interval >= 1),
    lists:foreach(fun(P) ->
                          StartNumber = proplists:get_value(startnumber, Opts) + CntPerWorker*(P-1),
                          CountParm = case Rem =/= 0 andalso P == 1 of
                                          true ->
                                              [{count, CntPerWorker + Rem}];
                                          false ->
                                              [{count, CntPerWorker}]
                                      end,
                          WOpts = replace_opts(Opts, [{startnumber, StartNumber},
                                                      {interval, Interval}
                                                     ] ++ CountParm),
                          proc_lib:spawn(?MODULE, run, [self(), PubSub, WOpts, AddrList, HostList])
                  end, lists:seq(1, NoWorkers)),
    timer:send_interval(1000, stats),
    maybe_spawn_gc_enforcer(Opts),
    main_loop(erlang:monotonic_time(millisecond), _Count = 0).

prepare(PubSub, Opts) ->
    Sname = list_to_atom(lists:flatten(io_lib:format("~p-~p-~p", [?MODULE, PubSub, rand:uniform(1000)]))),
    case proplists:get_bool(dist, Opts) of
        true ->
            net_kernel:start([Sname, shortnames]),
            io:format("Starting distribution with name ~p~n", [Sname]);
        false ->
            ok
    end,
    case proplists:get_bool(quic, Opts) of
        true -> maybe_start_quicer() orelse error({quic, not_supp_or_disabled});
        _ ->
            ok
    end,
    application:ensure_all_started(emqtt_bench).

init() ->
    process_flag(trap_exit, true),
    CRef = counters:new(?COUNTERS, [write_concurrency]),
    ok = persistent_term:put(?MODULE, CRef),
    Now = erlang:monotonic_time(millisecond),
    InitS = {Now, 0},
    put({stats, recv}, InitS),
    put({stats, pub}, InitS),
    put({stats, pub_succ}, InitS),
    put({stats, pub_fail}, InitS),
    put({stats, pub_overrun}, InitS),
    put({stats, sub_fail}, InitS),
    put({stats, sub}, InitS),
    put({stats, connect_succ}, InitS),
    put({stats, connect_fail}, InitS).


main_loop(Uptime, Count0) ->
    receive
        publish_complete ->
            return_print("publish complete", []);
        stats ->
            print_stats(Uptime),
            garbage_collect(),
            main_loop(Uptime, Count0);
        Msg ->
            print("main_loop_msg: ~p~n", [Msg]),
            main_loop(Uptime, Count0)
    end.

print_stats(Uptime) ->
    [print_stats(Uptime, Cnt) ||
        Cnt <- [recv, sub, pub, pub_succ, sub_fail, pub_fail, pub_overrun, connect_succ, connect_fail]],
    ok.

print_stats(Uptime, Name) ->
    CurVal = get_counter(Name),
    {LastTS, LastVal} = get({stats, Name}),
    case CurVal == LastVal of
        false ->
            Now = erlang:monotonic_time(millisecond),
            Elapsed = Now - LastTS,
            Tdiff = fmt_tdiff(Now - Uptime),
            print("~s ~s total=~w rate=~.2f/sec~n",
                  [Tdiff, Name, CurVal, (CurVal - LastVal) * 1000/Elapsed]),
            put({stats, Name}, {Now, CurVal});
        true -> ok
    end.

fmt_tdiff(D) -> do_fmt_tdiff(D div 1000).

do_fmt_tdiff(S) ->
    Factors = [{60, "s"}, {60, "m"}, {24, "h"}, {10000000, "d"}],
    Result = lists:reverse(do_fmt_tdiff(S, Factors)),
    iolist_to_binary([[integer_to_list(X), Unit] || {X, Unit} <- Result]).

do_fmt_tdiff(0, _) -> [];
do_fmt_tdiff(T, [{Fac, Unit} | Rest]) ->
    [{T rem Fac, Unit} | do_fmt_tdiff(T div Fac,  Rest)].

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

get_counter(recv) ->
    counters:get(cnt_ref(), ?IDX_RECV);
get_counter(sub) ->
    counters:get(cnt_ref(), ?IDX_SUB);
get_counter(pub) ->
    counters:get(cnt_ref(), ?IDX_PUB);
get_counter(pub_succ) ->
    counters:get(cnt_ref(), ?IDX_PUB_SUCCESS);
get_counter(sub_fail) ->
    counters:get(cnt_ref(), ?IDX_SUB_FAIL);
get_counter(pub_fail) ->
    counters:get(cnt_ref(), ?IDX_PUB_FAIL);
get_counter(pub_overrun) ->
    counters:get(cnt_ref(), ?IDX_PUB_OVERRUN);
get_counter(connect_succ) ->
    counters:get(cnt_ref(), ?IDX_CONN_SUCCESS);
get_counter(connect_fail) ->
    counters:get(cnt_ref(), ?IDX_CONN_FAIL).

inc_counter(recv) ->
    counters:add(cnt_ref(), ?IDX_RECV, 1);
inc_counter(sub) ->
    counters:add(cnt_ref(), ?IDX_SUB, 1);
inc_counter(sub_fail) ->
    counters:add(cnt_ref(), ?IDX_SUB_FAIL, 1);
inc_counter(pub) ->
    counters:add(cnt_ref(), ?IDX_PUB, 1);
inc_counter(pub_succ) ->
    counters:add(cnt_ref(), ?IDX_PUB_SUCCESS, 1);
inc_counter(pub_fail) ->
    counters:add(cnt_ref(), ?IDX_PUB_FAIL, 1);
inc_counter(pub_overrun) ->
    counters:add(cnt_ref(), ?IDX_PUB_OVERRUN, 1);
inc_counter(connect_succ) ->
    counters:add(cnt_ref(), ?IDX_CONN_SUCCESS, 1);
inc_counter(connect_fail) ->
    counters:add(cnt_ref(), ?IDX_CONN_FAIL, 1).

-compile({inline, [cnt_ref/0]}).
cnt_ref() -> persistent_term:get(?MODULE).

run(Parent, PubSub, Opts, AddrList, HostList) ->
    run(Parent, proplists:get_value(count, Opts), PubSub, Opts, AddrList, HostList).


run(_Parent, 0, _PubSub, Opts, _AddrList, _HostList) ->
    case proplists:get_value(publish_signal_pid, Opts) of
        Pid when is_pid(Pid) ->
            Pid ! go;
        _ ->
            ok
    end,
    done;
run(Parent, N, PubSub, Opts0, AddrList, HostList) ->
    SpawnOpts = case proplists:get_bool(lowmem, Opts0) of
                    true ->
                        [ {min_heap_size, 16}
                        , {min_bin_vheap_size, 16}
                        , {fullsweep_after, 1_000}
                        ];
                    false ->
                        []
                end,
    case PubSub of
        pub ->
            connect_pub(Parent, N, #{}, [{loop_pid, self()} | Opts0], AddrList, HostList);
        _ ->
            Opts = replace_opts(Opts0, [ {ifaddr, shard_addr(N, AddrList)}
                                       , {host, shard_addr(N, HostList)}
                                       ]),
            spawn_opt(?MODULE, connect, [Parent, N+proplists:get_value(startnumber, Opts), PubSub, Opts],
                      SpawnOpts),
            timer:sleep(proplists:get_value(interval, Opts)),
            run(Parent, N-1, PubSub, Opts, AddrList, HostList)
    end.

connect_pub(Parent, 0, Clients, Opts, _AddrList, _HostList) ->
    StartNum = proplists:get_value(startnumber, Opts),
    case proplists:get_value(publish_signal_pid, Opts) of
        Pid when is_pid(Pid) ->
            Pid ! go;
        _ ->
            ok
    end,
    ClientId = client_id(pub, StartNum, Opts),
    RandomPubWaitMS = random_pub_wait_period(Opts),
    AllOpts  = [ {seq, StartNum}
               , {client_id, ClientId}
               , {pub_start_wait, RandomPubWaitMS}
               , {loop_pid, self()}
               | Opts],
    loop_pub(Parent, Clients, loop_opts(AllOpts));
connect_pub(Parent, N, Clients0, Opts00, AddrList, HostList) when N > 0 ->
    process_flag(trap_exit, true),
    Opts0 = replace_opts(Opts00, [ {ifaddr, shard_addr(N, AddrList)}
                                 , {host, shard_addr(N, HostList)}
                                 ]),
    StartNum = proplists:get_value(startnumber, Opts0),
    Seq = StartNum + N,
    rand:seed(exsplus, erlang:timestamp()),
    MRef = case {proplists:get_value(publish_signal_mref, Opts0),
                 proplists:get_value(publish_signal_pid, Opts0)} of
               {MRef0, _} when is_reference(MRef0) -> MRef0;
               {_, Pid} when is_pid(Pid) ->
                   monitor(process, Pid);
               _ -> undefined
           end,
    Opts = [ {publish_signal_mref, MRef}
           , {seq, Seq}
           | Opts0],
    ClientId = client_id(pub, Seq, Opts),
    MqttOpts = [{clientid, ClientId},
                {tcp_opts, tcp_opts(Opts)},
                {ssl_opts, ssl_opts(Opts)}]
        ++ session_property_opts(Opts)
        ++ mqtt_opts(Opts),
    RandomPubWaitMS = random_pub_wait_period(Opts),
    {ok, Client} = emqtt:start_link(MqttOpts),
    ConnectFun = connect_fun(Opts),
    ConnRet = emqtt:ConnectFun(Client),
    Clients = Clients0#{Client => true},
    case is_reference(MRef) of
        true ->
            ok;
        false ->
            maybe_publish(Parent, Clients, [{client_id, ClientId} | Opts]),
            drain_published_pub(),
            ok
    end,
    case ConnRet of
        {ok, _Props} ->
            case MRef of
                undefined ->
                    erlang:send_after(RandomPubWaitMS, self(), ?PUBLISH(Client, Seq));
                _ ->
                    %% send `publish' only when all publishers
                    %% are in place.
                    ok
            end,
            timer:sleep(proplists:get_value(interval, Opts)),
            inc_counter(connect_succ),
            connect_pub(Parent, N - 1, Clients, proplists:delete(connection_attempts, Opts), AddrList, HostList);
        {error, Error} ->
            io:format("client(~w): connect error - ~p~n", [N, Error]),
            MaxRetries = proplists:get_value(num_retry_connect, Opts, 0),
            Retries = proplists:get_value(connection_attempts, Opts, 0),
            case Retries >= MaxRetries of
                true ->
                    inc_counter(connect_fail),
                    connect_pub(Parent, N - 1, Clients0, proplists:delete(connection_attempts, Opts), AddrList, HostList);
                false ->
                    io:format("client(~w): retrying...~n", [N]),
                    NOpts = proplists:delete(connection_attempts, Opts),
                    connect_pub(Parent, N, Clients0, [{connection_attempts, Retries + 1} | NOpts], AddrList, HostList)
            end
    end.

%% to avoid massive hit when everyone connects
maybe_publish(Parent, Clients, Opts) ->
    receive
        ?PUBLISH(Client, Seq) ->
            case Clients of
                #{Client := true} ->
                    spawn(
                      fun() ->
                              case (proplists:get_value(limit_fun, Opts))() of
                                  true ->
                                      %% this call hangs if emqtt inflight is full
                                      case publish_pub(Client, Seq, Opts) of
                                          ok -> next_publish_pub(Client, Seq, Opts);
                                          {ok, _} -> next_publish_pub(Client, Seq, Opts);
                                          {error, Reason} ->
                                              inc_counter(pub_fail),
                                              io:format("client: publish error - ~p~n", [Reason])
                                      end;
                                  _ ->
                                      Parent ! publish_complete,
                                      exit(normal)
                              end
                      end),
                    maybe_publish(Parent, Clients, Opts);
                _ ->
                    ok
            end
    after
        0 ->
            ok
    end.

connect(Parent, N, PubSub, Opts) ->
    process_flag(trap_exit, true),
    rand:seed(exsplus, erlang:timestamp()),
    MRef = case proplists:get_value(publish_signal_pid, Opts) of
               Pid when is_pid(Pid) ->
                   monitor(process, Pid);
               _ -> undefined
           end,
    ClientId = client_id(PubSub, N, Opts),
    MqttOpts = [{clientid, ClientId},
                {tcp_opts, tcp_opts(Opts)},
                {ssl_opts, ssl_opts(Opts)}]
        ++ session_property_opts(Opts)
        ++ mqtt_opts(Opts),
    MqttOpts1 = case PubSub of
                  conn -> [{force_ping, true} | MqttOpts];
                  _ -> MqttOpts
                end,
    RandomPubWaitMS = random_pub_wait_period(Opts),
    AllOpts  = [ {seq, N}
               , {client_id, ClientId}
               , {publish_signal_mref, MRef}
               , {pub_start_wait, RandomPubWaitMS}
               | Opts],
    {ok, Client} = emqtt:start_link(MqttOpts1),
    ConnectFun = connect_fun(Opts),
    ConnRet = emqtt:ConnectFun(Client),
    ContinueFn = fun() -> loop(Parent, N, Client, PubSub, loop_opts(AllOpts)) end,
    case ConnRet of
        {ok, _Props} ->
            Res =
                case PubSub of
                    conn -> ok;
                    sub -> subscribe(Client, N, AllOpts);
                    pub -> case MRef of
                               undefined ->
                                   erlang:send_after(RandomPubWaitMS, self(), publish);
                               _ ->
                                   %% send `publish' only when all publishers
                                   %% are in place.
                                   ok
                           end
                end,
            case Res of
                {error, _SubscribeError} ->
                    maybe_retry(Parent, N, PubSub, Opts, ContinueFn);
                _ ->
                    inc_counter(connect_succ),
                    PubSub =:= sub andalso inc_counter(sub),
                    loop(Parent, N, Client, PubSub, loop_opts(AllOpts))
            end;
        {error, Error} ->
            io:format("client(~w): connect error - ~p~n", [N, Error]),
            maybe_retry(Parent, N, PubSub, Opts, ContinueFn)
    end.

drain_published_pub() ->
    receive
        published ->
            inc_counter(recv),
            drain_published_pub();
        puback ->
            %% Publish success for QoS 1 (recv puback) and 2 (recv pubcomp)
            inc_counter(pub_succ),
            drain_published_pub()
    after
        0 ->
            ok
    end.

maybe_retry(Parent, N, PubSub, Opts, ContinueFn) ->
    MaxRetries = proplists:get_value(num_retry_connect, Opts, 0),
    Retries = proplists:get_value(connection_attempts, Opts, 0),
    case Retries >= MaxRetries of
        true ->
            inc_counter(connect_fail),
            PubSub =:= sub andalso inc_counter(sub_fail),
            ContinueFn();
        false ->
            io:format("client(~w): retrying...~n", [N]),
            NOpts = proplists:delete(connection_attempts, Opts),
            connect(Parent, N, PubSub, [{connection_attempts, Retries + 1} | NOpts])
    end.

loop_pub(Parent, Clients, Opts) ->
    LoopPid = proplists:get_value(loop_pid, Opts, self()),
    Idle = max(proplists:get_value(interval_of_msg, Opts, 0) * 2, 500),
    MRef = proplists:get_value(publish_signal_mref, Opts),
    receive
        {'DOWN', MRef, process, _Pid, start_publishing} ->
            RandomPubWaitMS = proplists:get_value(pub_start_wait, Opts),
            NumClients = maps:size(Clients),
            lists:foreach(fun(C) ->
                                  erlang:send_after(RandomPubWaitMS, LoopPid, {publish, C})
                          end,
                         maps:keys(NumClients)),
            loop_pub(Parent, Clients, Opts);
        ?PUBLISH(ClientPID, Seq) ->
            case (proplists:get_value(limit_fun, Opts))() of
                true ->
                    spawn(
                      fun() ->
                              %% this call hangs if emqtt inflight is full
                              case publish_pub(ClientPID, Seq, Opts) of
                                  ok -> next_publish_pub(ClientPID, Seq, Opts);
                                  {ok, _} -> next_publish_pub(ClientPID, Seq, Opts);
                                  {error, Reason} ->
                                      inc_counter(pub_fail),
                                      io:format("client: publish error - ~p~n", [Reason])
                              end
                      end),
                    loop_pub(Parent, Clients, Opts);
                _ ->
                    Parent ! publish_complete,
                    exit(normal)
            end;
        published ->
            inc_counter(recv),
            loop_pub(Parent, Clients, Opts);
        {'EXIT', _Client, normal} ->
            loop_pub(Parent, Clients, Opts);
        {'EXIT', _Client, Reason} ->
            io:format("client: EXIT for ~p~n", [Reason]),
            loop_pub(Parent, Clients, Opts);
        puback ->
            %% Publish success for QoS 1 (recv puback) and 2 (recv pubcomp)
            inc_counter(pub_succ),
            loop_pub(Parent, Clients, Opts);
        {disconnected, ReasonCode, _Meta} ->
            io:format("client: disconnected with reason ~w: ~p~n",
                      [ReasonCode, emqtt:reason_code_name(ReasonCode)]),
            loop_pub(Parent, Clients, Opts);
        Other ->
            io:format("client: discarded unkonwn message ~p~n", [Other]),
            loop_pub(Parent, Clients, Opts)
    after
        Idle ->
            case proplists:get_bool(lowmem, Opts) of
                true ->
                    LClients = maps:keys(Clients),
                    lists:foreach(fun(C) -> garbage_collect(C, [{type, major}]) end, LClients),
                    erlang:garbage_collect(self(), [{type, major}]);
                false ->
                    skip
            end,
            proc_lib:hibernate(?MODULE, loop_pub, [Parent, Clients, Opts])
    end.

loop(Parent, N, Client, PubSub, Opts) ->
    Idle = max(proplists:get_value(interval_of_msg, Opts, 0) * 2, 500),
    MRef = proplists:get_value(publish_signal_mref, Opts),
    receive
        {'DOWN', MRef, process, _Pid, start_publishing} ->
            RandomPubWaitMS = proplists:get_value(pub_start_wait, Opts),
            erlang:send_after(RandomPubWaitMS, self(), publish),
            loop(Parent, N, Client, PubSub, Opts);
        publish ->
           case (proplists:get_value(limit_fun, Opts))() of
                true ->
                   %% this call hangs if emqtt inflight is full
                    case publish(Client, Opts) of
                        ok -> next_publish(Opts);
                        {ok, _} -> next_publish(Opts);
                        {error, Reason} ->
                            inc_counter(pub_fail),
                            io:format("client(~w): publish error - ~p~n", [N, Reason])
                    end,
                    loop(Parent, N, Client, PubSub, Opts);
                _ ->
                    Parent ! publish_complete,
                    exit(normal)
            end;
        published ->
            inc_counter(recv),
            loop(Parent, N, Client, PubSub, Opts);
        {'EXIT', _Client, normal} ->
            ok;
        {'EXIT', _Client, Reason} ->
            io:format("client(~w): EXIT for ~p~n", [N, Reason]);
        puback ->
            %% Publish success for QoS 1 (recv puback) and 2 (recv pubcomp)
            inc_counter(pub_succ),
            loop(Parent, N, Client, PubSub, Opts);
        {disconnected, ReasonCode, _Meta} ->
            io:format("client(~w): disconnected with reason ~w: ~p~n",
                      [N, ReasonCode, emqtt:reason_code_name(ReasonCode)]);
        Other ->
            io:format("client(~w): discarded unkonwn message ~p~n", [N, Other]),
            loop(Parent, N, Client, PubSub, Opts)
    after
        Idle ->
            case proplists:get_bool(lowmem, Opts) of
                true ->
                    erlang:garbage_collect(Client, [{type, major}]),
                    erlang:garbage_collect(self(), [{type, major}]);
                false ->
                    skip
            end,
            proc_lib:hibernate(?MODULE, loop, [Parent, N, Client, PubSub, Opts])
	end.

put_publish_begin_time() ->
    NowT = erlang:monotonic_time(millisecond),
    put(last_publish_ts, NowT),
    ok.

next_publish(Opts) ->
    LoopPid = proplists:get_value(loop_pid, Opts, self()),
    Interval = proplists:get_value(interval_of_msg, Opts),
    LastT = get(last_publish_ts),
    NowT = erlang:monotonic_time(millisecond),
    Spent = NowT - LastT,
    Remain = Interval - Spent,
    Interval > 0 andalso Remain < 0 andalso inc_counter(pub_overrun),
    inc_counter(pub),
    case Remain > 0 of
        true -> _ = erlang:send_after(Remain, LoopPid, publish);
        false -> LoopPid ! publish
    end,
    ok.

next_publish_pub(Client, Seq, Opts) ->
    LoopPid = proplists:get_value(loop_pid, Opts, self()),
    Interval = proplists:get_value(interval_of_msg, Opts),
    LastT = get(last_publish_ts),
    NowT = erlang:monotonic_time(millisecond),
    Spent = NowT - LastT,
    Remain = Interval - Spent,
    Interval > 0 andalso Remain < 0 andalso inc_counter(pub_overrun),
    inc_counter(pub),
    case Remain > 0 of
        true -> _ = erlang:send_after(Remain, LoopPid, ?PUBLISH(Client, Seq));
        false -> LoopPid ! ?PUBLISH(Client, Seq)
    end,
    ok.

consumer_pub_msg_fun_init(0) ->
    fun() -> true end;
consumer_pub_msg_fun_init(N) when is_integer(N), N > 0 ->
    Ref = counters:new(1, []),
    counters:put(Ref, 1, N),
    fun() ->
        case counters:get(Ref, 1) of
            0 -> false;
            _ ->
                counters:sub(Ref, 1, 1), true
        end
    end.

subscribe(Client, N, Opts) ->
    Qos = proplists:get_value(qos, Opts),
    Res = emqtt:subscribe(Client, [{Topic, Qos} || Topic <- topics_opt(Opts)]),
    case Res of
        {ok, _, _} ->
            ok;
        {error, Reason} ->
            io:format("client(~w): subscribe error - ~p~n", [N, Reason]),
            emqtt:disconnect(Client, ?RC_UNSPECIFIED_ERROR)
    end,
    Res.

publish(Client, Opts) ->
    ok = put_publish_begin_time(),
    Flags   = [{qos, proplists:get_value(qos, Opts)},
               {retain, proplists:get_value(retain, Opts)}],
    Payload = proplists:get_value(payload, Opts),
    emqtt:publish(Client, topic_opt(Opts), Payload, Flags).

publish_pub(Client, Seq, Opts) ->
    ok = put_publish_begin_time(),
    Flags   = [{qos, proplists:get_value(qos, Opts)},
               {retain, proplists:get_value(retain, Opts)}],
    Payload = proplists:get_value(payload, Opts),
    emqtt:publish(Client, topic_opt([{seq, Seq} | Opts]), Payload, Flags).

session_property_opts(Opts) ->
    case session_property_opts(Opts, #{}) of
        Empty when map_size(Empty) =:= 0 ->
            [];
        PropertyOpts ->
            [{properties, PropertyOpts}]
    end.

session_property_opts([{expiry, Exp}|Left], Props) ->
    session_property_opts(Left, Props#{'Session-Expiry-Interval' => Exp});
session_property_opts([_|Left], Props) ->
    session_property_opts(Left, Props);
session_property_opts([], Props) ->
    Props.

mqtt_opts(Opts) ->
    WorkerPid = self(),
    Handler = #{ publish => fun(_) -> WorkerPid ! published end
               , puback => fun(_) -> WorkerPid ! puback end
               , disconnected => fun({ReasonCode, _}) ->
                                      WorkerPid ! {disconnected, ReasonCode, #{}};
                                    (_Reason) ->
                                      WorkerPid ! {disconnected, 16#80, #{}}
                                 end
               },
    mqtt_opts(Opts, [{msg_handler, Handler}]).

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
mqtt_opts([{lowmem, Bool}|Opts], Acc) ->
    mqtt_opts(Opts, [{low_mem, Bool} | Acc]);
mqtt_opts([{inflight, InFlight0}|Opts], Acc) ->
    InFlight = case InFlight0 of
                   0 -> infinity;
                   _ -> InFlight0
               end,
    mqtt_opts(Opts, [{max_inflight, InFlight} | Acc]);
mqtt_opts([_|Opts], Acc) ->
    mqtt_opts(Opts, Acc).

tcp_opts(Opts) ->
    tcp_opts(Opts, []).
tcp_opts([], Acc) ->
    Acc;
tcp_opts([{lowmem, true} | Opts], Acc) ->
    tcp_opts(Opts, [{recbuf, 64} , {sndbuf, 64} | Acc]);
tcp_opts([{ifaddr, IfAddr} | Opts], Acc) ->
    case inet_parse:address(IfAddr) of
        {ok, IpAddr} ->
            tcp_opts(Opts, [{ip, IpAddr}|Acc]);
        {error, Reason} ->
            error({bad_ip_address, {IfAddr, Reason}})
    end;
tcp_opts([_|Opts], Acc) ->
    tcp_opts(Opts, Acc).

ssl_opts(Opts) ->
    ssl_opts(Opts, [{verify, verify_none}]).
ssl_opts([], Acc) ->
    [{ciphers, all_ssl_ciphers()} | Acc];
ssl_opts([{keyfile, KeyFile} | Opts], Acc) ->
    ssl_opts(Opts, [{keyfile, KeyFile}|Acc]);
ssl_opts([{certfile, CertFile} | Opts], Acc) ->
    ssl_opts(Opts, [{certfile, CertFile}|Acc]);
ssl_opts([_|Opts], Acc) ->
    ssl_opts(Opts, Acc).

all_ssl_ciphers() ->
    Vers = ['tlsv1', 'tlsv1.1', 'tlsv1.2', 'tlsv1.3'],
    lists:usort(lists:concat([ssl:cipher_suites(all, Ver) || Ver <- Vers])).

-spec connect_fun(proplists:proplist()) -> FunName :: atom().
connect_fun(Opts)->
    case {proplists:get_bool(ws, Opts), proplists:get_bool(quic, Opts)} of
        {true, true} ->
            throw({error, "unsupported transport: ws over quic "});
        {true, false} ->
            ws_connect;
        {false, true} ->
            quic_connect;
        {false, false} ->
            connect
    end.

client_id(PubSub, N, Opts) ->
    Prefix =
    case proplists:get_value(ifaddr, Opts) of
        undefined ->
            {ok, Host} = inet:gethostname(), Host;
        IfAddr    ->
            IfAddr
    end,
    case { proplists:get_value(shortids, Opts)
         , proplists:get_value(prefix, Opts)
         } of
        {false, undefined} ->
            list_to_binary(lists:concat([Prefix, "_bench_", atom_to_list(PubSub),
                                    "_", N, "_", rand:uniform(16#FFFFFFFF)]));
        {false, Val} ->
            list_to_binary(lists:concat([Val, "_bench_", atom_to_list(PubSub),
                                         "_", N]));
        {true, Pref} when Pref =:= undefined; Pref =:= "" ->
            integer_to_binary(N);
        {true, Pref} ->
            list_to_binary(lists:concat([Pref, "_", N]))
    end.

topics_opt(Opts) ->
    Topics = topics_opt(Opts, []),
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

replace_opts(Opts, NewOpts) ->
    lists:foldl(fun({K, _V} = This, Acc) ->
                        lists:keyreplace(K, 1, Acc, This)
                end , Opts, NewOpts).

%% trim opts to save proc stack mem.
loop_opts(Opts) ->
    lists:filter(fun({K,__V}) ->
                         lists:member(K, [ interval_of_msg
                                         , payload
                                         , qos
                                         , retain
                                         , topic
                                         , lowmem
                                         , limit_fun
                                         , seq
                                         , publish_signal_mref
                                         , pub_start_wait
                                         , loop_pid
                                         ])
                 end, Opts).

-spec maybe_start_quicer() -> boolean().
maybe_start_quicer() ->
    case is_quicer_supp() of
        true ->
            case application:ensure_all_started(quicer) of
                {error, {quicer, {"no such file or directory", _}}} -> false;
                {ok, _} -> true
            end;
        false ->
            false
    end.

-spec is_quicer_supp() -> boolean().
is_quicer_supp() ->
    not (is_centos_6()
         orelse is_win32()
         orelse is_quicer_disabled()).

is_quicer_disabled() ->
    false =/= os:getenv("BUILD_WITHOUT_QUIC").

is_centos_6() ->
    case file:read_file("/etc/centos-release") of
        {ok, <<"CentOS release 6", _/binary >>} ->
            true;
        _ ->
            false
    end.

is_win32() ->
    win32 =:= element(1, os:type()).

random_pub_wait_period(Opts) ->
    MaxRandomPubWaitMS = proplists:get_value(max_random_wait, Opts, 0),
    MinRandomPubWaitMS = proplists:get_value(min_random_wait, Opts, 0),
    case MaxRandomPubWaitMS - MinRandomPubWaitMS of
        Period when Period =< 0 -> MinRandomPubWaitMS;
        Period -> MinRandomPubWaitMS - 1 + rand:uniform(Period)
    end.

maybe_spawn_gc_enforcer(Opts) ->
    LowMemMode = proplists:get_bool(lowmem, Opts),
    ForceMajorGCInterval = proplists:get_value(force_major_gc_interval, Opts, 0),
    case {LowMemMode, ForceMajorGCInterval} of
        {false, _} ->
            ignore;
        {true, 0} ->
            ignore;
        {true, Interval} when Interval > 0 ->
            spawn(fun MajorGC () ->
                          timer:sleep(Interval),
                          lists:foreach(
                            fun(P) -> erlang:garbage_collect(P, [{type, major}]) end,
                            processes()),
                          MajorGC()
                  end);
        {true, _} ->
            ignore
    end.

-spec addr_to_list(string() | undefined) -> [Ipstr::string() | undefined].
addr_to_list(Input) ->
    case Input =/= undefined andalso lists:member($,, Input) of
        false ->
            [Input];
        true ->
            string:tokens(Input, ",")
    end.

-spec shard_addr(non_neg_integer(), [Ipstr::string()]) -> Ipstr::string().
shard_addr(N, AddrList) ->
    Offset = N rem length(AddrList),
    lists:nth(Offset + 1, AddrList).
