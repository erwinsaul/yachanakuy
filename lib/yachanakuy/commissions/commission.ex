defmodule Yachanakuy.Commissions.Commission do
  use Ecto.Schema
  import Ecto.Changeset

  schema "commissions" do
    field :nombre, :string
    field :codigo, :string
    
    belongs_to :encargado, Yachanakuy.Accounts.User

    has_many :commission_operators, Yachanakuy.Commissions.CommissionOperator
    has_many :users, through: [:commission_operators, :user]

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(commission, attrs) do
    commission
    |> cast(attrs, [:nombre, :codigo, :encargado_id])
    |> validate_required([:nombre, :codigo])
    |> unique_constraint(:codigo)
  end
end
