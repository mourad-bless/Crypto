-- daomeme : à coller dans Supabase > SQL Editor > Run
create table public.profiles (
  user_id uuid primary key references auth.users on delete cascade,
  name text not null check (char_length(name) between 1 and 30),
  handle text not null check (handle ~ '^[a-z0-9_]{1,20}$'),
  bio text not null default '' check (char_length(bio) <= 140),
  emoji text not null default '🐸' check (char_length(emoji) <= 8),
  color text not null default '#FFD23F' check (color in ('#FFD23F','#FF5C8A','#3DDC97','#5CC8FF','#9B7BFF')),
  created_at timestamptz not null default now()
);
create unique index profiles_handle_key on public.profiles (handle);

create table public.coins (
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  id text not null check (id ~ '^[a-z0-9]{1,20}$'),
  name text not null check (char_length(name) between 1 and 30),
  ticker text not null check (ticker ~ '^[A-Z0-9]{2,8}$'),
  chain text not null check (chain in ('Solana','Ethereum','Base','BNB Chain')),
  address text not null check (
    (chain = 'Solana' and address ~ '^[1-9A-HJ-NP-Za-km-z]{32,44}$') or
    (chain <> 'Solana' and address ~ '^0x[a-fA-F0-9]{40}$')),
  description text not null default '' check (char_length(description) <= 100),
  logo text not null default '🪙' check (char_length(logo) <= 8),
  created_at timestamptz not null default now(),
  primary key (user_id, id)
);

create function public.limit_coins() returns trigger language plpgsql as $$
begin
  if not exists (select 1 from public.coins where user_id = new.user_id and id = new.id)
     and (select count(*) from public.coins where user_id = new.user_id) >= 10 then
    raise exception 'Maximum 10 memecoins par profil';
  end if;
  return new;
end $$;
create trigger coins_limit before insert on public.coins for each row execute function public.limit_coins();

alter table public.profiles enable row level security;
alter table public.coins enable row level security;
create policy "profils lisibles par tous" on public.profiles for select using (true);
create policy "coins lisibles par tous" on public.coins for select using (true);
create policy "profil: créer le sien" on public.profiles for insert to authenticated with check (auth.uid() = user_id);
create policy "profil: modifier le sien" on public.profiles for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "profil: supprimer le sien" on public.profiles for delete to authenticated using (auth.uid() = user_id);
create policy "coin: créer le sien" on public.coins for insert to authenticated with check (auth.uid() = user_id);
create policy "coin: modifier le sien" on public.coins for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "coin: supprimer le sien" on public.coins for delete to authenticated using (auth.uid() = user_id);
