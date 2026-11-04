defmodule GanttSvg do

  defp escala, do: 40
  defp margen_izquierdo, do: 90
  defp margen_superior, do: 70
  defp separacion, do: 50
  defp alto_barra, do: 30


  def generar(plan, tareas, ruta) do
    {:ok, archivo} = File.open(ruta, [:write, :utf8])

    if plan == nil do
      escribir_sin_plan(archivo)
    else
      escribir_gantt(archivo, plan, tareas)
    end

    File.close(archivo)
  end

  # Si no hay plan (proyecto vacío o red inválida) se dibuja solo una leyenda.
  defp escribir_sin_plan(archivo) do
    IO.write(archivo, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n")

    IO.write(
      archivo,
      "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"620\" height=\"120\" viewBox=\"0 0 620 120\">\n"
    )

    IO.write(archivo, "  <rect x=\"0\" y=\"0\" width=\"620\" height=\"120\" fill=\"#ffffff\" />\n")

    texto = escapar("Sin plan: no hay tareas o la red de dependencias es inválida.")

    IO.write(
      archivo,
      "  <text x=\"20\" y=\"65\" font-family=\"Arial\" font-size=\"16\" fill=\"#333333\">#{texto}</text>\n"
    )

    IO.write(archivo, "</svg>\n")
  end

  # Dibuja el diagrama de Gantt en formato SVG, elemento por elemento, a partir del plan y las tareas.
  defp escribir_gantt(archivo, plan, tareas) do
    finalizaciones = plan.finalizaciones

    # El tiempo total es el "fin" de la última tarea del plan
    {_id, _inicio, tiempo_total} = Enum.at(finalizaciones, -1)

    # El eje llega hasta el mayor entre el tiempo total y el mayor plazo
    plazo_mayor = mayor_plazo(tareas, 0)

    limite =
      if plazo_mayor > tiempo_total do
        plazo_mayor
      else
        tiempo_total
      end

    cantidad = length(finalizaciones)
    ancho = margen_izquierdo() + limite * escala() + 150
    alto = margen_superior() + cantidad * separacion() + 90
    y_final_eje = margen_superior() + cantidad * separacion()

    # Encabezado del SVG
    IO.write(archivo, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n")

    IO.write(
      archivo,
      "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"#{ancho}\" height=\"#{alto}\" viewBox=\"0 0 #{ancho} #{alto}\">\n"
    )

    IO.write(
      archivo,
      "  <rect x=\"0\" y=\"0\" width=\"#{ancho}\" height=\"#{alto}\" fill=\"#ffffff\" />\n"
    )

    titulo =
      escapar("Diagrama de Gantt - duración #{tiempo_total} - penalización #{plan.penalizacion}")

    IO.write(
      archivo,
      "  <text x=\"20\" y=\"30\" font-family=\"Arial\" font-size=\"18\" font-weight=\"bold\" fill=\"#2c3e50\">#{titulo}</text>\n"
    )

    escribir_eje(archivo, 0, limite, y_final_eje)
    escribir_barras(archivo, finalizaciones, tareas, 0)
    escribir_leyenda(archivo, y_final_eje + 30)

    IO.write(archivo, "</svg>\n")
  end

  # Dibuja una línea vertical y un número por cada unidad de tiempo (de 0 hasta limite).
  defp escribir_eje(archivo, tiempo, limite, y_final) do
    if tiempo > limite do
      :ok
    else
      x = margen_izquierdo() + tiempo * escala()
      y_inicio = margen_superior() - 10

      IO.write(
        archivo,
        "  <line x1=\"#{x}\" y1=\"#{y_inicio}\" x2=\"#{x}\" y2=\"#{y_final}\" stroke=\"#dddddd\" stroke-width=\"1\" />\n"
      )

      IO.write(
        archivo,
        "  <text x=\"#{x}\" y=\"#{y_inicio - 6}\" font-family=\"Arial\" font-size=\"12\" text-anchor=\"middle\" fill=\"#555555\">#{tiempo}</text>\n"
      )

      escribir_eje(archivo, tiempo + 1, limite, y_final)
    end
  end


  defp escribir_barras(_archivo, [], _tareas, _indice), do: :ok

  defp escribir_barras(archivo, [{id, inicio, fin} | resto], tareas, indice) do
    tarea = buscar_tarea(tareas, id)
    fuera_de_plazo = fin > tarea.plazo

    color =
      if fuera_de_plazo do
        "#e74c3c"
      else
        "#3498db"
      end

    x = margen_izquierdo() + inicio * escala()
    y = margen_superior() + indice * separacion()
    ancho = (fin - inicio) * escala()
    x_plazo = margen_izquierdo() + tarea.plazo * escala()
    id_seguro = escapar(id)

    IO.write(
      archivo,
      "  <text x=\"15\" y=\"#{y + 20}\" font-family=\"Arial\" font-size=\"14\" font-weight=\"bold\" fill=\"#2c3e50\">#{id_seguro}</text>\n"
    )

    IO.write(
      archivo,
      "  <rect x=\"#{x}\" y=\"#{y}\" width=\"#{ancho}\" height=\"#{alto_barra()}\" fill=\"#{color}\" stroke=\"#2c3e50\" stroke-width=\"1\" />\n"
    )

    IO.write(
      archivo,
      "  <line x1=\"#{x_plazo}\" y1=\"#{y - 5}\" x2=\"#{x_plazo}\" y2=\"#{y + alto_barra() + 5}\" stroke=\"#2c3e50\" stroke-width=\"2\" stroke-dasharray=\"4 3\" />\n"
    )

    x_texto =
      if x_plazo > x + ancho do
        x_plazo + 8
      else
        x + ancho + 8
      end

    texto_tiempos = escapar("inicio #{inicio} - fin #{fin}")

    IO.write(
      archivo,
      "  <text x=\"#{x_texto}\" y=\"#{y + 20}\" font-family=\"Arial\" font-size=\"12\" fill=\"#333333\">#{texto_tiempos}</text>\n"
    )

    escribir_barras(archivo, resto, tareas, indice + 1)
  end

end
