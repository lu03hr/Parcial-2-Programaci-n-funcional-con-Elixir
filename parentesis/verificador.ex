defmodule VerificadorParentesis do

  defp recorrer([], _posicion, estado), do: estado
  defp recorrer([simbolo | resto], posicion, estado) do
    nuevo_estado = procesar_simbolo(simbolo, posicion, estado)
    recorrer(resto, posicion + 1, nuevo_estado)
  end


  defp procesar_simbolo("(", posicion, estado) do
    balance = estado.balance + 1

    profundidad =
      if balance > estado.profundidad do
        balance
      else
        estado.profundidad
      end

    exceso =
      if balance > estado.p and estado.exceso_profundidad == nil do
        posicion
      else
        estado.exceso_profundidad
      end

    %{estado | balance: balance, profundidad: profundidad, exceso_profundidad: exceso}
  end

  defp procesar_simbolo(")", posicion, estado) do
    balance = estado.balance - 1

    cierre =
      if balance < 0 and estado.cierre_excesivo == nil do
        posicion
      else
        estado.cierre_excesivo
      end

    %{estado | balance: balance, cierre_excesivo: cierre}
  end

  defp procesar_simbolo(otro, posicion, estado) do
    invalido =
      if estado.simbolo_invalido == nil do
        {posicion, otro}
      else
        estado.simbolo_invalido
      end

    %{estado | simbolo_invalido: invalido}
  end

end
