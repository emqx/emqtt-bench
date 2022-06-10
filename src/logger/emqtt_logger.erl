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

-module(emqtt_logger).

%% API
-export([setup/1]).

-callback setup(list(any())) -> ok.

%%--------------------------------------------------------------------
%%% API
%%--------------------------------------------------------------------
setup(Opts) ->
    LogTo = proplists:get_value(log_to, Opts),
    setup(LogTo, Opts).

%%--------------------------------------------------------------------
%%% Internal functions
%%--------------------------------------------------------------------
setup(null, Opts) ->
    emqtt_logger_null:setup(Opts);
setup(console, Opts) ->
    emqtt_logger_console:setup(Opts).
