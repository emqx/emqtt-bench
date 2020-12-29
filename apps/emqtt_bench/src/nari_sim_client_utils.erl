-module(nari_sim_client_utils).

%% API
-export([ make_payload/0 ]).

make_payload() ->
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

strftime({{Y,M,D}, {H,MM,S}}) ->
    lists:flatten(
        io_lib:format(
            "~4..0w-~2..0w-~2..0w ~2..0w:~2..0w:~2..0w", [Y, M, D, H, MM, S])).

get_datetime() ->
    list_to_binary(strftime(calendar:local_time())).

get_date_value1() ->
    lists:map(fun(_) -> list_to_float(float_to_list(rand:uniform(), [{decimals,1}])) end,
        lists:seq(1, 3)).

get_date_value2() ->
    rand:uniform(100).

