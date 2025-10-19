defmodule Yachanakuy.Commissions.CommissionOperator do
  use Ecto.Schema
  import Ecto.Changeset

  schema "commission_operators" do
    belongs_to :commission, Yachanakuy.Commissions.Commission
    belongs_to :user, Yachanakuy.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(commission_operator, attrs) do
    commission_operator
    |> cast(attrs, [:commission_id, :user_id])
    |> validate_required([:commission_id, :user_id])
    |> unique_constraint([:commission_id, :user_id], name: :commission_operators_commission_id_user_id_index)
  end
end
