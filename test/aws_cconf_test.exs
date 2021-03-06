defmodule AwsCconfTest do
  use ExUnit.Case
  doctest AwsCconf

  setup_all do
    # on_exit(&cleanup/0)
    [
      test_creds: %{
        "default" => %{
          "aws_access_key_id" => "ABC"
        },
        "other" => %{
          "aws_access_key_id" => "abc",
          "aws_secret_access_key" => "cde",
          "aws_session_token" => "acdsdcdsbc",
          "_region_" => "will not be loaded default",
          "region" => "nor this"
        },
        "only-here" => %{
          "aws_access_key_id" => "CRED_K_ID"
        }
      },
      test_conf: %{
        "default" => %{
          "region" => "eu-west-1",
          "cli_pager" => "less",
          "aws_access_key_id" => "comes second"
        },
        "profile other" => %{
          "region" => "eu-west-1"
        },
        "profile accesskeys" => %{
          "aws_access_key_id" => "in_conf",
          "aws_secret_access_key" => "will_work_also",
          "cli_pager" => "more"
        },
        "profile trigger" => %{
          "region" => "eu-west-1",
          "role_arn" => "aws:arn:dada",
          "source_profile" => "other"
        },
        "profile another_trigger" => %{
          "region" => "eu-north-1",
          "role_arn" => "aws:arn:-----",
          "source_profile" => "accesskeys"
        }
      }
    ]
  end

  def cleanup() do
    IO.puts("Cleanup done")
  end

  #
  test "combines two maps", ctx do
    result = AwsCconf.combine({ctx.test_creds, ctx.test_conf})
    assert ["aws_access_key_id", "cli_pager", "region"] == Map.keys(result)
  end

  test "combines MAYBE two maps", ctx do
    result = AwsCconf.combine({ctx.test_creds, ctx.test_conf}, "only-here")
    assert %{"aws_access_key_id" => "CRED_K_ID"} = result

    result2 = AwsCconf.combine({ctx.test_creds, ctx.test_conf}, "accesskeys")
    assert %{"aws_access_key_id" => "in_conf"} = result2
  end

  test "only picks 3 keys (STRICT mode) from credentials", ctx do
    result = AwsCconf.combine({ctx.test_creds, ctx.test_conf}, "other")

    assert [
             "aws_access_key_id",
             "aws_secret_access_key",
             "aws_session_token",
             "region"
           ] == Map.keys(result)
  end

  test "all keys (NON strict) from credentials", ctx do
    result = AwsCconf.combine({ctx.test_creds, ctx.test_conf}, "other", false)

    assert [
             "_region_",
             "aws_access_key_id",
             "aws_secret_access_key",
             "aws_session_token",
             "region"
           ] == Map.keys(result)
  end

  test "values from credentials has presedence", ctx do
    result = AwsCconf.combine({ctx.test_creds, ctx.test_conf}, "other", false)
    assert result["region"] == "nor this"

    result2 = AwsCconf.combine({ctx.test_creds, ctx.test_conf}, "default", false)
    assert result2["aws_access_key_id"] == "ABC"
    assert result2["cli_pager"] == "less"
  end

  test "'source_profile' as be recursive map attr (default)", ctx do
    result = AwsCconf.combine({ctx.test_creds, ctx.test_conf}, "trigger")
    # IO.inspect(result)
    assert %{
             "aws_access_key_id" => "abc"
           } = result["source_profile"]

    result2 = AwsCconf.combine({ctx.test_creds, ctx.test_conf}, "another_trigger")
    # IO.inspect(result)
    assert %{
             "aws_access_key_id" => "in_conf",
             "cli_pager" => "more"
           } = result2["source_profile"]
  end

  test "'source_profile' as normal string attr", ctx do
    result = AwsCconf.combine({ctx.test_creds, ctx.test_conf}, "trigger", true, false)
    # IO.inspect(result)
    assert "other" = result["source_profile"]
  end
end
