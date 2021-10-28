%% This Source Code Form is subject to the terms of the Mozilla Public
%% License, v. 2.0. If a copy of the MPL was not distributed with this
%% file, You can obtain one at https://mozilla.org/MPL/2.0/.
%%
%% Copyright (c) 2021 VMware, Inc. or its affiliates.  All rights reserved.
%%

-module(queries).

-include_lib("eunit/include/eunit.hrl").

-include("include/khepri.hrl").
-include("src/internal.hrl").
-include("test/helpers.hrl").

query_a_non_existing_node_test() ->
    S0 = khepri_machine:init(#{}),
    Root = khepri_machine:get_root(S0),
    Ret = khepri_machine:find_matching_nodes(Root, [foo], #{}),

    ?assertEqual(
       {ok, #{}},
       Ret).

query_an_existing_node_with_no_value_test() ->
    Commands = [#put{path = [foo, bar],
                     payload = ?DATA_PAYLOAD(value)}],
    S0 = khepri_machine:init(#{commands => Commands}),
    Root = khepri_machine:get_root(S0),
    Ret = khepri_machine:find_matching_nodes(Root, [foo], #{}),

    ?assertEqual(
       {ok, #{[foo] => #{payload_version => 1,
                         child_list_version => 1,
                         child_list_count => 1}}},
       Ret).

query_an_existing_node_with_value_test() ->
    Commands = [#put{path = [foo, bar],
                     payload = ?DATA_PAYLOAD(value)}],
    S0 = khepri_machine:init(#{commands => Commands}),
    Root = khepri_machine:get_root(S0),
    Ret = khepri_machine:find_matching_nodes(Root, [foo, bar], #{}),

    ?assertEqual(
       {ok, #{[foo, bar] => #{data => value,
                              payload_version => 1,
                              child_list_version => 1,
                              child_list_count => 0}}},
       Ret).

query_a_node_with_matching_condition_test() ->
    Commands = [#put{path = [foo],
                     payload = ?DATA_PAYLOAD(value)}],
    S0 = khepri_machine:init(#{commands => Commands}),
    Root = khepri_machine:get_root(S0),
    Ret = khepri_machine:find_matching_nodes(
            Root,
            [#if_all{conditions = [foo,
                                   #if_data_matches{pattern = value}]}],
            #{}),

    ?assertEqual(
       {ok, #{[foo] => #{data => value,
                         payload_version => 1,
                         child_list_version => 1,
                         child_list_count => 0}}},
       Ret).

query_a_node_with_non_matching_condition_test() ->
    Commands = [#put{path = [foo],
                     payload = ?DATA_PAYLOAD(value)}],
    S0 = khepri_machine:init(#{commands => Commands}),
    Root = khepri_machine:get_root(S0),
    Ret = khepri_machine:find_matching_nodes(
            Root,
            [#if_all{conditions = [foo,
                                   #if_data_matches{pattern = other}]}],
            #{}),

    ?assertEqual(
       {ok, #{}},
       Ret).

query_child_nodes_of_a_specific_node_test() ->
    Commands = [#put{path = [foo, bar],
                     payload = ?DATA_PAYLOAD(bar_value)},
                #put{path = [baz],
                     payload = ?DATA_PAYLOAD(baz_value)}],
    S0 = khepri_machine:init(#{commands => Commands}),
    Root = khepri_machine:get_root(S0),
    Ret = khepri_machine:find_matching_nodes(
            Root,
            [#if_name_matches{regex = any}],
            #{}),

    ?assertEqual(
       {ok, #{[] => #{payload_version => 1,
                      child_list_version => 3,
                      child_list_count => 2},
              [foo] => #{payload_version => 1,
                         child_list_version => 1,
                         child_list_count => 1},
              [baz] => #{data => baz_value,
                         payload_version => 1,
                         child_list_version => 1,
                         child_list_count => 0}}},
       Ret).

query_child_nodes_of_a_specific_node_with_condition_on_leaf_test() ->
    Commands = [#put{path = [foo, bar],
                     payload = ?DATA_PAYLOAD(bar_value)},
                #put{path = [baz],
                     payload = ?DATA_PAYLOAD(baz_value)}],
    S0 = khepri_machine:init(#{commands => Commands}),
    Root = khepri_machine:get_root(S0),
    Ret = khepri_machine:find_matching_nodes(
            Root,
            [#if_all{conditions = [#if_name_matches{regex = any},
                                   #if_child_list_count{count = {ge, 1}}]}],
            #{}),

    ?assertEqual(
       {ok, #{[foo] => #{payload_version => 1,
                         child_list_version => 1,
                         child_list_count => 1}}},
       Ret).

query_many_nodes_with_condition_on_parent_test() ->
    Commands = [#put{path = [foo, bar],
                     payload = ?DATA_PAYLOAD(bar_value)},
                #put{path = [foo, youpi],
                     payload = ?DATA_PAYLOAD(youpi_value)},
                #put{path = [baz],
                     payload = ?DATA_PAYLOAD(baz_value)},
                #put{path = [baz, pouet],
                     payload = ?DATA_PAYLOAD(pouet_value)}],
    S0 = khepri_machine:init(#{commands => Commands}),
    Root = khepri_machine:get_root(S0),
    Ret = khepri_machine:find_matching_nodes(
            Root,
            [#if_child_list_count{count = {gt, 1}},
             #if_name_matches{regex = any}],
            #{}),

    ?assertEqual(
       {ok, #{[foo, bar] => #{data => bar_value,
                              payload_version => 1,
                              child_list_version => 1,
                              child_list_count => 0},
              [foo, youpi] => #{data => youpi_value,
                                payload_version => 1,
                                child_list_version => 1,
                                child_list_count => 0}}},
       Ret).

query_many_nodes_recursively_test() ->
    Commands = [#put{path = [foo, bar],
                     payload = ?DATA_PAYLOAD(bar_value)},
                #put{path = [foo, youpi],
                     payload = ?DATA_PAYLOAD(youpi_value)},
                #put{path = [baz],
                     payload = ?DATA_PAYLOAD(baz_value)},
                #put{path = [baz, pouet],
                     payload = ?DATA_PAYLOAD(pouet_value)}],
    S0 = khepri_machine:init(#{commands => Commands}),
    Root = khepri_machine:get_root(S0),
    Ret = khepri_machine:find_matching_nodes(
            Root,
            [#if_path_matches{regex = any}],
            #{}),

    ?assertEqual(
       {ok, #{[] => #{payload_version => 1,
                      child_list_version => 3,
                      child_list_count => 2},
              [foo] => #{payload_version => 1,
                         child_list_version => 2,
                         child_list_count => 2},
              [foo, bar] => #{data => bar_value,
                              payload_version => 1,
                              child_list_version => 1,
                              child_list_count => 0},
              [foo, youpi] => #{data => youpi_value,
                                payload_version => 1,
                                child_list_version => 1,
                                child_list_count => 0},
              [baz] => #{data => baz_value,
                         payload_version => 1,
                         child_list_version => 2,
                         child_list_count => 1},
              [baz, pouet] => #{data => pouet_value,
                                payload_version => 1,
                                child_list_version => 1,
                                child_list_count => 0}}},
       Ret).

query_many_nodes_recursively_using_regex_test() ->
    Commands = [#put{path = [foo, bar],
                     payload = ?DATA_PAYLOAD(bar_value)},
                #put{path = [foo, youpi],
                     payload = ?DATA_PAYLOAD(youpi_value)},
                #put{path = [baz],
                     payload = ?DATA_PAYLOAD(baz_value)},
                #put{path = [baz, pouet],
                     payload = ?DATA_PAYLOAD(pouet_value)}],
    S0 = khepri_machine:init(#{commands => Commands}),
    Root = khepri_machine:get_root(S0),
    Ret = khepri_machine:find_matching_nodes(
            Root,
            [#if_path_matches{regex = "o"}],
            #{}),

    ?assertEqual(
       {ok, #{[foo] => #{payload_version => 1,
                         child_list_version => 2,
                         child_list_count => 2},
              [foo, youpi] => #{data => youpi_value,
                                payload_version => 1,
                                child_list_version => 1,
                                child_list_count => 0},
              [baz, pouet] => #{data => pouet_value,
                                payload_version => 1,
                                child_list_version => 1,
                                child_list_count => 0}}},
       Ret).

query_many_nodes_recursively_with_condition_on_leaf_test() ->
    Commands = [#put{path = [foo, bar],
                     payload = ?DATA_PAYLOAD(bar_value)},
                #put{path = [foo, youpi],
                     payload = ?DATA_PAYLOAD(youpi_value)},
                #put{path = [baz],
                     payload = ?DATA_PAYLOAD(baz_value)},
                #put{path = [baz, pouet],
                     payload = ?DATA_PAYLOAD(pouet_value)}],
    S0 = khepri_machine:init(#{commands => Commands}),
    Root = khepri_machine:get_root(S0),
    Ret = khepri_machine:find_matching_nodes(
            Root,
            [#if_path_matches{regex = any}, #if_name_matches{regex = "o"}],
            #{}),

    ?assertEqual(
       {ok, #{[foo, youpi] => #{data => youpi_value,
                                payload_version => 1,
                                child_list_version => 1,
                                child_list_count => 0},
              [baz, pouet] => #{data => pouet_value,
                                payload_version => 1,
                                child_list_version => 1,
                                child_list_count => 0}}},
       Ret).

query_many_nodes_recursively_with_condition_on_self_test() ->
    Commands = [#put{path = [foo, bar],
                     payload = ?DATA_PAYLOAD(bar_value)},
                #put{path = [foo, youpi],
                     payload = ?DATA_PAYLOAD(youpi_value)},
                #put{path = [baz],
                     payload = ?DATA_PAYLOAD(baz_value)},
                #put{path = [baz, pouet],
                     payload = ?DATA_PAYLOAD(pouet_value)}],
    S0 = khepri_machine:init(#{commands => Commands}),
    Root = khepri_machine:get_root(S0),
    Ret = khepri_machine:find_matching_nodes(
            Root,
            [#if_all{conditions = [#if_path_matches{regex = any},
                                   #if_data_matches{pattern = '_'}]}],
            #{}),

    ?assertEqual(
       {ok, #{[foo, bar] => #{data => bar_value,
                              payload_version => 1,
                              child_list_version => 1,
                              child_list_count => 0},
              [foo, youpi] => #{data => youpi_value,
                                payload_version => 1,
                                child_list_version => 1,
                                child_list_count => 0},
              [baz] => #{data => baz_value,
                         payload_version => 1,
                         child_list_version => 2,
                         child_list_count => 1},
              [baz, pouet] => #{data => pouet_value,
                                payload_version => 1,
                                child_list_version => 1,
                                child_list_count => 0}}},
       Ret).

query_many_nodes_recursively_with_several_star_star_test() ->
    Commands = [#put{path = [foo, bar, baz, qux],
                     payload = ?DATA_PAYLOAD(qux_value)},
                #put{path = [foo, youpi],
                     payload = ?DATA_PAYLOAD(youpi_value)},
                #put{path = [baz],
                     payload = ?DATA_PAYLOAD(baz_value)},
                #put{path = [baz, pouet],
                     payload = ?DATA_PAYLOAD(pouet_value)}],
    S0 = khepri_machine:init(#{commands => Commands}),
    Root = khepri_machine:get_root(S0),
    Ret = khepri_machine:find_matching_nodes(
            Root,
            [#if_path_matches{regex = any},
             baz,
             #if_path_matches{regex = any}],
            #{}),

    ?assertEqual(
       {ok, #{[foo, bar, baz, qux] => #{data => qux_value,
                                        payload_version => 1,
                                        child_list_version => 1,
                                        child_list_count => 0}}},
       Ret).

query_a_node_using_relative_path_components_test() ->
    Commands = [#put{path = [foo, bar],
                     payload = ?DATA_PAYLOAD(value)}],
    S0 = khepri_machine:init(#{commands => Commands}),
    Root = khepri_machine:get_root(S0),
    Ret = khepri_machine:find_matching_nodes(
            Root, [?THIS_NODE, foo, ?PARENT_NODE, foo, bar], #{}),

    ?assertEqual(
       {ok, #{[foo, bar] => #{data => value,
                              payload_version => 1,
                              child_list_version => 1,
                              child_list_count => 0}}},
       Ret).

include_child_names_in_query_response_test() ->
    Commands = [#put{path = [foo, bar],
                     payload = ?DATA_PAYLOAD(bar_value)},
                #put{path = [foo, quux],
                     payload = ?DATA_PAYLOAD(quux_value)}],
    S0 = khepri_machine:init(#{commands => Commands}),
    Root = khepri_machine:get_root(S0),
    Ret = khepri_machine:find_matching_nodes(
            Root,
            [foo],
            #{include_child_names => true}),

    ?assertEqual(
       {ok, #{[foo] => #{payload_version => 1,
                         child_list_version => 2,
                         child_list_count => 2,
                         child_names => [bar, quux]}}},
       Ret).
