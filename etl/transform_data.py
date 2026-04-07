"""
============================================================
PROJETO: ETL Pipeline - Indicadores Educacionais
SCRIPT:  etl/transform_data.py
DESCRICAO: Transformacao e limpeza dos dados brutos de matriculas
AUTOR: Wesley Novaes
============================================================

Etapas do pipeline:
    1. Leitura dos dados brutos (CSV)
        2. Limpeza e padronizacao de campos
            3. Classificacoes e enriquecimento
                4. Validacao de qualidade
                    5. Exportacao dos dados processados
                    """

import pandas as pd
import numpy as np
from datetime import datetime
import os
import logging

# ------------------------------------------------------------
# Configuracao de logging
# ------------------------------------------------------------
logging.basicConfig(
      level=logging.INFO,
      format="%(asctime)s [%(levelname)s] %(message)s",
      datefmt="%Y-%m-%d %H:%M:%S"
)
log = logging.getLogger(__name__)

# ------------------------------------------------------------
# Caminhos dos arquivos
# ------------------------------------------------------------
BASE_DIR       = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW_PATH       = os.path.join(BASE_DIR, "data", "raw", "matriculas_raw.csv")
PROCESSED_PATH = os.path.join(BASE_DIR, "data", "processed", "matriculas_processed.csv")


# ------------------------------------------------------------
# 1. LEITURA DOS DADOS BRUTOS
# ------------------------------------------------------------
def load_raw_data(filepath: str) -> pd.DataFrame:
      """Carrega o arquivo CSV bruto e retorna um DataFrame."""
      log.info(f"Lendo dados brutos: {filepath}")
      df = pd.read_csv(filepath, sep=";", encoding="utf-8-sig", parse_dates=["data_matricula", "data_previsao_conclusao", "data_conclusao"])
      log.info(f"Registros carregados: {len(df):,}")
      return df


# ------------------------------------------------------------
# 2. LIMPEZA E PADRONIZACAO
# ------------------------------------------------------------
def clean_data(df: pd.DataFrame) -> pd.DataFrame:
      """Limpa e padroniza os dados brutos."""
      log.info("Iniciando limpeza dos dados...")

    # Remover duplicatas por matricula_id
      before = len(df)
      df = df.drop_duplicates(subset=["matricula_id"])
      log.info(f"Duplicatas removidas: {before - len(df)}")

    # Padronizar strings (remover espacos extras, capitalizar)
      str_cols = ["nome_curso", "modalidade", "area_conhecimento", "nome_unidade", "cidade", "uf", "status_matricula", "tipo_contrato"]
      for col in str_cols:
                if col in df.columns:
                              df[col] = df[col].str.strip().str.title()

            # Padronizar UF para maiusculo
            if "uf" in df.columns:
                      df["uf"] = df["uf"].str.upper()

    # Preencher valores nulos em campos nao criticos
    df["motivo_cancelamento"] = df["motivo_cancelamento"].fillna("Nao informado")
    df["tipo_contrato"]       = df["tipo_contrato"].fillna("Nao informado")

    # Garantir que valor_mensalidade seja numerico
    df["valor_mensalidade"] = pd.to_numeric(df["valor_mensalidade"], errors="coerce").fillna(0.0)

    log.info("Limpeza concluida.")
    return df


# ------------------------------------------------------------
# 3. ENRIQUECIMENTO E CLASSIFICACOES
# ------------------------------------------------------------
def enrich_data(df: pd.DataFrame) -> pd.DataFrame:
      """Adiciona colunas calculadas e classificacoes de negocio."""
    log.info("Enriquecendo dados...")

    hoje = pd.Timestamp(datetime.today().date())

    # Extrair componentes de data
    df["ano_matricula"]  = df["data_matricula"].dt.year
    df["mes_matricula"]  = df["data_matricula"].dt.month
    df["nome_mes"]       = df["data_matricula"].dt.strftime("%B")
    df["semestre"]       = df["data_matricula"].dt.quarter.apply(lambda q: 1 if q <= 2 else 2)

    # Calcular duracao em meses
    data_ref = df["data_conclusao"].fillna(hoje)
    df["duracao_meses"] = ((data_ref - df["data_matricula"]) / np.timedelta64(1, "M")).round(1)
    df["duracao_meses"] = df["duracao_meses"].clip(lower=0)

    # Flags booleanas para KPIs no Power BI
    df["flag_ativo"]     = (df["status_matricula"].str.lower() == "ativo").astype(int)
    df["flag_cancelado"] = (df["status_matricula"].str.lower() == "cancelado").astype(int)
    df["flag_formado"]   = (df["status_matricula"].str.lower() == "formado").astype(int)
    df["flag_trancado"]  = (df["status_matricula"].str.lower() == "trancado").astype(int)

    # Classificacao de faixa de mensalidade
    bins   = [0, 500, 1000, 2000, 5000, float("inf")]
    labels = ["Ate R$500", "R$501-1000", "R$1001-2000", "R$2001-5000", "Acima R$5000"]
    df["faixa_mensalidade"] = pd.cut(df["valor_mensalidade"], bins=bins, labels=labels, right=True)

    # Classificacao de tempo de permanencia
    df["faixa_permanencia"] = pd.cut(
              df["duracao_meses"],
              bins=[0, 6, 12, 24, 48, float("inf")],
              labels=["0-6 meses", "7-12 meses", "13-24 meses", "25-48 meses", "Mais de 48 meses"],
              right=True
    )

    log.info("Enriquecimento concluido.")
    return df


# ------------------------------------------------------------
# 4. VALIDACAO DE QUALIDADE
# ------------------------------------------------------------
def validate_data(df: pd.DataFrame) -> pd.DataFrame:
      """Executa checagens de qualidade e registra alertas."""
      log.info("Validando qualidade dos dados...")

    issues = []

    # Checar nulos em campos obrigatorios
    required_cols = ["matricula_id", "data_matricula", "status_matricula", "nome_curso", "nome_unidade"]
    for col in required_cols:
              nulls = df[col].isna().sum()
              if nulls > 0:
                            issues.append(f"Campo '{col}' possui {nulls} valor(es) nulo(s).")

          # Checar datas inconsistentes
          invalid_dates = df[df["data_conclusao"] < df["data_matricula"]].shape[0]
    if invalid_dates > 0:
              issues.append(f"{invalid_dates} registro(s) com data_conclusao anterior a data_matricula.")

    # Checar valores negativos em mensalidade
    neg_values = (df["valor_mensalidade"] < 0).sum()
    if neg_values > 0:
              issues.append(f"{neg_values} registro(s) com valor_mensalidade negativo.")

    if issues:
              for issue in issues:
                            log.warning(f"[QUALIDADE] {issue}")
    else:
        log.info("Nenhum problema de qualidade encontrado.")

    return df


# ------------------------------------------------------------
# 5. EXPORTACAO DOS DADOS PROCESSADOS
# ------------------------------------------------------------
def export_data(df: pd.DataFrame, filepath: str) -> None:
      """Exporta o DataFrame processado para CSV."""
      os.makedirs(os.path.dirname(filepath), exist_ok=True)
      df.to_csv(filepath, sep=";", index=False, encoding="utf-8-sig")
      log.info(f"Dados exportados: {filepath} ({len(df):,} registros)")


# ------------------------------------------------------------
# EXECUCAO PRINCIPAL
# ------------------------------------------------------------
def main():
      log.info("=" * 60)
      log.info("Iniciando pipeline ETL - Indicadores Educacionais")
      log.info("=" * 60)

    df = load_raw_data(RAW_PATH)
    df = clean_data(df)
    df = enrich_data(df)
    df = validate_data(df)
    export_data(df, PROCESSED_PATH)

    log.info("Pipeline finalizado com sucesso!")
    log.info(f"Total de registros processados: {len(df):,}")


if __name__ == "__main__":
      main()
