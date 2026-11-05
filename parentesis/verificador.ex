# Integrantes: Luisa Hernández, Isabella Hincapié, Camila González

defmodule VerificadorParentesis do
  @moduledoc """
  Módulo encargado de verificar con recursión las cadenas propuestas (n;p;cadena)
  e indicar si son válidas o los motivos por los que no lo son.
  """

  @doc """
  Lee las propuestas y escribe el informe de cada una en el archivo de salida. Devuelve :no_existe si el archivo de entrada no existe.
  """
  def verificar_archivo(ruta_entrada, ruta_salida) do
    if File.exists?(ruta_entrada) do
      {:ok, salida} = File.open(ruta_salida, [:write, :utf8])

      ruta_entrada
      |> File.stream!()
      |> Stream.with_index(1)
      |> Stream.map(fn {linea, numero} -> {numero, String.trim(linea)} end)
      |> Stream.filter(fn {_numero, texto} -> texto != "" end)
      |> Stream.filter(fn {_numero, texto} -> not String.starts_with?(texto, "#") end)
      |> Enum.each(fn {numero, texto} ->
        informe = verificar_linea(numero, texto)
        IO.write(salida, informe)
      end)

      File.close(salida)
      :ok
    else
      IO.puts("AVISO: no se encontró el archivo #{ruta_entrada}.")
      :no_existe
    end
  end

  # Separa n;p;cadena y valida que n y p sean enteros. Devuelve el texto del informe.
  defp verificar_linea(numero, texto) do
    case String.split(texto, ";") do
      [n_texto, p_texto, cadena_sin_limpiar] ->
        cadena = String.trim(cadena_sin_limpiar)
        resultado_n = Integer.parse(String.trim(n_texto))
        resultado_p = Integer.parse(String.trim(p_texto))

        case {resultado_n, resultado_p} do
          {{n, ""}, {p, ""}} ->
            evaluar(numero, n, p, cadena)

          _ ->
            "Línea #{numero}: formato inválido, n y p deben ser enteros: #{texto}\n"
        end

      _ ->
        "Línea #{numero}: formato inválido, se esperaba n;p;cadena: #{texto}\n"
    end
  end

  # Recorre la cadena con recursión y arma el informe con todos los motivos.
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

    # Se van agregando los motivos (lista vacía = la cadena es válida)
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

  # Caso base, termina cuando ya no quedan motivos y devuelve un texto vacío.
  defp formatear_motivos([]), do: ""

  # Caso recursivo, escribe el primer motivo en una línea y continúa con el resto.
  defp formatear_motivos([motivo | resto]) do
    "  - " <> motivo <> "\n" <> formatear_motivos(resto)
  end

  # Caso base, termina cuando ya no quedan símbolos y devuelve el estado final.
  defp recorrer([], _posicion, estado), do: estado

  # Caso recursivo, procesa el primer símbolo, actualiza el estado y continúa con el resto.
  defp recorrer([simbolo | resto], posicion, estado) do
    nuevo_estado = procesar_simbolo(simbolo, posicion, estado)
    recorrer(resto, posicion + 1, nuevo_estado)
  end

  # Para "(", sube el balance, actualiza la profundidad máxima y anota la primera posición donde se superó p.
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

  # Para ")", baja el balance y, si queda negativo, anota la primera posición donde cerró más de lo abierto.
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

  # Para cualquier otro símbolo, anota el primero que aparezca como inválido.
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
