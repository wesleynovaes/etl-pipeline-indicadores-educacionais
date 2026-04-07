-- ============================================================
-- PROJETO: ETL Pipeline - Indicadores Educacionais
-- SCRIPT:  03_views_analiticas.sql
-- DESCRICAO: Views analiticas para consumo no Power BI
-- AUTOR: Wesley Novaes
-- ============================================================

USE IndicadoresEducacionais;
GO

-- ------------------------------------------------------------
-- VIEW: Fato Matriculas (tabela fato para modelo estrela)
-- ------------------------------------------------------------
CREATE OR ALTER VIEW dbo.vw_FatoMatriculas AS
SELECT
    m.MatriculaID,
    m.AlunoID,
    m.CursoID,
    m.UnidadeID,
    CONVERT(INT, FORMAT(m.DataMatricula, 'yyyyMMdd'))           AS DataID,
    m.StatusMatricula,
    m.TipoContrato,
    m.ValorMensalidade,
    DATEDIFF(MONTH, m.DataMatricula, ISNULL(m.DataConclusao, GETDATE())) AS DuracaoMeses,
    CASE
        WHEN m.StatusMatricula = 'Ativo'     THEN 1 ELSE 0
    END AS FlagAtivo,
    CASE
        WHEN m.StatusMatricula = 'Cancelado' THEN 1 ELSE 0
    END AS FlagCancelado,
    CASE
        WHEN m.StatusMatricula = 'Formado'   THEN 1 ELSE 0
    END AS FlagFormado
FROM
    dbo.Matriculas m;
GO

-- ------------------------------------------------------------
-- VIEW: Dimensao Curso
-- ------------------------------------------------------------
CREATE OR ALTER VIEW dbo.vw_DimCurso AS
SELECT
    CursoID,
    NomeCurso,
    Modalidade,
    AreaConhecimento,
    CargaHoraria,
    CASE WHEN Ativo = 1 THEN 'Ativo' ELSE 'Inativo' END AS StatusCurso
FROM
    dbo.Cursos;
GO

-- ------------------------------------------------------------
-- VIEW: Dimensao Unidade
-- ------------------------------------------------------------
CREATE OR ALTER VIEW dbo.vw_DimUnidade AS
SELECT
    UnidadeID,
    NomeUnidade,
    Cidade,
    UF,
    CASE WHEN Ativo = 1 THEN 'Ativa' ELSE 'Inativa' END AS StatusUnidade
FROM
    dbo.Unidades;
GO

-- ------------------------------------------------------------
-- VIEW: Painel Consolidado (visao desnormalizada para consumo direto)
-- Ideal para conexao direta no Power BI sem necessidade de join
-- ------------------------------------------------------------
CREATE OR ALTER VIEW dbo.vw_PainelConsolidado AS
SELECT
    m.MatriculaID,
    m.AlunoID,
    c.NomeCurso,
    c.Modalidade,
    c.AreaConhecimento,
    u.NomeUnidade,
    u.Cidade,
    u.UF,
    m.DataMatricula,
    YEAR(m.DataMatricula)           AS AnoMatricula,
    MONTH(m.DataMatricula)          AS MesMatricula,
    DATENAME(MONTH, m.DataMatricula) AS NomeMesMatricula,
    m.DataPrevisaoConclusao,
    m.DataConclusao,
    m.StatusMatricula,
    m.TipoContrato,
    m.ValorMensalidade,
    m.MotivoCancelamento,
    DATEDIFF(MONTH, m.DataMatricula, ISNULL(m.DataConclusao, GETDATE())) AS DuracaoMeses
FROM
    dbo.Matriculas m
    INNER JOIN dbo.Cursos   c ON m.CursoID   = c.CursoID
    INNER JOIN dbo.Unidades u ON m.UnidadeID = u.UnidadeID;
GO

PRINT 'Views analiticas criadas com sucesso!';
