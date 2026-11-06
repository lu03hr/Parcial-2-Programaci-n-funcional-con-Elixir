# Parcial 2 - Programación III 

Problemas elegidos: **2** (Planificación de tareas con dependencias y diagrama SVG) y **4** (Paréntesis balanceados con profundidad máxima).

## Integrantes :)
- Luisa Fernanda Hernandez Ramirez
- Isabella Hincapié Bocanegra
- Camila de los Ángeles González Restrepo 

## Cómo ejecutar

Desde la carpeta del repositorio:

```
elixir tareas/main_tareas.exs
elixir tareas/main_tareas.exs tareas_invalido.csv
elixir tareas/main_tareas.exs tareas_vacio.csv
elixir tareas/main_tareas.exs tareas_una.csv
elixir tareas/main_tareas.exs tareas_paralelas.csv

elixir parentesis/main_parentesis.exs
elixir parentesis/main_parentesis.exs parametros_invalido.csv propuestas_extra.txt
```

También se puede entrar primero a la carpeta (`cd tareas` o `cd parentesis`) y ejecutar `elixir main_tareas.exs` o `elixir main_parentesis.exs`.

No hace falta compilar antes:

- `Code.require_file` carga los demás módulos (`.ex`) al ejecutar el programa, en lugar de compilarlos antes con `elixirc`. En el problema 2, `tarea.ex` se carga primero porque define los structs `%Tarea{}` y `%Plan{}`.
- `File.cd!(__DIR__)` ubica el programa en su propia carpeta, para que encuentre sus archivos aunque se ejecute desde la raíz del repositorio.

Las salidas se crean dentro de la carpeta de cada problema.

## Salidas

- **tareas:** `planes.csv`, `resumen_tareas.txt`, `validacion_tareas.txt`, `mejor_plan.svg`
- **parentesis:** `parentesis_n<N>_p<P>.txt`, `primera_n18_p18.txt`, `verificacion_parentesis.txt`, `secuencia_parentesis.csv`
