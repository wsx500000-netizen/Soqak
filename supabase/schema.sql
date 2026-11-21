create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text not null,
  role text not null default 'buyer'
    check (role in ('buyer', 'supervisor', 'admin')),
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.listings (
  id text primary key,
  title text not null,
  category text not null,
  location text not null,
  price bigint not null check (price >= 0),
  image_url text not null default '',
  description text not null default '',
  is_featured boolean not null default false,
  created_by uuid not null references public.profiles (id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected')),
  created_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  title text not null,
  total bigint not null check (total >= 0),
  status text not null default 'قيد المراجعة',
  created_at timestamptz not null default now()
);

create index if not exists listings_status_featured_created_idx
  on public.listings (status, is_featured desc, created_at desc);
create index if not exists listings_created_by_created_idx
  on public.listings (created_by, created_at desc);
create index if not exists orders_user_created_idx
  on public.orders (user_id, created_at desc);

create or replace function public.create_profile_for_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, email)
  values (new.id, coalesce(new.email, ''));
  return new;
end;
$$;

drop trigger if exists create_profile_after_signup on auth.users;
create trigger create_profile_after_signup
  after insert on auth.users
  for each row execute function public.create_profile_for_new_user();

create or replace function public.has_staff_role()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles
    where id = (select auth.uid())
      and is_active
      and role in ('admin', 'supervisor')
  );
$$;

create or replace function public.is_active_user()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles
    where id = (select auth.uid())
      and is_active
  );
$$;

alter table public.profiles enable row level security;
alter table public.listings enable row level security;
alter table public.orders enable row level security;

grant select on public.profiles to authenticated;
grant select on public.listings to anon, authenticated;
grant insert, delete on public.listings to authenticated;
grant select, insert on public.orders to authenticated;

drop policy if exists "Users read own profile and staff read all" on public.profiles;
create policy "Users read own profile and staff read all"
  on public.profiles for select to authenticated
  using (id = (select auth.uid()) or (select public.has_staff_role()));

drop policy if exists "Staff update profiles" on public.profiles;
create policy "Staff update profiles"
  on public.profiles for update to authenticated
  using ((select public.has_staff_role()))
  with check ((select public.has_staff_role()));

drop policy if exists "Approved listings are public" on public.listings;
create policy "Approved listings are public"
  on public.listings for select to anon, authenticated
  using (
    status = 'approved'
    or created_by = (select auth.uid())
    or (select public.has_staff_role())
  );

drop policy if exists "Users submit pending listings" on public.listings;
create policy "Users submit pending listings"
  on public.listings for insert to authenticated
  with check (
    created_by = (select auth.uid())
    and status = 'pending'
    and (select public.is_active_user())
  );

drop policy if exists "Staff manage listings" on public.listings;
create policy "Staff manage listings"
  on public.listings for update to authenticated
  using ((select public.has_staff_role()))
  with check ((select public.has_staff_role()));

drop policy if exists "Staff delete listings" on public.listings;
create policy "Staff delete listings"
  on public.listings for delete to authenticated
  using ((select public.has_staff_role()));

drop policy if exists "Users read own orders and staff read all" on public.orders;
create policy "Users read own orders and staff read all"
  on public.orders for select to authenticated
  using (user_id = (select auth.uid()) or (select public.has_staff_role()));

drop policy if exists "Users create own orders" on public.orders;
create policy "Users create own orders"
  on public.orders for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and status = 'قيد المراجعة'
    and (select public.is_active_user())
  );

drop policy if exists "Staff update orders" on public.orders;
create policy "Staff update orders"
  on public.orders for update to authenticated
  using ((select public.has_staff_role()))
  with check ((select public.has_staff_role()));

create or replace function public.set_profile_active(
  target_user_id uuid,
  active boolean
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.has_staff_role() then
    raise exception 'Staff access required';
  end if;
  update public.profiles
  set is_active = active
  where id = target_user_id;
end;
$$;

create or replace function public.moderate_listing(
  target_listing_id text,
  target_status text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.has_staff_role() then
    raise exception 'Staff access required';
  end if;
  if target_status not in ('approved', 'rejected') then
    raise exception 'Invalid listing status';
  end if;
  update public.listings
  set status = target_status
  where id = target_listing_id;
end;
$$;

create or replace function public.set_order_status(
  target_order_id uuid,
  target_status text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.has_staff_role() then
    raise exception 'Staff access required';
  end if;
  if target_status not in (
    'قيد المراجعة',
    'قيد التوصيل',
    'تم التسليم',
    'ملغي'
  ) then
    raise exception 'Invalid order status';
  end if;
  update public.orders
  set status = target_status
  where id = target_order_id;
end;
$$;

revoke all on function public.set_profile_active(uuid, boolean) from public;
revoke all on function public.moderate_listing(text, text) from public;
revoke all on function public.set_order_status(uuid, text) from public;
grant execute on function public.set_profile_active(uuid, boolean) to authenticated;
grant execute on function public.moderate_listing(text, text) to authenticated;
grant execute on function public.set_order_status(uuid, text) to authenticated;

insert into storage.buckets (id, name, public)
values ('listing-images', 'listing-images', true)
on conflict (id) do nothing;

drop policy if exists "Authenticated users upload listing images"
  on storage.objects;
create policy "Authenticated users upload listing images"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'listing-images'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and (select public.is_active_user())
  );

drop policy if exists "Listing images are public" on storage.objects;
create policy "Listing images are public"
  on storage.objects for select to anon, authenticated
  using (bucket_id = 'listing-images');
