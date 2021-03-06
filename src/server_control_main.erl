-module(server_control_main).

-export([start/0]).

-include("common.hrl").
-define(RPC_TIMEOUT, infinity).

commands_desc() ->
    [{"stop", "停止游戏服务器进程"},
     {"stop_all", "停止游戏集群进程"},
     {"stop_app", "关闭server application"},
     {"start_app", "打开server application"},
     {"cluster_status", "集群状态"}].
opt_spec_list() ->
    Node = case get(nodename) of
               undefined ->
                   throw(not_nodename);
               V ->
                   V
           end,
    [
     {help, $h, "help", undefined, "显示帮助，然后退出"},
     {node, undefined, "node", {atom, Node}, "管理节点"}
    ].
usage() ->
    getopt:usage(opt_spec_list(), "server_ctl", "<command> [<args>]", commands_desc()),
    err_misc:quit(1).
parse_arguments(CmdLine) ->
    case getopt:parse(opt_spec_list(), CmdLine) of
        {ok, {Opts, [Command | Args]}} ->
            {ok, {list_to_atom(Command), Opts, Args}};
        {ok, {_Opts, []}} ->            
            no_command;
        Error ->
            io:format("Error ~p~n", [Error]),
            no_command
    end.

start() ->
    {ok, [[NodeStr|_]|_]} = init:get_argument(nodename),
    put(nodename, list_to_atom(NodeStr)),
    {Command, Opts, Args} =
        case parse_arguments(init:get_plain_arguments()) of
            {ok, Res}  -> 
                Res;
            no_command ->
                usage()
        end,
    Node = proplists:get_value(node, Opts),
    net_adm:ping(Node),
    timer:sleep(1000), %% wait auto find node
    %% The reason we don't use a try/catch here is that rpc:call turns
    %% thrown errors into normal return values
    % io:format("Opts ~p~n", [Opts]),
    case catch action(Command, Node, Args, Opts) of
        ok ->
            io:format("done.~n", []),
            quit(0);
        {ok, Info} ->
            io:format("done (~p).~n", [Info]),
            quit(0);        
        Other ->
            io:format("other result ~p~n", [Other]),
            quit(2)
    end.
action(stop_all, MasterNode, _Args, _Opts) ->
    io:format("Stopping and halting all node~n", []),
    PidMRefs = [{spawn_monitor(fun() -> 
                                      call(Node, {main, stop_and_halt, [5]})
                              end), Node}
                || Node <- nodes() -- [MasterNode]], 
    [receive
         {'DOWN', MRef, process, _, normal} -> 
             ok;
         {'DOWN', MRef, process, _, Reason} ->
             io:format("Node ~p Error, Reason ~p", [Node, Reason])
     end || {{_Pid, MRef}, Node} <- PidMRefs],
    call(MasterNode, {main, stop_and_halt, [5]}),
    ok;
action(reload_all, Node, _, _) ->
    io:format("reload all module ~p~n", [Node]),
    call(Node, {reloader_misc, reload_all, []});
action(stop, Node, _Args, _Opts) ->
    io:format("Stopping and halting node ~p~n", [Node]),
    call(Node, {main, stop_and_halt, [5]});
action(Command, _Node, Args, Opts) ->
    io:format("Command: ~p Args: ~p Opts: ~p~n", [Command, Args, Opts]),
    invalid_command.

call(Node, {Mod, Fun, Args}) ->
    %%rpc_call(Node, Mod, Fun, lists:map(fun list_to_binary/1, Args)).
    rpc_call(Node, Mod, Fun, Args).

rpc_call(Node, Mod, Fun, Args) ->
    rpc:call(Node, Mod, Fun, Args, ?RPC_TIMEOUT).


quit(Status) ->
    case os:type() of
        {unix,  _} -> 
            halt(Status);
        {win32, _} -> 
            init:stop(Status),
            receive
            after infinity -> 
                    ok
            end
    end.
