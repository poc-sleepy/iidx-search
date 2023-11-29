SET check_function_bodies = false;
CREATE FUNCTION public.set_current_timestamp_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  _new record;
BEGIN
  _new := NEW;
  _new."updated_at" = NOW();
  RETURN _new;
END;
$$;
CREATE TABLE public.tracks (
    id text NOT NULL,
    song_id text NOT NULL,
    play_style text NOT NULL,
    track_type text NOT NULL,
    level smallint,
    notes smallint DEFAULT '0'::smallint,
    min_bpm smallint,
    max_bpm smallint,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    CONSTRAINT bpm CHECK (((min_bpm > 0) AND (max_bpm > 0) AND (max_bpm >= min_bpm))),
    CONSTRAINT level CHECK (((level > 0) AND (level <= 12))),
    CONSTRAINT notes CHECK ((notes >= 0))
);
COMMENT ON TABLE public.tracks IS '譜面';
CREATE FUNCTION public.track_is_soflan(track_row public.tracks) RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
  SELECT track_row.min_bpm != track_row.max_bpm
$$;
CREATE FUNCTION public.track_multiple_notes(track_row public.tracks, multiplier real) RETURNS real
    LANGUAGE sql STABLE
    AS $$
  SELECT track_row.notes * multiplier
$$;
CREATE FUNCTION public.track_score_a(track_row public.tracks) RETURNS integer
    LANGUAGE sql STABLE
    AS $$
  SELECT CEIL(track_multiple_notes(track_row, 2*6/9.0))
$$;
CREATE FUNCTION public.track_score_aa(track_row public.tracks) RETURNS integer
    LANGUAGE sql STABLE
    AS $$
  SELECT CEIL(track_multiple_notes(track_row, 2*7/9.0))
$$;
CREATE FUNCTION public.track_score_aaa(track_row public.tracks) RETURNS integer
    LANGUAGE sql STABLE
    AS $$
  SELECT CEIL(track_multiple_notes(track_row, 2*8/9.0))
$$;
CREATE FUNCTION public.track_score_b(track_row public.tracks) RETURNS integer
    LANGUAGE sql STABLE
    AS $$
  SELECT CEIL(track_multiple_notes(track_row, 2*5/9.0))
$$;
CREATE FUNCTION public.track_score_c(track_row public.tracks) RETURNS integer
    LANGUAGE sql STABLE
    AS $$
  SELECT CEIL(track_multiple_notes(track_row, 2*4/9.0))
$$;
CREATE FUNCTION public.track_score_d(track_row public.tracks) RETURNS integer
    LANGUAGE sql STABLE
    AS $$
  SELECT CEIL(track_multiple_notes(track_row, 2*3/9.0))
$$;
CREATE FUNCTION public.track_score_e(track_row public.tracks) RETURNS integer
    LANGUAGE sql STABLE
    AS $$
  SELECT CEIL(track_multiple_notes(track_row, 2*2/9.0))
$$;
CREATE FUNCTION public.track_score_max(track_row public.tracks) RETURNS integer
    LANGUAGE sql STABLE
    AS $$
  SELECT track_multiple_notes(track_row, 2)
$$;
CREATE TABLE public.play_styles (
    value text NOT NULL,
    comment text
);
COMMENT ON TABLE public.play_styles IS 'SPかDPか。ENUM用。';
CREATE TABLE public.songs (
    id text NOT NULL,
    title text NOT NULL,
    genre text,
    artist text,
    version_id text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    is_active boolean DEFAULT true NOT NULL
);
COMMENT ON TABLE public.songs IS '楽曲';
CREATE TABLE public.track_types (
    value text NOT NULL,
    comment text
);
COMMENT ON TABLE public.track_types IS '譜面タイプ。ENUM用。';
CREATE TABLE public.versions (
    id text NOT NULL,
    name text NOT NULL,
    short_name text NOT NULL,
    display_order smallint NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
COMMENT ON TABLE public.versions IS 'IIDXのバージョン';
ALTER TABLE ONLY public.play_styles
    ADD CONSTRAINT play_styles_pkey PRIMARY KEY (value);
ALTER TABLE ONLY public.songs
    ADD CONSTRAINT songs_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.songs
    ADD CONSTRAINT songs_title_key UNIQUE (title);
ALTER TABLE ONLY public.track_types
    ADD CONSTRAINT track_types_pkey PRIMARY KEY (value);
ALTER TABLE ONLY public.tracks
    ADD CONSTRAINT tracks_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.tracks
    ADD CONSTRAINT tracks_song_id_play_style_track_type_key UNIQUE (song_id, play_style, track_type);
ALTER TABLE ONLY public.versions
    ADD CONSTRAINT version_display_order_key UNIQUE (display_order);
ALTER TABLE ONLY public.versions
    ADD CONSTRAINT version_name_key UNIQUE (name);
ALTER TABLE ONLY public.versions
    ADD CONSTRAINT version_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.versions
    ADD CONSTRAINT version_short_name_key UNIQUE (short_name);
CREATE TRIGGER set_public_play_styles_updated_at BEFORE UPDATE ON public.play_styles FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();
COMMENT ON TRIGGER set_public_play_styles_updated_at ON public.play_styles IS 'trigger to set value of column "updated_at" to current timestamp on row update';
CREATE TRIGGER set_public_songs_updated_at BEFORE UPDATE ON public.songs FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();
COMMENT ON TRIGGER set_public_songs_updated_at ON public.songs IS 'trigger to set value of column "updated_at" to current timestamp on row update';
CREATE TRIGGER set_public_tracks_updated_at BEFORE UPDATE ON public.tracks FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();
COMMENT ON TRIGGER set_public_tracks_updated_at ON public.tracks IS 'trigger to set value of column "updated_at" to current timestamp on row update';
CREATE TRIGGER set_public_version_updated_at BEFORE UPDATE ON public.versions FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();
COMMENT ON TRIGGER set_public_version_updated_at ON public.versions IS 'trigger to set value of column "updated_at" to current timestamp on row update';
ALTER TABLE ONLY public.songs
    ADD CONSTRAINT songs_version_id_fkey FOREIGN KEY (version_id) REFERENCES public.versions(id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE ONLY public.tracks
    ADD CONSTRAINT tracks_play_style_fkey FOREIGN KEY (play_style) REFERENCES public.play_styles(value) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE ONLY public.tracks
    ADD CONSTRAINT tracks_song_id_fkey FOREIGN KEY (song_id) REFERENCES public.songs(id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE ONLY public.tracks
    ADD CONSTRAINT tracks_track_type_fkey FOREIGN KEY (track_type) REFERENCES public.track_types(value) ON UPDATE CASCADE ON DELETE RESTRICT;
