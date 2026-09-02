-- SisGESC Enterprise — migration starter para Supabase/PostgreSQL
-- Revise nomes, tipos, tenant_id e regras com o schema acadêmico existente antes de aplicar.
-- Nunca desative RLS em produção.

create extension if not exists pgcrypto;

create table if not exists public.leads (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  nome text not null,
  email text,
  telefone text,
  curso_interesse text,
  origem text not null default 'outro',
  etapa text not null default 'novo_lead' check (etapa in ('novo_lead','contato_realizado','proposta_enviada','matricula')),
  score smallint not null default 0 check (score between 0 and 100),
  owner_id uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.library_items (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  tombo text not null,
  titulo text not null,
  autor text,
  categoria text,
  formato text not null default 'fisico' check (formato in ('fisico','digital')),
  exemplares integer not null default 1 check (exemplares >= 0),
  created_at timestamptz not null default now(),
  unique (tenant_id, tombo)
);

create table if not exists public.library_loans (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  item_id uuid not null references public.library_items(id),
  borrower_id uuid not null references auth.users(id),
  borrowed_at date not null default current_date,
  due_at date not null,
  returned_at date,
  created_at timestamptz not null default now()
);

create table if not exists public.assets (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  patrimonio text not null,
  item text not null,
  categoria text not null,
  localizacao text,
  responsavel_id uuid references auth.users(id),
  valor numeric(14,2) not null default 0 check (valor >= 0),
  status text not null default 'em_uso' check (status in ('em_uso','em_manutencao','estoque_baixo','baixado')),
  created_at timestamptz not null default now(),
  unique (tenant_id, patrimonio)
);

create table if not exists public.roles (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  nome text not null check (nome in ('Administrador','Professor','Secretaria','Aluno')),
  unique (tenant_id, nome)
);

create table if not exists public.permissions (
  id uuid primary key default gen_random_uuid(),
  codigo text unique not null,
  descricao text not null
);

create table if not exists public.role_permissions (
  role_id uuid not null references public.roles(id) on delete cascade,
  permission_id uuid not null references public.permissions(id) on delete cascade,
  primary key (role_id, permission_id)
);

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  tenant_id uuid not null,
  role_id uuid references public.roles(id),
  nome text,
  status text not null default 'Pendente' check (status in ('Ativo','Pendente','Bloqueado')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.audit_logs (
  id bigint generated always as identity primary key,
  tenant_id uuid not null,
  actor_id uuid references auth.users(id),
  action text not null,
  resource text not null,
  resource_id text,
  ip inet,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists leads_tenant_stage_idx on public.leads (tenant_id, etapa, updated_at desc);
create index if not exists library_loans_tenant_due_idx on public.library_loans (tenant_id, due_at) where returned_at is null;
create index if not exists assets_tenant_status_idx on public.assets (tenant_id, status);
create index if not exists audit_logs_tenant_created_idx on public.audit_logs (tenant_id, created_at desc);

alter table public.leads enable row level security;
alter table public.library_items enable row level security;
alter table public.library_loans enable row level security;
alter table public.assets enable row level security;
alter table public.roles enable row level security;
alter table public.permissions enable row level security;
alter table public.role_permissions enable row level security;
alter table public.profiles enable row level security;
alter table public.audit_logs enable row level security;

-- Helper: substitua pelo seu mecanismo final se o tenant não estiver em profiles.
create or replace function public.current_tenant_id()
returns uuid language sql stable security definer set search_path = public
as $$ select tenant_id from public.profiles where id = auth.uid() $$;

create policy "tenant read leads" on public.leads for select using (tenant_id = public.current_tenant_id());
create policy "tenant write leads" on public.leads for insert with check (tenant_id = public.current_tenant_id());
create policy "tenant update leads" on public.leads for update using (tenant_id = public.current_tenant_id()) with check (tenant_id = public.current_tenant_id());

create policy "tenant read library items" on public.library_items for select using (tenant_id = public.current_tenant_id());
create policy "tenant manage library items" on public.library_items for all using (tenant_id = public.current_tenant_id()) with check (tenant_id = public.current_tenant_id());
create policy "tenant read library loans" on public.library_loans for select using (tenant_id = public.current_tenant_id());
create policy "tenant manage library loans" on public.library_loans for all using (tenant_id = public.current_tenant_id()) with check (tenant_id = public.current_tenant_id());

create policy "tenant read assets" on public.assets for select using (tenant_id = public.current_tenant_id());
create policy "tenant manage assets" on public.assets for all using (tenant_id = public.current_tenant_id()) with check (tenant_id = public.current_tenant_id());

create policy "own profile read" on public.profiles for select using (id = auth.uid());
create policy "own profile update safe fields" on public.profiles for update using (id = auth.uid()) with check (id = auth.uid());
create policy "tenant read roles" on public.roles for select using (tenant_id = public.current_tenant_id());
create policy "tenant read audit logs" on public.audit_logs for select using (tenant_id = public.current_tenant_id());

-- Não permita INSERT direto de audit_logs pelo cliente em produção.
-- Registre auditoria via trigger ou Edge Function com actor_id derivado de auth.uid().
