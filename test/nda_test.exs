defmodule NfaTest do
  use ExUnit.Case

  def nfa do
    %{
      states:   MapSet.new([0, 1, 2, 3]),
      alphabet: MapSet.new(["a", "b"]),
      transitions: %{
        {0, "a"} => [0, 1],
        {0, "b"} => [0],
        {1, "b"} => [2],
        {2, "b"} => [3]
      },
      start:     0,
      accepting: MapSet.new([3])
    }
  end

  def nfa_eps do
    %{
      states:   MapSet.new([0, 1, 2, 3]),
      alphabet: MapSet.new(["a", "b"]),
      transitions: %{
        {0, :epsilon} => [1],
        {1, :epsilon} => [2],
        {0, "a"}       => [0],
        {2, "b"}       => [3]
      },
      start:     0,
      accepting: MapSet.new([3])
    }
  end


  test "powerset: genera el conjunto potencia correctamente" do
    result = Automata.powerset([1, 2, 3])
    # 2^3 = 8 elementos
    assert length(result) == 8
    assert [] in result
    assert [1, 2, 3] in result

    assert Automata.powerset([]) == [[]]
  end

  test "e_closure: calcula correctamente estados alcanzables por epsilon" do
    nfa = nfa_eps()

    # ε-closure({0}) debe incluir 0, 1, 2 (cadena de ε-transiciones)
    assert Automata.e_closure(nfa.transitions, MapSet.new([0])) == MapSet.new([0, 1, 2])

    # ε-closure({1}) debe incluir 1 y 2
    assert Automata.e_closure(nfa.transitions, MapSet.new([1])) == MapSet.new([1, 2])

    # ε-closure({3}) solo contiene 3 (no hay ε-transiciones desde 3)
    assert Automata.e_closure(nfa.transitions, MapSet.new([3])) == MapSet.new([3])
  end

  test "determinize: convierte NFA simple a DFA determinista" do
    nfa = nfa()
    # Asumiendo que determinize devuelve {qp, sigma, inicio, final, delta}
    {_qp, _sigma, inicio_p, final_p, delta_p} = Automata.determinize(
      nfa.states,
      nfa.alphabet,
      nfa.start,
      nfa.accepting,
      nfa.transitions
    )

    # Estado inicial debe ser {0}
    assert inicio_p == MapSet.new([0])

    # Debe ser determinista (una sola transición por cada par estado-símbolo)
    # Verificamos que las llaves en el delta del DFA sean únicas
    for {state, symbol} <- Map.keys(delta_p) do
      assert Map.has_key?(delta_p, {state, symbol})
      # El valor debe ser un solo estado (o un MapSet que represente un nuevo estado)
      assert is_struct(delta_p[{state, symbol}], MapSet)
    end

    # Al menos un estado de aceptación debe contener el estado 3
    assert Enum.any?(final_p, fn set -> MapSet.member?(set, 3) end)
  end

  test "e_determinize: convierte NFA con epsilon a DFA" do
    nfa = nfa_eps()
    {_qp, _sigma, inicio_p, final_p, _delta_p} = Automata.e_determinize(
      nfa.states,
      nfa.alphabet,
      nfa.start,
      nfa.accepting,
      nfa.transitions
    )

    # El estado inicial debe considerar la clausura epsilon: {0, 1, 2}
    assert inicio_p == MapSet.new([0, 1, 2])

    # Debe haber un estado que acepte (el que contiene al 3)
    assert Enum.any?(final_p, fn set -> MapSet.member?(set, 3) end)
  end
end
