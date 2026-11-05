#integrantes: Isabella Hincapié Bocanegra, Luisa Fernanda Hernandez, Camila González Restrepo

defmodule Tarea do
  @moduledoc """
  Struct de una tarea del proyecto: id, duración, plazo y lista de dependencias.
  """
  defstruct id: "", duracion: 0, plazo: 0, dependencias: []
end

defmodule Plan do
  @moduledoc """
  Struct de un plan: orden de las tareas, finalizaciones {id, inicio, fin} y penalización.
  """
  defstruct orden: [], finalizaciones: [], penalizacion: 0
end
