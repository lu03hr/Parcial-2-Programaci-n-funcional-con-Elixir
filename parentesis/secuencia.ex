defmodule SecuenciaParentesis do

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

    Enum.at(filas, -1)
  end

end
