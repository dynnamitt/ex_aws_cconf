defmodule AwsCconfTest do
  use ExUnit.Case
  alias AwsCconf.Files
  doctest AwsCconf.Files

  # ExUnit.after_suite(fn ->
  #   System.put_env("MY_CREDS", "!")
  #   System.put_env("MY_CONF", "!")
  # end)

  @fix_creds "./fixtures/credentials"
  @fix_config "./fixtures/config"

  test "resolve non existant files" do
    paths = {"/not-a-dir/credentials", "/not-a-dir/conf"}
    assert [{:error, _}, {:error, :enoent}] = Files.resolved(paths)
  end

  test "resolve our files" do
    paths = {@fix_creds, @fix_config}
    [{:ok, creds}, {:ok, conf}] = Files.resolved(paths)
    assert creds
    assert conf
  end

  test "env will override" do
    System.put_env("MY_CREDS", @fix_creds)
    System.put_env("MY_CONF", @fix_config)
    # TODO reset

    paths = {"/not-a-dir/credentials", "/not-a-dir/conf"}
    envs = {"MY_CREDS", "MY_CONF"}
    [{:ok, creds}, {:ok, conf}] = Files.resolved(paths, envs)
    assert creds
    assert conf
  end
end
