defmodule ExGeeks.EtsCaching do
    @moduledoc """
    A genserver to operate the ETS tables for caching purpose
    and avoid requesting data with low change frequency

    add to your application.ex children supervisor spec
    ```elixir
    children = [
      ...,
      ExGeeks.EtsCaching
    ]
    ```
    If you use the EtsCaching process you have to properly configure it:
    ```elixir
    config :ex_geeks,
      cache_tables: [:table1, {:table2, [options]}]
    ```

    The cache table can either be an atom or a tuple with an atom and a set of options to feed to :ets.new/2
    If an atom only is provided the following default options are used: `[:set, :protected, :named_table]`

    Note that other Geeks Applications can leverage this cache, read their doc. for more details on how to enable
    this feature.
    """
    use GenServer

    alias ExGeeks.Helpers

    def init(arg) do
      Helpers.env(:cache_tables, %{raise: true})
      |> Enum.each( fn
        table ->
          :ets.new(table, [:set, :protected, :named_table])
        {table, options} ->
          :ets.new(table, options)
        end)
      {:ok, arg}
    end

    def start_link(arg) do
      GenServer.start_link(__MODULE__, arg, name: __MODULE__)
    end

    def handle_cast({:insert, table, key, value}, state) do
      :ets.insert(table, {key, value})
      {:noreply, state}
    end

    def handle_cast({:delete, table, key}, state) do
      :ets.delete(table, key)
      {:noreply, state}
    end

    # def new(table, options \\ [:set, :protected, :named_table]) do
    #   :ets.new(table, options)
    # end

    def get(table, key) do
      case :ets.lookup(table, key) do
        [] ->
          nil

        [{_key, value}] ->
          value
      end
    end

    def set(table, key, value) do
      GenServer.cast(__MODULE__, {:insert, table, key, value})
    end

    def delete(table, key) do
      GenServer.cast(__MODULE__, {:delete, table, key})
    end
end
