defmodule GeneradorParentesis do

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
