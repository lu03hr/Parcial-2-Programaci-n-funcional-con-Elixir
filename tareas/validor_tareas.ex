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

  defp analizar_registros([], filas, errores) do
    {invertir(filas, []), invertir(errores, [])}
  end
end
