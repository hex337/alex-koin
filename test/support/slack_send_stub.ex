defmodule AlexKoin.Test.SlackSendStub do
  @ets :slack_stub

  def init do
    :ets.new(@ets, [:set, :named_table, :public, read_concurrency: true,
                                                 write_concurrency: true])
    {:ok, %{}}
  end


  def respond_to(fun_name, list_of_args, value) do
    table = @ets
    key = fun_name
    # We're converting the list of arguments into a tuple because
    # match specs need to match on tuple elements. We also add the
    # returned value as the first elements so we can easily strip
    # it later before matching.
    element = List.to_tuple([value | list_of_args])
    true = :ets.insert(table, {key, element})
    :ok
  end

  # A stubbed function.
  def send_message(message, channel, slack) do
    respond! :send_message, [message, channel, slack]
  end

  def send_raw(message_json, slack) do
    respond! :send_raw, [message_json, slack]
  end

  defp respond!(fun_name, list_of_args) do
    table = @ets
    candidate_matches = :ets.tab2list(table)
    tuple_to_test = List.to_tuple(list_of_args)

    # Iterate through our ets and :ets.test_ms/2 each candidate
    # against this call. Note: stubs with exactly the same
    # arguments CAN AND WILL step on each other.
    matches = :ets.foldl(fn({^fun_name, query}, acc) ->
      # Convert to a list so we can extract the value to return
      # and match only on arguments.
      case Tuple.to_list(query) do
        [value | match_args] ->
          # Back to tuple and trying to match
          query_tuple = List.to_tuple(match_args)
          match_spec = {query_tuple, [], [:"$_"]}

          case :ets.test_ms(tuple_to_test, [match_spec]) do
            # No results, continue.
            {:ok, false} -> acc
            {:ok, []} -> acc

            # Match found, save it and continue.
            {:ok, element} -> [{match_args, value} | acc]
          end
        _ -> acc
      end

      # Skip if this stub is intended for other function names
      (_, acc) -> acc
    end,
    [],
    table
    )
    return!(fun_name, list_of_args, matches)
  end

  defp return!(fun_name, args, matches) do
    case matches do
      # Return the first match only
      [{_args, value} | _] -> if is_function(value) do
        :erlang.apply(value, args)
      else
        value
      end

      result ->
        raise RuntimeError,
          "Didn't find a response for #{__MODULE__}:#{fun_name} " <>
          "with #{inspect args}"
    end
  end
end
