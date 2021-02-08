defmodule Petal.New.Single do
  @moduledoc false
  use Petal.New.Generator
  alias Petal.New.{Project}

  template :new, [
    {:eex,  "petal_single/config/config.exs",             :project, "config/config.exs"},
    {:eex,  "petal_single/config/dev.exs",                :project, "config/dev.exs"},
    {:eex,  "petal_single/config/prod.exs",               :project, "config/prod.exs"},
    {:eex,  "petal_single/config/runtime.exs",            :project, "config/runtime.exs"},
    {:eex,  "petal_single/config/test.exs",               :project, "config/test.exs"},
    {:eex,  "petal_single/lib/app_name/application.ex",   :project, "lib/:app/application.ex"},
    {:eex,  "petal_single/lib/app_name.ex",               :project, "lib/:app.ex"},
    {:eex,  "petal_web/channels/user_socket.ex",          :project, "lib/:lib_web_name/channels/user_socket.ex"},
    {:keep, "petal_web/controllers",                      :project, "lib/:lib_web_name/controllers"},
    {:eex,  "petal_web/views/error_helpers.ex",           :project, "lib/:lib_web_name/views/error_helpers.ex"},
    {:eex,  "petal_web/views/error_view.ex",              :project, "lib/:lib_web_name/views/error_view.ex"},
    {:eex,  "petal_web/endpoint.ex",                      :project, "lib/:lib_web_name/endpoint.ex"},
    {:eex,  "petal_web/router.ex",                        :project, "lib/:lib_web_name/router.ex"},
    {:eex,  "petal_web/telemetry.ex",                     :project, "lib/:lib_web_name/telemetry.ex"},
    {:eex,  "petal_single/lib/app_name_web.ex",           :project, "lib/:lib_web_name.ex"},
    {:eex,  "petal_single/mix.exs",                       :project, "mix.exs"},
    {:eex,  "petal_single/README.md",                     :project, "README.md"},
    {:eex,  "petal_single/formatter.exs",                 :project, ".formatter.exs"},
    {:eex,  "petal_single/gitignore",                     :project, ".gitignore"},
    {:eex,  "petal_test/support/channel_case.ex",         :project, "test/support/channel_case.ex"},
    {:eex,  "petal_test/support/conn_case.ex",            :project, "test/support/conn_case.ex"},
    {:eex,  "petal_single/test/test_helper.exs",          :project, "test/test_helper.exs"},
    {:keep, "petal_test/channels",                        :project, "test/:lib_web_name/channels"},
    {:keep, "petal_test/controllers",                     :project, "test/:lib_web_name/controllers"},
    {:eex,  "petal_test/views/error_view_test.exs",       :project, "test/:lib_web_name/views/error_view_test.exs"},
  ]

  template :gettext, [
    {:eex,  "petal_gettext/gettext.ex",               :project, "lib/:lib_web_name/gettext.ex"},
    {:eex,  "petal_gettext/en/LC_MESSAGES/errors.po", :project, "priv/gettext/en/LC_MESSAGES/errors.po"},
    {:eex,  "petal_gettext/errors.pot",               :project, "priv/gettext/errors.pot"}
  ]

  template :html, [
    {:eex, "petal_web/controllers/page_controller.ex",         :project, "lib/:lib_web_name/controllers/page_controller.ex"},
    {:eex, "petal_web/templates/layout/app.html.eex",          :project, "lib/:lib_web_name/templates/layout/app.html.eex"},
    {:eex, "petal_web/templates/page/index.html.eex",          :project, "lib/:lib_web_name/templates/page/index.html.eex"},
    {:eex, "petal_web/views/layout_view.ex",                   :project, "lib/:lib_web_name/views/layout_view.ex"},
    {:eex, "petal_web/views/page_view.ex",                     :project, "lib/:lib_web_name/views/page_view.ex"},
    {:eex, "petal_test/controllers/page_controller_test.exs",  :project, "test/:lib_web_name/controllers/page_controller_test.exs"},
    {:eex, "petal_test/views/layout_view_test.exs",            :project, "test/:lib_web_name/views/layout_view_test.exs"},
    {:eex, "petal_test/views/page_view_test.exs",              :project, "test/:lib_web_name/views/page_view_test.exs"},
  ]

  template :live, [
    {:eex, "petal_live/templates/layout/root.html.leex",       :project, "lib/:lib_web_name/templates/layout/root.html.leex"},
    {:eex, "petal_live/templates/layout/app.html.leex",        :project, "lib/:lib_web_name/templates/layout/app.html.eex"},
    {:eex, "petal_live/templates/layout/live.html.leex",       :project, "lib/:lib_web_name/templates/layout/live.html.leex"},
    {:eex, "petal_web/views/layout_view.ex",                   :project, "lib/:lib_web_name/views/layout_view.ex"},
    {:eex, "petal_live/live/page_live.ex",                     :project, "lib/:lib_web_name/live/page_live.ex"},
    {:eex, "petal_web/templates/page/index.html.eex",          :project, "lib/:lib_web_name/live/page_live.html.leex"},
    {:eex, "petal_test/views/layout_view_test.exs",            :project, "test/:lib_web_name/views/layout_view_test.exs"},
    {:eex, "petal_test/live/page_live_test.exs",               :project, "test/:lib_web_name/live/page_live_test.exs"},
  ]

  template :ecto, [
    {:eex,  "petal_ecto/repo.ex",              :app, "lib/:app/repo.ex"},
    {:keep, "petal_ecto/priv/repo/migrations", :app, "priv/repo/migrations"},
    {:eex,  "petal_ecto/formatter.exs",        :app, "priv/repo/migrations/.formatter.exs"},
    {:eex,  "petal_ecto/seeds.exs",            :app, "priv/repo/seeds.exs"},
    {:eex,  "petal_ecto/data_case.ex",         :app, "test/support/data_case.ex"},
  ]

  template :webpack, [
    {:eex,  "petal_assets/webpack.config.js", :web, "assets/webpack.config.js"},
    {:text, "petal_assets/babelrc",           :web, "assets/.babelrc"},
    {:eex,  "petal_assets/app.js",            :web, "assets/js/app.js"},
    {:eex,  "petal_assets/app.scss",          :web, "assets/css/app.scss"},
    {:eex,  "petal_assets/socket.js",         :web, "assets/js/socket.js"},
    {:eex,  "petal_assets/package.json",      :web, "assets/package.json"},
    {:keep, "petal_assets/vendor",            :web, "assets/vendor"},
  ]

  template :webpack_live, [
    {:eex,  "petal_assets/webpack.config.js", :web, "assets/webpack.config.js"},
    {:text, "petal_assets/babelrc",           :web, "assets/.babelrc"},
    {:eex,  "petal_assets/app.js",            :web, "assets/js/app.js"},
    {:eex,  "petal_assets/app.scss",          :web, "assets/css/app.scss"},
    {:eex,  "petal_assets/package.json",      :web, "assets/package.json"},
    {:keep, "petal_assets/vendor",            :web, "assets/vendor"},
  ]

  template :bare, []

  template :static, [
    {:text, "petal_static/app.js",      :web, "priv/static/js/app.js"},
    {:text, "petal_static/app.css",     :web, "priv/static/css/app.css"},
    {:text, "petal_static/phoenix.css", :web, "priv/static/css/phoenix.css"},
    {:text, "petal_static/robots.txt",  :web, "priv/static/robots.txt"},
    {:text, "petal_static/phoenix.js",  :web, "priv/static/js/phoenix.js"},
    {:text, "petal_static/phoenix.png", :web, "priv/static/images/phoenix.png"},
    {:text, "petal_static/favicon.ico", :web, "priv/static/favicon.ico"}
  ]

  def prepare_project(%Project{app: app} = project) when not is_nil(app) do
    %Project{project | project_path: project.base_path}
    |> put_app()
    |> put_root_app()
    |> put_web_app()
  end

  defp put_app(%Project{base_path: base_path} = project) do
    %Project{project |
             in_umbrella?: in_umbrella?(base_path),
             app_path: base_path}
  end

  defp put_root_app(%Project{app: app, opts: opts} = project) do
    %Project{project |
             root_app: app,
             root_mod: Module.concat([opts[:module] || Macro.camelize(app)])}
  end

  defp put_web_app(%Project{app: app} = project) do
    %Project{project |
             web_app: app,
             lib_web_name: "#{app}_web",
             web_namespace: Module.concat(["#{project.root_mod}Web"]),
             web_path: project.project_path}
  end

  def generate(%Project{} = project) do
    if Project.live?(project), do: assert_live_switches!(project)

    copy_from project, __MODULE__, :new

    if Project.ecto?(project), do: gen_ecto(project)

    cond do
      Project.live?(project) -> gen_live(project)
      Project.html?(project) -> gen_html(project)
      true -> :noop
    end

    if Project.gettext?(project), do: gen_gettext(project)

    case {Project.webpack?(project), Project.html?(project)} do
      {true, _}      -> gen_webpack(project)
      {false, true}  -> gen_static(project)
      {false, false} -> gen_bare(project)
    end

    project
  end

  def gen_html(project) do
    copy_from project, __MODULE__, :html
  end

  def gen_gettext(project) do
    copy_from project, __MODULE__, :gettext
  end

  defp gen_live(project) do
    copy_from project, __MODULE__, :live
  end

  def gen_ecto(project) do
    copy_from project, __MODULE__, :ecto
    gen_ecto_config(project)
  end

  def gen_static(%Project{} = project) do
    copy_from project, __MODULE__, :static
  end

  def gen_webpack(%Project{web_path: web_path} = project) do
    if Project.live?(project) do
      copy_from project, __MODULE__, :webpack_live
    else
      copy_from project, __MODULE__, :webpack
    end

    statics = %{
      "petal_static/phoenix.css" => "assets/css/phoenix.css",
      "petal_static/robots.txt" => "assets/static/robots.txt",
      "petal_static/phoenix.png" => "assets/static/images/phoenix.png",
      "petal_static/favicon.ico" => "assets/static/favicon.ico"
    }

    for {source, target} <- statics do
      create_file Path.join(web_path, target), render(:static, source, project.binding)
    end
  end

  def gen_bare(%Project{} = project) do
    copy_from project, __MODULE__, :bare
  end

  def assert_live_switches!(project) do
    unless Project.html?(project) and Project.webpack?(project) do
      raise "cannot generate --live project with --no-html or --no-webpack. LiveView requires HTML and webpack"
    end
  end
end
