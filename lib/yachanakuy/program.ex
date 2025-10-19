defmodule Yachanakuy.Program do
  @moduledoc """
  The Program context.
  """
  import Ecto.Query, warn: false
  alias Yachanakuy.Repo

  alias Yachanakuy.Program.Speaker
  alias Yachanakuy.Program.Room
  alias Yachanakuy.Program.Session

  def count_speakers do
    Repo.aggregate(Speaker, :count, :id)
  end

  def count_sessions do
    Repo.aggregate(Session, :count, :id)
  end
  
  def list_speakers_with_filters(filters \\ %{}) do
    search = Map.get(filters, :search, "")
    page = Map.get(filters, :page, 1)
    page_size = Map.get(filters, :page_size, 10)

    offset = (page - 1) * page_size

    query = from s in Speaker,
      where: ^build_speaker_search_filter(search),
      limit: ^page_size,
      offset: ^offset,
      order_by: [asc: s.nombre_completo]

    Repo.all(query)
  end

  def count_speakers_filtered(filters \\ %{}) do
    search = Map.get(filters, :search, "")

    query = from s in Speaker,
      where: ^build_speaker_search_filter(search)

    Repo.aggregate(query, :count, :id)
  end

  defp build_speaker_search_filter(""), do: true
  defp build_speaker_search_filter(search) when is_binary(search) do
    search_pattern = "%#{search}%"
    dynamic([s], ilike(s.nombre_completo, ^search_pattern) or 
                   ilike(s.institucion, ^search_pattern) or
                   ilike(s.biografia, ^search_pattern))
  end

  def get_speaker!(id) do
    Repo.get!(Speaker, id)
  end

  def create_speaker(attrs \\ %{}) do
    %Speaker{}
    |> Speaker.changeset(attrs)
    |> Repo.insert()
  end

  def update_speaker(%Speaker{} = speaker, attrs) do
    speaker
    |> Speaker.changeset(attrs)
    |> Repo.update()
  end

  def delete_speaker(%Speaker{} = speaker) do
    Repo.delete(speaker)
  end

  def change_speaker(%Speaker{} = speaker, attrs \\ %{}) do
    Speaker.changeset(speaker, attrs)
  end

  def list_rooms do
    Repo.all(Room)
  end

  def get_room!(id) do
    Repo.get!(Room, id)
  end

  def create_room(attrs \\ %{}) do
    %Room{}
    |> Room.changeset(attrs)
    |> Repo.insert()
  end

  def update_room(%Room{} = room, attrs) do
    room
    |> Room.changeset(attrs)
    |> Repo.update()
  end

  def delete_room(%Room{} = room) do
    Repo.delete(room)
  end

  def change_room(%Room{} = room, attrs \\ %{}) do
    Room.changeset(room, attrs)
  end

  def list_sessions do
    Repo.all(Session)
  end

  def list_sessions_with_details do
    from(s in Session,
      left_join: r in assoc(s, :room),
      left_join: sp in assoc(s, :speaker),
      preload: [room: r, speaker: sp]
    )
    |> Repo.all()
  end

  def get_session_with_details!(id) do
    from(s in Session,
      left_join: r in assoc(s, :room),
      left_join: sp in assoc(s, :speaker),
      where: s.id == ^id,
      preload: [room: r, speaker: sp]
    )
    |> Repo.one!()
  end

  def list_speakers_with_sessions do
    Repo.all(Speaker)
    |> Repo.preload([:sessions])
  end
  
  def list_sessions_with_filters(filters \\ %{}) do
    search = Map.get(filters, :search, "")
    page = Map.get(filters, :page, 1)
    page_size = Map.get(filters, :page_size, 10)

    offset = (page - 1) * page_size

    query = from s in Session,
      left_join: r in assoc(s, :room),
      left_join: sp in assoc(s, :speaker),
      where: ^build_session_search_filter(search),
      limit: ^page_size,
      offset: ^offset,
      order_by: [asc: s.fecha, asc: s.hora_inicio]

    Repo.all(query)
  end

  def count_sessions_filtered(filters \\ %{}) do
    search = Map.get(filters, :search, "")

    query = from s in Session,
      left_join: r in assoc(s, :room),
      left_join: sp in assoc(s, :speaker),
      where: ^build_session_search_filter(search)

    Repo.aggregate(query, :count, :id)
  end

  defp build_session_search_filter(""), do: true
  defp build_session_search_filter(search) when is_binary(search) do
    search_pattern = "%#{search}%"
    dynamic([s, r, sp], ilike(s.titulo, ^search_pattern) or 
                           ilike(s.descripcion, ^search_pattern) or
                           ilike(r.nombre, ^search_pattern) or
                           ilike(sp.nombre_completo, ^search_pattern))
  end

  def get_session!(id) do
    Repo.get!(Session, id)
  end

  def create_session(attrs \\ %{}) do
    %Session{}
    |> Session.changeset(attrs)
    |> Repo.insert()
  end

  def update_session(%Session{} = session, attrs) do
    session
    |> Session.changeset(attrs)
    |> Repo.update()
  end

  def delete_session(%Session{} = session) do
    Repo.delete(session)
  end

  def change_session(%Session{} = session, attrs \\ %{}) do
    Session.changeset(session, attrs)
  end
end