defmodule ExGeeks.Helpers do
  @moduledoc """
  Helper Functions
  """
  alias ExGeeksWeb.EmailView

  import Ecto.Query
  require Logger
  @email_regex ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/
  def graphql_error(message, error \\ nil)

  def graphql_error(message, nil) when not is_binary(message) do
    {:ok, encoded_message} = Poison.encode(message)
    graphql_error(encoded_message, message)
  end

  def graphql_error(message, error) when not is_binary(message) do
    {:ok, encoded_message} = Poison.encode(message)
    graphql_error(encoded_message, error)
  end

  def graphql_error(message, nil) do
    message =
      case Poison.decode(message) do
        {:ok, _} ->
          message

        {:error, _} ->
          # not yet encoded, this means the message is a string
          # this is to have a uniform way of returning errors
          # All are encoded
          {:ok, encoded_message} = Poison.encode(message)
          encoded_message
      end

    {:error, %{message: message}}
  end

  def graphql_error(message, error) do
    message =
      case Poison.decode(message) do
        {:ok, _} ->
          message

        {:error, _} ->
          # not yet encoded, this means the message is a string
          # this is to have a uniform way of returning errors
          # All are encoded
          {:ok, encoded_message} = Poison.encode(message)
          encoded_message
      end

    {:error, %{message: message, errors: error}}
  end

  @doc """
  Used to standardize the return from a database query into a tuple.
  """
  def tuple_return(nil), do: {:error, :not_found}
  def tuple_return(response) when is_struct(response), do: {:ok, response}
  def tuple_return(response) when is_map(response), do: {:ok, response}

  @doc """
  Convert map string keys to :atom keys
  """
  def atomize_keys(nil), do: nil

  # Structs don't do enumerable and anyway the keys are already
  # atoms
  def atomize_keys(%{__struct__: _} = struct) do
    struct
  end

  def atomize_keys(%{} = map) do
    map
    |> Enum.map(fn {k, v} -> {atomize(k), atomize_keys(v)} end)
    |> Enum.into(%{})
  end

  # Walk the list and atomize the keys of
  # of any map members
  def atomize_keys([head | rest]) do
    [atomize_keys(head) | atomize_keys(rest)]
  end

  def atomize_keys(not_a_map) do
    not_a_map
  end

  def atomize(k) when is_binary(k) do
    String.to_atom(k)
  end

  def atomize(k) do
    k
  end

  def endpoint_get_callback(
        url,
        headers \\ [{"content-type", "application/json"}]
      ) do
    case HTTPoison.get(url, headers) do
      {:ok, response} ->
        fetch_response_body(response)

      {:error, error} ->
        Logger.error("#{inspect(error)}")
        {:error, error}
    end
  end

  def endpoint_put_callback(
        url,
        args,
        headers \\ [{"content-type", "application/json"}]
      ) do
    {:ok, body} = args |> Poison.encode()

    case HTTPoison.put(url, body, headers) do
      {:ok, response} ->
        fetch_response_body(response)

      {:error, error} ->
        Logger.error("#{inspect(error)}")

        {:error, "Target Server Error"}
    end
  end

  def endpoint_post_callback(
        url,
        args,
        headers \\ [{"content-type", "application/json"}]
      ) do
    {:ok, body} = args |> Poison.encode()

    case HTTPoison.post(url, body, headers) do
      {:ok, response} ->
        fetch_response_body(response)

      {:error, error} ->
        Logger.error("#{inspect(error)}")
        {:error, "users credentials server error"}
    end
  end

  defp content_type?(_body, headers, type) do
    Enum.any?(headers, fn
      {"content-type", ^type} -> true
      _ -> false
    end)
  end

  defp transform_body(body, headers) do
    cond do
      content_type?(body, headers, "application/json") ->
        {:ok, body} = Poison.encode(body)
        body

      content_type?(body, headers, "application/x-www-form-urlencoded") ->
        URI.encode_query(body)

      true ->
        body
    end
  end

  def endpoint_request_callback(
        method,
        url,
        body,
        headers \\ [{"content-type", "application/json"}]
      ) do
    body = transform_body(body, headers)

    case HTTPoison.request(method, url, body, headers) do
      {:ok, response} ->
        fetch_response_body(response)

      {:error, error} ->
        Logger.error("#{inspect(error)}")
        {:error, "Request failed #{inspect(error)}"}
    end
  end

  def endpoint_delete_callback(
        url,
        headers \\ [{"content-type", "application/json"}]
      ) do
    # to use a delete request with a body
    # refer to Httpoison.request/5
    # {:ok, body} = args |> Poison.encode()

    case HTTPoison.delete(url, headers) do
      {:ok, response} ->
        fetch_response_body(response)

      {:error, error} ->
        Logger.error("#{inspect(error)}")
        {:error, "users credentials server error"}
    end
  end

  def fetch_response_body(%{body: "", status_code: status_code})
      when status_code in 200..299,
      do: ""

  def fetch_response_body(%{body: "ok", status_code: status_code})
      when status_code in 200..299,
      do: ""

  ## this will pattern match with json encoded body that respects the utf-9
  ## https://en.wikipedia.org/wiki/Byte_order_mark
  def fetch_response_body(%{body: "\uFEFF" <> body, status_code: status_code} = response)
      when status_code in 200..299,
      do: fetch_response_body(response |> Map.put(:body, "#{body}"))

  def fetch_response_body(response) do
    with true <- response.status_code in 200..299, {:ok, body} <- Poison.decode(response.body) do
      body
    else
      false ->
        Logger.error("#{inspect(response)}")

        case Poison.decode(response.body) do
          {:ok, body} ->
            {:error, body}

          _ ->
            {:error, response.body}
        end
    end
  end

  def email_regex do
    @email_regex
  end

  def add_offset(query, 0), do: query
  def add_offset(query, nil), do: query

  def add_offset(query, offset) do
    query
    |> offset(^offset)
  end

  def add_limit(query, 0), do: query
  def add_limit(query, nil), do: query

  def add_limit(query, limit) do
    query
    |> limit(^limit)
  end

  def render_template(template, assigns \\ []) do
    {:ok, html_body} =
      EmailView.render_to_string(
        template,
        assigns
      )
      |> Mjml.to_html()

    html_body
  end
end
