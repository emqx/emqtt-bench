%%%-----------------------------------------------------------------------------
%%% @Copyright (C) 2014-2015, Feng Lee <feng@emqtt.io>
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
%%% @doc
%%% eMQTTD Benchmark Client.
%%%
%%% @end
%%%-----------------------------------------------------------------------------
-module(emqttd_benchmark).

-export([start/1, run/3, connect/3, loop/3]).

-record(server, {host = "localhost", port = 1883, maxclients = 10000, interval = 10}).

-define(LOGGER, {console, warning}).

start([Host, Port, MaxClients, Interval]) when is_atom(Host), is_atom(Port), is_atom(MaxClients), is_atom(Interval) ->
    Server = #server{host       = atom_to_list(Host),
                     port       = int(Port),
                     maxclients = int(MaxClients),
                     interval   = int(Interval)},
	start(Server);

start(Server = #server{maxclients = MaxClients}) ->
	spawn(?MODULE, run, [self(), Server, MaxClients]),
	mainloop(1).

mainloop(Count) ->
	receive
		{connected, _Client} ->
			io:format("conneted: ~p~n", [Count]),
			mainloop(Count+1)
	end.

run(_Parent, _Server, 0) ->
	ok;
run(Parent, Server = #server{interval = Interval}, N) ->
	spawn(?MODULE, connect, [Parent, Server, N]),
	timer:sleep(Interval),
	run(Parent, Server, N-1).

connect(Parent, #server{host = Host, port = Port}, N) ->
    {ok, LocHost} = inet:gethostname(),
    ClientId = client_id(LocHost, N),
	case emqttc:start_link([{host, Host}, {port, Port}, {client_id, ClientId}, {logger, ?LOGGER}]) of
    {ok, Client} -> 
        Parent ! {connected, Client},
        random:seed(now()),
        process_flag(trap_exit, true),
        Topic = topic(LocHost, N),
        emqttc:subscribe(Client, Topic),
        loop(N, Client, Topic);
    {error, Error} ->
        io:format("client ~p connect error: ~p~n", [N, Error])
    end.

loop(N, Client, Topic) ->
	Timeout = 5000 + random:uniform(5000),
    receive
        {publish, Topic, _Payload} ->
            %io:format("Message Received from ~s: ~p~n", [Topic, Payload])
            loop(N, Client, Topic);
        {'EXIT', Client, Reason} ->
            io:format("client ~p EXIT: ~p~n", [N, Reason])
	after
		Timeout -> send(N, Client, Topic), loop(N, Client, Topic)
	end.

send(N, Client, Topic) ->
    Payload = list_to_binary([integer_to_list(N), ":", <<"Hello, emqttd!">>]),
	emqttc:publish(Client, Topic, Payload).
	 
client_id(Host, N) ->
    list_to_binary(lists:concat(["testclient_", Host, "_", N, "_", random:uniform(16#FFFFFFFF)])).

topic(Host, N) ->
    list_to_binary(lists:concat([Host, "/", N, "/", random:uniform(16#FFFFFFFF)])).

int(A) when is_atom(A) -> list_to_integer(atom_to_list(A)).



