-- =====================================================================
-- SisGESC — ERP Educacional
-- Schema PostgreSQL para Supabase
-- Rode este arquivo inteiro no SQL Editor do seu projeto Supabase
-- =====================================================================

-- ---------------------------------------------------------------------
-- EXTENSÕES
-- ---------------------------------------------------------------------
create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------
-- LIMPEZA (permite rodar o script de novo sem erro)
-- ---------------------------------------------------------------------
drop table if exists afastamentos cascade;
drop table if exists folha_pagamento cascade;
drop table if exists renegociacoes cascade;
drop table if exists pagamentos cascade;
drop table if exists mensalidades cascade;
drop table if exists notas cascade;
drop table if exists matriculas cascade;
drop table if exists turmas cascade;
drop table if exists disciplinas cascade;
drop table if exists funcionarios cascade;
drop table if exists cargos cascade;
drop table if exists departamentos cascade;
drop table if exists alunos cascade;
drop table if exists cursos cascade;
drop table if exists pessoas cascade;

-- ---------------------------------------------------------------------
-- NÚCLEO: PESSOAS
-- ---------------------------------------------------------------------
create table pessoas (
    id uuid primary key default gen_random_uuid(),
    nome varchar(100) not null,
    sobrenome varchar(150) not null,
    cpf varchar(14) unique not null,
    email varchar(150),
    telefone varchar(20),
    data_nascimento date,
    criado_em timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- ACADÊMICO
-- ---------------------------------------------------------------------
create table cursos (
    id uuid primary key default gen_random_uuid(),
    nome varchar(100) not null unique
);

create table alunos (
    id uuid primary key default gen_random_uuid(),
    pessoa_id uuid not null references pessoas(id) on delete cascade,
    ra varchar(20) unique not null,
    curso_id uuid references cursos(id),
    periodo smallint not null default 1,
    status varchar(20) not null default 'ativo'
        check (status in ('ativo','trancado','inativo')),
    criado_em timestamptz not null default now()
);

create table departamentos (
    id uuid primary key default gen_random_uuid(),
    nome varchar(100) not null unique
);

create table cargos (
    id uuid primary key default gen_random_uuid(),
    nome varchar(100) not null,
    departamento_id uuid references departamentos(id)
);

create table funcionarios (
    id uuid primary key default gen_random_uuid(),
    pessoa_id uuid not null references pessoas(id) on delete cascade,
    cargo_id uuid references cargos(id),
    departamento_id uuid references departamentos(id),
    data_admissao date not null default current_date,
    data_demissao date,
    salario numeric(10,2) not null default 0,
    regime varchar(20) not null default 'CLT'
        check (regime in ('CLT','PJ','Horista')),
    status varchar(20) not null default 'ativo'
        check (status in ('ativo','afastado','inativo')),
    criado_em timestamptz not null default now(),

    constraint chk_demissao
        check (status <> 'inativo' or data_demissao is not null)
);

create table disciplinas (
    id uuid primary key default gen_random_uuid(),
    nome varchar(150) not null
);

create table turmas (
    id uuid primary key default gen_random_uuid(),
    codigo varchar(20) unique not null,
    disciplina_id uuid references disciplinas(id),
    professor_id uuid references funcionarios(id),
    curso_id uuid references cursos(id),
    horario varchar(60),
    semestre varchar(10) not null default '2025/1',
    status varchar(20) not null default 'ativa'
        check (status in ('ativa','encerrada','cancelada'))
);

create table matriculas (
    id uuid primary key default gen_random_uuid(),
    aluno_id uuid not null references alunos(id) on delete cascade,
    turma_id uuid not null references turmas(id) on delete cascade,
    data_matricula date not null default current_date,
    unique (aluno_id, turma_id)
);

create table notas (
    id uuid primary key default gen_random_uuid(),
    matricula_id uuid not null references matriculas(id) on delete cascade,
    n1 numeric(4,2) default 0,
    n2 numeric(4,2) default 0,
    n3 numeric(4,2) default 0,
    frequencia numeric(5,2) default 100,
    unique (matricula_id)
);

-- ---------------------------------------------------------------------
-- FINANCEIRO
-- ---------------------------------------------------------------------
create table mensalidades (
    id uuid primary key default gen_random_uuid(),
    aluno_id uuid not null references alunos(id) on delete cascade,
    valor numeric(10,2) not null,
    desconto_percentual numeric(5,2) default 0,
    mes_referencia date not null,
    vencimento date not null,
    status varchar(20) not null default 'a_vencer'
        check (status in ('pago','a_vencer','atraso')),
    data_ultima_cobranca timestamptz
);

create table pagamentos (
    id uuid primary key default gen_random_uuid(),
    mensalidade_id uuid references mensalidades(id) on delete set null,
    aluno_id uuid not null references alunos(id) on delete cascade,
    valor numeric(10,2) not null,
    metodo varchar(20) not null check (metodo in ('PIX','Cartão','Boleto')),
    data_pagamento date not null default current_date,
    comprovante varchar(40)
);

create table renegociacoes (
    id uuid primary key default gen_random_uuid(),
    aluno_id uuid not null references alunos(id) on delete cascade,
    valor_original numeric(10,2) not null,
    parcelas smallint not null,
    valor_parcela numeric(10,2) not null,
    situacao varchar(20) not null default 'pendente'
        check (situacao in ('regular','pendente','quebrado')),
    data_acordo date not null default current_date
);

-- ---------------------------------------------------------------------
-- RECURSOS HUMANOS
-- ---------------------------------------------------------------------
create table folha_pagamento (
    id uuid primary key default gen_random_uuid(),
    funcionario_id uuid not null references funcionarios(id) on delete cascade,
    mes_referencia date not null,
    salario_base numeric(10,2) not null,
    beneficios numeric(10,2) default 0,
    descontos numeric(10,2) default 0,
    liquido numeric(10,2) generated always as
        (salario_base + coalesce(beneficios,0) - coalesce(descontos,0)) stored,
    status varchar(20) not null default 'processando'
        check (status in ('pago','processando')),
    unique (funcionario_id, mes_referencia)
);

create table afastamentos (
    id uuid primary key default gen_random_uuid(),
    funcionario_id uuid not null references funcionarios(id) on delete cascade,
    data_inicio date not null,
    data_fim date,
    motivo varchar(150)
);

-- ---------------------------------------------------------------------
-- TRIGGERS
-- ---------------------------------------------------------------------

-- Impede marcar funcionário como "inativo" sem data de demissão
create or replace function tr_funcionario_demissao() returns trigger as $$
begin
    if new.status = 'inativo' and new.data_demissao is null then
        raise exception 'Informe a data de demissão.';
    end if;
    return new;
end;
$$ language plpgsql;

create trigger trg_funcionario_demissao
before update on funcionarios
for each row execute function tr_funcionario_demissao();

-- Atualiza automaticamente o status da mensalidade quando um pagamento é lançado
create or replace function tr_pagamento_atualiza_mensalidade() returns trigger as $$
begin
    if new.mensalidade_id is not null then
        update mensalidades set status = 'pago' where id = new.mensalidade_id;
    end if;
    return new;
end;
$$ language plpgsql;

create trigger trg_pagamento_atualiza_mensalidade
after insert on pagamentos
for each row execute function tr_pagamento_atualiza_mensalidade();

-- ---------------------------------------------------------------------
-- VIEWS — usadas pelo Dashboard e pela seção de BI/Analytics
-- ---------------------------------------------------------------------

create or replace view vw_alunos_detalhe as
select
    a.id, a.ra, a.periodo, a.status,
    p.nome || ' ' || p.sobrenome as nome_completo,
    p.cpf, p.email, p.telefone,
    c.nome as curso
from alunos a
join pessoas p on p.id = a.pessoa_id
left join cursos c on c.id = a.curso_id;

create or replace view vw_funcionarios_detalhe as
select
    f.id, f.status, f.regime, f.data_admissao, f.data_demissao, f.salario,
    p.nome || ' ' || p.sobrenome as nome_completo,
    p.cpf,
    ca.nome as cargo,
    d.nome as departamento
from funcionarios f
join pessoas p on p.id = f.pessoa_id
left join cargos ca on ca.id = f.cargo_id
left join departamentos d on d.id = f.departamento_id;

create or replace view vw_turmas_detalhe as
select
    t.id, t.codigo, t.horario, t.semestre, t.status,
    disc.nome as disciplina,
    prof_p.nome || ' ' || prof_p.sobrenome as professor,
    c.nome as curso,
    count(m.id) as total_alunos
from turmas t
left join disciplinas disc on disc.id = t.disciplina_id
left join funcionarios prof on prof.id = t.professor_id
left join pessoas prof_p on prof_p.id = prof.pessoa_id
left join cursos c on c.id = t.curso_id
left join matriculas m on m.turma_id = t.id
group by t.id, disc.nome, prof_p.nome, prof_p.sobrenome, c.nome;

create or replace view vw_mensalidades_detalhe as
select
    mens.id, mens.valor, mens.desconto_percentual, mens.vencimento, mens.status,
    p.nome || ' ' || p.sobrenome as aluno,
    c.nome as curso
from mensalidades mens
join alunos a on a.id = mens.aluno_id
join pessoas p on p.id = a.pessoa_id
left join cursos c on c.id = a.curso_id;

create or replace view vw_notas_detalhe as
select
    n.id, n.n1, n.n2, n.n3, n.frequencia,
    round((n.n1 + n.n2 + n.n3) / 3.0, 1) as media,
    p.nome || ' ' || p.sobrenome as aluno,
    t.codigo as turma_codigo,
    disc.nome as disciplina
from notas n
join matriculas m on m.id = n.matricula_id
join alunos a on a.id = m.aluno_id
join pessoas p on p.id = a.pessoa_id
join turmas t on t.id = m.turma_id
left join disciplinas disc on disc.id = t.disciplina_id;

create or replace view vw_folha_detalhe as
select
    fp.id, fp.mes_referencia, fp.salario_base, fp.beneficios, fp.descontos,
    fp.liquido, fp.status,
    p.nome || ' ' || p.sobrenome as nome_completo,
    ca.nome as cargo
from folha_pagamento fp
join funcionarios f on f.id = fp.funcionario_id
join pessoas p on p.id = f.pessoa_id
left join cargos ca on ca.id = f.cargo_id;

create or replace view vw_pagamentos_detalhe as
select
    pg.id, pg.valor, pg.metodo, pg.data_pagamento, pg.comprovante,
    p.nome || ' ' || p.sobrenome as aluno
from pagamentos pg
join alunos a on a.id = pg.aluno_id
join pessoas p on p.id = a.pessoa_id
order by pg.data_pagamento desc;

create or replace view vw_renegociacoes_detalhe as
select
    r.id, r.valor_original, r.parcelas, r.valor_parcela, r.situacao, r.data_acordo,
    p.nome || ' ' || p.sobrenome as aluno
from renegociacoes r
join alunos a on a.id = r.aluno_id
join pessoas p on p.id = a.pessoa_id;

create or replace view vw_inadimplentes as
select
    a.id as aluno_id,
    p.nome || ' ' || p.sobrenome as aluno,
    c.nome as curso,
    count(mens.id) as parcelas_atraso,
    sum(mens.valor) as valor_total,
    max(mens.vencimento) as ultimo_vencimento
from mensalidades mens
join alunos a on a.id = mens.aluno_id
join pessoas p on p.id = a.pessoa_id
left join cursos c on c.id = a.curso_id
where mens.status = 'atraso'
group by a.id, p.nome, p.sobrenome, c.nome;

create or replace view vw_arrecadacao_por_curso as
select
    c.nome as curso,
    count(distinct a.id) as total_alunos,
    coalesce(sum(mens.valor) filter (where mens.status = 'pago'), 0) as receita_mes,
    round(
        100.0 * count(distinct mens.aluno_id) filter (where mens.status = 'atraso')
        / nullif(count(distinct a.id), 0), 1
    ) as inadimplencia_pct
from cursos c
left join alunos a on a.curso_id = c.id
left join mensalidades mens on mens.aluno_id = a.id
group by c.nome;

-- ---------------------------------------------------------------------
-- ROW LEVEL SECURITY
-- Projeto acadêmico / demo de portfólio: liberamos leitura e escrita
-- públicas (via chave "anon") para que o site funcione sem tela de
-- login. Se você adicionar autenticação depois, troque estas políticas
-- por regras baseadas em auth.uid().
-- ---------------------------------------------------------------------
do $$
declare
    t text;
begin
    for t in
        select unnest(array[
            'pessoas','cursos','alunos','departamentos','cargos','funcionarios',
            'disciplinas','turmas','matriculas','notas','mensalidades',
            'pagamentos','renegociacoes','folha_pagamento','afastamentos'
        ])
    loop
        execute format('alter table %I enable row level security;', t);
        execute format('drop policy if exists "public_all" on %I;', t);
        execute format(
            'create policy "public_all" on %I for all using (true) with check (true);', t
        );
    end loop;
end $$;

-- =====================================================================
-- FIM DO SCHEMA — os dados de exemplo (seed) estão em seed.sql
-- =====================================================================
