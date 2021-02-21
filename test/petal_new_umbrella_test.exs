Code.require_file "mix_helper.exs", __DIR__

defmodule Mix.Tasks.Petal.New.UmbrellaTest do
  use ExUnit.Case, async: false
  import MixHelper

  @app "petal_umb"

  setup config do
    # The shell asks to install deps.
    # We will politely say not.
    decline_prompt()
    {:ok, tmp_dir: to_string(config.test)}
  end

  defp decline_prompt do
    send self(), {:mix_shell_input, :yes?, false}
  end

  defp root_path(app, path \\ "") do
    Path.join(["#{app}_umbrella", path])
  end

  defp app_path(app, path) do
    Path.join(["#{app}_umbrella/apps/#{app}", path])
  end

  defp web_path(app, path) do
    Path.join(["#{app}_umbrella/apps/#{app}_web", path])
  end

  test "new with umbrella and defaults" do
    in_tmp "new with umbrella and defaults", fn ->
      Mix.Tasks.Petal.New.run([@app, "--umbrella"])

      assert_file root_path(@app, "README.md")
      assert_file root_path(@app, ".gitignore")

      assert_file app_path(@app, "README.md")
      assert_file app_path(@app, ".gitignore"), "#{@app}-*.tar"

      assert_file web_path(@app, "README.md")

      assert_file root_path(@app, "mix.exs"), fn file ->
        assert file =~ "apps_path: \"apps\""
      end

      assert_file app_path(@app, "mix.exs"), fn file ->
        assert file =~ "app: :petal_umb"
        assert file =~ ~S{build_path: "../../_build"}
        assert file =~ ~S{config_path: "../../config/config.exs"}
        assert file =~ ~S{deps_path: "../../deps"}
        assert file =~ ~S{lockfile: "../../mix.lock"}
      end

      assert_file root_path(@app, "config/config.exs"), fn file ->
        assert file =~ ~S[import_config "#{config_env()}.exs"]
        assert file =~ "config :phoenix, :json_library, Jason"
        assert file =~ "ecto_repos: [PetalUmb.Repo]"
        assert file =~ ":petal_umb_web, PetalUmbWeb.Endpoint"
        assert file =~ "generators: [context_app: :petal_umb]\n"
        refute file =~ "namespace"
      end

      assert_file root_path(@app, "config/dev.exs"), fn file ->
        assert file =~ ~r{watchers: \[\s+node:}
        assert file =~ "cd: Path.expand(\"../apps/petal_umb_web/assets\", __DIR__)"
        assert file =~ "lib/#{@app}_web/(live|views)/.*(ex)"
        assert file =~ "lib/#{@app}_web/templates/.*(eex)"
      end

      assert_file root_path(@app, "config/prod.exs"), fn file ->
        assert file =~ "port: 80"
      end

      assert_file root_path(@app, "config/runtime.exs"), ~r/ip: {0, 0, 0, 0, 0, 0, 0, 0}/

      assert_file app_path(@app, ".formatter.exs"), fn file ->
        assert file =~ "import_deps: [:ecto]"
        assert file =~ "inputs: [\"*.{ex,exs}\", \"priv/*/seeds.exs\", \"{config,lib,test}/**/*.{ex,exs}\"]"
        assert file =~ "subdirectories: [\"priv/*/migrations\"]"
      end

      assert_file web_path(@app, ".formatter.exs"), fn file ->
        assert file =~ "inputs: [\"*.{ex,exs}\", \"{config,lib,test}/**/*.{ex,exs}\"]"
        refute file =~ "import_deps: [:ecto]"
        refute file =~ "subdirectories:"
      end

      assert_file app_path(@app, "lib/#{@app}/application.ex"), ~r/defmodule PetalUmb.Application do/
      assert_file app_path(@app, "lib/#{@app}/application.ex"), ~r/PetalUmb.Repo/
      assert_file app_path(@app, "lib/#{@app}.ex"), ~r/defmodule PetalUmb do/
      assert_file app_path(@app, "mix.exs"), fn file ->
        assert file =~ "mod: {PetalUmb.Application, []}"
        assert file =~ "{:phoenix_pubsub, \"~> 2.0\"}"
      end
      assert_file app_path(@app, "test/test_helper.exs")

      assert_file web_path(@app, "lib/#{@app}_web/application.ex"), ~r/defmodule PetalUmbWeb.Application do/
      assert_file web_path(@app, "mix.exs"), fn file ->
        assert file =~ "mod: {PetalUmbWeb.Application, []}"
        assert file =~ "{:jason, \"~> 1.0\"}"
      end
      assert_file web_path(@app, "lib/#{@app}_web.ex"), fn file ->
        assert file =~ "defmodule PetalUmbWeb do"
        assert file =~ ~r/use Phoenix.View,\s+root: "lib\/petal_umb_web\/templates"/
      end
      assert_file web_path(@app, "lib/#{@app}_web/endpoint.ex"), ~r/defmodule PetalUmbWeb.Endpoint do/
      assert_file web_path(@app, "test/#{@app}_web/controllers/page_controller_test.exs")
      assert_file web_path(@app, "test/#{@app}_web/views/page_view_test.exs")
      assert_file web_path(@app, "test/#{@app}_web/views/error_view_test.exs")
      assert_file web_path(@app, "test/#{@app}_web/views/layout_view_test.exs")
      assert_file web_path(@app, "test/support/conn_case.ex")
      assert_file web_path(@app, "test/test_helper.exs")

      assert_file web_path(@app, "lib/#{@app}_web/controllers/page_controller.ex"),
                  ~r/defmodule PetalUmbWeb.PageController/

      assert_file web_path(@app, "lib/#{@app}_web/views/page_view.ex"),
                  ~r/defmodule PetalUmbWeb.PageView/

      assert_file web_path(@app, "lib/#{@app}_web/router.ex"), "defmodule PetalUmbWeb.Router"
      assert_file web_path(@app, "lib/#{@app}_web/templates/layout/app.html.eex"),
                  "<title>PetalUmb · Phoenix Framework</title>"

      assert_file web_path(@app, "test/#{@app}_web/views/page_view_test.exs"),
                  "defmodule PetalUmbWeb.PageViewTest"

      # webpack
      assert_file web_path(@app, ".gitignore"), "/assets/node_modules/"
      assert_file web_path(@app, ".gitignore"), "#{@app}_web-*.tar"
      assert_file( web_path(@app, ".gitignore"),  ~r/\n$/)
      assert_file web_path(@app, "assets/webpack.config.js"), "js/app.js"
      assert_file web_path(@app, "assets/.babelrc"), "env"
      assert_file web_path(@app, "assets/static/favicon.ico")
      assert_file web_path(@app, "assets/static/images/phoenix.png")
      assert_file web_path(@app, "assets/css/app.scss")
      assert_file web_path(@app, "assets/js/app.js"),
                  ~s[import socket from "./socket"]
      assert_file web_path(@app, "assets/js/socket.js"),
                  ~s[import {Socket} from "phoenix"]

      assert_file web_path(@app, "assets/package.json"), fn file ->
        assert file =~ ~s["file:../../../deps/phoenix"]
        assert file =~ ~s["file:../../../deps/phoenix_html"]
      end

      refute File.exists?(web_path(@app, "priv/static/css/app.css"))
      refute File.exists?(web_path(@app, "priv/static/js/phoenix.js"))
      refute File.exists?(web_path(@app, "priv/static/js/app.js"))

      assert File.exists?(web_path(@app, "assets/vendor"))

      # web deps
      assert_file web_path(@app, "mix.exs"), fn file ->
        assert file =~ "{:petal_umb, in_umbrella: true}"
        assert file =~ "{:phoenix,"
        refute file =~ "{:phoenix_live_view,"
        assert file =~ "{:gettext,"
        assert file =~ "{:plug_cowboy,"
      end

      # app deps
      assert_file web_path(@app, "mix.exs"), fn file ->
        assert file =~ "{:phoenix_ecto,"
        assert file =~ "{:jason,"
      end

      # Ecto
      config = ~r/config :petal_umb, PetalUmb.Repo,/
      assert_file root_path(@app, "config/dev.exs"), config
      assert_file root_path(@app, "config/test.exs"), config
      assert_file root_path(@app, "config/runtime.exs"), config

      assert_file app_path(@app, "mix.exs"), fn file ->
        assert file =~ "aliases: aliases()"
        assert file =~ "ecto.setup"
        assert file =~ "ecto.reset"
        assert file =~ "{:jason,"
      end

      assert_file app_path(@app, "lib/#{@app}/repo.ex"), ~r"defmodule PetalUmb.Repo"
      assert_file app_path(@app, "priv/repo/seeds.exs"), ~r"PetalUmb.Repo.insert!"
      assert_file app_path(@app, "test/support/data_case.ex"), ~r"defmodule PetalUmb.DataCase"
      assert_file app_path(@app, "priv/repo/migrations/.formatter.exs"), ~r"import_deps: \[:ecto_sql\]"

      # Telemetry
      assert_file web_path(@app, "mix.exs"), fn file ->
        assert file =~ "{:telemetry_metrics, \"~> 0.4\"}"
        assert file =~ "{:telemetry_poller, \"~> 0.4\"}"
      end

      assert_file web_path(@app, "lib/#{@app}_web/telemetry.ex"), fn file ->
        assert file =~ "defmodule PetalUmbWeb.Telemetry do"
        assert file =~ "{:telemetry_poller, measurements: periodic_measurements()"
        assert file =~ "defp periodic_measurements do"
        assert file =~ "# {PetalUmbWeb, :count_users, []}"
        assert file =~ "def metrics do"
        assert file =~ "summary(\"phoenix.endpoint.stop.duration\","
        assert file =~ "summary(\"phoenix.router_dispatch.stop.duration\","
        assert file =~ "# Database Metrics"
        assert file =~ "summary(\"petal_umb.repo.query.total_time\","
      end

      # Install dependencies?
      assert_received {:mix_shell, :yes?, ["\nFetch and install dependencies?"]}

      # Instructions
      assert_received {:mix_shell, :info, ["\nWe are almost there" <> _ = msg]}
      assert msg =~ "$ cd petal_umb"
      assert msg =~ "$ mix deps.get"

      assert_received {:mix_shell, :info, ["Then configure your database in config/dev.exs" <> _]}
      assert_received {:mix_shell, :info, ["Start your Phoenix app" <> _]}

      # Channels
      assert File.exists?(web_path(@app, "/lib/#{@app}_web/channels"))
      assert_file web_path(@app, "lib/#{@app}_web/channels/user_socket.ex"), ~r"defmodule PetalUmbWeb.UserSocket"
      assert_file web_path(@app, "lib/#{@app}_web/endpoint.ex"), ~r"socket \"/socket\", PetalUmbWeb.UserSocket"

      # Gettext
      assert_file web_path(@app, "lib/#{@app}_web/gettext.ex"), ~r"defmodule PetalUmbWeb.Gettext"
      assert File.exists?(web_path(@app, "priv/gettext/errors.pot"))
      assert File.exists?(web_path(@app, "priv/gettext/en/LC_MESSAGES/errors.po"))
    end
  end

  test "new with no_dashboard" do
    in_tmp "new with no_dashboard", fn ->
      Mix.Tasks.Petal.New.run([@app, "--umbrella", "--no-dashboard"])

      assert_file web_path(@app, "mix.exs"), &refute(&1 =~ ~r":phoenix_live_dashboard")

      assert_file web_path(@app, "lib/#{@app}_web/templates/layout/app.html.eex"), fn file ->
        refute file =~ ~s|<%= link "LiveDashboard", to: Routes.live_dashboard_path(@conn, :home)|
      end

      assert_file web_path(@app, "lib/#{@app}_web/endpoint.ex"), fn file ->
        assert file =~ ~s|defmodule PetalUmbWeb.Endpoint|
        refute file =~ ~s|socket "/live"|
        refute file =~ ~s|plug Phoenix.LiveDashboard.RequestLogger|
      end
    end
  end

  test "new with no_html" do
    in_tmp "new with no_html", fn ->
      Mix.Tasks.Petal.New.run([@app, "--umbrella", "--no-html"])

      assert_file web_path(@app, "mix.exs"), fn file ->
        refute file =~ ~s|:phoenix_live_view|
        assert file =~ ~s|:phoenix_live_dashboard|
      end

      assert_file web_path(@app, "lib/#{@app}_web/endpoint.ex"), fn file ->
        assert file =~ ~s|defmodule PetalUmbWeb.Endpoint|
        assert file =~ ~s|socket "/live"|
        assert file =~ ~s|plug Phoenix.LiveDashboard.RequestLogger|
      end

      assert_file web_path(@app, "lib/#{@app}_web/router.ex"), fn file ->
        refute file =~ ~s|pipeline :browser|
        assert file =~ ~s|pipe_through [:fetch_session, :protect_from_forgery]|
      end
    end
  end
  test "new with binary_id" do
    in_tmp "new with binary_id", fn ->
      Mix.Tasks.Petal.New.run([@app, "--umbrella", "--binary-id"])
      assert_file root_path(@app, "config/config.exs"),
                  ~r/generators: \[context_app: :petal_umb, binary_id: true\]/
    end
  end

  test "new with PETAL no_dashboard" do
    in_tmp "new with PETAL no_dashboard", fn ->
      Mix.Tasks.Petal.New.run([@app, "--umbrella", "--no-dashboard"])

      assert_file web_path(@app, "mix.exs"), &refute(&1 =~ ~r":phoenix_live_dashboard")

      assert_file web_path(@app, "lib/#{@app}_web/templates/layout/root.html.leex"), fn file ->
        refute file =~ ~s|<%= link "LiveDashboard", to: Routes.live_dashboard_path(@conn, :home)|
      end

      assert_file web_path(@app, "lib/#{@app}_web/endpoint.ex"), fn file ->
        assert file =~ ~s|defmodule PetalUmbWeb.Endpoint|
        assert file =~ ~s|socket "/live"|
        refute file =~ ~s|plug Phoenix.LiveDashboard.RequestLogger|
      end
    end
  end

  test "new with PETAL" do
    in_tmp "new with PETAL", fn ->
      Mix.Tasks.Petal.New.run([@app, "--umbrella"])

      refute_file web_path(@app, "lib/#{@app}_web/controllers/page_controller.ex")

      assert_file web_path(@app, "lib/#{@app}_web/live/page_live.ex"), fn file ->
        assert file =~ "defmodule PetalUmbWeb.PageLive do"
      end

      assert_file web_path(@app, "lib/#{@app}_web/live/page_live.html.leex"), fn file ->
        assert file =~ ~s[Welcome]
      end

      assert_file web_path(@app, "mix.exs"), &assert(&1 =~ ~r":phoenix_live_view")
      assert_file web_path(@app, "mix.exs"), &assert(&1 =~ ~r":floki")

      assert_file web_path(@app, "assets/package.json"),
                  ~s["phoenix_live_view": "file:../../../deps/phoenix_live_view"]

      assert_file web_path(@app, "assets/js/app.js"), fn file ->
        assert file =~ ~s[import {LiveSocket} from "phoenix_live_view"]
      end

      assert_file web_path(@app, "assets/css/app.scss"), fn file ->
        assert file =~ ~s[.petal-click-loading]
      end

      assert_file root_path(@app, "config/config.exs"), fn file ->
        assert file =~ "live_view:"
        assert file =~ "signing_salt:"
      end

      assert_file web_path(@app, "lib/#{@app}_web.ex"), fn file ->
        assert file =~ "import Phoenix.LiveView.Helpers"
        assert file =~ "def live_view do"
        assert file =~ "def live_component do"
      end

      assert_file web_path(@app, "lib/petal_umb_web/endpoint.ex"), ~s[socket "/live", Phoenix.LiveView.Socket]
      assert_file web_path(@app, "lib/petal_umb_web/router.ex"), fn file ->
        assert file =~ ~s[plug :fetch_live_flash]
        assert file =~ ~s[plug :put_root_layout, {PetalUmbWeb.LayoutView, :root}]
        assert file =~ ~s[live "/", PageLive]
        refute file =~ ~s[plug :fetch_flash]
        refute file =~ ~s[PageController]
      end
    end
  end

  test "new with uppercase" do
    in_tmp "new with uppercase", fn ->
      Mix.Tasks.Petal.New.run(["petalUmb", "--umbrella"])

      assert_file "petalUmb_umbrella/README.md"

      assert_file "petalUmb_umbrella/apps/petalUmb/mix.exs", fn file ->
        assert file =~ "app: :petalUmb"
      end

      assert_file "petalUmb_umbrella/apps/petalUmb_web/mix.exs", fn file ->
        assert file =~ "app: :petalUmb_web"
      end

      assert_file "petalUmb_umbrella/config/dev.exs", fn file ->
        assert file =~ ~r/config :petalUmb, PetalUmb.Repo,/
        assert file =~ "database: \"petalumb_dev\""
      end
    end
  end

  test "new with path, app and module" do
    in_tmp "new with path, app and module", fn ->
      project_path = Path.join(File.cwd!(), "custom_path")
      Mix.Tasks.Petal.New.run([project_path, "--umbrella", "--app", @app, "--module", "PhoteuxBlog"])

      assert_file "custom_path_umbrella/apps/petal_umb/mix.exs", ~r/app: :petal_umb/
      assert_file "custom_path_umbrella/apps/petal_umb_web/lib/petal_umb_web/endpoint.ex", ~r/app: :#{@app}_web/
      assert_file "custom_path_umbrella/apps/petal_umb_web/lib/#{@app}_web.ex", ~r/use Phoenix.Controller, namespace: PhoteuxBlogWeb/
      assert_file "custom_path_umbrella/apps/petal_umb/lib/petal_umb/application.ex", ~r/defmodule PhoteuxBlog.Application/
      assert_file "custom_path_umbrella/apps/petal_umb/mix.exs", ~r/mod: {PhoteuxBlog.Application, \[\]}/
      assert_file "custom_path_umbrella/apps/petal_umb_web/lib/petal_umb_web/application.ex", ~r/defmodule PhoteuxBlogWeb.Application/
      assert_file "custom_path_umbrella/apps/petal_umb_web/mix.exs", ~r/mod: {PhoteuxBlogWeb.Application, \[\]}/
      assert_file "custom_path_umbrella/config/config.exs", ~r/namespace: PhoteuxBlogWeb/
      assert_file "custom_path_umbrella/config/config.exs", ~r/namespace: PhoteuxBlog/
    end
  end

  test "new inside umbrella" do
    in_tmp "new inside umbrella", fn ->
      File.write! "mix.exs", MixHelper.umbrella_mixfile_contents()
      File.mkdir! "apps"
      File.cd! "apps", fn ->
        assert_raise Mix.Error, "Unable to nest umbrella project within apps", fn ->
          Mix.Tasks.Petal.New.run([@app, "--umbrella"])
        end
      end
    end
  end

  test "new defaults to pg adapter" do
    in_tmp "new defaults to pg adapter", fn ->
      app = "custom_path"
      project_path = Path.join(File.cwd!(), app)
      Mix.Tasks.Petal.New.run([project_path, "--umbrella"])

      assert_file app_path(app, "mix.exs"), ":postgrex"
      assert_file app_path(app, "lib/custom_path/repo.ex"), "Ecto.Adapters.Postgres"

      assert_file root_path(app, "config/dev.exs"), [~r/username: "postgres"/, ~r/password: "postgres"/, ~r/hostname: "localhost"/]
      assert_file root_path(app, "config/test.exs"), [~r/username: "postgres"/, ~r/password: "postgres"/, ~r/hostname: "localhost"/]
      assert_file root_path(app, "config/runtime.exs"), [~r/url: database_url/]

      assert_file web_path(app, "test/support/conn_case.ex"), "Ecto.Adapters.SQL.Sandbox.start_owner"
      assert_file web_path(app, "test/support/channel_case.ex"), "Ecto.Adapters.SQL.Sandbox.start_owner"
    end
  end

  test "new with mysql adapter" do
    in_tmp "new with mysql adapter", fn ->
      app = "custom_path"
      project_path = Path.join(File.cwd!(), app)
      Mix.Tasks.Petal.New.run([project_path, "--umbrella", "--database", "mysql"])

      assert_file app_path(app, "mix.exs"), ":myxql"
      assert_file app_path(app, "lib/custom_path/repo.ex"), "Ecto.Adapters.MyXQL"

      assert_file root_path(app, "config/dev.exs"), [~r/username: "root"/, ~r/password: ""/]
      assert_file root_path(app, "config/test.exs"), [~r/username: "root"/, ~r/password: ""/]
      assert_file root_path(app, "config/runtime.exs"), [~r/url: database_url/]

      assert_file web_path(app, "test/support/conn_case.ex"), "Ecto.Adapters.SQL.Sandbox.start_owner"
      assert_file web_path(app, "test/support/channel_case.ex"), "Ecto.Adapters.SQL.Sandbox.start_owner"
    end
  end

  test "new with mssql adapter" do
    in_tmp "new with mssql adapter", fn ->
      app = "custom_path"
      project_path = Path.join(File.cwd!(), app)
      Mix.Tasks.Petal.New.run([project_path, "--umbrella", "--database", "mssql"])

      assert_file app_path(app, "mix.exs"), ":tds"
      assert_file app_path(app, "lib/custom_path/repo.ex"), "Ecto.Adapters.Tds"

      assert_file root_path(app, "config/dev.exs"), [~r/username: "sa"/, ~r/password: "some!Password"/]
      assert_file root_path(app, "config/test.exs"), [~r/username: "sa"/, ~r/password: "some!Password"/]
      assert_file root_path(app, "config/runtime.exs"), [~r/url: database_url/]

      assert_file web_path(app, "test/support/conn_case.ex"), "Ecto.Adapters.SQL.Sandbox.start_owner"
      assert_file web_path(app, "test/support/channel_case.ex"), "Ecto.Adapters.SQL.Sandbox.start_owner"
    end
  end

  test "new with invalid database adapter" do
    in_tmp "new with invalid database adapter", fn ->
      project_path = Path.join(File.cwd!(), "custom_path")
      assert_raise Mix.Error, ~s(Unknown database "invalid"), fn ->
        Mix.Tasks.Petal.New.run([project_path, "--umbrella", "--database", "invalid"])
      end
    end
  end

  test "new with invalid args" do
    assert_raise Mix.Error, ~r"Application name must start with a letter and ", fn ->
      Mix.Tasks.Petal.New.run ["007invalid", "--umbrella"]
    end

    assert_raise Mix.Error, ~r"Application name must start with a letter and ", fn ->
      Mix.Tasks.Petal.New.run ["valid1", "--app", "007invalid", "--umbrella"]
    end

    assert_raise Mix.Error, ~r"Module name must be a valid Elixir alias", fn ->
      Mix.Tasks.Petal.New.run ["valid2", "--module", "not.valid", "--umbrella"]
    end

    assert_raise Mix.Error, ~r"Module name \w+ is already taken", fn ->
      Mix.Tasks.Petal.New.run ["string", "--umbrella"]
    end

    assert_raise Mix.Error, ~r"Module name \w+ is already taken", fn ->
      Mix.Tasks.Petal.New.run ["valid3", "--app", "mix", "--umbrella"]
    end

    assert_raise Mix.Error, ~r"Module name \w+ is already taken", fn ->
      Mix.Tasks.Petal.New.run ["valid4", "--module", "String", "--umbrella"]
    end
  end

  test "invalid options" do
    assert_raise Mix.Error, ~r/Invalid option: -d/, fn ->
      Mix.Tasks.Petal.New.run(["valid5", "-database", "mysql", "--umbrella"])
    end
  end

  describe "ecto task" do
    test "can only be run within an umbrella app dir", %{tmp_dir: tmp_dir} do
      in_tmp tmp_dir, fn ->
        cwd = File.cwd!()
        umbrella_path = root_path(@app)
        Mix.Tasks.Petal.New.run([@app, "--umbrella"])
        flush()

        for dir <- [cwd, umbrella_path] do
          File.cd!(dir, fn ->
            assert_raise Mix.Error, ~r"The ecto task can only be run within an umbrella's apps directory", fn ->
              Mix.Tasks.Petal.New.Ecto.run(["valid"])
            end
          end)
        end
      end
    end
  end

  describe "web task" do
    test "can only be run within an umbrella app dir", %{tmp_dir: tmp_dir} do
      in_tmp tmp_dir, fn ->
        cwd = File.cwd!()
        umbrella_path = root_path(@app)
        Mix.Tasks.Petal.New.run([@app, "--umbrella"])
        flush()

        for dir <- [cwd, umbrella_path] do
          File.cd!(dir, fn ->
            assert_raise Mix.Error, ~r"The web task can only be run within an umbrella's apps directory", fn ->
              Mix.Tasks.Petal.New.Web.run(["valid"])
            end
          end)
        end
      end
    end

    test "generates web-only files", %{tmp_dir: tmp_dir} do
      in_tmp tmp_dir, fn ->
        umbrella_path = root_path(@app)
        Mix.Tasks.Petal.New.run([@app, "--umbrella"])
        flush()

        File.cd!(Path.join(umbrella_path, "apps"))
        decline_prompt()
        Mix.Tasks.Petal.New.Web.run(["another"])

        assert_file "another/README.md"
        assert_file "another/mix.exs", fn file ->
          assert file =~ "app: :another"
          assert file =~ "deps_path: \"../../deps\""
          assert file =~ "lockfile: \"../../mix.lock\""
        end

        assert_file "../config/config.exs", fn file ->
          assert file =~ "ecto_repos: [Another.Repo]"
        end

        assert_file "../config/prod.exs", fn file ->
          assert file =~ "port: 80"
        end

        assert_file "../config/runtime.exs", ~r/ip: {0, 0, 0, 0, 0, 0, 0, 0}/

        assert_file "another/lib/another/application.ex", ~r/defmodule Another.Application do/
        assert_file "another/mix.exs", ~r/mod: {Another.Application, \[\]}/
        assert_file "another/lib/another.ex", ~r/defmodule Another do/
        assert_file "another/lib/another/endpoint.ex", ~r/defmodule Another.Endpoint do/

        assert_file "another/test/another/controllers/page_controller_test.exs"
        assert_file "another/test/another/views/page_view_test.exs"
        assert_file "another/test/another/views/error_view_test.exs"
        assert_file "another/test/another/views/layout_view_test.exs"
        assert_file "another/test/support/conn_case.ex"
        assert_file "another/test/test_helper.exs"

        assert_file "another/lib/another/controllers/page_controller.ex",
                    ~r/defmodule Another.PageController/

        assert_file "another/lib/another/views/page_view.ex",
                    ~r/defmodule Another.PageView/

        assert_file "another/lib/another/router.ex", "defmodule Another.Router"
        assert_file "another/lib/another.ex", "defmodule Another"
        assert_file "another/lib/another/templates/layout/app.html.eex",
                    "<title>Another · Phoenix Framework</title>"

        # webpack
        assert_file "another/.gitignore", "/assets/node_modules"
        assert_file "another/.gitignore",  ~r/\n$/
        assert_file "another/assets/webpack.config.js", "js/app.js"
        assert_file "another/assets/.babelrc", "env"
        assert_file "another/assets/static/favicon.ico"
        assert_file "another/assets/static/images/phoenix.png"
        assert_file "another/assets/css/app.scss"
        assert_file "another/assets/js/app.js",
                    ~s[import socket from "./socket"]
        assert_file "another/assets/js/socket.js",
                    ~s[import {Socket} from "phoenix"]

        assert_file "another/assets/package.json", fn file ->
          assert file =~ ~s["file:../../../deps/phoenix"]
          assert file =~ ~s["file:../../../deps/phoenix_html"]
        end

        refute File.exists? "another/priv/static/css/app.css"
        refute File.exists? "another/priv/static/js/phoenix.js"
        refute File.exists? "another/priv/static/js/app.js"

        assert File.exists?("another/assets/vendor")

        # Ecto
        assert_file "another/mix.exs", fn file ->
          assert file =~ "{:phoenix_ecto,"
        end
        assert_file "another/lib/another.ex", ~r"defmodule Another"
        refute_file "another/lib/another/repo.ex"
        refute_file "another/priv/repo/seeds.exs"
        refute_file "another/test/support/data_case.ex"

        # Install dependencies?
        assert_received {:mix_shell, :yes?, ["\nFetch and install dependencies?"]}

        # Instructions
        assert_received {:mix_shell, :info, ["\nWe are almost there" <> _ = msg]}
        assert msg =~ "$ cd another"
        assert msg =~ "$ mix deps.get"

        refute_received {:mix_shell, :info, ["Then configure your database" <> _]}
        assert_received {:mix_shell, :info, ["Start your Phoenix app" <> _]}

        # Channels
        assert File.exists?("another/lib/another/channels")
        assert_file "another/lib/another/channels/user_socket.ex", ~r"defmodule Another.UserSocket"
        assert_file "another/lib/another/endpoint.ex", ~r"socket \"/socket\", Another.UserSocket"

        # Gettext
        assert_file "another/lib/another/gettext.ex", ~r"defmodule Another.Gettext"
        assert File.exists?("another/priv/gettext/errors.pot")
        assert File.exists?("another/priv/gettext/en/LC_MESSAGES/errors.po")
      end
    end
  end
end
