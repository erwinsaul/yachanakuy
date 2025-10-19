defmodule Yachanakuy.Commissions do
  @moduledoc """
  The Commissions context.
  """
  import Ecto.Query, warn: false
  alias Yachanakuy.Repo

  alias Yachanakuy.Commissions.Commission
  alias Yachanakuy.Commissions.CommissionOperator

  def list_commissions do
    Repo.all(Commission)
  end

  def list_commissions_with_supervisor do
    Repo.all(Commission)
    |> Repo.preload([:encargado])
  end

  def get_commission_with_supervisor!(id) do
    Repo.get!(Commission, id)
    |> Repo.preload([:encargado])
  end

  def list_commission_operators_with_users do
    Repo.all(CommissionOperator)
    |> Repo.preload([:user, :commission])
  end

  def get_operators_for_commission_with_details(commission_id) do
    import Ecto.Query

    query = from co in CommissionOperator,
      where: co.commission_id == ^commission_id,
      join: u in assoc(co, :user),
      join: c in assoc(co, :commission),
      preload: [user: u, commission: c]

    Repo.all(query)
  end

  def get_commission!(id) do
    Repo.get!(Commission, id)
  end

  def create_commission(attrs \\ %{}) do
    %Commission{}
    |> Commission.changeset(attrs)
    |> Repo.insert()
  end

  def update_commission(%Commission{} = commission, attrs) do
    commission
    |> Commission.changeset(attrs)
    |> Repo.update()
  end

  def delete_commission(%Commission{} = commission) do
    Repo.delete(commission)
  end

  def change_commission(%Commission{} = commission, attrs \\ %{}) do
    Commission.changeset(commission, attrs)
  end

  alias Yachanakuy.Commissions.CommissionOperator

  def list_commission_operators do
    Repo.all(CommissionOperator)
  end

  def get_commission_operator!(id) do
    Repo.get!(CommissionOperator, id)
  end

  def create_commission_operator(attrs \\ %{}) do
    %CommissionOperator{}
    |> CommissionOperator.changeset(attrs)
    |> Repo.insert()
  end

  def update_commission_operator(%CommissionOperator{} = commission_operator, attrs) do
    commission_operator
    |> CommissionOperator.changeset(attrs)
    |> Repo.update()
  end

  def delete_commission_operator(%CommissionOperator{} = commission_operator) do
    Repo.delete(commission_operator)
  end

  def change_commission_operator(%CommissionOperator{} = commission_operator, attrs \\ %{}) do
    CommissionOperator.changeset(commission_operator, attrs)
  end

  def get_operators_for_commission(commission_id) do
    import Ecto.Query

    query = from co in CommissionOperator,
      where: co.commission_id == ^commission_id,
      join: u in assoc(co, :user),
      select: u

    Repo.all(query)
  end

  def list_commissions_by_supervisor(supervisor_id) do
    import Ecto.Query

    query = from c in Commission,
      where: c.encargado_id == ^supervisor_id

    Repo.all(query)
  end

  def count_operators_in_commission(commission_id) do
    import Ecto.Query

    query = from co in CommissionOperator,
      where: co.commission_id == ^commission_id

    Repo.aggregate(query, :count, :id)
  end
end