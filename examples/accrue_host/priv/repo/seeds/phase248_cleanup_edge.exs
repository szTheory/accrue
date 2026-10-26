# The heldout browser lane owns these five deterministic edge rows. Keep this
# cleanup narrower than the ordinary host seed or the shared E2E seed.
alias Accrue.Billing.{Charge, Customer, Invoice, Subscription}
alias AccrueHost.{OrdinarySeedBoundary, Repo}
import Ecto.Query

unless System.get_env("PHASE248_PROOF_LANE") == "heldout" and
         System.get_env("ACCRUE_HOST_BROWSER_PORT") == "4102" and
         System.get_env("ACCRUE_HOST_E2E_DISABLE_SQL_SANDBOX") != "1" do
  raise "Phase 248 edge cleanup requires the heldout sandbox lane on port 4102"
end

[[database, role, server_address]] =
  Repo.query!("SELECT current_database(), current_user, host(inet_server_addr())").rows

unless OrdinarySeedBoundary.allowed?(Mix.env(), database, role, server_address, nil) do
  raise "Phase 248 edge cleanup requires the local disposable host test database"
end

expected = [
  {Customer, "cus_e2e_edge_1"},
  {Subscription, "sub_e2e_edge_at_risk"},
  {Subscription, "sub_e2e_edge_canceling"},
  {Charge, "ch_e2e_edge_jpy"},
  {Invoice, "in_e2e_edge_jpy"}
]

{:ok, :ok} =
  Repo.transaction(fn ->
    rows =
      Enum.map(expected, fn {schema, processor_id} ->
        matches = Repo.all(from row in schema, where: row.processor_id == ^processor_id)

        if length(matches) > 1,
          do: raise("Phase 248 edge cleanup found a duplicate #{processor_id}")

        row = List.first(matches)

        if row && row.processor != "fake" do
          raise "Phase 248 edge cleanup found a non-fixture processor for #{processor_id}"
        end

        {schema, processor_id, row}
      end)

    customer =
      rows
      |> Enum.find(fn {_schema, id, _row} -> id == "cus_e2e_edge_1" end)
      |> elem(2)

    if customer &&
         (customer.email != "edge-longname@example.test" or customer.owner_type != "User") do
      raise "Phase 248 edge cleanup found an unexpected edge customer"
    end

    for {_schema, processor_id, row} <- rows,
        processor_id != "cus_e2e_edge_1",
        row do
      unless customer && row.customer_id == customer.id do
        raise "Phase 248 edge cleanup found an unexpected owner for #{processor_id}"
      end
    end

    if customer do
      for {schema, ids} <- [
            {Subscription, ["sub_e2e_edge_at_risk", "sub_e2e_edge_canceling"]},
            {Charge, ["ch_e2e_edge_jpy"]},
            {Invoice, ["in_e2e_edge_jpy"]}
          ] do
        if Repo.exists?(
             from row in schema,
               where: row.customer_id == ^customer.id and row.processor_id not in ^ids
           ) do
          raise "Phase 248 edge cleanup found an unrelated customer child"
        end
      end
    end

    for {_schema, _processor_id, row} <- Enum.reverse(rows), row do
      Repo.delete!(row)
    end

    :ok
  end)
