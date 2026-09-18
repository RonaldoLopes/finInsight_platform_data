# FinInsight Platform

Plataforma de dados de mercado financeiro em Azure + Databricks — Medallion Architecture (Bronze/Silver/Gold), AI/ML e GenAI, provisionada 100% via Terraform.

> Projeto de estudo para a certificação **Databricks Certified Data Engineer Associate**, com foco em engenharia de dados real aplicada ao mercado financeiro.

## Sumário

- [Visão geral](#visão-geral)
- [Arquitetura](#arquitetura)
- [Estrutura do repositório](#estrutura-do-repositório)
- [Pré-requisitos](#pré-requisitos)
- [Como subir a infraestrutura (Terraform)](#como-subir-a-infraestrutura-terraform)
- [Confirmação no Portal Azure](#confirmação-no-portal-azure)
- [Pipelines de dados](#pipelines-de-dados)
- [Catálogo de tabelas](#catálogo-de-tabelas)
- [AI/ML](#aiml)
- [GenAI](#genai)
- [CI/CD](#cicd)
- [Ambientes](#ambientes)
- [Documentação completa](#documentação-completa)

## Visão geral

A FinInsight Capital (empresa fictícia) consolida dados públicos e gratuitos de mercado financeiro
(BCB, B3, Yahoo Finance, Alpha Vantage, FRED, CoinGecko e notícias) em um Lakehouse Databricks,
calcula KPIs de risco/retorno (VaR, Sharpe, volatilidade, drawdown), treina modelos preditivos e
gera insights automáticos em linguagem natural via GenAI.

## Arquitetura

```
Fontes → Landing (ADLS Gen2) → Bronze (Auto Loader/DLT) → Silver (cálculos financeiros)
       → Gold (star schema + KPIs) → AI/ML (MLflow) + GenAI (RAG/ai_query) → Power BI / Databricks SQL
```

![Arquitetura de referência](docs/diagramas/d_arquitetura.png)

Detalhes completos, com diagramas, estão na apostila em `docs/Apostila_FinInsight_Databricks_Azure.pdf`.

## Estrutura do repositório

```
fininsight-platform/
├── README.md
├── docs/
│   ├── Apostila_FinInsight_Databricks_Azure.pdf
│   └── diagramas/
│       ├── d_arquitetura.png
│       ├── d_medallion.png
│       ├── d_starschema.png
│       └── d_terraform.png
├── infra/                          # Terraform (IaC)
│   ├── main.tf
│   ├── backend.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── envs/
│   │   ├── dev/terraform.tfvars
│   │   ├── hml/terraform.tfvars
│   │   └── prod/terraform.tfvars
│   └── modules/
│       ├── network/
│       ├── storage/                # ADLS Gen2 (landing/bronze/silver/gold)
│       ├── keyvault/
│       ├── databricks/             # Workspace + Access Connector
│       ├── unity-catalog/          # Metastore, Storage Credential, Catalog
│       └── ai-services/            # Azure OpenAI (opcional)
├── pipelines/                      # Delta Live Tables / Lakeflow Declarative Pipelines
│   ├── bronze/
│   │   ├── bz_b3_cotacoes.py
│   │   ├── bz_bcb_series.py
│   │   ├── bz_yfinance_precos.py
│   │   ├── bz_alphavantage_fx.py
│   │   ├── bz_fred_indicadores.py
│   │   ├── bz_coingecko_cripto.py
│   │   └── bz_noticias_raw.py
│   ├── silver/
│   │   ├── sv_precos_ativos.py
│   │   ├── sv_retornos_volatilidade.py     # cálculos financeiros (SMA, RSI, z-score)
│   │   ├── sv_precos_com_macro.py          # join multi-fonte
│   │   ├── sv_indicadores_macro.py
│   │   ├── sv_cambio.py
│   │   ├── sv_cripto.py
│   │   ├── sv_noticias_processadas.py
│   │   └── sv_carteiras_scd2.py            # APPLY CHANGES INTO (SCD2)
│   └── gold/
│       ├── dim_ativo.py
│       ├── dim_data.py
│       ├── dim_moeda.py
│       ├── fato_precos_diarios.py
│       ├── fato_retornos.py
│       ├── fato_volatilidade.py
│       ├── fato_risco_var_sharpe.py        # VaR, Sharpe, Drawdown
│       ├── fato_score_ml.py
│       ├── fato_insights_genai.py
│       └── fato_sentiment_noticias.py
├── notebooks/                       # jobs de coleta e orquestração
│   ├── 01_coleta_apis.py
│   ├── 02_streaming_producer.py
│   ├── 03_registro_pipeline_dlt.py
│   ├── 05_batch_scoring.py
│   └── 06_genai_insights.py
├── ml/                               # treino e registro de modelos (MLflow)
│   ├── previsao_series_temporais.py
│   ├── classificador_risco.py
│   └── clusterizacao_ativos.py
├── genai/
│   ├── vector_search_setup.py
│   └── prompts/
├── databricks.yml                    # Databricks Asset Bundle (Jobs + Pipelines)
├── bitbucket-pipelines.yml            # CI/CD DEV → HML → PROD
└── tests/
    └── test_transformacoes_silver.py
```

## Pré-requisitos

- Conta Azure com permissão de Owner/Contributor no(s) Resource Group(s)
- Terraform >= 1.7
- Databricks CLI (`databricks bundle` — Asset Bundles)
- Python 3.10+ (para os jobs de coleta e notebooks locais de teste)
- Chaves gratuitas: Alpha Vantage (free tier) e, opcionalmente, NewsAPI

![Estrutura de módulos Terraform](docs/diagramas/d_terraform.png)

## Como subir a infraestrutura (Terraform)

```bash
cd infra
terraform init -backend-config=envs/dev/backend.hcl
terraform validate
terraform plan  -var-file=envs/dev/terraform.tfvars -out=plan.out
terraform apply plan.out
```

Repita trocando `dev` por `hml`/`prod` conforme o ambiente. Nunca aponte dois ambientes para o
mesmo Storage Account/catálogo.

## Confirmação no Portal Azure

Após o `apply`, confirme manualmente (checklist resumido — passo a passo completo no Capítulo 10
da apostila):

1. Resource Group → 4 containers (landing/bronze/silver/gold) na Storage Account.
2. Access Connector → Identity → Object ID copiado.
3. IAM na Storage Account → `Storage Blob/Queue Data Contributor` atribuídos.
4. IAM no Resource Group → `EventGrid EventSubscription Contributor` e `Storage Account Contributor`.
5. Databricks Catalog Explorer → External Location → **Test connection** (tudo verde).
6. Catalog Explorer → catálogo `fininsight_dev` com schemas bronze/silver/gold.

## Pipelines de dados

Deploy do pipeline DLT via Asset Bundle:

```bash
databricks bundle deploy -t dev
databricks bundle run fininsight_pipeline_diario -t dev
```

A camada Silver realiza **cálculos financeiros completos** (não apenas limpeza): retorno
logarítmico, médias móveis (SMA 21d/63d), volatilidade anualizada, RSI 14 dias, z-score de preço e
joins multi-fonte (preço + câmbio + indicador macro). Ver Capítulo 18 da apostila para o código
completo.

![Pipeline medallion detalhado](docs/diagramas/d_medallion.png)

## Catálogo de tabelas

23 tabelas no total: 7 Bronze, 6 Silver, 10 Gold (3 dimensões + 7 fatos). Lista completa e modelo
dimensional (star schema) no Capítulo 23-24 da apostila.

![Modelo dimensional Gold](docs/diagramas/d_starschema.png)

## AI/ML

- Feature Store com features derivadas da Silver/Gold (retorno, volatilidade, RSI, z-score)
- Modelos: previsão de câmbio (Prophet), classificação de risco (Gradient Boosting), clusterização
  de ativos (KMeans)
- Tracking, Registry e Serving via MLflow

## GenAI

- Insights diários automáticos via `ai_query` (Databricks Foundation Model API) ou Azure OpenAI
- RAG sobre notícias financeiras com Databricks Vector Search
- Sumarização e sentiment de notícias via `ai_summarize` / `ai_classify`

## CI/CD

Deploy automatizado por branch via Bitbucket Pipelines + Databricks Asset Bundles:
`develop` → DEV, `release/*` → HML, `main` → PROD (com PR obrigatório para `main`).

## Ambientes

| Ambiente | Catálogo Unity Catalog | Uso |
|---|---|---|
| DEV | `fininsight_dev` | Desenvolvimento e testes |
| HML | `fininsight_hml` | Homologação / validação de negócio |
| PROD | `fininsight_prod` | Produção |

## Documentação completa

O passo a passo detalhado (infraestrutura, pipelines, modelagem, AI/ML, GenAI, governança e
troubleshooting) está em **`docs/Apostila_FinInsight_Databricks_Azure.pdf`**, com índice
clicável e marcadores por capítulo.
