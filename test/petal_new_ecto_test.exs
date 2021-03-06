Code.require_file "mix_helper.exs", __DIR__

defmodule Mix.Tasks.Petal.New.EctoTest do
  use ExUnit.Case
  import MixHelper
  import ExUnit.CaptureIO

  setup do
    # The shell asks to install deps.
    # We will politely say not.
    send self(), {:mix_shell_input, :yes?, false}
    :ok
  end

  @app_name "petal_ecto"

  test "new without args" do
    assert capture_io(fn -> Mix.Tasks.Petal.New.Ecto.run([]) end) =~
           "Creates a new Ecto project within an umbrella project."
  end

  test "new outside umbrella", config do
    in_tmp config.test, fn ->
      assert_raise Mix.Error, ~r"The ecto task can only be run within an umbrella's apps directory", fn ->
        Mix.Tasks.Petal.New.Ecto.run ["007invalid"]
      end
    end
  end

  test "new with defaults", config do
    in_tmp_umbrella_project config.test, fn ->
      Mix.Tasks.Petal.New.Ecto.run([@app_name])

      # Install dependencies?
      assert_received {:mix_shell, :yes?, ["\nFetch and install dependencies?"]}

      # Instructions
      assert_received {:mix_shell, :info, ["\nWe are almost there" <> _ = msg]}
      assert msg =~ "$ cd petal_ecto"
      assert msg =~ "$ mix deps.get"

      assert_received {:mix_shell, :info, ["Then configure your database in config/dev.exs" <> _]}
    end
  end
end
