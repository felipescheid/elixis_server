defmodule ElixisServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    port = String.to_integer(System.get_env("PORT") || "4040")

    children = [
      {Task.Supervisor, name: ElixisServer.TaskSupervisor},
      # Here we are configuring the child specification so that tasks will restart if the child process crashes.
      # By default, the :restart value is set to :temporary, which means that tasks never restart.
      # We want to restart the acceptor tasks if they crash. 
      Supervisor.child_spec({Task, fn -> ElixisServer.accept(port) end}, restart: :permanent),
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ElixisServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
