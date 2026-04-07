-- ============================================================
-- PROJETO: ETL Pipeline - Indicadores Educacionais
-- SCRIPT:  02_stored_procedures.sql
-- DESCRICAO: Stored Procedures para extracao de dados
-- AUTOR: Wesley Novaes
-- ============================================================

USE IndicadoresEducacionais;
GO

-- ------------------------------------------------------------
-- SP: Extracao de matriculas ativas por periodo
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.sp_ExtracaoMatriculasAtivas
    @DataInicio DATE,
    @DataFim    DATE
AS
BEGIN
    SET NOCOUNT ON;

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
        m.DataPrevisaoConclusao,
        m.StatusMatricula,
        m.TipoContrato,
        m.ValorMensalidade,
        YEAR(m.DataMatricula)  AS AnoMatricula,
        MONTH(m.DataMatricula) AS MesMatricula,
        DATEDIFF(MONTH, m.DataMatricula, GETDATE()) AS MesesAtivo
    FROM
        dbo.Matriculas m
        INNER JOIN dbo.Cursos   c ON m.CursoID   = c.CursoID
        INNER JOIN dbo.Unidades u ON m.UnidadeID = u.UnidadeID
    WHERE
        m.StatusMatricula = 'Ativo'
        AND m.DataMatricula BETWEEN @DataInicio AND @DataFim
    ORDER BY
        m.DataMatricula DESC;
END;
GO

-- ------------------------------------------------------------
-- SP: Resumo de indicadores por unidade
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.sp_IndicadoresPorUnidade
    @AnoReferencia INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Ano INT = ISNULL(@AnoReferencia, YEAR(GETDATE()));

    SELECT
        u.NomeUnidade,
        u.Cidade,
        u.UF,
        COUNT(*)                                                          AS TotalMatriculas,
        SUM(CASE WHEN m.StatusMatricula = 'Ativo'     THEN 1 ELSE 0 END) AS Ativos,
        SUM(CASE WHEN m.StatusMatricula = 'Cancelado' THEN 1 ELSE 0 END) AS Cancelados,
        SUM(CASE WHEN m.StatusMatricula = 'Trancado'  THEN 1 ELSE 0 END) AS Trancados,
        SUM(CASE WHEN m.StatusMatricula = 'Formado'   THEN 1 ELSE 0 END) AS Formados,
        ROUND(
                  100.0 * SUM(CASE WHEN m.StatusMatricula = 'Formado' THEN 1 ELSE 0 END)
                  / NULLIF(COUNT(*), 0), 2
              )                                                                  AS PercConclusao,
        ROUND(
                  100.0 * SUM(CASE WHEN m.StatusMatricula = 'Cancelado' THEN 1 ELSE 0 END)
                  / NULLIF(COUNT(*), 0), 2
              )                                                                  AS PercCancelamento,
        ROUND(SUM(m.ValorMensalidade), 2)                                  AS ReceitaMensal
    FROM
        dbo.Matriculas m
        INNER JOIN dbo.Unidades u ON m.UnidadeID = u.UnidadeID
    WHERE
        YEAR(m.DataMatricula) = @Ano
    GROUP BY
        u.NomeUnidade, u.Cidade, u.UF
    ORDER BY
        TotalMatriculas DESC;
END;
GO

-- ------------------------------------------------------------
-- SP: Evolucao mensal de matriculas (serie temporal)
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.sp_EvolucaoMensalMatriculas
    @AnoInicio INT,
    @AnoFim    INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        YEAR(m.DataMatricula)             AS Ano,
        MONTH(m.DataMatricula)            AS Mes,
        DATENAME(MONTH, m.DataMatricula)  AS NomeMes,
        c.Modalidade,
        COUNT(*)                           AS TotalMatriculas,
        SUM(m.ValorMensalidade)            AS ReceitaTotal
    FROM
        dbo.Matriculas m
        INNER JOIN dbo.Cursos c ON m.CursoID = c.CursoID
    WHERE
        YEAR(m.DataMatricula) BETWEEN @AnoInicio AND @AnoFim
    GROUP BY
        YEAR(m.DataMatricula),
        MONTH(m.DataMatricula),
        DATENAME(MONTH, m.DataMatricula),
        c.Modalidade
    ORDER BY
        Ano, Mes;
END;
GO

PRINT 'Stored Procedures criadas com sucesso!';
