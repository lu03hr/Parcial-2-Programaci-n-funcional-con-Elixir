defmodule ValidorTareas do

    # Punto de entrada. Hace todas las revisiones, escribe el reporte y devuelve el resultado.
    def validar(registros, ruta_salida) do
    {filas, errores_formato} = analizar_registros(registros, [], [])

    errores_ids = revisar_ids(filas, [], [])
    errores_numeros = revisar_numeros(filas, [])
    errores_dependencias = revisar_dependencias(filas, filas, [])

    grafo = construir_grafo(filas, filas, [])
    ciclos = buscar_ciclos(grafo, grafo, [], [])
    errores_ciclos = describir_ciclos(ciclos, [])

    errores =
      errores_formato ++
        errores_ids ++ errores_numeros ++ errores_dependencias ++ errores_ciclos

    escribir_reporte(errores, ruta_salida)

    if errores == [] do
      :ok
    else
      {:error, contar(errores, 0)}
    end
  end


  # FORMATO: cada línea debe tener 4 campos separados por ; y Devuelve {filas, errores}. Cada fila es la tupla {numero, id, duracion, plazo, dependencias}
  defp analizar_registros([], filas, errores) do
    {invertir(filas, []), invertir(errores, [])}
  end

  defp analizar_registros([{numero, texto} | resto], filas, errores) do
    partes = String.split(texto, ";")

    case partes do
      [id, duracion, plazo, dependencias] ->
        fila =
          {numero, String.trim(id), String.trim(duracion), String.trim(plazo),
           String.trim(dependencias)}

        analizar_registros(resto, [fila | filas], errores)

      _ ->
        mensaje =
          "Línea #{numero}: se esperaban 4 campos separados por ';' pero hay #{length(partes)}."

        analizar_registros(resto, filas, [mensaje | errores])
    end
  end

# Revisa que los IDs sean válidos y no estén duplicados. Devuelve una lista de errores.
  defp revisar_ids([], _vistos, errores), do: invertir(errores, [])

  defp revisar_ids([{numero, id, _duracion, _plazo, _deps} | resto], vistos, errores) do
    errores_1 =
      if id == "" do
        ["Línea #{numero}: el identificador está vacío." | errores]
      else
        errores
      end

    errores_2 =
      if length(String.split(id, "|")) > 1 do
        ["Línea #{numero}: el ID '#{id}' no puede contener '|'." | errores_1]
      else
        errores_1
      end

    primera_linea = buscar_linea(id, vistos)

    errores_3 =
      if id != "" and primera_linea != nil do
        [
          "Línea #{numero}: el ID '#{id}' está duplicado (ya apareció en la línea #{primera_linea})."
          | errores_2
        ]
      else
        errores_2
      end

    revisar_ids(resto, vistos ++ [{id, numero}], errores_3)
  end

  # Busca la línea donde apareció un ID por primera vez. Devuelve nil si no se encuentra.
    defp buscar_linea(_id, []), do: nil

  defp buscar_linea(id, [{otro_id, linea} | resto]) do
    if id == otro_id do
      linea
    else
      buscar_linea(id, resto)
    end
  end

    defp revisar_numeros([], errores), do: invertir(errores, [])

    defp revisar_numeros([{numero, id, duracion, plazo, _deps} | resto], errores) do
    errores_1 =
      case Integer.parse(duracion) do
        {valor, ""} ->
          if valor > 0 do
            errores
          else
            ["Línea #{numero} (tarea '#{id}'): la duración #{duracion} debe ser positiva." | errores]
          end

        _ ->
          ["Línea #{numero} (tarea '#{id}'): la duración '#{duracion}' no es un entero." | errores]
      end

    errores_2 =
      case Integer.parse(plazo) do
        {valor, ""} ->
          if valor >= 0 do
            errores_1
          else
            ["Línea #{numero} (tarea '#{id}'): el plazo #{plazo} no puede ser negativo." | errores_1]
          end

        _ ->
          ["Línea #{numero} (tarea '#{id}'): el plazo '#{plazo}' no es un entero." | errores_1]
      end

    revisar_numeros(resto, errores_2)
  end

end
