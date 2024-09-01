defmodule ElixisServer.Command do
  # the ~S prevents \r and \r from being converted to carriage return/line feed until they are evaluated in the test
  @doc ~S"""
  Parses the given `line` into a command

  ## Examples

    iex> ElixisServer.Command.parse("CREATE shopping\r\n")
    {:ok, {:create, "shopping"}}

    iex> ElixisServer.Command.parse "CREATE shopping \r\n"
    {:ok, {:create, "shopping"}}

    iex> ElixisServer.Command.parse "PUT shopping milk 1\r\n"
    {:ok, {:put, "shopping", "milk", "1"}}

    iex> ElixisServer.Command.parse "GET shopping milk\r\n"
    {:ok, {:get, "shopping", "milk"}}

    iex> ElixisServer.Command.parse "DELETE shopping eggs\r\n"
    {:ok, {:delete, "shopping", "eggs"}}

  Unknown command or commands with the wrong number of arguments
  return an error:

    iex> ElixisServer.Command.parse "UNKNOWN shopping eggs\r\n"
    {:error, :unknown_command}

    iex> ElixisServer.Command.parse "GET shopping\r\n"
    {:error, :unknown_command}


  """
  def parse(line) do
    case String.split(line) do
      ["CREATE", bucket] -> {:ok, {:create, bucket}}
      ["GET", bucket, key] -> {:ok, {:get, bucket, key}}
      ["PUT", bucket, key, value] -> {:ok, {:put, bucket, key, value}}
      ["DELETE", bucket, key] -> {:ok, {:delete, bucket, key}}
      _ -> {:error, :unknown_command}
    end
  end

  @doc """
  Runs the given command
  """
  def run(command)

  def run({:create, bucket}) do
    case Elixis.Router.route(bucket, Elixis.Registry, :create, [Elixis.Registry, bucket]) do
      pid when is_pid(pid) -> {:ok, "OK\r\n"}
      _ -> {:error, "FAILED TO CREATE BUCKET"}
    end
  end

  def run({:get, bucket, key}) do
    lookup(bucket, fn pid ->
      value = Elixis.Bucket.get(pid, key)
      {:ok, "#{value}\r\nOK\r\n"}
    end)
  end

  def run({:put, bucket, key, value}) do
    lookup(bucket, fn pid ->
      Elixis.Bucket.put(pid, key, value)
      {:ok, "OK\r\n"}
    end)
  end

  def run({:delete, bucket, key}) do
    lookup(bucket, fn pid ->
      Elixis.Bucket.delete(pid, key)
      {:ok, "OK\r\n"}
    end)
  end

  defp lookup(bucket, callback) do
    case Elixis.Router.route(bucket, Elixis.Registry, :lookup, [Elixis.Registry, bucket]) do
      {:ok, pid} -> callback.(pid)
      :error -> {:error, :not_found}
    end
  end
end
