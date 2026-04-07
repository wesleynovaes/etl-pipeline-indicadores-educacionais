-- ============================================================
-- PROJETO: ETL Pipeline - Indicadores Educacionais
-- SCRIPT:  01_create_tables.sql
-- DESCRICAO: Criacao das tabelas no banco de dados SQL Server
-- AUTOR: Wesley Novaes
-- ============================================================

USE IndicadoresEducacionais;
GO

-- ------------------------------------------------------------
-- Tabela de Cursos
-- ------------------------------------------------------------
IF OBJECT_ID('dbo.Cursos', 'U') IS NOT NULL
    DROP TABLE dbo.Cursos;

CREATE TABLE dbo.Cursos (
      CursoID       INT IDENTITY(1,1) PRIMARY KEY,
      NomeCurso     VARCHAR(150)  NOT NULL,
      Modalidade    VARCHAR(50)   NOT NULL,  -- Presencial, EAD, Hibrido
    AreaConhecimento VARCHAR(100) NOT NULL,
      CargaHoraria  INT           NULL,
      Ativo         BIT           NOT NULL DEFAULT 1,
      DataCriacao   DATETIME      NOT NULL DEFAULT GETDATE()
  );
GO

-- ------------------------------------------------------------
-- Tabela de Unidades
-- ------------------------------------------------------------
IF OBJECT_ID('dbo.Unidades', 'U') IS NOT NULL
    DROP TABLE dbo.Unidades;

CREATE TABLE dbo.Unidades (
      UnidadeID     INT IDENTITY(1,1) PRIMARY KEY,
      NomeUnidade   VARCHAR(150)  NOT NULL,
      Cidade        VARCHAR(100)  NOT NULL,
      UF            CHAR(2)       NOT NULL,
      Ativo         BIT           NOT NULL DEFAULT 1
  );
GO

-- ------------------------------------------------------------
-- Tabela de Matriculas (fato principal)
-- ------------------------------------------------------------
IF OBJECT_ID('dbo.Matriculas', 'U') IS NOT NULL
    DROP TABLE dbo.Matriculas;

CREATE TABLE dbo.Matriculas (
      MatriculaID       INT IDENTITY(1,1) PRIMARY KEY,
      CursoID           INT           NOT NULL,
      UnidadeID         INT           NOT NULL,
      AlunoID           INT           NOT NULL,
      DataMatricula     DATE          NOT NULL,
      DataPrevisaoConclusao DATE      NULL,
      DataConclusao     DATE          NULL,
      StatusMatricula   VARCHAR(50)   NOT NULL,  -- Ativo, Cancelado, Trancado, Formado
    TipoContrato      VARCHAR(50)   NULL,       -- Integral, Parcial, Bolsista
    ValorMensalidade  DECIMAL(10,2) NULL,
      DataCancelamento  DATE          NULL,
      MotivoCancelamento VARCHAR(200) NULL,
      DataCriacao       DATETIME      NOT NULL DEFAULT GETDATE(),
      CONSTRAINT FK_Matriculas_Cursos    FOREIGN KEY (CursoID)   REFERENCES dbo.Cursos(CursoID),
      CONSTRAINT FK_Matriculas_Unidades  FOREIGN KEY (UnidadeID) REFERENCES dbo.Unidades(UnidadeID)
  );
GO

-- ------------------------------------------------------------
-- Tabela de Dimensao Tempo (para modelo estrela no Power BI)
-- ------------------------------------------------------------
IF OBJECT_ID('dbo.DimTempo', 'U') IS NOT NULL
    DROP TABLE dbo.DimTempo;

CREATE TABLE dbo.DimTempo (
      DataID        INT           PRIMARY KEY,  -- Formato YYYYMMDD
    Data          DATE          NOT NULL,
      Ano           INT           NOT NULL,
      Semestre      INT           NOT NULL,
      Trimestre     INT           NOT NULL,
      Mes           INT           NOT NULL,
      NomeMes       VARCHAR(20)   NOT NULL,
      Semana        INT           NOT NULL,
      DiaSemana     INT           NOT NULL,
      NomeDiaSemana VARCHAR(20)   NOT NULL,
      DiaUtil       BIT           NOT NULL DEFAULT 1
  );
GO

PRINT 'Tabelas criadas com sucesso!';
