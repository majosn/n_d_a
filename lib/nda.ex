defmodule Automata do
  # NFA / DFA se representan como mapas con la forma:
  #  %{
  # states: MapSet de estados
  # alphabet:MapSet de símbolos
  # transitions:lista de {src, symbol, tgt}  (symbol == :eps para ε),
  # start
  # accepting: MapSet
  # }

  def powerset([]), do: [[]]
  def powerset([h | t]) do
    pss = powerset(t)
    pss ++ Enum.map(pss, fn ss -> [h | ss] end)
  end

  # determinize
  def determinize(_states, alphabet, start, accepting, transitions) do
    start_set = MapSet.new([start])

    {dfa_states, dfa_delta} = explore([start_set], MapSet.new([start_set]), %{}, transitions, alphabet)

    final_p =
      dfa_states
      |> Enum.filter(fn d_state -> !MapSet.disjoint?(d_state, accepting) end)
      |> MapSet.new()

    {dfa_states, alphabet, start_set, final_p, dfa_delta}
  end

  # BFS para NFA sin transiciones epsilon
  defp explore([], visited, delta_acc, _, _), do: {MapSet.to_list(visited), delta_acc}
  defp explore([current | rest], visited, delta_acc, nfa_trans, alphabet) do
    {new_states, new_delta} =
      Enum.reduce(alphabet, {[], delta_acc}, fn symbol, {s_acc, d_acc} ->
        target =
          current
          |> Enum.flat_map(fn s -> Map.get(nfa_trans, {s, symbol}, []) end)
          |> MapSet.new()

        if MapSet.size(target) > 0 do
          {[target | s_acc], Map.put(d_acc, {current, symbol}, target)}
        else
          {s_acc, d_acc}
        end
      end)

    unvisited = Enum.reject(new_states, &MapSet.member?(visited, &1))
    new_visited = Enum.reduce(unvisited, visited, &MapSet.put(&2, &1))

    explore(rest ++ unvisited, new_visited, new_delta, nfa_trans, alphabet)
  end


  # e closure
  def e_closure(transitions, states) do
    # Convertimos a lista para iterar si es un MapSet
    states_list = MapSet.to_list(states)
    do_e_closure(transitions, states_list, MapSet.new(states_list))
  end

  defp do_e_closure(_transitions, [], visited), do: visited
  defp do_e_closure(transitions, [current | rest], visited) do
    eps_targets =
      Map.get(transitions, {current, :epsilon}, [])
      |> Enum.reject(&MapSet.member?(visited, &1))

    new_visited = Enum.reduce(eps_targets, visited, &MapSet.put(&2, &1))
    do_e_closure(transitions, rest ++ eps_targets, new_visited)
  end

  def e_determinize(_states, alphabet, start, accepting, transitions) do
    start_set = e_closure(transitions, MapSet.new([start]))

    {dfa_states, dfa_delta} = explore_eps([start_set], MapSet.new([start_set]), %{}, transitions, alphabet)

    final_p =
      dfa_states
      |> Enum.filter(fn d_state -> !MapSet.disjoint?(d_state, accepting) end)
      |> MapSet.new()

    {dfa_states, alphabet, start_set, final_p, dfa_delta}
  end

  # BFS para NFA con transiciones epsilon
  defp explore_eps([], visited, delta_acc, _, _), do: {MapSet.to_list(visited), delta_acc}
  defp explore_eps([current | rest], visited, delta_acc, nfa_trans, alphabet) do
    {new_states, new_delta} =
      Enum.reduce(alphabet, {[], delta_acc}, fn symbol, {s_acc, d_acc} ->
        moved =
          current
          |> Enum.flat_map(fn s -> Map.get(nfa_trans, {s, symbol}, []) end)
          |> MapSet.new()

        target = if MapSet.size(moved) > 0, do: e_closure(nfa_trans, moved), else: MapSet.new()

        if MapSet.size(target) > 0 do
          {[target | s_acc], Map.put(d_acc, {current, symbol}, target)}
        else
          {s_acc, d_acc}
        end
      end)

    unvisited = Enum.reject(new_states, &MapSet.member?(visited, &1))
    new_visited = Enum.reduce(unvisited, visited, &MapSet.put(&2, &1))

    explore_eps(rest ++ unvisited, new_visited, new_delta, nfa_trans, alphabet)
  end
end
