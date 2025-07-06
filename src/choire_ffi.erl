-module(choire_ffi).

-export([exec/3]).

exec(Command, Args, Cwd) ->
    Command_ = binary_to_list(Command),
    Args_ = lists:map(fun(Arg) -> binary_to_list(Arg) end, Args),
    Cwd_ = binary_to_list(Cwd),

    % Ensure working directory exists
    case ensure_directory(Cwd_) of
        ok ->
            execute_command(Command_, Args_, Cwd_);
        Error ->
            Error
    end.

ensure_directory(Dir) ->
    case filelib:is_dir(Dir) of
        true ->
            ok;
        false ->
            case file:make_dir(Dir) of
                ok ->
                    ok;
                {error, eexist} ->
                    ok;
                {error, Reason} ->
                    {error, {mkdir_failed, Reason}}
            end
    end.

execute_command(Command_, Args_, Cwd_) ->
    Name = case Command_ of
        "./" ++ _ ->
            {spawn_executable, Command_};
        "/" ++ _ ->
            {spawn_executable, Command_};
        _ ->
            case os:find_executable(Command_) of
                false ->
                    {error, {command_not_found, Command_}};
                Executable ->
                    {spawn_executable, Executable}
            end
    end,

    case Name of
        {error, _} = Error ->
            Error;
        {spawn_executable, Exec} ->
            Port = open_port({spawn_executable, Exec},
                           [exit_status,
                            binary,
                            hide,
                            stream,
                            eof,
                            stderr_to_stdout,
                            {args, Args_},
                            {cd, Cwd_}]),
            do_exec(Port, [])
    end.

do_exec(Port, Acc) ->
    receive
        {Port, {data, Data}} ->
            do_exec(Port, [Data | Acc]);
        {Port, {exit_status, 0}} ->
            port_close(Port),
            {ok, list_to_binary(lists:reverse(Acc))};
        {Port, {exit_status, Code}} ->
            port_close(Port),
            {error, {Code, list_to_binary(lists:reverse(Acc))}}
    end.
