# Carga los módulos del problema, así no hace falta compilar antes
Code.require_file("tarea.ex")
Code.require_file("lector_tareas.ex")
Code.require_file("validador_tareas.ex")
Code.require_file("planificador.ex")
Code.require_file("gantt_svg.ex")

defmodule MainTareas do
  # Revisa que el archivo exista, si no, avisa sin romper el programa
  def main(ruta_entrada) do
    if File.exists?(ruta_entrada) do
      procesar(ruta_entrada)
    else
      IO.puts("AVISO: no se encontró el archivo de entrada #{ruta_entrada}.")
    end
  end

  # lee, valida con recursión, si todo está bien, planifica
  defp procesar(ruta_entrada) do
    registros = LectorTareas.leer_registros(ruta_entrada)
    resultado_validacion = ValidadorTareas.validar(registros, "validacion_tareas.txt")

    case resultado_validacion do
      :ok ->
        planificar(registros)

      {:error, cantidad} ->
        # Red inválida. No se enumeran planes. Se reemplazan las salidas para que
        # no queden archivos viejos de otra ejecución, y el SVG muestra la leyenda.
        Planificador.escribir_resumen_invalido("resumen_tareas.txt", cantidad)
        Planificador.escribir_planes_vacio("planes.csv")
        GanttSvg.generar(nil, [], "mejor_plan.svg")
    end
  end


  defp planificar(registros) do
    tareas = LectorTareas.convertir_registros(registros)

    if tareas == [] do
      # Caso proyecto vacío (el mensaje se muestra al escribir el resumen)
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

# Si se pasa un archivo como argumento se usa ese; si no, el de por defecto.
ruta =
  case System.argv() do
    [primero | _resto] -> primero
    [] -> "tareas.csv"
  end

MainTareas.main(ruta)
