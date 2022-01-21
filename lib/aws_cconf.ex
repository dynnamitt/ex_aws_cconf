defmodule AwsCconf do
  @moduledoc """
  select a profile and combine parsed config attrs
  """

  @creds_attrs_subset [
    "aws_access_key_id",
    "aws_secret_access_key",
    "aws_session_token"
  ]

  # TRIGGERS for new "STS Session credentials"
  @attr_src_p "source_profile"
  @attr_mfa "mfa_serial"

  # https://stackoverflow.com/questions/62311866/how-to-use-the-aws-python-sdk-while-connecting-via-sso-credentials
  @attr_sso_url "sso_start_url"

  @doc """
  Selects a profile (in each map) then merge the keyvalues.

  .aws/credentials ALWAYS come first,
  then .aws/config
  """
  @spec combine(
          {creds :: map(), config :: map()},
          profile_name :: String.t(),
          strict_creds_subset? :: boolean(),
          recurse_src_profile_attr? :: boolean()
        ) :: map()
  def combine(
        {creds, config},
        profile_name \\ "default",
        strict_creds_subset? \\ true,
        recurse_src_profile_attr? \\ true
      ) do
    attrs =
      [creds[profile_name], get_config_p(config, profile_name)]
      |> case do
        [creds_p, conf_p] when strict_creds_subset? and creds_p != nil ->
          [Map.take(creds_p, @creds_attrs_subset), conf_p]

        [creds_p, conf_p] ->
          [creds_p, conf_p]
      end
      |> Enum.reject(&(&1 == nil))
      |> Enum.reduce(fn x, acc -> Enum.into(acc, x) end)

    case attrs do
      %{@attr_src_p => src_p} when recurse_src_profile_attr? ->
        %{attrs | @attr_src_p => combine({creds, config}, src_p, strict_creds_subset?, false)}

      _ ->
        attrs
    end
  end

  defp get_config_p(profiles, pname) when pname == "default" do
    profiles[pname]
  end

  defp get_config_p(profiles, pname) do
    profiles
    |> Map.keys()
    # TODO compile regex to avoid special-char injection
    |> Enum.find(&String.match?(&1, ~r/profile\ *#{pname}/))
    |> then(&profiles[&1])
  end
end
