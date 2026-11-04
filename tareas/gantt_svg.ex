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
end
