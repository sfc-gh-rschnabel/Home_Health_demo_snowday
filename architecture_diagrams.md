# Lincare SnowDay Demo - Architecture Diagrams

## Overall Platform Architecture

```mermaid
graph TB
    subgraph sources [Data Sources]
        EDI[EDI_835_837_Files]
        CRM[CRM_Salesforce]
        CMS[CMS_Medicare_Data]
        Avaya[Avaya_PBX]
        Five9[Five9_Cloud]
        Ring[RingCentral]
    end

    subgraph ingestion [Snowflake Ingestion]
        Stage[Internal_Stages]
        Copy[COPY_INTO]
    end

    subgraph raw [RAW_DATA Schema]
        Claims[claims_submissions]
        Denials[claims_denials]
        Appeals[denial_appeals]
        SalesAct[sales_rep_activity]
        Referrals[physician_referrals]
        CMSData[cms_respiratory_claims]
        CDRs[call_detail_records]
    end

    subgraph transform [TRANSFORMED Schema - Dynamic Tables]
        Bronze[Bronze_Layer_1min]
        Silver[Silver_Layer_5min]
        Gold[Gold_Layer_DOWNSTREAM]
        Alerts[Realtime_Alerts_1min]
    end

    subgraph analytics [ANALYTICS Schema]
        SemView[Semantic_View]
        DenialViews[Denial_Analytics]
        SalesViews[Sales_Analytics]
        CallViews[Call_Center_Analytics]
    end

    subgraph ai [AI and Apps Layer]
        Search[Cortex_Search_Service]
        Agent[Intelligence_Agent]
        Streamlit[Streamlit_Dashboard]
    end

    sources --> ingestion
    ingestion --> raw
    raw --> Bronze
    Bronze --> Silver
    Silver --> Gold
    Silver --> Alerts
    Gold --> analytics
    analytics --> ai
    Search --> Agent
    SemView --> Agent
    Agent --> Streamlit
```

## Dynamic Tables Pipeline (Medallion Architecture)

```mermaid
graph LR
    subgraph bronze [Bronze - 1min Lag]
        DT_Claims[DT_CLEAN_CLAIMS]
        DT_Denials[DT_CLEAN_DENIALS]
        DT_Sales[DT_CLEAN_SALES_ACTIVITY]
        DT_Calls[DT_CLEAN_CALL_RECORDS]
    end

    subgraph silver [Silver - 5min Lag]
        DT_DenPayer[DT_DENIAL_RATE_BY_PAYER]
        DT_DenLoc[DT_DENIAL_RATE_BY_LOCATION]
        DT_SalesPipe[DT_SALES_PIPELINE_METRICS]
        DT_CallMetrics[DT_CALL_CENTER_METRICS]
        DT_LocHealth[DT_LOCATION_HEALTH_SCORE]
    end

    subgraph gold [Gold - DOWNSTREAM]
        DT_KPIs[DT_EXECUTIVE_KPIS]
        DT_Cross[DT_CROSS_DOMAIN_CORRELATION]
        DT_Rank[DT_LOCATION_RANKINGS]
    end

    subgraph alerts [Alerts - 1min Lag]
        DT_Alert[DT_REALTIME_ALERTS]
    end

    DT_Claims --> DT_DenPayer
    DT_Denials --> DT_DenPayer
    DT_Denials --> DT_DenLoc
    DT_Sales --> DT_SalesPipe
    DT_Calls --> DT_CallMetrics
    DT_Claims --> DT_LocHealth
    DT_Calls --> DT_LocHealth

    DT_DenPayer --> DT_KPIs
    DT_SalesPipe --> DT_KPIs
    DT_CallMetrics --> DT_KPIs
    DT_DenPayer --> DT_Cross
    DT_CallMetrics --> DT_Cross
    DT_LocHealth --> DT_Rank
    DT_DenPayer --> DT_Alert
    DT_CallMetrics --> DT_Alert
```

## Intelligence Agent Architecture

```mermaid
graph TB
    User[User_Natural_Language_Query]
    Agent[Lincare_Operations_Agent]
    LLM[Claude_4_Sonnet_Orchestration]

    subgraph tools [Agent Tools]
        Analyst[Cortex_Analyst - Text_to_SQL]
        SearchTool[Cortex_Search - Policy_Lookup]
    end

    subgraph data [Data Sources]
        SV[SV_LINCARE_OPERATIONS]
        Docs[LINCARE_POLICY_DOCUMENTS]
        SearchSvc[LINCARE_POLICY_SEARCH_Service]
    end

    User --> Agent
    Agent --> LLM
    LLM --> Analyst
    LLM --> SearchTool
    Analyst --> SV
    SearchTool --> SearchSvc
    SearchSvc --> Docs
```

## Competitive Architecture Comparison

```mermaid
graph LR
    subgraph snowflake [Snowflake - 5 Steps]
        SF1[COPY_INTO] --> SF2[CREATE_DYNAMIC_TABLE]
        SF2 --> SF3[CREATE_SEMANTIC_VIEW]
        SF3 --> SF4[CREATE_AGENT]
        SF4 --> SF5[Streamlit_App]
    end

    subgraph fabric [Microsoft Fabric - 8 Steps]
        F1[OneLake_Ingest] --> F2[Data_Factory_Pipeline]
        F2 --> F3[Synapse_SQL_Pool]
        F3 --> F4[Power_BI_Semantic_Model]
        F4 --> F5[Azure_AI_Search]
        F5 --> F6[Azure_OpenAI]
        F6 --> F7[Copilot_Studio]
        F7 --> F8[Power_Apps]
    end

    subgraph databricks [Databricks - 7 Steps]
        D1[Unity_Catalog_Ingest] --> D2[Delta_Live_Tables]
        D2 --> D3[SQL_Warehouse]
        D3 --> D4[Vector_Search_Index]
        D4 --> D5[Embedding_Model]
        D5 --> D6[Mosaic_AI_Agent]
        D6 --> D7[External_App_Deploy]
    end
```

## Data Model (Star Schema)

```mermaid
erDiagram
    FACT_CLAIMS ||--o{ DIM_LOCATION : "location_id"
    FACT_CLAIMS ||--o{ DIM_PAYER : "payer_code"
    FACT_CLAIMS ||--o{ DIM_EQUIPMENT : "hcpcs_code"
    FACT_CLAIMS ||--o{ DIM_PHYSICIAN : "physician_npi"
    FACT_CLAIMS ||--o{ DIM_TIME : "submission_date"
    FACT_DENIALS ||--o{ FACT_CLAIMS : "claim_id"
    FACT_APPEALS ||--o{ FACT_DENIALS : "denial_id"
    FACT_SALES_ACTIVITY ||--o{ DIM_LOCATION : "location_id"
    FACT_REFERRALS ||--o{ DIM_LOCATION : "location_id"
    FACT_REFERRALS ||--o{ DIM_PHYSICIAN : "physician_npi"
    FACT_CALLS ||--o{ DIM_LOCATION : "location_id"
```

## Use Case Integration (Cross-Domain Value)

```mermaid
graph TB
    subgraph uc1 [Use Case 1 - Denials Reduction]
        Denial[High_Denial_Rate]
        RootCause[Root_Cause_Analysis]
        Recovery[Appeal_and_Recovery]
    end

    subgraph uc3 [Use Case 3 - Call Center]
        BillingCalls[Billing_Inquiry_Spike]
        Complaints[Patient_Complaints]
        Volume[Call_Volume_Surge]
    end

    subgraph uc2 [Use Case 2 - Sales]
        RepActivity[Rep_Engagement_Drop]
        RefDecline[Referral_Decline]
        MarketGap[Market_Coverage_Gap]
    end

    subgraph insight [Cross-Domain Insights]
        Correlation[Location_Health_Score]
        Prediction[Predictive_Alerts]
        Action[Automated_Routing]
    end

    Denial --> BillingCalls
    Denial --> Complaints
    BillingCalls --> Volume
    RepActivity --> RefDecline
    RefDecline --> MarketGap

    Denial --> Correlation
    BillingCalls --> Correlation
    RepActivity --> Correlation
    Correlation --> Prediction
    Prediction --> Action
```
