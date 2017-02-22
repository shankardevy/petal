defmodule Phx.New.Generator do
  @moduledoc false
  import Mix.Generator
  alias Phx.New.{Project}

  @phoenix Path.expand("../..", __DIR__)

  @callback prepare_project(Project.t) :: Project.t
  @callback generate(Project.t) :: Project.t

  defmacro __using__(_env) do
    quote do
      @behaviour unquote(__MODULE__)
      import unquote(__MODULE__)
      import Mix.Generator
      Module.register_attribute(__MODULE__, :templates, accumulate: true)
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(env) do
    root = Path.expand("../../templates", __DIR__)
    templates_ast = for {_name, mappings} <- Module.get_attribute(env.module, :templates) do
      for {format, source, _, _} <- mappings, format != :keep do
        path = Path.join(root, source)
        quote do
          @external_resource unquote(path)
          def render(unquote(source)), do: unquote(File.read!(path))
        end
      end
    end

    quote do
      unquote(templates_ast)
      def template_files(name), do: Keyword.fetch!(@templates, name)
      # Embed missing files from Phoenix static.
      embed_text :phoenix_js, from_file: Path.expand("../../../priv/static/phoenix.js", unquote(__DIR__))
      embed_text :phoenix_png, from_file: Path.expand("../../../priv/static/phoenix.png", unquote(__DIR__))
      embed_text :phoenix_favicon, from_file: Path.expand("../../../priv/static/favicon.ico", unquote(__DIR__))
    end
  end

  defmacro template(name, mappings) do
    quote do
      @templates {unquote(name), unquote(mappings)}
    end
  end

  def copy_from(%Project{} = project, mod, mapping) when is_list(mapping) do
    for {format, source, project_location, target_path} <- mapping do
      target = Project.join_path(project, project_location, target_path)

      case format do
        :keep ->
          File.mkdir_p!(target)
        :text ->
          create_file(target, mod.render(source))
        :append ->
          append_to(Path.dirname(target), Path.basename(target), mod.render(source))
        :eex  ->
          contents = EEx.eval_string(mod.render(source), project.binding, file: source)
          create_file(target, contents)
      end
    end
  end

  def append_to(path, file, contents) do
    file = Path.join(path, file)
    File.write!(file, File.read!(file) <> contents)
  end

  def in_single?(path) do
    mixfile = Path.join(path, "mix.exs")
    apps_path = Path.join(path, "apps")

    File.exists?(mixfile) and not File.exists?(apps_path)
  end

  def in_umbrella?(app_path) do
    try do
      umbrella = Path.expand(Path.join [app_path, "..", ".."])
      File.exists?(Path.join(umbrella, "mix.exs")) &&
        Mix.Project.in_project(:umbrella_check, umbrella, fn _ ->
          path = Mix.Project.config[:apps_path]
          path && Path.expand(path) == Path.join(umbrella, "apps")
        end)
    catch
      _, _ -> false
    end
  end

  def put_binding(%Project{opts: opts} = project) do
    db           = Keyword.get(opts, :database, "postgres")
    ecto         = Keyword.get(opts, :ecto, true)
    html         = Keyword.get(opts, :html, true)
    brunch       = Keyword.get(opts, :brunch, true)
    phoenix_path = phoenix_path(project.project_path, Keyword.get(opts, :dev, false))

    # We lowercase the database name because according to the
    # SQL spec, they are case insensitive unless quoted, which
    # means creating a database like FoO is the same as foo in
    # some storages.
    {adapter_app, adapter_module, adapter_config} =
      get_ecto_adapter(db, String.downcase(project.app), project.app_mod)

    pubsub_server = get_pubsub_server(project.app_mod)
    brunch_deps_prefix = if project.in_umbrella?, do: "../../../", else: "../"

    adapter_config =
      case Keyword.fetch(opts, :binary_id) do
        {:ok, value} -> Keyword.put_new(adapter_config, :binary_id, value)
        :error -> adapter_config
      end

    binding = [
      app_name: project.app,
      app_module: inspect(project.app_mod),
      root_app_name: project.root_app,
      root_app_module: inspect(project.root_mod),
      web_app_name: project.web_app,
      endpoint_module: inspect(Module.concat(project.web_namespace, Endpoint)),
      web_namespace: inspect(project.web_namespace),
      phoenix_dep: phoenix_dep(phoenix_path),
      phoenix_path: phoenix_path,
      phoenix_static_path: phoenix_static_path(phoenix_path),
      pubsub_server: pubsub_server,
      secret_key_base: random_string(64),
      prod_secret_key_base: random_string(64),
      signing_salt: random_string(8),
      in_umbrella: project.in_umbrella?,
      brunch_deps_prefix: brunch_deps_prefix,
      brunch: brunch,
      ecto: ecto,
      html: html,
      adapter_app: adapter_app,
      adapter_module: adapter_module,
      adapter_config: adapter_config,
      hex?: Code.ensure_loaded?(Hex),
      generator_config: generator_config(adapter_config),
      namespaced?: namespaced?(project)]

    %Project{project | binding: binding}
  end

  defp namespaced?(project) do
    project.in_umbrella? || Macro.camelize(project.app) != inspect(project.app_mod)
  end

  def gen_ecto_config(%Project{app_path: app_path, binding: binding}) do
    adapter_config = binding[:adapter_config]

    append_to app_path, "config/dev.exs", """

    # Configure your database
    config :#{binding[:app_name]}, #{binding[:app_module]}.Repo,
    adapter: #{inspect binding[:adapter_module]}#{kw_to_config adapter_config[:dev]},
    pool_size: 10
    """

    append_to app_path, "config/test.exs", """

    # Configure your database
    config :#{binding[:app_name]}, #{binding[:app_module]}.Repo,
    adapter: #{inspect binding[:adapter_module]}#{kw_to_config adapter_config[:test]}
    """

    append_to app_path, "config/prod.secret.exs", """

    # Configure your database
    config :#{binding[:app_name]}, #{binding[:app_module]}.Repo,
    adapter: #{inspect binding[:adapter_module]}#{kw_to_config adapter_config[:prod]},
    pool_size: 20
    """
  end

  defp get_pubsub_server(module) do
    module
    |> Module.split()
    |> hd()
    |> Module.concat(PubSub)
  end
  defp get_ecto_adapter("mssql", app, module) do
    {:tds_ecto, Tds.Ecto, db_config(app, module, "db_user", "db_password")}
  end
  defp get_ecto_adapter("mysql", app, module) do
    {:mariaex, Ecto.Adapters.MySQL, db_config(app, module, "root", "")}
  end
  defp get_ecto_adapter("postgres", app, module) do
    {:postgrex, Ecto.Adapters.Postgres, db_config(app, module, "postgres", "postgres")}
  end
  defp get_ecto_adapter("sqlite", app, module) do
    {:sqlite_ecto, Sqlite.Ecto,
     dev:  [database: "db/#{app}_dev.sqlite"],
     test: [database: "db/#{app}_test.sqlite", pool: Ecto.Adapters.SQL.Sandbox],
     prod: [database: "db/#{app}_prod.sqlite"],
     test_setup_all: "Ecto.Adapters.SQL.Sandbox.mode(#{inspect module}.Repo, :manual)",
     test_setup: ":ok = Ecto.Adapters.SQL.Sandbox.checkout(#{inspect module}.Repo)",
     test_async: "Ecto.Adapters.SQL.Sandbox.mode(#{inspect module}.Repo, {:shared, self()})"}
  end
  defp get_ecto_adapter("mongodb", app, module) do
    {:mongodb_ecto, Mongo.Ecto,
     dev:  [database: "#{app}_dev"],
     test: [database: "#{app}_test", pool_size: 1],
     prod: [database: "#{app}_prod"],
     test_setup_all: "",
     test_setup: "",
     test_async: "Mongo.Ecto.truncate(#{inspect module}.Repo, [])",
     binary_id: true,
     migration: false,
     sample_binary_id: "111111111111111111111111"}
  end
  defp get_ecto_adapter(db, _app, _mod) do
    Mix.raise "Unknown database #{inspect db}"
  end

  defp db_config(app, module, user, pass) do
    [dev:  [username: user, password: pass, database: "#{app}_dev", hostname: "localhost"],
     test: [username: user, password: pass, database: "#{app}_test", hostname: "localhost",
            pool: Ecto.Adapters.SQL.Sandbox],
     prod: [username: user, password: pass, database: "#{app}_prod"],
     test_setup_all: "Ecto.Adapters.SQL.Sandbox.mode(#{inspect module}.Repo, :manual)",
     test_setup: ":ok = Ecto.Adapters.SQL.Sandbox.checkout(#{inspect module}.Repo)",
     test_async: "Ecto.Adapters.SQL.Sandbox.mode(#{inspect module}.Repo, {:shared, self()})"]
  end

  defp kw_to_config(kw) do
    Enum.map(kw, fn {k, v} ->
      ",\n  #{k}: #{inspect v}"
    end)
  end

  defp generator_config(adapter_config) do
    adapter_config
    |> Keyword.take([:binary_id, :migration, :sample_binary_id])
    |> Enum.filter(fn {_, value} -> not is_nil(value) end)
    |> case do
      [] -> nil
      conf ->
        """

        # Configure phoenix generators
        config :phoenix, :generators#{kw_to_config(conf)}
        """
    end
  end

  defp phoenix_path(path, true) do
    absolute = Path.expand(path)
    relative = Path.relative_to(absolute, @phoenix)

    if absolute == relative do
      Mix.raise "--dev projects must be generated inside Phoenix directory"
    end

    relative
    |> Path.split()
    |> Enum.map(fn _ -> ".." end)
    |> Path.join()
  end
  defp phoenix_path(_path, false) do
    "deps/phoenix"
  end

  defp phoenix_dep("deps/phoenix"), do: ~s[{:phoenix, "~> 1.2.0"}]
  # defp phoenix_dep("deps/phoenix"), do: ~s[{:phoenix, github: "phoenixframework/phoenix", override: true}]
  defp phoenix_dep(path), do: ~s[{:phoenix, path: #{inspect path}, override: true}]

  defp phoenix_static_path("deps/phoenix"), do: "deps/phoenix"
  defp phoenix_static_path(path), do: Path.join("..", path)

  defp random_string(length) do
    :crypto.strong_rand_bytes(length) |> Base.encode64 |> binary_part(0, length)
  end
end
