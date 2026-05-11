# 🎓 SisGESC — ERP Educacional

<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&height=250&color=0:00c6ff,50:0072ff,100:00ff88&text=SisGESC&fontSize=55&fontColor=ffffff&animation=fadeIn&fontAlignY=38" />
</p>

<p align="center">
  <img src="https://img.shields.io/badge/MySQL-Database-blue?style=for-the-badge&logo=mysql" />
  <img src="https://img.shields.io/badge/SQL-Advanced-orange?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Data%20Warehouse-BI-green?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Status-Em%20Desenvolvimento-success?style=for-the-badge" />
</p>

---

# 📚 Sobre o Projeto

O **SisGESC** é um sistema ERP educacional completo desenvolvido utilizando **MySQL**, focado em:

- Gestão Acadêmica
- Recursos Humanos
- Financeiro
- Business Intelligence
- Data Warehouse

O projeto foi desenvolvido aplicando conceitos de:

- Modelagem Relacional
- Integridade Referencial
- Triggers
- Modelo OLTP
- Modelo OLAP
- Modelo Estrela
- SQL Avançado

---

# 🧠 Arquitetura do Sistema

```txt
SisGESC
├── RH
├── Acadêmico
├── Financeiro
└── BI / Data Warehouse
```

---

# ⚙️ Funcionalidades

## 👨‍🎓 Acadêmico

- Cadastro de alunos
- Cadastro de professores
- Controle de turmas
- Controle de disciplinas
- Matrículas
- Notas
- Frequência

---

## 🏢 Recursos Humanos

- Funcionários
- Departamentos
- Cargos
- Histórico de cargos
- Folha de pagamento
- Controle de afastamentos

---

## 💰 Financeiro

- Contratos
- Mensalidades
- Pagamentos
- Métodos de pagamento
- Descontos
- Renegociação
- Controle de inadimplência

---

## 📊 BI / Data Warehouse

- Modelo estrela
- Tabela fato
- Dimensões
- Indicadores financeiros
- Análise de arrecadação

---

# 🛠️ Tecnologias Utilizadas

<div align="center">

| Tecnologia | Uso |
|---|---|
| MySQL | Banco de Dados |
| SQL | Scripts |
| DBML | Modelagem |
| Data Warehouse | BI |
| GitHub | Versionamento |

</div>

---

# 🗂️ Estrutura do Projeto

```bash
SisGESC/
│
├── README.md
├── LICENSE
├── .gitignore
│
├── docs/
│   ├── dicionario-de-dados.pdf
│   ├── modelo-er.png
│   └── requisitos.md
│
├── dbml/
│   └── sisgesc.dbml
│
├── sql/
│   ├── 01_database.sql
│   ├── 02_tables.sql
│   ├── 03_triggers.sql
│   ├── 04_inserts.sql
│   └── 05_queries.sql
│
├── imagens/
│   └── diagrama.png
│
└── exemplos/
    └── consultas.sql
```

---

# 🚀 Como Executar

## 1️⃣ Clone o repositório

```bash
git clone https://github.com/jcauan374-ads/SisGESC.git
```

---

## 2️⃣ Abra no MySQL Workbench

Execute os scripts na ordem:

```sql
01_database.sql
02_tables.sql
03_triggers.sql
04_inserts.sql
05_queries.sql
```

---

# 🔥 Principais Conceitos Aplicados

✅ Integridade Referencial  
✅ Chaves Primárias e Estrangeiras  
✅ Relacionamentos N:N  
✅ Triggers  
✅ Procedures  
✅ Data Warehouse  
✅ Modelo Estrela  
✅ BI  
✅ Normalização  

---

# 📈 Modelo de Banco

```txt
Pessoas → Funcionários → RH
        → Alunos → Acadêmico
                  → Financeiro
                  → BI
```

---

# 📊 Exemplo de Query

```sql
SELECT 
    p.nome,
    c.nome_cargo,
    f.salario_vigente
FROM tb_funcionarios f
JOIN tb_pessoas p 
ON f.pk_pessoa_id = p.pk_pessoa_id
JOIN tb_cargos c
ON f.fk_cargo = c.pk_cargo;
```

---

# 🧩 Diferenciais do Projeto

- Estrutura profissional
- Banco modularizado
- Scripts organizados
- Separação OLTP e OLAP
- Modelo corporativo
- ERP completo

---

# 🗄️ Exemplo de Modelagem DBML

```dbml
Project SisGESC {
  database_type: 'MySQL'
}

Table tb_pessoas {
  pk_pessoa_id int [pk, increment]
  nome varchar(100)
  sobrenome varchar(150)
  cpf varchar(14)
}

Table tb_alunos {
  pk_pessoa_id int [pk]
  ra varchar(20)
  curso varchar(100)
}

Ref: tb_alunos.pk_pessoa_id > tb_pessoas.pk_pessoa_id
```

---

# 📦 Scripts SQL

## 01_database.sql

```sql
DROP DATABASE IF EXISTS db_sisgesc;

CREATE DATABASE db_sisgesc;

USE db_sisgesc;
```

---

## 02_tables.sql

```sql
CREATE TABLE tb_pessoas (
    pk_pessoa_id INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    sobrenome VARCHAR(150) NOT NULL,
    cpf VARCHAR(14) UNIQUE NOT NULL
);

CREATE TABLE tb_alunos (
    pk_pessoa_id INT PRIMARY KEY,
    ra VARCHAR(20) UNIQUE NOT NULL,
    curso VARCHAR(100) NOT NULL,
    
    CONSTRAINT fk_aluno_pessoa
    FOREIGN KEY (pk_pessoa_id)
    REFERENCES tb_pessoas(pk_pessoa_id)
);
```

---

## 03_triggers.sql

```sql
DELIMITER $$

CREATE TRIGGER tr_funcionario_demissao
BEFORE UPDATE ON tb_funcionarios
FOR EACH ROW
BEGIN

IF NEW.status_funcionario = 'inativo'
AND NEW.data_demissao IS NULL THEN

SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = 'Informe a data de demissão.';

END IF;

END$$

DELIMITER ;
```

---

## 04_inserts.sql

```sql
INSERT INTO tb_pessoas
(nome, sobrenome, cpf)
VALUES
('Carlos', 'Bezerra', '111.111.111-11');

INSERT INTO tb_alunos
(pk_pessoa_id, ra, curso)
VALUES
(1, '42920949', 'ADS');
```

---

## 05_queries.sql

```sql
SELECT * FROM tb_pessoas;

SELECT * FROM tb_alunos;

SELECT * FROM tb_funcionarios;
```

---

# 📌 Possíveis Melhorias Futuras

- API REST
- Interface Web
- Dashboard BI
- Integração com Power BI
- Sistema de autenticação
- Controle de permissões
- Dockerização
- Backup automático

---

# 👨‍💻 Autor

## José Cauan

<p align="left">
  <a href="https://github.com/jcauan374-ads">
    <img src="https://img.shields.io/badge/GitHub-jcauan374--ads-000?style=for-the-badge&logo=github" />
  </a>
  <a href="https://br.linkedin.com/in/jos%C3%A9-cauan-8247922b0">
    <img src="https://img.shields.io/badge/LinkedIn-José_Cauan-0077B5?style=for-the-badge&logo=linkedin&logoColor=white" />
  </a>
  <a href="mailto:jcauan374@gmail.com">
    <img src="https://img.shields.io/badge/Gmail-jcauan374@gmail.com-D14836?style=for-the-badge&logo=gmail&logoColor=white" />
  </a>
</p>

---

# ⭐ Objetivo

Projeto acadêmico criado para estudos de:

- Banco de Dados
- Engenharia de Software
- Business Intelligence
- SQL Avançado
- Data Warehouse

---

# 📌 Status do Projeto

```txt
🚧 Em desenvolvimento 🚧
```

---

<p align="center">
  Feito com 💙 por José Cauan
</p>
