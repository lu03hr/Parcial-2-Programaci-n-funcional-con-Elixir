# Integrantes: Luisa Hernández, Isabella Hincapié, Camila González

defmodule LectorParametros do
  @moduledoc """
  Módulo encargado de leer y validar el archivo de parámetros con formato
  n;profundidad_max, devolviendo cada línea como un par válido o un error.
  """

  @doc """
  Lee el archivo de parámetros mediante un Stream, y devuelve una
  lista de {:ok, n, p} o {:error, mensaje} por cada línea.
  """
  def leer(ruta) do
    ruta
    |> File.stream!()
    |> Stream.with_index(1)
    |> Stream.map(fn {linea, numero} -> {numero, String.trim(linea)} end)
    |> Stream.filter(fn {_numero, texto} -> texto != "" end)
    |> Stream.filter(fn {_numero, texto} -> not String.starts_with?(texto, "#") end)
    |> Stream.map(fn {numero, texto} -> convertir_linea(numero, texto) end)
    |> Enum.to_list()
  end

  # Verifica que la línea tenga dos enteros con n >= 1 y 1 <= p <= n.
  defp convertir_linea(numero, texto) do
    case String.split(texto, ";") do
      [n_texto, p_texto] ->
        resultado_n = Integer.parse(String.trim(n_texto))
        resultado_p = Integer.parse(String.trim(p_texto))

        case {resultado_n, resultado_p} do
          {{n, ""}, {p, ""}} ->
            if n >= 1 and p >= 1 and p <= n do
              {:ok, n, p}
            else
              {:error, "Línea #{numero}: se requiere n >= 1 y 1 <= p <= n, y se recibió '#{texto}'."}
            end

          _ ->
            {:error, "Línea #{numero}: n y p deben ser enteros, y se recibió '#{texto}'."}
        end

      _ ->
        {:error, "Línea #{numero}: el formato debe ser n;profundidad_max, y se recibió '#{texto}'."}
    end
  end

end
