defmodule Yachanakuy.EventsTest do
  use Yachanakuy.DataCase

  alias Yachanakuy.Events

  import Yachanakuy.EventsFixtures
  import Yachanakuy.AccountsFixtures

  describe "settings" do
    alias Yachanakuy.Events.Settings

    @valid_attrs %{
      nombre: "Congreso Internacional de Tecnología 2025",
      descripcion: "Un congreso para compartir conocimientos sobre las últimas tecnologías",
      fecha_inicio: ~D[2025-06-15],
      fecha_fin: ~D[2025-06-17],
      ubicacion: "La Paz, Bolivia",
      direccion_evento: "Campus Universitario - Universidad Mayor de San Andrés",
      logo: "/images/congreso-logo.png",
      estado: "publicado",
      inscripciones_abiertas: true,
      info_turismo: "La Paz es una ciudad multicultural con una rica historia."
    }
    @update_attrs %{
      nombre: "Congreso Internacional de Tecnología 2026",
      estado: "borrador",
      inscripciones_abiertas: false
    }
    @invalid_attrs %{
      nombre: nil,
      estado: "invalid_estado"
    }

    test "create_settings/1 with valid data creates a settings" do
      assert {:ok, %Settings{} = settings} = Events.create_settings(@valid_attrs)
      assert settings.nombre == "Congreso Internacional de Tecnología 2025"
      assert settings.descripcion == "Un congreso para compartir conocimientos sobre las últimas tecnologías"
      assert settings.fecha_inicio == ~D[2025-06-15]
      assert settings.fecha_fin == ~D[2025-06-17]
      assert settings.ubicacion == "La Paz, Bolivia"
      assert settings.direccion_evento == "Campus Universitario - Universidad Mayor de San Andrés"
      assert settings.logo == "/images/congreso-logo.png"
      assert settings.estado == "publicado"
      assert settings.inscripciones_abiertas == true
      assert settings.info_turismo == "La Paz es una ciudad multicultural con una rica historia."
    end

    test "create_settings/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Events.create_settings(@invalid_attrs)
    end

    test "create_settings/1 fails when settings already exist" do
      settings_fixture()
      
      assert {:error, :singleton_exists} = Events.create_settings(@valid_attrs)
    end

    test "update_settings/2 with valid data updates the settings" do
      settings = settings_fixture()
      assert {:ok, %Settings{} = settings} = Events.update_settings(settings, @update_attrs)
      assert settings.nombre == "Congreso Internacional de Tecnología 2026"
      assert settings.estado == "borrador"
      assert settings.inscripciones_abiertas == false
    end

    test "update_settings/2 with invalid data returns error changeset" do
      settings = settings_fixture()
      assert {:error, %Ecto.Changeset{}} = Events.update_settings(settings, @invalid_attrs)
      assert settings == Events.get_congress_settings!()
    end

    test "delete_settings/1 deletes the settings" do
      settings = settings_fixture()
      assert {:ok, %Settings{}} = Events.delete_settings(settings)
      assert is_nil(Events.get_congress_settings())
    end

    test "get_congress_settings/0 returns the settings" do
      settings = settings_fixture()
      assert Events.get_congress_settings() == settings
    end

    test "get_congress_settings!/0 returns the settings" do
      settings = settings_fixture()
      assert Events.get_congress_settings!() == settings
    end

    test "get_congress_settings/0 returns nil when no settings exist" do
      assert is_nil(Events.get_congress_settings())
    end
  end

  describe "attendee_categories" do
    alias Yachanakuy.Events.AttendeeCategory

    @valid_attrs %{
      nombre: "Estudiante",
      codigo: "EST",
      precio: Decimal.new("50.00"),
      color: "#3b82f6"
    }
    @update_attrs %{
      nombre: "Profesional",
      codigo: "PROF",
      precio: Decimal.new("100.00"),
      color: "#10b981"
    }
    @invalid_attrs %{
      nombre: nil,
      codigo: nil,
      precio: nil
    }

    test "list_attendee_categories/0 returns all attendee categories" do
      attendee_category = attendee_category_fixture()
      assert Events.list_attendee_categories() == [attendee_category]
    end

    test "get_attendee_category!/1 returns the attendee category with given id" do
      attendee_category = attendee_category_fixture()
      assert Events.get_attendee_category!(attendee_category.id) == attendee_category
    end

    test "create_attendee_category/1 with valid data creates a attendee category" do
      assert {:ok, %AttendeeCategory{} = attendee_category} = Events.create_attendee_category(@valid_attrs)
      assert attendee_category.nombre == "Estudiante"
      assert attendee_category.codigo == "EST"
      assert attendee_category.precio == Decimal.new("50.00")
      assert attendee_category.color == "#3b82f6"
    end

    test "create_attendee_category/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Events.create_attendee_category(@invalid_attrs)
    end

    test "attendee category codigo must be unique" do
      attendee_category = attendee_category_fixture()
      attrs_with_duplicate_codigo = Map.put(@valid_attrs, :codigo, attendee_category.codigo)
      assert {:error, %Ecto.Changeset{}} = Events.create_attendee_category(attrs_with_duplicate_codigo)
    end

    test "update_attendee_category/2 with valid data updates the attendee category" do
      attendee_category = attendee_category_fixture()
      assert {:ok, %AttendeeCategory{} = attendee_category} = Events.update_attendee_category(attendee_category, @update_attrs)
      assert attendee_category.nombre == "Profesional"
      assert attendee_category.codigo == "PROF"
      assert attendee_category.precio == Decimal.new("100.00")
      assert attendee_category.color == "#10b981"
    end

    test "update_attendee_category/2 with invalid data returns error changeset" do
      attendee_category = attendee_category_fixture()
      assert {:error, %Ecto.Changeset{}} = Events.update_attendee_category(attendee_category, @invalid_attrs)
      assert attendee_category == Events.get_attendee_category!(attendee_category.id)
    end

    test "delete_attendee_category/1 deletes the attendee category" do
      attendee_category = attendee_category_fixture()
      assert {:ok, %AttendeeCategory{}} = Events.delete_attendee_category(attendee_category)
      assert_raise Ecto.NoResultsError, fn -> Events.get_attendee_category!(attendee_category.id) end
    end

    test "attendee category precio must be greater than 0" do
      attrs = Map.put(@valid_attrs, :precio, Decimal.new("-10.00"))
      assert {:error, %Ecto.Changeset{}} = Events.create_attendee_category(attrs)
      
      attrs_zero = Map.put(@valid_attrs, :precio, Decimal.new("0.00"))
      assert {:error, %Ecto.Changeset{}} = Events.create_attendee_category(attrs_zero)
    end
  end

  describe "settings_validation" do
    test "settings estado must be one of valid values" do
      valid_states = ["borrador", "publicado", "activo", "finalizado"]
      
      Enum.each(valid_states, fn state ->
        attrs = %{nombre: "Test", estado: state}
        assert {:ok, %Settings{}} = Events.create_settings(attrs)
        Events.delete_settings(Events.get_congress_settings!())
      end)
      
      invalid_state_attrs = %{nombre: "Test", estado: "invalid"}
      assert {:error, %Ecto.Changeset{}} = Events.create_settings(invalid_state_attrs)
    end

    test "settings inscripciones_abiertas defaults to false" do
      attrs = Map.delete(@valid_attrs, :inscripciones_abiertas)
      assert {:ok, %Settings{} = settings} = Events.create_settings(attrs)
      assert settings.inscripciones_abiertas == false
    end

    test "settings cannot have fecha_fin before fecha_inicio" do
      attrs = Map.merge(@valid_attrs, %{
        fecha_inicio: ~D[2025-06-17],
        fecha_fin: ~D[2025-06-15]
      })
      assert {:error, %Ecto.Changeset{}} = Events.create_settings(attrs)
    end
  end
end