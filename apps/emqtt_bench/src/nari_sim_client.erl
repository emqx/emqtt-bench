-module(nari_sim_client).

-include("nari_sim_client.hrl").

-export([ start_link/1
    , stop/1
]).

start_link({Opts}) ->
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
            Payload = nari_sim_client_utils:make_payload(),
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

