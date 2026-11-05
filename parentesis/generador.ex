defmodule GeneradorParentesis do

  def generar(n, p) do
    construir("", 0, 0, n, p)
  end

  # Caso base
  defp construir(prefijo, _abiertos, cerrados, n, _p) when cerrados == n do
    [prefijo]
  end
  # Caso recursivo
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

end
