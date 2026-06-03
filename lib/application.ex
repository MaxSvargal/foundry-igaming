defmodule IgamingRef.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        {Phoenix.PubSub, name: IgamingRef.PubSub},
        IgamingRef.Web.Endpoint
      ] ++ data_children()

    opts = [strategy: :one_for_one, name: IgamingRef.Supervisor]

    with {:ok, _pid} <- Supervisor.start_link(children, opts) do
      # Load seed data on app boot (for preview server demo)
      if not Application.get_env(:igaming_ref, :foundry_tasks_only, false) do
        load_seeds()
      end

      {:ok, _pid}
    end
  end

  defp data_children do
    if Application.get_env(:igaming_ref, :foundry_tasks_only, false) do
      # Keep the preview UI bootable even when Foundry tasks run without a DB.
      []
    else
      [
        IgamingRef.Repo,
        {Oban, Application.fetch_env!(:igaming_ref, Oban)}
      ]
    end
  end

  defp load_seeds do
    # Load demo data from seeds.exs for preview server.
    # Only runs in dev environment when database is available.
    case Application.get_env(:igaming_ref, :environment, :dev) do
      :prod ->
        :ok

      _ ->
        seed_file = Application.app_dir(:igaming_ref, "priv/repo/seeds.exs")

        if File.exists?(seed_file) do
          Code.eval_file(seed_file)
        end
    end
  rescue
    _ -> :ok  # Silently fail if seeds can't load (DB might not be ready yet)
  end
end

defmodule IgamingRef.Repo do
  use AshPostgres.Repo, otp_app: :igaming_ref

  def installed_extensions do
    ["ash-functions", "uuid-ossp", "citext"]
  end

  def min_pg_version do
    %Version{major: 16, minor: 0, patch: 0}
  end
end

# Note: Domain modules are defined in dedicated files:
# - lib/finance.ex
# - lib/players.ex
# - lib/promotions.ex
# - lib/accounts.ex
# - lib/ops.ex
# - lib/gaming.ex
