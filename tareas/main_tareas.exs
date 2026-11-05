File.cd!(__DIR__)
Code.require_file("tarea.ex")
Code.require_file("lector_tareas.ex")
Code.require_file("validador_tareas.ex")
Code.require_file("planificador.ex")
Code.require_file("gantt_svg.ex")

#integrantes: Isabella Hincapié Bocanegra, Luisa Fernanda Hernandez, Camila González Restrepo


defmodule MainTareas do
  @moduledoc """
  Programa principal del problema 2: lee, valida, planifica y genera las salidas
  """

  @doc """
  Función principal, si el archivo existe lo procesa; si no, muestra un aviso

  ## Parámetros

    - ruta_entrada: Ruta del archivo de tareas, por defecto tareas.csv
  """
  def main(ruta_entrada) do
    if File.exists?(ruta_entrada) do
      procesar(ruta_entrada)
    else
      IO.puts("AVISO: no se encontró el archivo de entrada #{ruta_entrada}.")
    end
  end

  # valida las tareas; si hay errores no se enumeran planes
  defp procesar(ruta_entrada) do
    registros = LectorTareas.leer_registros(ruta_entrada)
    resultado_validacion = ValidadorTareas.validar(registros, "validacion_tareas.txt")

    case resultado_validacion do
      :ok ->
        planificar(registros)

      {:error, cantidad} ->
        Planificador.escribir_resumen_invalido("resumen_tareas.txt", cantidad)
        Planificador.escribir_planes_vacio("planes.csv")
        GanttSvg.generar(nil, [], "mejor_plan.svg")
    end
  end

  # convierte las tareas y genera planes.csv, el resumen y el svg
  defp planificar(registros) do
    tareas = LectorTareas.convertir_registros(registros)

    if tareas == [] do
      Planificador.escribir_resumen_vacio("resumen_tareas.txt")
      Planificador.escribir_planes_vacio("planes.csv")
      GanttSvg.generar(nil, [], "mejor_plan.svg")
    else
      resultado = Planificador.planificar(tareas, "planes.csv")
      Planificador.escribir_resumen(resultado, tareas, "resumen_tareas.txt")

      primer_plan = Planificador.primer_plan_optimo(resultado)
      GanttSvg.generar(primer_plan, tareas, "mejor_plan.svg")
    end
  end
end

ruta =
  case System.argv() do
    [primero | _resto] -> primero
    [] -> "tareas.csv"
  end

MainTareas.main(ruta)
