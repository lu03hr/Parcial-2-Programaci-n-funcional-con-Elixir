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


  defp revisar_ids([], _vistos, errores), do: invertir(errores, [])
end
