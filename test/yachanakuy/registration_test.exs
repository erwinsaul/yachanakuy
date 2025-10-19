defmodule Yachanakuy.RegistrationTest do
  use Yachanakuy.DataCase

  alias Yachanakuy.Registration
  alias Yachanakuy.Events

  import Yachanakuy.RegistrationFixtures
  import Yachanakuy.AccountsFixtures

  describe "attendees" do
    alias Yachanakuy.Registration.Attendee

    @valid_attrs %{
      nombre_completo: "Juan Pérez",
      numero_documento: "123456789",
      email: "juan.perez@example.com",
      telefono: "789456123",
      institucion: "Universidad Mayor de San Andrés",
      estado: "pendiente_revision"
    }
    @update_attrs %{
      nombre_completo: "María González",
      numero_documento: "987654321",
      email: "maria.gonzalez@example.com",
      telefono: "654987321",
      institucion: "Universidad Católica Boliviana"
    }
    @invalid_attrs %{
      nombre_completo: nil,
      numero_documento: nil,
      email: nil
    }

    def attendee_fixture(attrs \\ %{}) do
      {:ok, attendee} = Registration.create_attendee(Enum.into(attrs, @valid_attrs))
      attendee
    end

    test "list_attendees/0 returns all attendees" do
      attendee = attendee_fixture()
      assert Registration.list_attendees() == [attendee]
    end

    test "get_attendee!/1 returns the attendee with given id" do
      attendee = attendee_fixture()
      assert Registration.get_attendee!(attendee.id) == attendee
    end

    test "create_attendee/1 with valid data creates a attendee" do
      category = category_fixture()
      attrs = Map.put(@valid_attrs, :category_id, category.id)
      
      assert {:ok, %Attendee{} = attendee} = Registration.create_attendee(attrs)
      assert attendee.nombre_completo == "Juan Pérez"
      assert attendee.numero_documento == "123456789"
      assert attendee.email == "juan.perez@example.com"
      assert attendee.telefono == "789456123"
      assert attendee.institucion == "Universidad Mayor de San Andrés"
      assert attendee.estado == "pendiente_revision"
    end

    test "create_attendee/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Registration.create_attendee(@invalid_attrs)
    end

    test "update_attendee/2 with valid data updates the attendee" do
      attendee = attendee_fixture()
      assert {:ok, %Attendee{} = attendee} = Registration.update_attendee(attendee, @update_attrs)
      assert attendee.nombre_completo == "María González"
      assert attendee.numero_documento == "987654321"
      assert attendee.email == "maria.gonzalez@example.com"
      assert attendee.telefono == "654987321"
      assert attendee.institucion == "Universidad Católica Boliviana"
    end

    test "update_attendee/2 with invalid data returns error changeset" do
      attendee = attendee_fixture()
      assert {:error, %Ecto.Changeset{}} = Registration.update_attendee(attendee, @invalid_attrs)
      assert attendee == Registration.get_attendee!(attendee.id)
    end

    test "delete_attendee/1 deletes the attendee" do
      attendee = attendee_fixture()
      assert {:ok, %Attendee{}} = Registration.delete_attendee(attendee)
      assert_raise Ecto.NoResultsError, fn -> Registration.get_attendee!(attendee.id) end
    end

    test "change_attendee/1 returns a attendee changeset" do
      attendee = attendee_fixture()
      assert %Ecto.Changeset{} = Registration.change_attendee(attendee)
    end

    test "attendee email must be unique" do
      attendee1 = attendee_fixture()
      attrs_with_duplicate_email = Map.put(@valid_attrs, :email, attendee1.email)
      category = category_fixture()
      attrs_with_duplicate_email = Map.put(attrs_with_duplicate_email, :category_id, category.id)
      
      assert {:error, %Ecto.Changeset{}} = Registration.create_attendee(attrs_with_duplicate_email)
    end

    test "attendee numero_documento must be unique" do
      attendee1 = attendee_fixture()
      attrs_with_duplicate_doc = Map.put(@valid_attrs, :numero_documento, attendee1.numero_documento)
      category = category_fixture()
      attrs_with_duplicate_doc = Map.put(attrs_with_duplicate_doc, :category_id, category.id)
      
      assert {:error, %Ecto.Changeset{}} = Registration.create_attendee(attrs_with_duplicate_doc)
    end
  end

  describe "attendee approval" do
    alias Yachanakuy.Registration.Attendee

    test "approve_attendee/2 changes state from pending to approved" do
      attendee = attendee_fixture(%{estado: "pendiente_revision"})
      admin_user = user_fixture(%{rol: "admin"})
      
      assert {:ok, %Attendee{} = updated_attendee} = Registration.approve_attendee(attendee, admin_user)
      assert updated_attendee.estado == "aprobado"
      assert updated_attendee.revisado_por == admin_user.id
      assert updated_attendee.fecha_revision != nil
      assert updated_attendee.codigo_qr != nil
      assert updated_attendee.token_descarga != nil
      assert updated_attendee.credencial_digital != nil
    end

    test "approve_attendee/2 fails if attendee is not pending" do
      attendee = attendee_fixture(%{estado: "aprobado"})
      admin_user = user_fixture(%{rol: "admin"})
      
      assert {:error, "Solo se pueden aprobar inscripciones en estado pendiente de revisión"} = 
             Registration.approve_attendee(attendee, admin_user)
    end

    test "reject_attendee/3 changes state from pending to rejected" do
      attendee = attendee_fixture(%{estado: "pendiente_revision"})
      admin_user = user_fixture(%{rol: "admin"})
      reason = "Documentación incompleta"
      
      assert {:ok, %Attendee{} = updated_attendee} = Registration.reject_attendee(attendee, admin_user, reason)
      assert updated_attendee.estado == "rechazado"
      assert updated_attendee.revisado_por == admin_user.id
      assert updated_attendee.fecha_revision != nil
      assert updated_attendee.motivo_rechazo == reason
    end
  end

  describe "attendee delivery" do
    alias Yachanakuy.Registration.Attendee

    test "cannot deliver credential to pending attendee" do
      attendee = attendee_fixture(%{estado: "pendiente_revision"})
      admin_user = user_fixture(%{rol: "admin"})
      
      assert {:error, "No se puede entregar credencial a un participante no aprobado"} = 
             Registration.deliver_credential(attendee, admin_user)
    end

    test "can deliver credential to approved attendee" do
      attendee = attendee_fixture(%{estado: "aprobado"})
      admin_user = user_fixture(%{rol: "admin"})
      
      assert {:ok, %Attendee{} = updated_attendee} = Registration.deliver_credential(attendee, admin_user)
      assert updated_attendee.credencial_entregada == true
      assert updated_attendee.fecha_entrega_credencial != nil
      assert updated_attendee.quien_entrego_credencial == admin_user.id
    end

    test "cannot deliver credential twice to same attendee" do
      attendee = attendee_fixture(%{estado: "aprobado", credencial_entregada: true})
      admin_user = user_fixture(%{rol: "admin"})
      
      assert {:error, "La credencial ya fue entregada a este participante"} = 
             Registration.deliver_credential(attendee, admin_user)
    end
  end

  defp category_fixture(attrs \\ %{}) do
    {:ok, category} = Events.create_attendee_category(Enum.into(attrs, %{
      nombre: "Estudiante",
      codigo: "EST",
      precio: Decimal.new("50.00"),
      color: "#3b82f6"
    }))
    category
  end
end