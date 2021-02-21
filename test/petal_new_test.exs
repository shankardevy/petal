Code.require_file "mix_helper.exs", __DIR__

defmodule Mix.Tasks.Petal.NewTest do
  use ExUnit.Case, async: false
  import MixHelper
  import ExUnit.CaptureIO

  @app_name "petal_blog"

  setup do
    # The shell asks to install deps.
    # We will politely say not.
    send self(), {:mix_shell_input, :yes?, false}
    :ok
  end

  test "assets are in sync with installer" do
    for file <- ~w(favicon.ico phoenix.js phoenix.png) do
      assert File.read!("../priv/static/#{file}") ==
        File.read!("templates/petal_static/#{file}")
    end
  end

  test "returns the version" do
    Mix.Tasks.Petal.New.run(["-v"])
    assert_received {:mix_shell, :info, ["Phoenix v" <> _]}
  end

  test "new with defaults" do
    in_tmp "new with defaults", fn ->
      Mix.Tasks.Petal.New.run([@app_name])

      assert_file "petal_blog/README.md"

      assert_file "petal_blog/.formatter.exs", fn file ->
        assert file =~ "import_deps: [:ecto, :phoenix]"
        assert file =~ "inputs: [\"*.{ex,exs}\", \"priv/*/seeds.exs\", \"{config,lib,test}/**/*.{ex,exs}\"]"
        assert file =~ "subdirectories: [\"priv/*/migrations\"]"
      end

      assert_file "petal_blog/mix.exs", fn file ->
        assert file =~ "app: :petal_blog"
        refute file =~ "deps_path: \"../../deps\""
        refute file =~ "lockfile: \"../../mix.lock\""
      end

      assert_file "petal_blog/config/config.exs", fn file ->
        assert file =~ "ecto_repos: [PetalBlog.Repo]"
        assert file =~ "config :phoenix, :json_library, Jason"
        refute file =~ "namespace: PetalBlog"
        refute file =~ "config :petal_blog, :generators"
      end

      assert_file "petal_blog/config/prod.exs", fn file ->
        assert file =~ "port: 80"
      end

      assert_file "petal_blog/config/runtime.exs", ~r/ip: {0, 0, 0, 0, 0, 0, 0, 0}/

      assert_file "petal_blog/lib/petal_blog/application.ex", ~r/defmodule PetalBlog.Application do/
      assert_file "petal_blog/lib/petal_blog.ex", ~r/defmodule PetalBlog do/
      assert_file "petal_blog/mix.exs", fn file ->
        assert file =~ "mod: {PetalBlog.Application, []}"
        assert file =~ "{:jason, \"~> 1.0\"}"
        assert file =~ "{:phoenix_live_dashboard,"
      end

      assert_file "petal_blog/lib/petal_blog_web.ex", fn file ->
        assert file =~ "defmodule PetalBlogWeb do"
        assert file =~ "use Phoenix.View,\n        root: \"lib/petal_blog_web/templates\""
      end

      assert_file "petal_blog/test/petal_blog_web/controllers/page_controller_test.exs"
      assert_file "petal_blog/test/petal_blog_web/views/page_view_test.exs"
      assert_file "petal_blog/test/petal_blog_web/views/error_view_test.exs"
      assert_file "petal_blog/test/petal_blog_web/views/layout_view_test.exs"
      assert_file "petal_blog/test/support/conn_case.ex"
      assert_file "petal_blog/test/test_helper.exs"

      assert_file "petal_blog/lib/petal_blog_web/controllers/page_controller.ex",
                  ~r/defmodule PetalBlogWeb.PageController/

      assert_file "petal_blog/lib/petal_blog_web/views/page_view.ex",
                  ~r/defmodule PetalBlogWeb.PageView/

      assert_file "petal_blog/lib/petal_blog_web/router.ex", fn file ->
        assert file =~ "defmodule PetalBlogWeb.Router"
        assert file =~ "live_dashboard"
        assert file =~ "import Phoenix.LiveDashboard.Router"
      end

      assert_file "petal_blog/lib/petal_blog_web/endpoint.ex", fn file ->
        assert file =~ ~s|defmodule PetalBlogWeb.Endpoint|
        assert file =~ ~s|socket "/live"|
        assert file =~ ~s|plug Phoenix.LiveDashboard.RequestLogger|
      end

      assert_file "petal_blog/lib/petal_blog_web/templates/layout/app.html.eex",
                  "<title>PetalBlog · Phoenix Framework</title>"
      assert_file "petal_blog/lib/petal_blog_web/templates/page/index.html.eex", fn file ->
        version = Application.spec(:petal_new, :vsn) |> to_string() |> Version.parse!()
        changelog_vsn = "v#{version.major}.#{version.minor}"
        assert file =~
          "https://github.com/phoenixframework/phoenix/blob/#{changelog_vsn}/CHANGELOG.md"
      end

      # webpack
      assert_file "petal_blog/.gitignore", "/assets/node_modules/"
      assert_file "petal_blog/.gitignore", "petal_blog-*.tar"
      assert_file "petal_blog/.gitignore", ~r/\n$/
      assert_file "petal_blog/assets/webpack.config.js", "js/app.js"
      assert_file "petal_blog/assets/.babelrc", "env"
      assert_file "petal_blog/config/dev.exs", fn file ->
        assert file =~ "watchers: [\n    node:"
        assert file =~ "lib/petal_blog_web/(live|views)/.*(ex)"
        assert file =~ "lib/petal_blog_web/templates/.*(eex)"
      end
      assert_file "petal_blog/assets/static/favicon.ico"
      assert_file "petal_blog/assets/static/images/phoenix.png"
      assert_file "petal_blog/assets/css/app.scss"
      assert_file "petal_blog/assets/js/app.js",
                  ~s[import socket from "./socket"]
      assert_file "petal_blog/assets/js/socket.js",
                  ~s[import {Socket} from "phoenix"]

      assert_file "petal_blog/assets/package.json", fn file ->
        assert file =~ ~s["file:../deps/phoenix"]
        assert file =~ ~s["file:../deps/phoenix_html"]
      end

      refute File.exists? "petal_blog/priv/static/css/app.scss"
      refute File.exists? "petal_blog/priv/static/js/phoenix.js"
      refute File.exists? "petal_blog/priv/static/js/app.js"

      assert File.exists?("petal_blog/assets/vendor")

      # Ecto
      config = ~r/config :petal_blog, PetalBlog.Repo,/
      assert_file "petal_blog/mix.exs", fn file ->
        assert file =~ "{:phoenix_ecto,"
        assert file =~ "aliases: aliases()"
        assert file =~ "ecto.setup"
        assert file =~ "ecto.reset"
      end
      assert_file "petal_blog/config/dev.exs", config
      assert_file "petal_blog/config/test.exs", config
      assert_file "petal_blog/config/runtime.exs", config
      assert_file "petal_blog/config/test.exs", ~R/database: "petal_blog_test#\{System.get_env\("MIX_TEST_PARTITION"\)\}"/
      assert_file "petal_blog/lib/petal_blog/repo.ex", ~r"defmodule PetalBlog.Repo"
      assert_file "petal_blog/lib/petal_blog_web.ex", ~r"defmodule PetalBlogWeb"
      assert_file "petal_blog/lib/petal_blog_web/endpoint.ex", ~r"plug Phoenix.Ecto.CheckRepoStatus, otp_app: :petal_blog"
      assert_file "petal_blog/priv/repo/seeds.exs", ~r"PetalBlog.Repo.insert!"
      assert_file "petal_blog/test/support/data_case.ex", ~r"defmodule PetalBlog.DataCase"
      assert_file "petal_blog/priv/repo/migrations/.formatter.exs", ~r"import_deps: \[:ecto_sql\]"

      # LiveView (disabled by default)
      refute_file "petal_blog/lib/petal_blog_web/live/page_live_view.ex"
      refute_file "petal_blog/assets/js/live.js"
      assert_file "petal_blog/mix.exs", &refute(&1 =~ ~r":phoenix_live_view")
      assert_file "petal_blog/mix.exs", &refute(&1 =~ ~r":floki")
      assert_file "petal_blog/assets/package.json",
                  &refute(&1 =~ ~s["phoenix_live_view": "file:../deps/phoenix_live_view"])

      assert_file "petal_blog/assets/js/app.js", fn file -> refute file =~ "LiveSocket" end

      assert_file "petal_blog/lib/petal_blog_web.ex", fn file ->
        refute file =~ "Phoenix.LiveView"
      end
      assert_file "petal_blog/lib/petal_blog_web/router.ex", &refute(&1 =~ ~s[plug :fetch_live_flash])
      assert_file "petal_blog/lib/petal_blog_web/router.ex", &refute(&1 =~ ~s[plug :put_root_layout])
      assert_file "petal_blog/lib/petal_blog_web/router.ex", &refute(&1 =~ ~s[HomeLive])
      assert_file "petal_blog/lib/petal_blog_web/router.ex", &assert(&1 =~ ~s[PageController])

      # Telemetry
      assert_file "petal_blog/mix.exs", fn file ->
        assert file =~ "{:telemetry_metrics, \"~> 0.4\"}"
        assert file =~ "{:telemetry_poller, \"~> 0.4\"}"
      end

      assert_file "petal_blog/lib/petal_blog_web/telemetry.ex", fn file ->
        assert file =~ "defmodule PetalBlogWeb.Telemetry do"
        assert file =~ "{:telemetry_poller, measurements: periodic_measurements()"
        assert file =~ "defp periodic_measurements do"
        assert file =~ "# {PetalBlogWeb, :count_users, []}"
        assert file =~ "def metrics do"
        assert file =~ "summary(\"phoenix.endpoint.stop.duration\","
        assert file =~ "summary(\"phoenix.router_dispatch.stop.duration\","
        assert file =~ "# Database Metrics"
        assert file =~ "summary(\"petal_blog.repo.query.total_time\","
      end

      # Install dependencies?
      assert_received {:mix_shell, :yes?, ["\nFetch and install dependencies?"]}

      # Instructions
      assert_received {:mix_shell, :info, ["\nWe are almost there" <> _ = msg]}
      assert msg =~ "$ cd petal_blog"
      assert msg =~ "$ mix deps.get"

      assert_received {:mix_shell, :info, ["Then configure your database in config/dev.exs" <> _]}
      assert_received {:mix_shell, :info, ["Start your Phoenix app" <> _]}

      # Channels
      assert File.exists?("petal_blog/lib/petal_blog_web/channels")
      assert_file "petal_blog/lib/petal_blog_web/channels/user_socket.ex", ~r"defmodule PetalBlogWeb.UserSocket"
      assert_file "petal_blog/lib/petal_blog_web/endpoint.ex", ~r"socket \"/socket\", PetalBlogWeb.UserSocket"
      assert File.exists?("petal_blog/test/petal_blog_web/channels")

      # Gettext
      assert_file "petal_blog/lib/petal_blog_web/gettext.ex", ~r"defmodule PetalBlogWeb.Gettext"
      assert File.exists?("petal_blog/priv/gettext/errors.pot")
      assert File.exists?("petal_blog/priv/gettext/en/LC_MESSAGES/errors.po")
    end
  end

  test "new with no_dashboard" do
    in_tmp "new with no_dashboard", fn ->
      Mix.Tasks.Petal.New.run([@app_name, "--no-dashboard"])

      assert_file "petal_blog/mix.exs", &refute(&1 =~ ~r":phoenix_live_dashboard")

      assert_file "petal_blog/lib/petal_blog_web/templates/layout/app.html.eex", fn file ->
        refute file =~ ~s|<%= link "LiveDashboard", to: Routes.live_dashboard_path(@conn, :home)|
      end

      assert_file "petal_blog/lib/petal_blog_web/endpoint.ex", fn file ->
        assert file =~ ~s|defmodule PetalBlogWeb.Endpoint|
        refute file =~ ~s|socket "/live"|
        refute file =~ ~s|plug Phoenix.LiveDashboard.RequestLogger|
      end
    end
  end

  test "new with no_html" do
    in_tmp "new with no_html", fn ->
      Mix.Tasks.Petal.New.run([@app_name, "--no-html"])

      assert_file "petal_blog/mix.exs", fn file ->
        refute file =~ ~s|:phoenix_live_view|
        assert file =~ ~s|:phoenix_live_dashboard|
      end

      assert_file "petal_blog/lib/petal_blog_web/endpoint.ex", fn file ->
        assert file =~ ~s|defmodule PetalBlogWeb.Endpoint|
        assert file =~ ~s|socket "/live"|
        assert file =~ ~s|plug Phoenix.LiveDashboard.RequestLogger|
      end

      assert_file "petal_blog/lib/petal_blog_web/router.ex", fn file ->
        refute file =~ ~s|pipeline :browser|
        assert file =~ ~s|pipe_through [:fetch_session, :protect_from_forgery]|
      end
    end
  end

  test "new with binary_id" do
    in_tmp "new with binary_id", fn ->
      Mix.Tasks.Petal.New.run([@app_name, "--binary-id"])
      assert_file "petal_blog/config/config.exs", ~r/generators: \[binary_id: true\]/
    end
  end

  test "new petal" do
    in_tmp "new petal", fn ->
      Mix.Tasks.Petal.New.run([@app_name])
      assert_file "petal_blog/mix.exs", &assert(&1 =~ ~r":phoenix_live_view")
      assert_file "petal_blog/mix.exs", &assert(&1 =~ ~r":floki")

      refute_file "petal_blog/lib/petal_blog_web/controllers/page_controller.ex"

      assert_file "petal_blog/lib/petal_blog_web/live/page_live.ex", fn file ->
        assert file =~ "defmodule PetalBlogWeb.PageLive do"
      end

      assert_file "petal_blog/lib/petal_blog_web/templates/layout/root.html.leex", fn file ->
        assert file =~ ~s|<%= live_title_tag assigns[:page_title]|
        assert file =~ ~s|<%= link "LiveDashboard", to: Routes.live_dashboard_path(@conn, :home)|
      end

      assert_file "petal_blog/lib/petal_blog_web/live/page_live.html.leex", fn file ->
        assert file =~ ~s[Welcome]
      end

      assert_file "petal_blog/assets/package.json",
                  ~s["phoenix_live_view": "file:../deps/phoenix_live_view"]

      assert_file "petal_blog/assets/js/app.js", fn file ->
        assert file =~ ~s[import {LiveSocket} from "phoenix_live_view"]
      end

      assert_file "petal_blog/assets/css/app.scss", fn file ->
        assert file =~ ~s[.petal-click-loading]
      end

      assert_file "petal_blog/config/config.exs", fn file ->
        assert file =~ "live_view:"
        assert file =~ "signing_salt:"
      end

      assert_file "petal_blog/lib/petal_blog_web.ex", fn file ->
        assert file =~ "import Phoenix.LiveView.Helpers"
        assert file =~ "def live_view do"
        assert file =~ "def live_component do"
      end

      assert_file "petal_blog/lib/petal_blog_web/endpoint.ex", ~s[socket "/live", Phoenix.LiveView.Socket]
      assert_file "petal_blog/lib/petal_blog_web/router.ex", fn file ->
        assert file =~ ~s[plug :fetch_live_flash]
        assert file =~ ~s[plug :put_root_layout, {PetalBlogWeb.LayoutView, :root}]
        assert file =~ ~s[live "/", PageLive]
        refute file =~ ~s[plug :fetch_flash]
        refute file =~ ~s[PageController]
      end
    end
  end

  test "new with live no_dashboard" do
    in_tmp "new with live no_dashboard", fn ->
      Mix.Tasks.Petal.New.run([@app_name, "--live", "--no-dashboard"])

      assert_file "petal_blog/mix.exs", &refute(&1 =~ ~r":phoenix_live_dashboard")

      assert_file "petal_blog/lib/petal_blog_web/templates/layout/root.html.leex", fn file ->
        refute file =~ ~s|<%= link "LiveDashboard", to: Routes.live_dashboard_path(@conn, :home)|
      end

      assert_file "petal_blog/lib/petal_blog_web/endpoint.ex", fn file ->
        assert file =~ ~s|defmodule PetalBlogWeb.Endpoint|
        assert file =~ ~s|socket "/live"|
        refute file =~ ~s|plug Phoenix.LiveDashboard.RequestLogger|
      end
    end
  end

  test "new with uppercase" do
    in_tmp "new with uppercase", fn ->
      Mix.Tasks.Petal.New.run(["petalBlog"])

      assert_file "petalBlog/README.md"

      assert_file "petalBlog/mix.exs", fn file ->
        assert file =~ "app: :petalBlog"
      end

      assert_file "petalBlog/config/dev.exs", fn file ->
        assert file =~ ~r/config :petalBlog, PetalBlog.Repo,/
        assert file =~ "database: \"petalblog_dev\""
      end
    end
  end

  test "new with path, app and module" do
    in_tmp "new with path, app and module", fn ->
      project_path = Path.join(File.cwd!(), "custom_path")
      Mix.Tasks.Petal.New.run([project_path, "--app", @app_name, "--module", "PhoteuxBlog"])

      assert_file "custom_path/.gitignore"
      assert_file "custom_path/.gitignore", ~r/\n$/
      assert_file "custom_path/mix.exs", ~r/app: :petal_blog/
      assert_file "custom_path/lib/petal_blog_web/endpoint.ex", ~r/app: :petal_blog/
      assert_file "custom_path/config/config.exs", ~r/namespace: PhoteuxBlog/
      assert_file "custom_path/lib/petal_blog_web.ex", ~r/use Phoenix.Controller, namespace: PhoteuxBlogWeb/
    end
  end

  test "new inside umbrella" do
    in_tmp "new inside umbrella", fn ->
      File.write! "mix.exs", MixHelper.umbrella_mixfile_contents()
      File.mkdir! "apps"
      File.cd! "apps", fn ->
        Mix.Tasks.Petal.New.run([@app_name])

        assert_file "petal_blog/mix.exs", fn file ->
          assert file =~ "deps_path: \"../../deps\""
          assert file =~ "lockfile: \"../../mix.lock\""
        end

        assert_file "petal_blog/assets/package.json", fn file ->
          assert file =~ ~s["file:../../../deps/phoenix"]
          assert file =~ ~s["file:../../../deps/phoenix_html"]
        end
      end
    end
  end

  test "new with --no-install" do
    in_tmp "new with no install", fn ->
      Mix.Tasks.Petal.New.run([@app_name, "--no-install"])

      # Does not prompt to install dependencies
      refute_received {:mix_shell, :yes?, ["\nFetch and install dependencies?"]}

      # Instructions
      assert_received {:mix_shell, :info, ["\nWe are almost there" <> _ = msg]}
      assert msg =~ "$ cd petal_blog"
      assert msg =~ "$ mix deps.get"

      assert_received {:mix_shell, :info, ["Then configure your database in config/dev.exs" <> _]}
      assert_received {:mix_shell, :info, ["Start your Phoenix app" <> _]}
    end
  end

  test "new defaults to pg adapter" do
    in_tmp "new defaults to pg adapter", fn ->
      project_path = Path.join(File.cwd!(), "custom_path")
      Mix.Tasks.Petal.New.run([project_path])

      assert_file "custom_path/mix.exs", ":postgrex"
      assert_file "custom_path/config/dev.exs", [~r/username: "postgres"/, ~r/password: "postgres"/, ~r/hostname: "localhost"/]
      assert_file "custom_path/config/test.exs", [~r/username: "postgres"/, ~r/password: "postgres"/, ~r/hostname: "localhost"/]
      assert_file "custom_path/config/runtime.exs", [~r/url: database_url/]
      assert_file "custom_path/lib/custom_path/repo.ex", "Ecto.Adapters.Postgres"

      assert_file "custom_path/test/support/conn_case.ex", "Ecto.Adapters.SQL.Sandbox.start_owner"
      assert_file "custom_path/test/support/channel_case.ex", "Ecto.Adapters.SQL.Sandbox.start_owner"
      assert_file "custom_path/test/support/data_case.ex", "Ecto.Adapters.SQL.Sandbox.start_owner"
    end
  end

  test "new with mysql adapter" do
    in_tmp "new with mysql adapter", fn ->
      project_path = Path.join(File.cwd!(), "custom_path")
      Mix.Tasks.Petal.New.run([project_path, "--database", "mysql"])

      assert_file "custom_path/mix.exs", ":myxql"
      assert_file "custom_path/config/dev.exs", [~r/username: "root"/, ~r/password: ""/]
      assert_file "custom_path/config/test.exs", [~r/username: "root"/, ~r/password: ""/]
      assert_file "custom_path/config/runtime.exs", [~r/url: database_url/]
      assert_file "custom_path/lib/custom_path/repo.ex", "Ecto.Adapters.MyXQL"

      assert_file "custom_path/test/support/conn_case.ex", "Ecto.Adapters.SQL.Sandbox.start_owner"
      assert_file "custom_path/test/support/channel_case.ex", "Ecto.Adapters.SQL.Sandbox.start_owner"
      assert_file "custom_path/test/support/data_case.ex", "Ecto.Adapters.SQL.Sandbox.start_owner"
    end
  end

  test "new with mssql adapter" do
    in_tmp "new with mssql adapter", fn ->
      project_path = Path.join(File.cwd!(), "custom_path")
      Mix.Tasks.Petal.New.run([project_path, "--database", "mssql"])

      assert_file "custom_path/mix.exs", ":tds"
      assert_file "custom_path/config/dev.exs", [~r/username: "sa"/, ~r/password: "some!Password"/]
      assert_file "custom_path/config/test.exs", [~r/username: "sa"/, ~r/password: "some!Password"/]
      assert_file "custom_path/config/runtime.exs", [~r/url: database_url/]
      assert_file "custom_path/lib/custom_path/repo.ex", "Ecto.Adapters.Tds"

      assert_file "custom_path/test/support/conn_case.ex", "Ecto.Adapters.SQL.Sandbox.start_owner"
      assert_file "custom_path/test/support/channel_case.ex", "Ecto.Adapters.SQL.Sandbox.start_owner"
      assert_file "custom_path/test/support/data_case.ex", "Ecto.Adapters.SQL.Sandbox.start_owner"
    end
  end

  test "new with invalid database adapter" do
    in_tmp "new with invalid database adapter", fn ->
      project_path = Path.join(File.cwd!(), "custom_path")
      assert_raise Mix.Error, ~s(Unknown database "invalid"), fn ->
        Mix.Tasks.Petal.New.run([project_path, "--database", "invalid"])
      end
    end
  end

  test "new with invalid args" do
    assert_raise Mix.Error, ~r"Application name must start with a letter and ", fn ->
      Mix.Tasks.Petal.New.run ["007invalid"]
    end

    assert_raise Mix.Error, ~r"Application name must start with a letter and ", fn ->
      Mix.Tasks.Petal.New.run ["valid", "--app", "007invalid"]
    end

    assert_raise Mix.Error, ~r"Module name must be a valid Elixir alias", fn ->
      Mix.Tasks.Petal.New.run ["valid", "--module", "not.valid"]
    end

    assert_raise Mix.Error, ~r"Module name \w+ is already taken", fn ->
      Mix.Tasks.Petal.New.run ["string"]
    end

    assert_raise Mix.Error, ~r"Module name \w+ is already taken", fn ->
      Mix.Tasks.Petal.New.run ["valid", "--app", "mix"]
    end

    assert_raise Mix.Error, ~r"Module name \w+ is already taken", fn ->
      Mix.Tasks.Petal.New.run ["valid", "--module", "String"]
    end
  end

  test "invalid options" do
    assert_raise Mix.Error, ~r/Invalid option: -d/, fn ->
      Mix.Tasks.Petal.New.run(["valid", "-database", "mysql"])
    end
  end

  test "new without args" do
    in_tmp "new without args", fn ->
      assert capture_io(fn -> Mix.Tasks.Petal.New.run([]) end) =~
             "Creates a new Phoenix project."
    end
  end
end
