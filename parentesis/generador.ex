# Integrantes: Luisa Hernández, Isabella Hincapié, Camila González

defmodule GeneradorParentesis do
  @moduledoc """
  Módulo encargado de generar cadenas de paréntesis balanceados según la cantidad
  de pares n y la profundidad máxima permitida p, de forma recursiva y perezosa.
  """

  @doc """
  Devuelve un Stream con las cadenas de n pares de paréntesis balanceados cuya profundidad no supera p.
  """
  def generar(n, p) do
    construir("", 0, 0, n, p)
  end

  # Caso base, termina la construcción cuando ya se agregaron todos los paréntesis de cierre.
  defp construir(prefijo, _abiertos, cerrados, n, _p) when cerrados == n do
    [prefijo]
  end

  # Caso recursivo, obtiene las opciones válidas y continúa construyendo las cadenas, combina los resultados sin generarlos todos de inmediato.
  defp construir(prefijo, abiertos, cerrados, n, p) do
    opciones = opciones_validas(abiertos, cerrados, n, p)

    Stream.flat_map(opciones, fn simbolo ->
      if simbolo == "(" do
        construir(prefijo <> "(", abiertos + 1, cerrados, n, p)
      else
        construir(prefijo <> ")", abiertos, cerrados + 1, n, p)
      end
    end)
  end

  # Devuelve la lista de símbolos que se pueden agregar sin romper los límites.
  defp opciones_validas(abiertos, cerrados, n, p) do
    pendientes = abiertos - cerrados
    puede_abrir = abiertos < n and pendientes < p
    puede_cerrar = cerrados < abiertos

    opciones_1 =
      if puede_abrir do
        ["("]
      else
        []
      end

    if puede_cerrar do
      opciones_1 ++ [")"]
    else
      opciones_1
    end
  end

  @doc """
  Cuenta las soluciones consumiendo el Stream una por una, sin guardarlas en una lista.
  """
  def contar(n, p) do
    n
    |> generar(p)
    |> Enum.count()
  end

  @doc """
  Escribe cada solución en el archivo apenas se genera y al final agrega "Total: N".
  Devuelve el total.
  """
  def escribir_en_archivo(n, p, ruta) do
    {:ok, archivo} = File.open(ruta, [:write, :utf8])

    total =
      n
      |> generar(p)
      |> Stream.map(fn cadena ->
        IO.write(archivo, cadena <> "\n")
        cadena
      end)
      |> Enum.count()

    IO.write(archivo, "Total: #{total}\n")
    File.close(archivo)
    total
  end

  @doc """
  Escribe solo la primera solución del Stream, las demás nunca se calculan.
  """
  def escribir_primera(n, p, ruta) do
    primeras =
      n
      |> generar(p)
      |> Enum.take(1)

    {:ok, archivo} = File.open(ruta, [:write, :utf8])
    escribir_cadenas(archivo, primeras)
    File.close(archivo)
    primeras
  end

  # Caso base, termina cuando ya no quedan cadenas por escribir.
  defp escribir_cadenas(_archivo, []), do: :ok

  # Caso recursivo, escribe la primera cadena en una línea y continúa con el resto de la lista.
  defp escribir_cadenas(archivo, [cadena | resto]) do
    IO.write(archivo, cadena <> "\n")
    escribir_cadenas(archivo, resto)
  end

end
