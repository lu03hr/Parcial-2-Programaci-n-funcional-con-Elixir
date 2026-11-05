defmodule VerificadorParentesis do

  defp evaluar(numero, n, p, cadena) do
    simbolos = String.graphemes(cadena)

    estado_inicial = %{
      balance: 0,
      profundidad: 0,
      simbolo_invalido: nil,
      cierre_excesivo: nil,
      exceso_profundidad: nil,
      p: p
    }

    estado = recorrer(simbolos, 0, estado_inicial)
    longitud = length(simbolos)

    motivos_1 =
      if longitud != 2 * n do
        ["La longitud es #{longitud} y debería ser #{2 * n}."]
      else
        []
      end

    motivos_2 =
      if estado.simbolo_invalido != nil do
        {posicion, simbolo} = estado.simbolo_invalido

        motivos_1 ++
          [
            "Contiene un símbolo no permitido '#{simbolo}' en la posición #{posicion} (solo se permiten '(' y ')')."
          ]
      else
        motivos_1
      end

    motivos_3 =
      if estado.cierre_excesivo != nil do
        posicion = estado.cierre_excesivo
        prefijo = String.slice(cadena, 0, posicion + 1)

        motivos_2 ++
          [
            "Cierra más paréntesis de los que abrió. Primer prefijo problemático: \"#{prefijo}\" (posición #{posicion})."
          ]
      else
        motivos_2
      end

    motivos_4 =
      if estado.balance != 0 do
        motivos_3 ++ ["Termina con balance #{estado.balance} y debería terminar en 0."]
      else
        motivos_3
      end

    motivos_5 =
      if estado.exceso_profundidad != nil do
        posicion = estado.exceso_profundidad
        prefijo = String.slice(cadena, 0, posicion + 1)

        motivos_4 ++
          [
            "Excede la profundidad máxima p=#{p}. Primer prefijo que la excede: \"#{prefijo}\" (posición #{posicion})."
          ]
      else
        motivos_4
      end

    if motivos_5 == [] do
      "Línea #{numero}: n=#{n}, p=#{p}, cadena=#{cadena} -> VÁLIDA (profundidad máxima alcanzada: #{estado.profundidad}).\n"
    else
      lineas_motivos = formatear_motivos(motivos_5)

      "Línea #{numero}: n=#{n}, p=#{p}, cadena=#{cadena} -> INVÁLIDA\n" <>
        lineas_motivos <> "  - Profundidad máxima alcanzada: #{estado.profundidad}.\n"
    end
  end

  
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
