-- ProdeApp: Setup completo de base de datos

-- Tabla de perfiles de usuario
create table if not exists profiles (
  id uuid references auth.users on delete cascade primary key,
  username text unique not null,
  credits integer default 900,
  created_at timestamp with time zone default now()
);

-- Tabla de partidos
create table if not exists matches (
  id serial primary key,
  league text not null,
  home_team text not null,
  away_team text not null,
  match_time timestamp with time zone not null,
  status text default 'upcoming', -- upcoming, live, finished
  result text, -- 'home', 'draw', 'away'
  created_at timestamp with time zone default now()
);

-- Tabla de apuestas
create table if not exists bets (
  id serial primary key,
  user_id uuid references profiles(id) on delete cascade,
  match_id integer references matches(id) on delete cascade,
  pick text not null, -- 'home', 'draw', 'away'
  credits_wagered integer default 300,
  status text default 'pending', -- pending, won, lost
  created_at timestamp with time zone default now(),
  unique(user_id, match_id)
);

-- Activar Row Level Security
alter table profiles enable row level security;
alter table matches enable row level security;
alter table bets enable row level security;

-- Políticas para profiles
create policy "Usuarios ven su propio perfil" on profiles for select using (auth.uid() = id);
create policy "Usuarios actualizan su propio perfil" on profiles for update using (auth.uid() = id);
create policy "Usuarios ven el ranking" on profiles for select using (true);

-- Políticas para matches (todos pueden ver)
create policy "Todos ven los partidos" on matches for select using (true);

-- Políticas para bets
create policy "Usuarios ven sus apuestas" on bets for select using (auth.uid() = user_id);
create policy "Usuarios crean apuestas" on bets for insert with check (auth.uid() = user_id);

-- Función para crear perfil automáticamente al registrarse
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, username)
  values (new.id, split_part(new.email, '@', 1));
  return new;
end;
$$ language plpgsql security definer;

-- Trigger para ejecutar la función al registrarse
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Partidos de ejemplo
insert into matches (league, home_team, away_team, match_time) values
('Liga Argentina', 'Boca Juniors', 'River Plate', now() + interval '2 hours'),
('Champions League', 'Real Madrid', 'Bayern Munich', now() + interval '3 hours'),
('Premier League', 'Arsenal', 'Man City', now() + interval '5 hours'),
('La Liga', 'Barcelona', 'Atlético Madrid', now() + interval '26 hours'),
('Serie A', 'Inter Milan', 'Juventus', now() + interval '27 hours'),
('Mundial 2026 - Grupo A', 'Argentina', 'Polonia', now() + interval '50 hours'),
('Mundial 2026 - Grupo A', 'Arabia Saudita', 'México', now() + interval '53 hours'),
('Mundial 2026 - Grupo B', 'Francia', 'Australia', now() + interval '56 hours'),
('Mundial 2026 - Grupo C', 'Brasil', 'Serbia', now() + interval '59 hours');
