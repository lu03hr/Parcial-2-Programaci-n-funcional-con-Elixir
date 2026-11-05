# Integrantes: Luisa Hernández, Isabella Hincapié, Camila González

defmodule SecuenciaParentesis do
  @moduledoc """
  Módulo encargado de generar la secuencia de cantidades de soluciones para
  n = 1, 2, 3, ... con profundidad máxima igual a n, usando un Stream infinito.
  """

  @doc """
  Cuenta las soluciones para n = 1, 2, 3... con p = n, las escribe en un CSV y se detiene
  en el primer n cuyo total llegue al umbral. Devuelve esa última fila {n, total}.
  """
  def escribir(ruta, umbral) do
    {:ok, archivo} = File.open(ruta, [:write, :utf8])
    IO.write(archivo, "n;total\n")

    filas =
      Stream.iterate(1, fn n -> n + 1 end)
      |> Stream.take_while(fn n ->
        n == 1 or GeneradorParentesis.contar(n - 1, n - 1) < umbral
      end)
      |> Stream.map(fn n -> {n, GeneradorParentesis.contar(n, n)} end)
      |> Stream.map(fn {n, total} ->
        IO.write(archivo, "#{n};#{total}\n")
        IO.puts("  n=#{n}  total=#{total}")
        {n, total}
      end)
      |> Enum.to_list()

    File.close(archivo)

    # Enum.at con -1 devuelve el último elemento de la lista
    Enum.at(filas, -1)
  end

end
