defmodule Tarea do
  # Una tarea del proyecto.
  #   id:            identificador (texto), ejemplo "A"
  #   duracion:      entero positivo
  #   plazo:         entero >= 0 (tiempo límite para terminar)
  #   dependencias:  lista de ids que deben terminar antes, ejemplo ["B", "C"]
  defstruct id: "", duracion: 0, plazo: 0, dependencias: []
end

defmodule Plan do
  # Un orden válido de ejecución.
  #   orden:           lista de ids en el orden en que se ejecutan, ["A", "B", "C", "D"]
  #   finalizaciones:  lista de tuplas {id, inicio, fin}, una por tarea y en el mismo orden.
  #                    Ejemplo: [{"A", 0, 3}, {"B", 3, 5}]
  #   penalizacion:    suma de max(0, fin - plazo) de todas las tareas
  defstruct orden: [], finalizaciones: [], penalizacion: 0
end
