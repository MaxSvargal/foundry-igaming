# IgamingRef seeds — Demo data for preview server
# This file is executed by `mix ecto.setup` and `mix ecto.reset`.
# Only runs in dev/test environments.

require Logger

alias IgamingRef.Gaming
alias IgamingRef.Promotions
alias IgamingRef.Repo

# Clear existing data (safe for demo/reset)
Repo.delete_all(Promotions.BonusCampaign)
Repo.delete_all(Gaming.Game)

# Create featured games
# Games are read-only; created via :sync action which simulates provider sync
provider_id = "11111111-1111-1111-1111-111111111111"

games = [
  %{
    provider_id: provider_id,
    provider_game_code: "starburst",
    title: "Starburst",
    category: "slot",
    rtp: Decimal.new("96.09"),
    volatility: :medium
  },
  %{
    provider_id: provider_id,
    provider_game_code: "gonzo_quest",
    title: "Gonzo's Quest",
    category: "slot",
    rtp: Decimal.new("95.97"),
    volatility: :high
  },
  %{
    provider_id: provider_id,
    provider_game_code: "book_of_ra",
    title: "Book of Ra",
    category: "slot",
    rtp: Decimal.new("96.30"),
    volatility: :medium
  },
  %{
    provider_id: provider_id,
    provider_game_code: "blackjack_live",
    title: "Live Blackjack",
    category: "live",
    rtp: Decimal.new("99.50"),
    volatility: :low
  }
]

created_games =
  Enum.map(games, fn game_attrs ->
    case Gaming.Game |> Ash.Changeset.for_create(:sync, game_attrs) |> Repo.create() do
      {:ok, game} ->
        game

      {:error, error} ->
        Logger.warning("Could not create game #{game_attrs[:title]}: #{inspect(error)}")
        nil
    end
  end)
  |> Enum.reject(&is_nil/1)

IO.puts("✓ Created #{length(created_games)} featured games")

# Create active bonus campaigns
now = DateTime.utc_now()
tomorrow = DateTime.add(now, 24 * 60 * 60, :second)
in_30_days = DateTime.add(now, 30 * 24 * 60 * 60, :second)

campaigns = [
  %{
    name: "Welcome Bonus - 100% Match",
    kind: :deposit_match,
    eligibility_rule: "IgamingRef.Promotions.Rules.PlayerEligibleForCampaign",
    bonus_amount: Money.new(10_000, :EUR),
    wagering_multiplier: Decimal.new("3"),
    max_redemptions: nil,
    starts_at: now,
    expires_at: in_30_days
  },
  %{
    name: "Free Spins Friday",
    kind: :free_spins,
    eligibility_rule: "IgamingRef.Promotions.Rules.PlayerEligibleForCampaign",
    bonus_amount: Money.new(5_000, :EUR),
    wagering_multiplier: Decimal.new("2"),
    max_redemptions: 500,
    starts_at: now,
    expires_at: in_30_days
  },
  %{
    name: "Cashback Weekend",
    kind: :cashback,
    eligibility_rule: "IgamingRef.Promotions.Rules.PlayerEligibleForCampaign",
    bonus_amount: Money.new(2_500, :EUR),
    wagering_multiplier: Decimal.new("1"),
    max_redemptions: nil,
    starts_at: now,
    expires_at: in_30_days
  }
]

created_campaigns =
  Enum.map(campaigns, fn campaign_attrs ->
    with {:ok, campaign} <-
           Promotions.BonusCampaign
           |> Ash.Changeset.for_create(:create, campaign_attrs)
           |> Repo.create(),
         {:ok, activated} <-
           campaign
           |> Ash.Changeset.for_update(:activate)
           |> Repo.update() do
      activated
    else
      {:error, error} ->
        Logger.warning("Could not create campaign #{campaign_attrs[:name]}: #{inspect(error)}")
        nil
    end
  end)
  |> Enum.reject(&is_nil/1)

IO.puts("✓ Created #{length(created_campaigns)} active bonus campaigns")
IO.puts("")
IO.puts("Demo data loaded! Preview UI should now show featured games and active promotions.")
