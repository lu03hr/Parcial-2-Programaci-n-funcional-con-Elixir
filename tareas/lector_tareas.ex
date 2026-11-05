#integrantes: Isabella Hincapié Bocanegra, Luisa Fernanda Hernandez, Camila González Restrepo

defmodule LectorTareas do
  @moduledoc """
  Módulo para leer tareas.csv de forma perezosa y convertir cada línea en un %Tarea{}
  """

  @doc """
  Función para leer el archivo con File.stream! y devolver las líneas útiles con su número de línea.

  ## Parámetros

    - ruta: Ruta del archivo de tareas
  """
  def leer_registros(ruta) do
    ruta
    |> File.stream!()
    |> Stream.with_index(1)
    |> Stream.map(fn {linea, numero} -> {numero, String.trim(linea)} end)
    |> Stream.filter(fn {_numero, texto} -> texto != "" end)
    |> Stream.filter(fn {_numero, texto} -> not String.starts_with?(texto, "#") end)
    |> Enum.to_list()
  end

  @doc """
  Función para convertir los registros ya validados en una lista de %Tarea{}
  """
  def convertir_registros(registros) do
    registros
    |> Stream.map(fn {_numero, texto} -> convertir_linea(texto) end)
    |> Enum.to_list()
  end

  # convierte una línea "id;duracion;plazo;dependencias" en un %Tarea{}
  defp convertir_linea(texto) do
    [id, duracion_texto, plazo_texto, dependencias_texto] = String.split(texto, ";")

    {duracion, _resto_duracion} = Integer.parse(String.trim(duracion_texto))
    {plazo, _resto_plazo} = Integer.parse(String.trim(plazo_texto))
    dependencias = separar_dependencias(String.trim(dependencias_texto))

    %Tarea{
      id: String.trim(id),
      duracion: duracion,
      plazo: plazo,
      dependencias: dependencias
    }
  end

  # "-" significa sin dependencias; si no, se separan por "|"
  defp separar_dependencias("-"), do: []

  defp separar_dependencias(texto) do
    texto
    |> String.split("|")
    |> Enum.map(fn dependencia -> String.trim(dependencia) end)
  end
end
