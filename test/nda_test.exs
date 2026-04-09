defmodule NfaTest do
  use ExUnit.Case

  test "Automata no determinista a determinista- fucnion determinize" do
    q      = [0, 1, 2, 3]
    sigma  = [:a, :b]
    inicio = 0
    final  = [3]
    delta  = %{
      {0, :a} => [0, 1],
      {0, :b} => [0],
      {1, :b} => [2],
      {2, :b} => [3]
    }

    {qp, sigma_p, inicio_p, final_p, delta_p} =
      Nfa.determinize(q, sigma, inicio, final, delta)

    q0  = MapSet.new([0])
    q01 = MapSet.new([0, 1])
    q02 = MapSet.new([0, 2])
    q03 = MapSet.new([0, 3])

    # El alfabeto no cambia
    assert sigma_p == [:a, :b]

    # El estado inicial es {0}
    assert inicio_p == q0

    # Los 4 subconjuntos alcanzables están presentes
    assert q0  in qp
    assert q01 in qp
    assert q02 in qp
    assert q03 in qp

    # Solo {0,3} es aceptado (intersecta con final del NFA)
    assert q03 in final_p
    refute q0  in final_p
    refute q01 in final_p
    refute q02 in final_p

    # Transiciones del DFA
    assert delta_p[{q0,  :a}] == q01
    assert delta_p[{q0,  :b}] == q0
    assert delta_p[{q01, :a}] == q01
    assert delta_p[{q01, :b}] == q02
    assert delta_p[{q02, :a}] == q01
    assert delta_p[{q02, :b}] == q03
    assert delta_p[{q03, :a}] == q01
    assert delta_p[{q03, :b}] == q0
  end
end
