%%%-----------------------------------------------------------------------------
%%% @Copyright (C) 2014-2016, Feng Lee <feng@emqtt.io>
%%%
%%% Permission is hereby granted, free of charge, to any person obtaining a copy
%%% of this software and associated documentation files (the "Software"), to deal
%%% in the Software without restriction, including without limitation the rights
%%% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
%%% copies of the Software, and to permit persons to whom the Software is
%%% furnished to do so, subject to the following conditions:
%%%
%%% The above copyright notice and this permission notice shall be included in all
%%% copies or substantial portions of the Software.
%%%
%%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%%% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%%% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%%% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%%% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%%% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
%%% SOFTWARE.
%%%-----------------------------------------------------------------------------

-module(emqtt_benchmark).

-export([main/2, start/2, run/3, connect/4, loop/4]).

-define(TAB, eb_stats).

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
    main_loop(os:timestamp(), 0).

prepare() ->
    application:ensure_all_started(emqtt_benchmark).

init() ->
    ets:new(?TAB, [public, named_table, {write_concurrency, true}]),
    put({stats, recv}, 0),
    ets:insert(?TAB, {recv, 0}),
    put({stats, sent}, 0),
    ets:insert(?TAB, {sent, 0}).

main_loop(Uptime, Count) ->
	receive
		{connected, _N, _Client} ->
			io:format("conneted: ~w~n", [Count]),
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

print_stats(Uptime, Key) ->
    [{Key, Val}] = ets:lookup(?TAB, Key),
    LastVal = get({stats, Key}),
    case Val == LastVal of
        false ->
            Tdiff = timer:now_diff(os:timestamp(), Uptime) div 1000,
            io:format("~s(~w): total=~w, rate=~w(msg/sec)~n",
                        [Key, Tdiff, Val, Val - LastVal]),
            put({stats, Key}, Val);
        true  ->
            ok
    end.

run(Parent, PubSub, Opts) ->
    run(Parent, proplists:get_value(count, Opts), PubSub, Opts).

run(_Parent, 0, _PubSub, _Opts) ->
    done;
run(Parent, N, PubSub, Opts) ->
    spawn(?MODULE, connect, [Parent, N, PubSub, Opts]),
	timer:sleep(proplists:get_value(interval, Opts)),
	run(Parent, N-1, PubSub, Opts).
    
connect(Parent, N, PubSub, Opts) ->
    process_flag(trap_exit, true),
    random:seed(os:timestamp()),
    ClientId = client_id(PubSub, N, Opts),
    MqttOpts = [{client_id, ClientId} | mqtt_opts(Opts)],
    TcpOpts  = tcp_opts(Opts),
    AllOpts  = [{seq, N}, {client_id, ClientId} | Opts],
	case emqttc:start_link(MqttOpts, TcpOpts) of
    {ok, Client} ->
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
        io:format("client ~p connect error: ~p~n", [N, Error])
    end.

loop(N, Client, PubSub, Opts) ->
    receive
        publish ->
            publish(Client, Opts),
            ets:update_counter(?TAB, sent, {2, 1}),
            loop(N, Client, PubSub, Opts);
        {publish, _Topic, _Payload} ->
            ets:update_counter(?TAB, recv, {2, 1}),
            loop(N, Client, PubSub, Opts);
        {'EXIT', Client, Reason} ->
            io:format("client ~p EXIT: ~p~n", [N, Reason])
	end.

subscribe(Client, Opts) ->
    Qos = proplists:get_value(qos, Opts),
    emqttc:subscribe(Client, [{Topic, Qos} || Topic <- topics_opt(Opts)]).

publish(Client, Opts) ->
    Flags   = [{qos, proplists:get_value(qos, Opts)},
               {retain, proplists:get_value(retain, Opts)}],
    Payload = proplists:get_value(payload, Opts),
    emqttc:publish(Client, topic_opt(Opts), Payload, Flags).

mqtt_opts(Opts) ->
    [{logger, error}|mqtt_opts(Opts, [])].
mqtt_opts([], Acc) ->
    Acc;
mqtt_opts([{host, Host}|Opts], Acc) ->
    mqtt_opts(Opts, [{host, Host}|Acc]);
mqtt_opts([{port, Port}|Opts], Acc) ->
    mqtt_opts(Opts, [{port, Port}|Acc]);
mqtt_opts([{username, Username}|Opts], Acc) ->
    mqtt_opts(Opts, [{username, list_to_binary(Username)}|Acc]);
mqtt_opts([{password, Password}|Opts], Acc) ->
    mqtt_opts(Opts, [{password, list_to_binary(Password)}|Acc]);
mqtt_opts([{keepalive, I}|Opts], Acc) ->
    mqtt_opts(Opts, [{keepalive, I}|Acc]);
mqtt_opts([{clean, Bool}|Opts], Acc) ->
    mqtt_opts(Opts, [{clean_sess, Bool}|Acc]);
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

client_id(PubSub, N, Opts) ->
    Prefix =
    case proplists:get_value(ifaddr, Opts) of
        undefined ->
            {ok, Host} = inet:gethostname(), Host;
        IfAddr    ->
            IfAddr
    end,
    list_to_binary(lists:concat([Prefix, "_bench_", atom_to_list(PubSub),
                                    "_", N, "_", random:uniform(16#FFFFFFFF)])).

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

