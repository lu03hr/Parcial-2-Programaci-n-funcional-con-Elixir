#integrantes: Isabella Hincapié Bocanegra, Luisa Fernanda Hernandez, Camila González Restrepo


defmodule Planificador do
  @moduledoc """
  Módulo para encontrar recursivamente todos los planes válidos de un proyecto
  y escribir planes.csv y resumen_tareas.txt
  """

  @doc """
  Función para enumerar todos los planes válidos y escribir cada uno en planes.csv

  ## Parámetros

    - tareas: Lista de structs %Tarea{} ya validados.
    - ruta_csv: Ruta del archivo de planes.
  """
  def planificar(tareas, ruta_csv) do
    {:ok, archivo} = File.open(ruta_csv, [:write, :utf8])
    IO.write(archivo, "id;orden;duracion_total;penalizacion\n")

    pendientes = Enum.sort_by(tareas, fn tarea -> tarea.id end)

    acumulador = %{total: 0, minima: nil, mejores: [], tareas: tareas}

    resultado = explorar(pendientes, [], 0, acumulador, archivo)

    File.close(archivo)
    resultado
  end

  # Caso base: no quedan tareas pendientes, el plan está completo y se registra
  defp explorar([], hechas, tiempo, acumulador, archivo) do
    registrar_plan(hechas, tiempo, acumulador, archivo)
  end

  # Caso recursivo: busca las tareas habilitadas (dependencias terminadas) y las prueba
  defp explorar(pendientes, hechas, tiempo, acumulador, archivo) do
    habilitadas =
      Enum.filter(pendientes, fn tarea ->
        dependencias_cumplidas?(tarea.dependencias, hechas)
      end)

    probar(habilitadas, pendientes, hechas, tiempo, acumulador, archivo)
  end

  # Caso base: no hay más tareas habilitadas para probar
  defp probar([], _pendientes, _hechas, _tiempo, acumulador, _archivo), do: acumulador

  # ejecuta la primera habilitada, sigue explorando y luego retrocede para probar las otras
  defp probar([tarea | otras], pendientes, hechas, tiempo, acumulador, archivo) do
    inicio = tiempo
    fin = tiempo + tarea.duracion

    nuevas_hechas = [{tarea.id, inicio, fin} | hechas]
    nuevos_pendientes = quitar_tarea(pendientes, tarea.id)

    acumulador_1 = explorar(nuevos_pendientes, nuevas_hechas, fin, acumulador, archivo)
    probar(otras, pendientes, hechas, tiempo, acumulador_1, archivo)
  end

  # Quita de las pendientes la tarea con el id dado
  defp quitar_tarea(pendientes, id) do
    Enum.filter(pendientes, fn tarea -> tarea.id != id end)
  end

  # Verifica recursivamente que todas las dependencias ya estén terminadas
  defp dependencias_cumplidas?([], _hechas), do: true

  defp dependencias_cumplidas?([dependencia | resto], hechas) do
    if terminada?(dependencia, hechas) do
      dependencias_cumplidas?(resto, hechas)
    else
      false
    end
  end

  # Busca recursivamente si un id está en la lista de tareas hechas
  defp terminada?(_id, []), do: false

  defp terminada?(id, [{otro_id, _inicio, _fin} | resto]) do
    if id == otro_id do
      true
    else
      terminada?(id, resto)
    end
  end

  # arma el %Plan{}, calcula su penalización y escribe su fila en planes.csv de inmediato
  defp registrar_plan(hechas, tiempo_total, acumulador, archivo) do
    finalizaciones = Enum.reverse(hechas)
    orden = Enum.map(finalizaciones, fn {id, _inicio, _fin} -> id end)
    penalizacion = calcular_penalizacion(finalizaciones, acumulador.tareas, 0)

    plan = %Plan{orden: orden, finalizaciones: finalizaciones, penalizacion: penalizacion}

    numero = acumulador.total + 1
    texto_orden = Enum.join(orden, " → ")

    IO.write(archivo, "#{numero};#{texto_orden};#{tiempo_total};#{penalizacion}\n")

    actualizar_mejores(acumulador, numero, plan)
  end

  # suma max(0, fin - plazo) de cada tarea del plan
  defp calcular_penalizacion([], _tareas, suma), do: suma

  defp calcular_penalizacion([{id, _inicio, fin} | resto], tareas, suma) do
    tarea = buscar_tarea(tareas, id)
    retraso = fin - tarea.plazo

    penalizacion_tarea =
      if retraso > 0 do
        retraso
      else
        0
      end

    calcular_penalizacion(resto, tareas, suma + penalizacion_tarea)
  end

  # busca recursivamente el struct %Tarea{} que tiene el id dado
  defp buscar_tarea([tarea | resto], id) do
    if tarea.id == id do
      tarea
    else
      buscar_tarea(resto, id)
    end
  end

  # actualiza el acumulador, un plan mejor reinicia los mejores, un empate se agrega
  defp actualizar_mejores(acumulador, numero, plan) do
    minima = acumulador.minima

    cond do
      minima == nil or plan.penalizacion < minima ->
        %{acumulador | total: numero, minima: plan.penalizacion, mejores: [{numero, plan}]}

      plan.penalizacion == minima ->
        %{acumulador | total: numero, mejores: acumulador.mejores ++ [{numero, plan}]}

      true ->
        %{acumulador | total: numero}
    end
  end

  @doc """
  Función que devuelve el primer plan con penalización mínima, o nil si no hay planes
  """
  def primer_plan_optimo(resultado) do
    case resultado.mejores do
      [{_numero, plan} | _resto] -> plan
      [] -> nil
    end
  end

  @doc """
  Función para escribir el resumen del proyecto en el archivo y en pantalla
  """
  def escribir_resumen(resultado, tareas, ruta) do
    duracion_total = sumar_duraciones(tareas, 0)
    {:ok, archivo} = File.open(ruta, [:write, :utf8])

    escribir_linea(archivo, "Total de planes válidos: #{resultado.total}")

    if resultado.total == 0 do
      escribir_linea(archivo, "No existe ningún plan válido.")
    else
      escribir_linea(archivo, "Duración total del proyecto: #{duracion_total}")
      escribir_linea(archivo, "Penalización mínima: #{resultado.minima}")
      escribir_linea(archivo, "Planes con penalización mínima:")
      escribir_mejores(archivo, resultado.mejores)
    end

    File.close(archivo)
  end

  @doc """
  Función para escribir el resumen cuando el proyecto no tiene tareas
  """
  def escribir_resumen_vacio(ruta) do
    escribir_resumen_sin_planes(ruta, "Proyecto vacío: no hay tareas, no se enumeran planes.")
  end

  @doc """
  Función para escribir el resumen cuando la red de tareas es inválida
  """
  def escribir_resumen_invalido(ruta, cantidad) do
    escribir_resumen_sin_planes(
      ruta,
      "Red de tareas inválida (#{cantidad} problemas): no se enumeran planes. Ver validacion_tareas.txt"
    )
  end

  # reemplaza el resumen con un solo mensaje y lo muestra en pantalla
  defp escribir_resumen_sin_planes(ruta, mensaje) do
    {:ok, archivo} = File.open(ruta, [:write, :utf8])
    escribir_linea(archivo, mensaje)
    File.close(archivo)
  end

  @doc """
  Función para dejar planes.csv solo con el encabezado cuando no se enumeran planes
  """
  def escribir_planes_vacio(ruta) do
    {:ok, archivo} = File.open(ruta, [:write, :utf8])
    IO.write(archivo, "id;orden;duracion_total;penalizacion\n")
    File.close(archivo)
  end

  # escribe recursivamente cada plan con penalización mínima
  defp escribir_mejores(_archivo, []), do: :ok

  defp escribir_mejores(archivo, [{numero, plan} | resto]) do
    texto_orden = Enum.join(plan.orden, " → ")
    escribir_linea(archivo, "  Plan #{numero}: #{texto_orden} (penalización #{plan.penalizacion})")
    escribir_mejores(archivo, resto)
  end

  # muestra el texto en pantalla y lo escribe en el archivo
  defp escribir_linea(archivo, texto) do
    IO.puts(texto)
    IO.write(archivo, texto <> "\n")
  end

  # suma recursivamente la duración de todas las tareas
  defp sumar_duraciones([], suma), do: suma

  defp sumar_duraciones([tarea | resto], suma) do
    sumar_duraciones(resto, suma + tarea.duracion)
  end
end
