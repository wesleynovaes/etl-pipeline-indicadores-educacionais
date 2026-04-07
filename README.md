# 📊 ETL Pipeline — Indicadores Educacionais

> Pipeline de dados completo: extração via SQL Server, transformação com Python (Pandas) e visualização em Power BI.
>
> ![Status](https://img.shields.io/badge/status-concluído-brightgreen)
> ![Python](https://img.shields.io/badge/Python-3.10+-blue)
> ![SQL Server](https://img.shields.io/badge/SQL%20Server-2019-red)
> ![Power BI](https://img.shields.io/badge/Power%20BI-Dashboard-yellow)
>
> ---
>
> ## 📌 Sobre o Projeto
>
> Este projeto demonstra um pipeline ETL aplicado à análise de indicadores educacionais institucionais. O objetivo é transformar dados operacionais brutos — como matrículas, contratos e status de alunos — em informações estratégicas acessíveis por dashboards gerenciais.
>
> O pipeline cobre três camadas:
>
> - **Extração:** consultas SQL otimizadas com Stored Procedures e Views analíticas no SQL Server
> - - **Transformação:** limpeza, padronização e enriquecimento de dados com Python e Pandas
>   - - **Carga e Visualização:** dados processados consumidos diretamente pelo Power BI via modelo OLAP
>    
>     - ---
>
> ## 🗂️ Estrutura do Projeto
>
> ```
> etl-pipeline-indicadores-educacionais/
> │
> ├── README.md
> ├── .gitignore
> │
> ├── data/
> │   ├── raw/
> │   │   └── matriculas_raw.csv          # Dados brutos simulados
> │   └── processed/
> │       └── matriculas_processed.csv    # Dados após transformação
> │
> ├── sql/
> │   ├── 01_create_tables.sql            # Criação das tabelas no SQL Server
> │   ├── 02_stored_procedures.sql        # SPs para extração dos dados
> │   └── 03_views_analiticas.sql         # Views para consumo no Power BI
> │
> ├── etl/
> │   └── transform_data.py               # Script Python de transformação
> │
> └── docs/
>     └── arquitetura_pipeline.md         # Documentação da arquitetura
> ```
>
> ---
>
> ## 🛠️ Stack Tecnológica
>
> | Camada | Tecnologia |
> |---|---|
> | Banco de dados | SQL Server 2019 |
> | Extração | T-SQL, Stored Procedures, Views |
> | Transformação | Python 3.10+, Pandas, NumPy |
> | Orquestração ETL | Pentaho Data Integration (PDI) |
> | Visualização | Power BI Desktop / Power BI Service |
> | Modelagem | Modelo estrela (Star Schema), OLAP |
>
> ---
>
> ## ⚙️ Como Executar
>
> ### Pré-requisitos
>
> - Python 3.10+
> - - SQL Server 2019 (ou superior)
>   - - Power BI Desktop
>     - - Bibliotecas Python: `pandas`, `numpy`, `pyodbc`
>      
>       - ### Instalação das dependências
>      
>       - ```bash
>         pip install pandas numpy pyodbc
>         ```
>
> ### 1. Configurar o banco de dados
>
> Execute os scripts SQL na seguinte ordem:
>
> ```sql
> -- 1. Criar estrutura de tabelas
> -- sql/01_create_tables.sql
>
> -- 2. Criar Stored Procedures de extração
> -- sql/02_stored_procedures.sql
>
> -- 3. Criar Views analíticas
> -- sql/03_views_analiticas.sql
> ```
>
> ### 2. Executar a transformação Python
>
> ```bash
> python etl/transform_data.py
> ```
>
> O script irá:
> - Ler os dados brutos de `data/raw/matriculas_raw.csv`
> - - Aplicar limpeza, padronização e classificações
>   - - Salvar o resultado em `data/processed/matriculas_processed.csv`
>    
>     - ### 3. Conectar ao Power BI
>    
>     - Abra o Power BI Desktop e conecte à fonte de dados processada (CSV ou diretamente via SQL Server) para consumir o modelo analítico.
>    
>     - ---
>
> ## 📈 Resultados e Indicadores
>
> O pipeline alimenta um dashboard gerencial com os seguintes indicadores:
>
> - **Volume de matrículas ativas** por período e unidade
> - - **Taxa de inadimplência contratual** por segmento
>   - - **Distribuição por status** (ativo, cancelado, trancado, formado)
>     - - **Evolução temporal** de matrículas (mensal/anual)
>       - - **Ranking de cursos** por volume e taxa de conclusão
>        
>         - ---
>
> ## 📐 Arquitetura do Pipeline
>
> ```
> [SQL Server]
>   └── Stored Procedures / Views Analíticas
>         │
>         ▼
> [Python - Pandas]
>   └── Limpeza → Padronização → Classificação → Exportação CSV
>         │
>         ▼
> [Power BI]
>   └── Modelo Estrela (Star Schema)
>         └── Dashboards e Relatórios Gerenciais
> ```
>
> > Documentação detalhada da arquitetura disponível em [`docs/arquitetura_pipeline.md`](docs/arquitetura_pipeline.md)
> >
> > ---
> >
> > ## 👤 Autor
> >
> > **Wesley Novaes**
> > Analista de Dados & BI | SQL Server · Power BI · DAX · Python · ETL
> >
> > [![LinkedIn](https://img.shields.io/badge/LinkedIn-wesley--novaes-blue?logo=linkedin)](https://www.linkedin.com/in/wesley-novaes/)
> > [![GitHub](https://img.shields.io/badge/GitHub-wesleynovaes-black?logo=github)](https://github.com/wesleynovaes)
> >
> > ---
> >
> > > *Dados brutos utilizados neste projeto são fictícios e gerados exclusivamente para fins de demonstração.*
