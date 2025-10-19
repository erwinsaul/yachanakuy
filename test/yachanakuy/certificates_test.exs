defmodule Yachanakuy.CertificatesTest do
  use Yachanakuy.DataCase

  alias Yachanakuy.Certificates
  alias Yachanakuy.Registration

  import Yachanakuy.CertificatesFixtures
  import Yachanakuy.RegistrationFixtures
  import Yachanakuy.AccountsFixtures

  describe "certificates" do
    alias Yachanakuy.Certificates.Certificate

    @valid_attrs %{
      porcentaje_asistencia: Decimal.new("85.50"),
      sesiones_asistidas: 8,
      total_sesiones: 10,
      fecha_generacion: ~U[2023-12-01 10:00:00Z]
    }
    @update_attrs %{
      porcentaje_asistencia: Decimal.new("90.00"),
      sesiones_asistidas: 9
    }
    @invalid_attrs %{
      porcentaje_asistencia: nil,
      sesiones_asistidas: nil
    }

    def certificate_fixture(attrs \\ %{}) do
      attendee = approved_attendee_fixture(%{sesiones_asistidas: 8})
      attrs = Map.merge(@valid_attrs, attrs)
      attrs = Map.put(attrs, :attendee_id, attendee.id)
      
      {:ok, certificate} = Certificates.create_certificate(attrs)
      certificate
    end

    test "list_certificates/0 returns all certificates" do
      certificate = certificate_fixture()
      assert Certificates.list_certificates() == [certificate]
    end

    test "get_certificate!/1 returns the certificate with given id" do
      certificate = certificate_fixture()
      assert Certificates.get_certificate!(certificate.id) == certificate
    end

    test "create_certificate/1 with valid data creates a certificate" do
      attendee = approved_attendee_fixture(%{sesiones_asistidas: 8})
      attrs = Map.merge(@valid_attrs, %{attendee_id: attendee.id})
      
      assert {:ok, %Certificate{} = certificate} = Certificates.create_certificate(attrs)
      assert certificate.porcentaje_asistencia == Decimal.new("85.50")
      assert certificate.sesiones_asistidas == 8
      assert certificate.total_sesiones == 10
      assert certificate.codigo_verificacion != nil
      assert certificate.archivo_pdf != nil
    end

    test "create_certificate/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Certificates.create_certificate(@invalid_attrs)
    end

    test "certificate code must be unique" do
      certificate1 = certificate_fixture()
      attendee = approved_attendee_fixture(%{sesiones_asistidas: 8})
      attrs_with_duplicate_code = Map.merge(@valid_attrs, %{
        attendee_id: attendee.id,
        codigo_verificacion: certificate1.codigo_verificacion
      })
      
      assert {:error, %Ecto.Changeset{}} = Certificates.create_certificate(attrs_with_duplicate_code)
    end

    test "update_certificate/2 with valid data updates the certificate" do
      certificate = certificate_fixture()
      assert {:ok, %Certificate{} = certificate} = Certificates.update_certificate(certificate, @update_attrs)
      assert certificate.porcentaje_asistencia == Decimal.new("90.00")
      assert certificate.sesiones_asistidas == 9
    end

    test "update_certificate/2 with invalid data returns error changeset" do
      certificate = certificate_fixture()
      assert {:error, %Ecto.Changeset{}} = Certificates.update_certificate(certificate, @invalid_attrs)
      assert certificate == Certificates.get_certificate!(certificate.id)
    end

    test "delete_certificate/1 deletes the certificate" do
      certificate = certificate_fixture()
      assert {:ok, %Certificate{}} = Certificates.delete_certificate(certificate)
      assert_raise Ecto.NoResultsError, fn -> Certificates.get_certificate!(certificate.id) end
    end

    test "change_certificate/1 returns a certificate changeset" do
      certificate = certificate_fixture()
      assert %Ecto.Changeset{} = Certificates.change_certificate(certificate)
    end
  end

  describe "certificate generation" do
    alias Yachanakuy.Certificates.Certificate

    test "generate_certificate_for_attendee/2 creates a certificate for approved attendee" do
      attendee = approved_attendee_fixture(%{sesiones_asistidas: 7})
      
      assert {:ok, %Certificate{} = certificate} = 
             Certificates.generate_certificate_for_attendee(attendee.id)
      
      assert certificate.attendee_id == attendee.id
      assert certificate.porcentaje_asistencia == Decimal.new("70.00")
      assert certificate.sesiones_asistidas == 7
      assert certificate.total_sesiones == 10
      assert certificate.codigo_verificacion != nil
      assert certificate.archivo_pdf != nil
    end

    test "cannot generate certificate for non-approved attendee" do
      attendee = attendee_fixture(%{estado: "pendiente_revision", sesiones_asistidas: 5})
      
      assert {:error, "Solo se pueden generar certificados para participantes aprobados"} = 
             Certificates.generate_certificate_for_attendee(attendee.id)
    end

    test "cannot generate certificate for attendee with zero sessions" do
      attendee = approved_attendee_fixture(%{sesiones_asistidas: 0})
      
      assert {:ok, %Certificate{} = certificate} = 
             Certificates.generate_certificate_for_attendee(attendee.id)
      
      assert certificate.porcentaje_asistencia == Decimal.new("0.00")
    end

    test "attendee can only have one certificate" do
      attendee = approved_attendee_fixture(%{sesiones_asistidas: 6})
      
      # Generate first certificate
      assert {:ok, %Certificate{}} = 
             Certificates.generate_certificate_for_attendee(attendee.id)
      
      # Try to generate second certificate
      assert {:error, "El participante ya tiene un certificado generado"} = 
             Certificates.generate_certificate_for_attendee(attendee.id)
    end
  end

  describe "certificate verification" do
    alias Yachanakuy.Certificates.Certificate

    test "verify_certificate_code/1 returns certificate info for valid code" do
      certificate = certificate_fixture()
      
      assert {:ok, %{certificate: verified_certificate, attendee: _attendee, settings: _settings}} = 
             Certificates.verify_certificate_code(certificate.codigo_verificacion)
      
      assert verified_certificate.id == certificate.id
    end

    test "verify_certificate_code/1 returns error for invalid code" do
      assert {:error, "Código de verificación no válido"} = 
             Certificates.verify_certificate_code("INVALID_CODE")
    end
  end
end