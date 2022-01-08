defmodule AwsCconfTest do
  use ExUnit.Case
  alias AwsCconf.Files
  doctest AwsCconf.Files

  test "resolve non existant files" do
    paths = ["/not-a-dir/credentials", "/not-a-dir/conf"]
    assert [{:error, _}, {:error, _}] = Files.resolved(paths)
  end

  test "resolve existant files" do
    paths = ["/fxitures/credentials", "/fixtures/conf"]
    [{:ok, creds}, {:ok, conf}] = Files.resolved(paths)
    assert creds
    assert conf
  end
end
