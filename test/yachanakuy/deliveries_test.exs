defmodule Yachanakuy.DeliveriesTest do
  use Yachanakuy.DataCase

  alias Yachanakuy.Deliveries
  alias Yachanakuy.Registration

  import Yachanakuy.DeliveriesFixtures
  import Yachanakuy.RegistrationFixtures
  import Yachanakuy.AccountsFixtures

  describe "meal_deliveries" do
    alias Yachanakuy.Deliveries.MealDelivery

    test "register_meal_delivery/3 creates a meal delivery" do
      attendee = approved_attendee_fixture()
      meal = meal_fixture()
      user = user_fixture()
      
      assert {:ok, %MealDelivery{} = meal_delivery} = 
             Deliveries.register_meal_delivery(attendee.id, meal.id, user)
      
      assert meal_delivery.attendee_id == attendee.id
      assert meal_delivery.meal_id == meal.id
      assert meal_delivery.entregado_por == user.id
      assert meal_delivery.fecha_entrega != nil
    end

    test "cannot register meal delivery for non-approved attendee" do
      attendee = attendee_fixture(%{estado: "pendiente_revision"})
      meal = meal_fixture()
      user = user_fixture()
      
      assert {:error, "Solo se pueden entregar refrigerios a participantes aprobados"} = 
             Deliveries.register_meal_delivery(attendee.id, meal.id, user)
    end

    test "cannot register the same meal twice to same attendee" do
      attendee = approved_attendee_fixture()
      meal = meal_fixture()
      user = user_fixture()
      
      # Register first delivery
      assert {:ok, %MealDelivery{}} = 
             Deliveries.register_meal_delivery(attendee.id, meal.id, user)
      
      # Try to register the same delivery again
      assert {:error, "El participante ya recibió este refrigerio"} = 
             Deliveries.register_meal_delivery(attendee.id, meal.id, user)
    end
  end

  describe "session_attendances" do
    alias Yachanakuy.Deliveries.SessionAttendance

    test "register_session_attendance/3 creates a session attendance" do
      attendee = approved_attendee_fixture()
      session = session_fixture()
      user = user_fixture()
      
      assert {:ok, %SessionAttendance{} = session_attendance} = 
             Deliveries.register_session_attendance(attendee.id, session.id, user)
      
      assert session_attendance.attendee_id == attendee.id
      assert session_attendance.session_id == session.id
      assert session_attendance.escaneado_por == user.id
      assert session_attendance.fecha_escaneo != nil
    end

    test "cannot register session attendance for non-approved attendee" do
      attendee = attendee_fixture(%{estado: "pendiente_revision"})
      session = session_fixture()
      user = user_fixture()
      
      assert {:error, "Solo pueden registrar asistencia participantes aprobados"} = 
             Deliveries.register_session_attendance(attendee.id, session.id, user)
    end

    test "cannot register the same session attendance twice" do
      attendee = approved_attendee_fixture()
      session = session_fixture()
      user = user_fixture()
      
      # Register first attendance
      assert {:ok, %SessionAttendance{}} = 
             Deliveries.register_session_attendance(attendee.id, session.id, user)
      
      # Try to register the same attendance again
      assert {:error, "El participante ya registró asistencia a esta sesión"} = 
             Deliveries.register_session_attendance(attendee.id, session.id, user)
    end
  end

  describe "credential and material delivery" do
    alias Yachanakuy.Registration.Attendee

    test "deliver_credential/2 delivers credential to approved attendee" do
      attendee = approved_attendee_fixture()
      user = user_fixture()
      
      assert {:ok, %Attendee{} = updated_attendee} = 
             Deliveries.deliver_credential(attendee, user)
      
      assert updated_attendee.credencial_entregada == true
      assert updated_attendee.fecha_entrega_credencial != nil
      assert updated_attendee.quien_entrego_credencial == user.id
    end

    test "deliver_material/2 delivers material to approved attendee" do
      attendee = approved_attendee_fixture()
      user = user_fixture()
      
      assert {:ok, %Attendee{} = updated_attendee} = 
             Deliveries.deliver_material(attendee, user)
      
      assert updated_attendee.material_entregado == true
      assert updated_attendee.fecha_entrega_material != nil
      assert updated_attendee.quien_entrego_material == user.id
    end

    test "cannot deliver credential to non-approved attendee" do
      attendee = attendee_fixture(%{estado: "pendiente_revision"})
      user = user_fixture()
      
      assert {:error, "No se puede entregar credencial a un participante no aprobado"} = 
             Deliveries.deliver_credential(attendee, user)
    end

    test "cannot deliver material to non-approved attendee" do
      attendee = attendee_fixture(%{estado: "pendiente_revision"})
      user = user_fixture()
      
      assert {:error, "No se puede entregar material a un participante no aprobado"} = 
             Deliveries.deliver_material(attendee, user)
    end

    test "cannot deliver credential twice to same attendee" do
      attendee = attendee_fixture(%{estado: "aprobado", credencial_entregada: true})
      user = user_fixture()
      
      assert {:error, "La credencial ya fue entregada a este participante"} = 
             Deliveries.deliver_credential(attendee, user)
    end

    test "cannot deliver material twice to same attendee" do
      attendee = attendee_fixture(%{estado: "aprobado", material_entregado: true})
      user = user_fixture()
      
      assert {:error, "El material ya fue entregado a este participante"} = 
             Deliveries.deliver_material(attendee, user)
    end
  end
end