defmodule Yachanakuy.QR.GeneratorTest do
  use Yachanakuy.DataCase

  alias Yachanakuy.QR.Generator

  describe "attendee_qr_generation" do
    import Yachanakuy.RegistrationFixtures
    import Yachanakuy.AccountsFixtures

    test "generate_attendee_qr/2 creates a valid QR code" do
      attendee = attendee_fixture()
      
      assert {:ok, qr_svg_content} = Generator.generate_attendee_qr(attendee.id, %{
        nombre_completo: attendee.nombre_completo,
        numero_documento: attendee.numero_documento
      })
      
      # Verify it's valid SVG content
      assert qr_svg_content =~ "<svg"
      assert qr_svg_content =~ "</svg>"
      assert String.length(qr_svg_content) > 100
    end

    test "generate_qr/1 creates a valid QR code from text" do
      text = "https://yachanakuy.example.com/attendee/123"
      
      assert {:ok, qr_svg_content} = Generator.generate_qr(text)
      
      # Verify it's valid SVG content
      assert qr_svg_content =~ "<svg"
      assert qr_svg_content =~ "</svg>"
      assert String.length(qr_svg_content) > 100
    end

    test "validate_qr/1 validates correct QR data" do
      qr_data = %{
        attendee_id: 123,
        action: "credencial",
        event_type: "yachanakuy_event_verification",
        timestamp: System.system_time(:second)
      }
      
      assert {:ok, validated_data} = Generator.validate_qr(qr_data)
      assert validated_data == qr_data
    end

    test "validate_qr/1 rejects QR data without attendee_id" do
      qr_data = %{
        action: "credencial",
        event_type: "yachanakuy_event_verification",
        timestamp: System.system_time(:second)
      }
      
      assert {:error, "Falta el campo attendee_id en el código QR"} = Generator.validate_qr(qr_data)
    end

    test "validate_qr/1 rejects QR data with wrong event_type" do
      qr_data = %{
        attendee_id: 123,
        action: "credencial",
        event_type: "wrong_event_type",
        timestamp: System.system_time(:second)
      }
      
      assert {:error, "Tipo de evento no válido"} = Generator.validate_qr(qr_data)
    end

    test "validate_qr/1 rejects QR data with non-integer attendee_id" do
      qr_data = %{
        attendee_id: "abc123",
        action: "credencial",
        event_type: "yachanakuy_event_verification",
        timestamp: System.system_time(:second)
      }
      
      assert {:error, "attendee_id debe ser un número entero"} = Generator.validate_qr(qr_data)
    end
  end
end