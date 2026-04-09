defmodule Nfa do
#Parámetros
#q: lista de estados del NFA, [0, 1, 2, 3]
#sigma: alfabeto [:a, :b]
#inicio: 0
# final: [3]
#delta: mapa de transiciones {estado, símbolo} => [estados], %{{0,:a}=>[0,1], {0,:b}=>[0], {1,:b}=>[2], {2,:b}=>[3]}

#QP - estados AFD
# sigma_p - alfabeto AFD
# final_p - aceptados AFD
# inicio_p - inicial AFD
# delta_p - transiciones AFD

  def determinize(_q, sigma, inicio, final, delta) do
    inicio_p = MapSet.new([inicio])
    final_set = MapSet.new(final)

    {qp, delta_p, final_p} =
      bfs([inicio_p], MapSet.new([inicio_p]), %{}, [], sigma, final_set, delta)

    {qp, sigma, inicio_p, final_p, delta_p}
  end

  defp bfs([], visited, delta_p, final_p, _sigma, _final_set, _delta) do
    {MapSet.to_list(visited), delta_p, final_p}
  end

  defp bfs([current | rest], visited, delta_p, final_p, sigma, final_set, delta) do
    {new_delta_p, new_states} =
      Enum.reduce(sigma, {delta_p, []}, fn symbol, {dp_acc, new_acc} ->
        target = move(current, symbol, delta)

        updated_delta_p =
          if MapSet.size(target) > 0 do
            Map.put(dp_acc, {current, symbol}, target)
          else
            dp_acc
          end

        new_unvisited =
          if MapSet.size(target) > 0 and not MapSet.member?(visited, target) do
            [target | new_acc]
          else
            new_acc
          end

        {updated_delta_p, new_unvisited}
      end)

    new_final_p =
      if MapSet.disjoint?(current, final_set) do
        final_p
      else
        [current | final_p]
      end

    new_visited = Enum.reduce(new_states, visited, &MapSet.put(&2, &1))
    new_queue = rest ++ new_states

    bfs(new_queue, new_visited, new_delta_p, new_final_p, sigma, final_set, delta)
  end

  defp move(state_set, symbol, delta) do
    state_set
    |> MapSet.to_list()
    |> Enum.flat_map(fn q -> Map.get(delta, {q, symbol}, []) end)
    |> MapSet.new()
  end
end
