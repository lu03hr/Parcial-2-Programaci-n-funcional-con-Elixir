defmodule Planificador do

  def planificar(tareas, ruta_csv) do
    {:ok, archivo} = File.open(ruta_csv, [:write, :utf8])
    IO.write(archivo, "id;orden;duracion_total;penalizacion\n")

    # Se ordenan por id para que las tareas habilitadas se prueben de manera alfabetica
    pendientes = Enum.sort_by(tareas, fn tarea -> tarea.id end)

    acumulador = %{total: 0, minima: nil, mejores: [], tareas: tareas}

    resultado = explorar(pendientes, [], 0, acumulador, archivo)

    File.close(archivo)
    resultado
  end

  defp explorar([], hechas, tiempo, acumulador, archivo) do
    registrar_plan(hechas, tiempo, acumulador, archivo)
  end

  defp explorar(pendientes, hechas, tiempo, acumulador, archivo) do
    habilitadas =
      Enum.filter(pendientes, fn tarea ->
        dependencias_cumplidas?(tarea.dependencias, hechas)
      end)

    probar(habilitadas, pendientes, hechas, tiempo, acumulador, archivo)
  end

  defp probar([], _pendientes, _hechas, _tiempo, acumulador, _archivo), do: acumulador

  defp probar([tarea | otras], pendientes, hechas, tiempo, acumulador, archivo) do
    inicio = tiempo
    fin = tiempo + tarea.duracion

    nuevas_hechas = [{tarea.id, inicio, fin} | hechas]
    nuevos_pendientes = quitar_tarea(pendientes, tarea.id)

    acumulador_1 = explorar(nuevos_pendientes, nuevas_hechas, fin, acumulador, archivo)
    probar(otras, pendientes, hechas, tiempo, acumulador_1, archivo)
  end

  defp quitar_tarea(pendientes, id) do
    Enum.filter(pendientes, fn tarea -> tarea.id != id end)
  end

  defp dependencias_cumplidas?([], _hechas), do: true

  defp dependencias_cumplidas?([dependencia | resto], hechas) do
    if terminada?(dependencia, hechas) do
      dependencias_cumplidas?(resto, hechas)
    else
      false
    end
  end

  defp terminada?(_id, []), do: false

  defp terminada?(id, [{otro_id, _inicio, _fin} | resto]) do
    if id == otro_id do
      true
    else
      terminada?(id, resto)
    end
  end

  defp registrar_plan(hechas, tiempo_total, acumulador, archivo) do
    finalizaciones = Enum.reverse(hechas)
    orden = Enum.map(finalizaciones, fn {id, _inicio, _fin} -> id end)
    penalizacion = calcular_penalizacion(finalizaciones, acumulador.tareas, 0)

    plan = %Plan{orden: orden, finalizaciones: finalizaciones, penalizacion: penalizacion}

    numero = acumulador.total + 1
    texto_orden = Enum.join(orden, " → ")

    # Se escribe la fila de inmediato
    IO.write(archivo, "#{numero};#{texto_orden};#{tiempo_total};#{penalizacion}\n")

    actualizar_mejores(acumulador, numero, plan)
  end

  # calcular_penalizacion/3
  # Suma max(0, fin - plazo) de cada tarea del plan.
  defp calcular_penalizacion([], _tareas, suma), do: suma

  defp calcular_penalizacion([{id, _inicio, fin} | resto], tareas, suma) do
    tarea = buscar_tarea(tareas, id)
    retraso = fin - tarea.plazo

    # max(0, retraso): si terminó a tiempo no hay penalización
    penalizacion_tarea =
      if retraso > 0 do
        retraso
      else
        0
      end

    calcular_penalizacion(resto, tareas, suma + penalizacion_tarea)
  end


  defp buscar_tarea([tarea | resto], id) do
    if tarea.id == id do
      tarea
    else
      buscar_tarea(resto, id)
    end
  end


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

  def primer_plan_optimo(resultado) do
    case resultado.mejores do
      [{_numero, plan} | _resto] -> plan
      [] -> nil
    end
  end

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

  def escribir_resumen_vacio(ruta) do
    escribir_resumen_sin_planes(ruta, "Proyecto vacío: no hay tareas, no se enumeran planes.")
  end

  def escribir_resumen_invalido(ruta, cantidad) do
    escribir_resumen_sin_planes(
      ruta,
      "Red de tareas inválida (#{cantidad} problemas): no se enumeran planes. Ver validacion_tareas.txt"
    )
  end

  defp escribir_resumen_sin_planes(ruta, mensaje) do
    {:ok, archivo} = File.open(ruta, [:write, :utf8])
    escribir_linea(archivo, mensaje)
    File.close(archivo)
  end

  def escribir_planes_vacio(ruta) do
    {:ok, archivo} = File.open(ruta, [:write, :utf8])
    IO.write(archivo, "id;orden;duracion_total;penalizacion\n")
    File.close(archivo)
  end

  defp escribir_mejores(_archivo, []), do: :ok

  defp escribir_mejores(archivo, [{numero, plan} | resto]) do
    texto_orden = Enum.join(plan.orden, " → ")
    escribir_linea(archivo, "  Plan #{numero}: #{texto_orden} (penalización #{plan.penalizacion})")
    escribir_mejores(archivo, resto)
  end

  defp escribir_linea(archivo, texto) do
    IO.puts(texto)
    IO.write(archivo, texto <> "\n")
  end

  defp sumar_duraciones([], suma), do: suma

  defp sumar_duraciones([tarea | resto], suma) do
    sumar_duraciones(resto, suma + tarea.duracion)
  end
end
