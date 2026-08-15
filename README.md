# ExGeeks

Small shared Elixir helpers used across Geeks projects.

This library intentionally stays focused on plain application utilities. It does not include Phoenix views, template compilation, MJML rendering, assets, or web endpoint setup.

## What It Provides

- `ExGeeks.Helpers`: general helper functions for configuration, GraphQL-style errors, map key conversion, HTTP calls, API filters, Ecto pagination, email validation, and BSON id validation.
- `ExGeeks.EtsCaching`: a small GenServer wrapper around named ETS tables for simple shared caching.

## Helpers

### Configuration

Use `ExGeeks.Helpers.env/2` to read values from the `:ex_geeks` application environment:

```elixir
ExGeeks.Helpers.env(:some_key, %{default: "fallback"})
ExGeeks.Helpers.env(:required_key, %{raise: true})
```

### Error Formatting

`graphql_error/2` returns standardized `{:error, map}` tuples with JSON-encoded messages:

```elixir
ExGeeks.Helpers.graphql_error("Something went wrong")
ExGeeks.Helpers.graphql_error(%{code: "invalid"}, %{field: "email"})
```

### Data Helpers

- `tuple_return/1` converts `nil` to `{:error, :not_found}` and maps/structs to `{:ok, value}`.
- `atomize_keys/2` recursively converts string keys to atoms.
- `email_regex/0` returns the shared email validation regex.
- `valid_bson?/1` checks whether a string looks like a BSON ObjectId.

### HTTP Helpers

The HTTP helpers wrap `HTTPoison` and decode JSON responses with `Poison`:

```elixir
ExGeeks.Helpers.endpoint_get_callback(url)
ExGeeks.Helpers.endpoint_post_callback(url, %{name: "Geeks"})
ExGeeks.Helpers.endpoint_put_callback(url, %{name: "Geeks"})
ExGeeks.Helpers.endpoint_delete_callback(url)
ExGeeks.Helpers.endpoint_request_callback(:patch, url, body)
```

Pass `raw: true` to keep the original `HTTPoison.Response` and add `:decoded_body`.

### API Filters

`build_filters/2` converts filter input into regular filters and concatenated-field search filters used by Geeks APIs.

```elixir
filters = [%{key: "name", value: ["Ada"]}]
fields = %{"name" => ["profile.firstname", "profile.lastname"]}

ExGeeks.Helpers.build_filters(filters, fields)
```

### Ecto Query Helpers

Use `add_offset/2` and `add_limit/2` to conditionally apply pagination clauses:

```elixir
query
|> ExGeeks.Helpers.add_offset(offset)
|> ExGeeks.Helpers.add_limit(limit)
```

## ETS Caching

Add `ExGeeks.EtsCaching` to your application supervisor:

```elixir
children = [
  ExGeeks.EtsCaching
]
```

Configure the named ETS tables:

```elixir
config :ex_geeks,
  cache_tables: [
    :users_cache,
    {:tokens_cache, [:set, :protected, :named_table]}
  ]
```

Use the cache through the module API:

```elixir
ExGeeks.EtsCaching.set(:users_cache, user_id, user)
ExGeeks.EtsCaching.get(:users_cache, user_id)
ExGeeks.EtsCaching.delete(:users_cache, user_id)
```
