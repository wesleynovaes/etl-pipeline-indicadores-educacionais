# Arquitetura do Pipeline ETL

## Visao Geral

Este documento descreve a arquitetura tecnica do pipeline ETL desenvolvido para analise de indicadores educacionais institucionais. O pipeline segue o padrao classico de tres camadas: Extracao, Transformacao e Carga (ETL), com saida final em dashboard Power BI.

---

## Diagrama da Arquitetura

```
+---------------------------+
|     FONTES DE DADOS       |
|  SQL Server (OLTP)        |
|  - Tabelas operacionais   |
|  - Sistemas de matriculas |
+------------+--------------+
             |
                          v
                          +---------------------------+
                          |     CAMADA DE EXTRACAO    |
                          |  T-SQL / Stored Procedures|
                          |  - sp_ExtracaoMatriculas  |
                          |  - sp_IndicadoresUnidade  |
                          |  - sp_EvolucaoMensal      |
                          |  Views Analiticas:        |
                          |  - vw_FatoMatriculas      |
                          |  - vw_PainelConsolidado   |
                          +------------+--------------+
                                       |
                                                    v (CSV exportado / pyodbc)
                                                    +---------------------------+
                                                    |   CAMADA DE TRANSFORMACAO |
                                                    |  Python 3.10+ / Pandas    |
                                                    |  - Limpeza de dados       |
                                                    |  - Padronizacao de campos |
                                                    |  - Enriquecimento (KPIs)  |
                                                    |  - Validacao de qualidade |
                                                    |  - Exportacao CSV         |
                                                    +------------+--------------+
                                                                 |
                                                                              v
                                                                              +---------------------------+
                                                                              |     CAMADA DE CARGA       |
                                                                              |  data/processed/          |
                                                                              |  matriculas_processed.csv |
                                                                              +------------+--------------+
                                                                                           |
                                                                                                        v
                                                                                                        +---------------------------+
                                                                                                        |      VISUALIZACAO         |
                                                                                                        |  Power BI Desktop/Service |
                                                                                                        |  Modelo Estrela (Star)    |
                                                                                                        |  - Fato: Matriculas       |
                                                                                                        |  - Dim: Curso, Unidade,   |
                                                                                                        |         Tempo             |
                                                                                                        |  KPIs e Dashboards        |
                                                                                                        +---------------------------+
                                                                                                        ```
                                                                                                        
                                                                                                        ---
                                                                                                        
                                                                                                        ## Detalhamento das Camadas
                                                                                                        
                                                                                                        ### 1. Fontes de Dados
                                                                                                        
                                                                                                        Os dados de origem residem em banco SQL Server, alimentado pelos sistemas operacionais da instituicao. As principais entidades sao:
                                                                                                        
                                                                                                        - **Matriculas** — registro central com status, datas e valores
                                                                                                        - **Cursos** — catalogo de cursos com modalidade e area de conhecimento
                                                                                                        - **Unidades** — unidades fisicas/virtuais da instituicao
                                                                                                        - **DimTempo** — dimensao calendario para analise temporal
                                                                                                        
                                                                                                        ### 2. Extracao (SQL Server)
                                                                                                        
                                                                                                        A extracao e realizada via T-SQL com tres Stored Procedures especializadas:
                                                                                                        
                                                                                                        | Stored Procedure | Finalidade |
                                                                                                        |---|---|
                                                                                                        | `sp_ExtracaoMatriculasAtivas` | Extrai matriculas ativas por intervalo de datas |
                                                                                                        | `sp_IndicadoresPorUnidade` | Consolida KPIs por unidade para o ano de referencia |
                                                                                                        | `sp_EvolucaoMensalMatriculas` | Serie temporal mensal de matriculas por modalidade |
                                                                                                        
                                                                                                        As Views analiticas (`vw_FatoMatriculas`, `vw_PainelConsolidado`) permitem conexao direta do Power BI ao SQL Server sem necessidade de ETL intermediario em cenarios de atualizacao em tempo real.
                                                                                                        
                                                                                                        ### 3. Transformacao (Python / Pandas)
                                                                                                        
                                                                                                        O script `etl/transform_data.py` executa o pipeline de transformacao em cinco etapas sequenciais:
                                                                                                        
                                                                                                        **Etapa 1 — Leitura:** carrega o CSV bruto com tipagem adequada para campos de data.
                                                                                                        
                                                                                                        **Etapa 2 — Limpeza:** remove duplicatas, padroniza strings (strip + title case), preenche nulos em campos nao obrigatorios e garante tipos numericos corretos.
                                                                                                        
                                                                                                        **Etapa 3 — Enriquecimento:** adiciona colunas derivadas:
                                                                                                        - `ano_matricula`, `mes_matricula`, `semestre`
                                                                                                        - `duracao_meses` (tempo de permanencia calculado)
                                                                                                        - `flag_ativo`, `flag_cancelado`, `flag_formado`, `flag_trancado` (KPIs binarios)
                                                                                                        - `faixa_mensalidade` e `faixa_permanencia` (segmentacoes)
                                                                                                        
                                                                                                        **Etapa 4 — Validacao:** checa nulos em campos obrigatorios, inconsistencias de datas e valores negativos. Alertas sao registrados via logging sem interromper o pipeline.
                                                                                                        
                                                                                                        **Etapa 5 — Exportacao:** salva o resultado em `data/processed/matriculas_processed.csv` com encoding UTF-8 BOM (compativel com Power BI).
                                                                                                        
                                                                                                        ### 4. Modelagem (Power BI — Star Schema)
                                                                                                        
                                                                                                        O modelo de dados no Power BI segue o padrao estrela (Star Schema):
                                                                                                        
                                                                                                        ```
                                                                                                                 [DimCurso]
                                                                                                                               |
                                                                                                                               [DimUnidade]--+--[FatoMatriculas]--[DimTempo]
                                                                                                                               ```
                                                                                                                               
                                                                                                                               **Tabela Fato:** `FatoMatriculas` — uma linha por matricula com chaves estrangeiras e metricas numericas.
                                                                                                                               
                                                                                                                               **Tabelas Dimensao:**
                                                                                                                               - `DimCurso` — atributos descritivos do curso
                                                                                                                               - `DimUnidade` — atributos da unidade (cidade, UF)
                                                                                                                               - `DimTempo` — calendario completo para analise temporal
                                                                                                                               
                                                                                                                               ### 5. Visualizacao (Power BI)
                                                                                                                               
                                                                                                                               O dashboard apresenta os seguintes indicadores:
                                                                                                                               
                                                                                                                               - Total de matriculas ativas, formadas, canceladas e trancadas
                                                                                                                               - Taxa de conclusao e taxa de cancelamento por unidade
                                                                                                                               - Evolucao mensal de novas matriculas
                                                                                                                               - Distribuicao por modalidade (Presencial, EAD, Hibrido)
                                                                                                                               - Ranking de cursos por volume de matriculas
                                                                                                                               - Mapa de calor por regiao (cidade/UF)
                                                                                                                               
                                                                                                                               ---
                                                                                                                               
                                                                                                                               ## Decisoes Tecnicas
                                                                                                                               
                                                                                                                               **Por que Star Schema?** O modelo estrela simplifica as consultas DAX no Power BI, melhora a performance de carregamento e facilita a manutencao por novos membros da equipe.
                                                                                                                               
                                                                                                                               **Por que separar extracao (SQL) e transformacao (Python)?** Permite evolucao independente das camadas. A extracao pode migrar para Pentaho PDI (ja utilizado no ambiente) sem alterar a logica de transformacao Python.
                                                                                                                               
                                                                                                                               **Por que CSV como formato intermediario?** Portabilidade e rastreabilidade. O arquivo processado pode ser auditado, versionado e consumido por qualquer ferramenta de BI sem dependencia de conexao ao banco.
                                                                                                                               
                                                                                                                               ---
                                                                                                                               
                                                                                                                               ## Tecnologias Utilizadas
                                                                                                                               
                                                                                                                               | Tecnologia | Versao | Finalidade |
                                                                                                                               |---|---|---|
                                                                                                                               | SQL Server | 2019 | Banco de dados relacional |
                                                                                                                               | T-SQL | — | Extracao e modelagem |
                                                                                                                               | Python | 3.10+ | Transformacao ETL |
                                                                                                                               | Pandas | 2.x | Manipulacao de dados |
                                                                                                                               | NumPy | 1.x | Calculos vetorizados |
                                                                                                                               | Pentaho PDI | 9.x | Orquestracao (ambiente producao) |
                                                                                                                               | Power BI Desktop | Latest | Modelagem e visualizacao |
                                                                                                                               | Power BI Service | Latest | Publicacao e atualizacao automatica |
                                                                                                                               
                                                                                                                               ---
                                                                                                                               
                                                                                                                               ## Autor
                                                                                                                               
                                                                                                                               **Wesley Novaes** — Analista de Dados & BI  
                                                                                                                               [LinkedIn](https://www.linkedin.com/in/wesley-novaes/) | [GitHub](https://github.com/wesleynovaes)
