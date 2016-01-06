defmodule Voorhees.JSONApi do
  import ExUnit.Assertions

  def assert_schema(%{"data" => list } = actual , expected) when is_list(list) do
    list
    |> Enum.map(&(_assert_resource(&1, expected)))

    if included = actual["included"] do
      included
      |> Enum.map(&(_assert_resource(&1, expected)))
    end

    actual
  end

  def assert_schema(%{"data" => resource } = actual , expected) when is_map(resource) do
    _assert_resource(resource, expected)

    actual
  end

  defp _assert_resource(resource, expected) do
    %{"type" => type, "attributes" => attributes} = resource

    expected
    |> Map.fetch(String.to_atom(type))
    |> case do
      :error ->
        assert false, "Expected schema did not contain type: #{type}"
      {:ok, expected_schema} ->
        %{attributes: expected_attributes} = expected_schema
        _assert_attributes(attributes, expected_attributes)
    end
  end

  defp _assert_attributes(attributes, expected_attributes) do
    attribute_names = attributes
    |> Map.keys
    |> Enum.map(&(String.to_atom(&1)))

    extra_attributes = attribute_names -- expected_attributes
    assert [] == extra_attributes, "Payload contained additional attributes: #{extra_attributes |> Enum.join(", ")}"

    missing_attributes = expected_attributes -- attribute_names
    assert [] == missing_attributes, "Payload was missing attributes: #{missing_attributes |> Enum.join(", ")}"
  end

  def assert_payload(actual, expected, options \\ []) do
    comparison = compare_payloads(actual, expected, options)
    assert :ok == comparison, error_message(comparison)

    actual
  end

  defp error_message(:ok), do: ""
  defp error_message({:error, message}), do: "Payload did not match expected\n\n" <> message

  defp compare_payloads(actual, expected, options) do
    expected = normalize_map(expected)

    with {:ok, actual_data} <- Map.fetch(actual, "data"),
         {:ok, expected_data} <- Map.fetch(expected, "data") do
           compare_resources(actual_data, expected_data, options)
           |> case do
             {:error, message} -> {:error, "\"data\" did not match expected\n" <> message}
             :ok -> :ok
           end
         end
  end

  defp compare_resources(actual, expected, options) when is_map(actual) do
    filtered_actual = filter_out_extra_keys(actual, expected, options)

    if (filtered_actual == expected) do
      :ok
    else
      {:error, """
        Expected:
          #{inspect expected}
        Actual (filtered):
          #{inspect filtered_actual}
        Actual (untouched):
          #{inspect actual}
        """}
    end
  end

  defp compare_resources(actual, expected, options) when is_list(actual) do
    if Dict.get(options, :ignore_list_order) do
      compare_resources_list(actual, expected, options, :ignore_list_order)
    else
      compare_resources_list(actual, expected, options)
    end
  end

  defp compare_resources_list(actual, expected, options, :ignore_list_order) when is_list(actual) do
    filtered_actual = filter_out_extra_keys(actual, expected, options)

    extra_resources = filtered_actual -- expected
    missing_resources = expected -- filtered_actual

    if Enum.empty?(extra_resources) && Enum.empty?(missing_resources) do
      :ok
    else
      message = ""
      if Enum.any?(extra_resources) do
        extra_resources_inspection =
          extra_resources
          |> Enum.map(&inspect/1)
          |> Enum.join(",\n  ")
        message = message <> "Contained extra resources:\n  " <> extra_resources_inspection <> "\n"
      end
      if Enum.any?(missing_resources) do
        missing_resources_inspection =
          missing_resources
          |> Enum.map(&inspect/1)
          |> Enum.join(",\n  ")
        message = message <> "Missing resources:\n  " <> missing_resources_inspection <> "\n"
      end
      {:error, message}
    end
  end

  defp compare_resources_list(actual, expected, options) when is_list(actual) do
    message = actual
    |> Enum.zip(expected)
    |> Enum.map(fn
      {actual_resource, expected_resource} ->
        compare_resources(actual_resource, expected_resource, options)
    end)
    |> Enum.with_index
    |> Enum.reduce({:ok, ""}, fn
      {{:error, message}, index}, {_state, acc_message} = acc ->
        {:error, acc_message <> "\nResource at index #{index} did not match\n" <> message}
      _, acc -> acc
    end)
  end

  defp normalize_map(map) when is_map(map) do
    map
    |> Enum.map(&normalize_map_entry/1)
    |> Enum.into(%{})
  end

  defp normalize_map(list) when is_list(list), do: Enum.map(list, &normalize_map/1)
  defp normalize_map(value), do: value

  defp normalize_map_entry({key, value}) when is_map(value) or is_list(value), do: {normalize_key(key), normalize_map(value)}
  defp normalize_map_entry({key, value}), do: {normalize_key(key), value}

  defp normalize_key(key) when is_atom(key), do: Atom.to_string(key)
  defp normalize_key(key), do: key

  defp filter_out_extra_keys(payload, expected_payload, options) when is_list(payload) do
    filtered_payload = payload
    |> Enum.with_index
    # When payload is longer than expected_payload, we need to filter out the other potential matches based on an existing payload
    |> Enum.map(fn {value, index} -> filter_out_extra_keys(value, Enum.at(expected_payload, index) || Enum.at(expected_payload, 0), options) end)

    if Dict.get(options, :ignore_list_order) do
      if filtered_payload -- expected_payload == [] && expected_payload -- filtered_payload == [] do
        filtered_payload = expected_payload
      end
    end

    filtered_payload
  end

  defp filter_out_extra_keys(payload, nil, _options) when is_map(payload), do: payload

  defp filter_out_extra_keys(payload, expected_payload, options) when is_map(payload) do
    payload
    |> Enum.filter(fn
      {key, _value} ->
        expected_payload
        |> Map.keys
        |> Enum.member?(key)
    end)
    |> Enum.map(fn
      {key, value} when is_map(value) or is_list(value) -> {key, filter_out_extra_keys(value, expected_payload[key], options)}
      entry -> entry
    end)
    |> Enum.into(%{})
  end

  defp filter_out_extra_keys(payload, _expected_payload, _options), do: payload
end
