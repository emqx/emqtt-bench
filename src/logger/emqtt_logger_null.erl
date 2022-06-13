%%--------------------------------------------------------------------
%% Copyright (c) 2022 EMQ Technologies Co., Ltd. All Rights Reserved.
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

-module(emqtt_logger_null).

-behaviour(emqtt_logger).

%% API
-export([setup/1]).

%%--------------------------------------------------------------------
%%% API
%%--------------------------------------------------------------------
setup(_Opts) ->
    Logger = get_logger(),
    group_leader(Logger, self()),
    ok.

%%--------------------------------------------------------------------
%%% Internal functions
%%--------------------------------------------------------------------
get_logger() ->
    case erlang:whereis(?MODULE) of
        undefined ->
            Pid = start(),
            erlang:register(?MODULE, Pid),
            Pid;
        Pid ->
            Pid
    end.

start() ->
    spawn(fun loop/0).

loop() ->
    receive
        {io_request, From, Ref, _Req} ->
            From ! {io_reply, Ref, ok}
    end,
    loop().
