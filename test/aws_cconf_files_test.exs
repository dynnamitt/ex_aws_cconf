defmodule AwsCconfFileTest do
  use ExUnit.Case
  alias AwsCconf.Files
  doctest AwsCconf.Files

  setup_all do
    t_dir = System.tmp_dir!()
    t_suffix = s = for _ <- 1..10, into: "", do: <<Enum.random('0123456789abcdef')>>

    fix = [
      test_credentials: t_dir <> "/test_credentials_" <> t_suffix,
      test_config: t_dir <> "/test_config_" <> t_suffix
    ]

    IO.puts("Writing 2 temp files:")
    IO.inspect(fix)

    File.write(fix[:test_credentials], "[default]\nx=1")
    File.write(fix[:test_config], "[default]\n[another]\n")

    on_exit(&cleanup/0)

    fix
  end

  def cleanup() do
    System.delete_env("MY_CREDS")
    System.delete_env("MY_CONF")
    IO.puts("removed envs")
  end

  #

  test "cannot resolve non existant files" do
    paths = {"/not-a-dir/credentials", "/not-a-dir/conf"}
    assert [{:error, :enoent}, {:error, :enoent}] = Files.resolved(paths)
  end

  test "resolve our test files", ctx do
    paths = {ctx.test_credentials, ctx.test_config}
    [{:ok, creds}, {:ok, conf}] = Files.resolved(paths)
    assert 1 == Enum.count(Map.keys(creds))
    assert 2 == Enum.count(Map.keys(conf))
  end

  test "env will override", ctx do
    IO.puts("setting envs...")

    System.put_env("MY_CREDS", ctx.test_credentials)
    System.put_env("MY_CONF", ctx.test_config)
    # TODO reset

    paths = {"/not-a-dir/credentials", "/not-a-dir/conf"}
    envs = {"MY_CREDS", "MY_CONF"}
    [{:ok, creds}, {:ok, conf}] = Files.resolved(paths, envs)
    assert 1 == Enum.count(Map.keys(creds))
    assert 2 == Enum.count(Map.keys(conf))
  end
end
