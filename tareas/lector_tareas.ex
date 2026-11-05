defmodule LectorTareas do


  def leer_registros(ruta) do
    ruta
    |> File.stream!()
    |> Stream.with_index(1)
    |> Stream.map(fn {linea, numero} -> {numero, String.trim(linea)} end)
    |> Stream.filter(fn {_numero, texto} -> texto != "" end)
    |> Stream.filter(fn {_numero, texto} -> not String.starts_with?(texto, "#") end)
    |> Enum.to_list()
  end


  def convertir_registros(registros) do
    registros
    |> Stream.map(fn {_numero, texto} -> convertir_linea(texto) end)
    |> Enum.to_list()
  end


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


  defp separar_dependencias("-"), do: []

  defp separar_dependencias(texto) do
    texto
    |> String.split("|")
    |> Enum.map(fn dependencia -> String.trim(dependencia) end)
  end
end
