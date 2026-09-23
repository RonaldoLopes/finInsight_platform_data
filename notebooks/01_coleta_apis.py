# Databricks notebook source
# MAGIC %md
# MAGIC # Reading APIs for Auto Loader incremental ingestion

# COMMAND ----------

# DBTITLE 1,Imports
import requests, json
from datetime import date

# COMMAND ----------

# DBTITLE 1,Colect data
def coletar_bcb_sgs(codigo_serie: int, nome: str):
    url = f"https://api.bcb.gov.br/dados/serie/bcdata.sgs.{codigo_serie}/dados/ultimos/20?formato=json"
    resp = requests.get(url, timeout=30)
    resp.raise_for_status()
    dados = resp.json()
    hoje = date.today()
    caminho = (f"/Volumes/fininsight_dev/landing/raw/bcb/{nome}/"
               f"ano={hoje.year}/mes={hoje.month:02d}/dia={hoje.day:02d}/dados.json")
    dbutils.fs.put(caminho, json.dumps(dados), overwrite=True)
    
coletar_bcb_sgs(11, "selic") # taxa Selic diária
coletar_bcb_sgs(433, "ipca") # IPCA mensal
coletar_bcb_sgs(1, "ptax_dolar") # câmbio PTAX
