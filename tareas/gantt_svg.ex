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

end
