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

# Revisa que los IDs sean válidos y no estén duplicados. "vistos" es la lista de {id, linea} ya revisados (en orden de aparición).
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

  # Revisa que los campos numéricos sean válidos.
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

  # Revisa que las dependencias sean válidas (no esten vacías, repetidas, desconocidas o a sí misma). "todas" es la lista completa de filas (sirve para saber si un id existe).
    defp revisar_dependencias([], _todas, errores), do: invertir(errores, [])

  defp revisar_dependencias([{numero, id, _d, _p, deps_texto} | resto], todas, errores) do
    errores_1 =
      if deps_texto == "-" do
        # "-" significa que no tiene dependencias
        errores
      else
        lista = String.split(deps_texto, "|")
        revisar_lista_deps(lista, [], numero, id, todas, errores)
      end

    revisar_dependencias(resto, todas, errores_1)
  end

  # Revisa una lista de dependencias. "vistas" guarda las dependencias ya revisadas para detectar repetidas.
    defp revisar_lista_deps([], _vistas, _numero, _id, _todas, errores), do: errores

        defp revisar_lista_deps([dep_sin_limpiar | resto], vistas, numero, id, todas, errores) do
    dep = String.trim(dep_sin_limpiar)

    errores_1 =
      if dep == "" do
        ["Línea #{numero} (tarea '#{id}'): hay una dependencia vacía." | errores]
      else
        errores
      end

    errores_2 =
      if dep != "" and dep == id do
        ["Línea #{numero}: la tarea '#{id}' depende de sí misma." | errores_1]
      else
        errores_1
      end

    errores_3 =
      if dep != "" and esta_en_lista?(dep, vistas) do
        ["Línea #{numero} (tarea '#{id}'): la dependencia '#{dep}' está repetida." | errores_2]
      else
        errores_2
      end

    errores_4 =
      if dep != "" and dep != id and not existe_id?(dep, todas) do
        [
          "Línea #{numero} (tarea '#{id}'): la dependencia '#{dep}' no existe (tarea desconocida)."
          | errores_3
        ]
      else
        errores_3
      end

    revisar_lista_deps(resto, [dep | vistas], numero, id, todas, errores_4)
  end

  # Devuelve true si un id está en la lista de filas.
  defp existe_id?(_id, []), do: false

  defp existe_id?(id, [{_n, otro_id, _d, _p, _deps} | resto]) do
    if id == otro_id do
      true
    else
      existe_id?(id, resto)
    end
  end

  # Para cada fila arma {id, dependencias} quitando las inválidas (vacías, a sí misma, desconocidas o repetidas) para que el recorrido no se enrede.
  defp construir_grafo([], _todas, grafo), do: invertir(grafo, [])

  defp construir_grafo([{_n, id, _d, _p, deps_texto} | resto], todas, grafo) do
    dependencias =
      if deps_texto == "-" do
        []
      else
        filtrar_deps(String.split(deps_texto, "|"), id, todas, [])
      end

    construir_grafo(resto, todas, [{id, dependencias} | grafo])
  end

defp filtrar_deps([], _id, _todas, aceptadas), do: invertir(aceptadas, [])

  defp filtrar_deps([dep_sin_limpiar | resto], id, todas, aceptadas) do
    dep = String.trim(dep_sin_limpiar)

    es_valida =
      dep != "" and dep != id and existe_id?(dep, todas) and not esta_en_lista?(dep, aceptadas)

    if es_valida do
      filtrar_deps(resto, id, todas, [dep | aceptadas])
    else
      filtrar_deps(resto, id, todas, aceptadas)
    end
  end
# Busca ciclos en el grafo. "visitados" es la lista de nodos ya revisados y "ciclos" es la lista de ciclos encontrados.
  defp buscar_ciclos([], _grafo, _visitados, ciclos), do: invertir(ciclos, [])

  defp buscar_ciclos([{id, _deps} | resto], grafo, visitados, ciclos) do
    if esta_en_lista?(id, visitados) do
      buscar_ciclos(resto, grafo, visitados, ciclos)
    else
      ciclos_1 = ciclos_desde(id, id, [id], grafo, ciclos)
      buscar_ciclos(resto, grafo, [id | visitados], ciclos_1)
    end
  end

  # Invertir: Da la vuelta a una lista (reemplaza a Enum.reverse).
  defp invertir([], acumulado), do: acumulado
  defp invertir([primero | resto], acumulado), do: invertir(resto, [primero | acumulado])

  defp contar([], cantidad), do: cantidad
  defp contar([_primero | resto], cantidad), do: contar(resto, cantidad + 1)
end
