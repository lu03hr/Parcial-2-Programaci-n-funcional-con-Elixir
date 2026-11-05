# Integrantes: Luisa Hernández, Isabella Hincapié, Camila González

File.cd!(__DIR__)

# Carga los módulos del problema (así no hace falta compilar antes)
Code.require_file("generador.ex")
Code.require_file("parametros.ex")
Code.require_file("verificador.ex")
Code.require_file("secuencia.ex")

defmodule MainParentesis do
  @moduledoc """
  Módulo principal del problema de paréntesis balanceados, encargado de ejecutar
  en orden las cuatro partes del programa.
  """

  @doc """
  Ejecuta todo en orden: verificación de propuestas, generación para cada (n, p), primera solución de n=18 y stream infinito.
  """
  def main(ruta_parametros, ruta_propuestas) do
    IO.puts("1. Validación previa: verificación de cadenas propuestas")
    case VerificadorParentesis.verificar_archivo(ruta_propuestas, "verificacion_parentesis.txt") do
      :ok -> IO.puts("  Resultado en verificacion_parentesis.txt")
      :no_existe -> IO.puts("  No se verificaron propuestas.")
    end

    IO.puts("")
    IO.puts("2. Cadenas balanceadas para cada (n, p) ")
    procesar_parametros(ruta_parametros)

    IO.puts("")
    IO.puts("3. Primera solución para n=18, p=18 (solo el primer elemento del Stream) ")
    [primera] = GeneradorParentesis.escribir_primera(18, 18, "primera_n18_p18.txt")
    IO.puts("  #{primera}")

    IO.puts("")
    IO.puts("4. Stream infinito: crecimiento de soluciones (p = n) ")
    {n_final, total_final} = SecuenciaParentesis.escribir("secuencia_parentesis.csv", 1000)
    IO.puts("  Se detuvo en n=#{n_final} con total=#{total_final}; n=#{n_final + 1} nunca se calculó.")
  end

 # Si el archivo no existe, avisa. Si existe, lo lee y ejecuta cada par válido.
  defp procesar_parametros(ruta) do
    if File.exists?(ruta) do
      resultados = LectorParametros.leer(ruta)
      ejecutar_resultados(resultados)
    else
      IO.puts("AVISO: no se encontró el archivo #{ruta}.")
    end
  end

  # Caso base, termina cuando ya no quedan resultados por procesar.
  defp ejecutar_resultados([]), do: :ok

  # Caso recursivo (registro correcto), genera el archivo para ese (n, p), muestra el total y continúa con el resto.
  defp ejecutar_resultados([{:ok, n, p} | resto]) do
    ruta_salida = "parentesis_n#{n}_p#{p}.txt"
    total = GeneradorParentesis.escribir_en_archivo(n, p, ruta_salida)
    IO.puts("  n=#{n}, p=#{p}: total = #{total}  (archivo #{ruta_salida})")
    ejecutar_resultados(resto)
  end

  # Caso recursivo (registro incorrecto), avisa el error y continúa con el resto.
  defp ejecutar_resultados([{:error, mensaje} | resto]) do
    IO.puts("  AVISO: registro incorrecto. #{mensaje}")
    ejecutar_resultados(resto)
  end

end

# Argumentos opcionales: parametros y propuestas.
{ruta_parametros, ruta_propuestas} =
  case System.argv() do
    [primero, segundo | _resto] -> {primero, segundo}
    [primero] -> {primero, "propuestas.txt"}
    [] -> {"parametros.csv", "propuestas.txt"}
  end

MainParentesis.main(ruta_parametros, ruta_propuestas)
