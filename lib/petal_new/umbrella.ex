defmodule Petal.New.Umbrella do
  @moduledoc false
  use Petal.New.Generator
  alias Petal.New.{Ecto, Web, Project}

  template :new, [
    {:eex,    "petal_umbrella/gitignore",               :project, ".gitignore"},
    {:eex,    "petal_umbrella/config/config.exs",       :project, "config/config.exs"},
    {:config, "petal_umbrella/config/extra_config.exs", :project, "config/config.exs"},
    {:eex,    "petal_umbrella/config/dev.exs",          :project, "config/dev.exs"},
    {:eex,    "petal_umbrella/config/test.exs",         :project, "config/test.exs"},
    {:eex,    "petal_umbrella/config/prod.exs",         :project, "config/prod.exs"},
    {:eex,    "petal_umbrella/config/runtime.exs",      :project, "config/runtime.exs"},
    {:eex,    "petal_umbrella/mix.exs",                 :project, "mix.exs"},
    {:eex,    "petal_umbrella/README.md",               :project, "README.md"},
    {:eex,    "petal_umbrella/formatter.exs",           :project, ".formatter.exs"},
  ]

  def prepare_project(%Project{app: app} = project) when not is_nil(app) do
    project
    |> put_app()
    |> put_web()
    |> put_root_app()
  end
  defp put_app(project) do
    project_path = Path.expand(project.base_path <> "_umbrella")
    app_path = Path.join(project_path, "apps/#{project.app}")

    %Project{project |
             in_umbrella?: true,
             app_path: app_path,
             project_path: project_path}
  end
  def put_web(%Project{app: app, opts: opts} = project) do
    web_app = :"#{app}_web"
    web_namespace = Module.concat([opts[:web_module] || "#{project.app_mod}Web"])

    %Project{project |
             web_app: web_app,
             lib_web_name: web_app,
             web_namespace: web_namespace,
             generators: [context_app: :"#{app}"],
             web_path: Path.join(project.project_path, "apps/#{web_app}/")}
  end

  defp put_root_app(%Project{app: app} = project) do
    %Project{project |
             root_app: :"#{app}_umbrella",
             root_mod: Module.concat(project.app_mod, "Umbrella")}
  end

  def generate(%Project{} = project) do
    if in_umbrella?(project.project_path) do
      Mix.raise "Unable to nest umbrella project within apps"
    end
    copy_from project, __MODULE__, :new

    project
    |> Web.generate()
    |> Ecto.generate()
  end
end
