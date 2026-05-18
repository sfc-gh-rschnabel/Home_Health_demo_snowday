"""
Lincare Operations Analytics Dashboard - Streamlit in Snowflake (SiS)
Multi-tab dashboard covering Denials, Sales, Call Center, and AI Assistant
"""

import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from snowflake.snowpark.context import get_active_session

session = get_active_session()

st.set_page_config(
    page_title="Lincare Operations Dashboard",
    page_icon="🫁",
    layout="wide",
    initial_sidebar_state="expanded"
)

st.markdown("""
<style>
    .main-header {font-size: 2.2rem; font-weight: bold; color: #0066CC; text-align: center; margin-bottom: 1rem;}
    .kpi-card {background: white; padding: 1.2rem; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.08); border-left: 4px solid #0066CC; margin: 0.3rem 0;}
    .section-header {color: #1a1a2e; border-bottom: 2px solid #0066CC; padding-bottom: 0.5rem; margin: 1.5rem 0 1rem 0;}
    .alert-card {background: #fff3cd; padding: 1rem; border-radius: 8px; border-left: 4px solid #ffc107; margin: 0.5rem 0;}
    .good {color: #28a745;} .bad {color: #dc3545;} .neutral {color: #6c757d;}
</style>
""", unsafe_allow_html=True)


def run_query(sql):
    try:
        return session.sql(sql).to_pandas()
    except Exception as e:
        st.error(f"Query error: {e}")
        return pd.DataFrame()


def metric_card(label, value, delta=None, icon="📊"):
    delta_html = f'<p style="color:#666;font-size:0.85rem;margin:0;">{delta}</p>' if delta else ""
    st.markdown(f"""<div class="kpi-card">
        <h4 style="color:#0066CC;margin:0;font-size:0.95rem;">{icon} {label}</h4>
        <h2 style="color:#1a1a2e;margin:0.3rem 0 0 0;font-size:1.8rem;">{value}</h2>
        {delta_html}</div>""", unsafe_allow_html=True)


# Sidebar
st.sidebar.markdown("## 🫁 Lincare Operations")
st.sidebar.success("Connected to Snowflake")

tab_selection = st.sidebar.radio("Navigation", [
    "Executive Summary",
    "Denials Command Center",
    "Sales Intelligence",
    "Call Center Operations",
    "AI Assistant"
])

st.sidebar.markdown("---")
st.sidebar.markdown("### Snowflake Features")
st.sidebar.info("Dynamic Tables | Semantic View | Cortex Search | Intelligence Agent | Streamlit")

# ============================================================================
# TAB 1: EXECUTIVE SUMMARY
# ============================================================================
if tab_selection == "Executive Summary":
    st.markdown('<h1 class="main-header">Lincare Operations Command Center</h1>', unsafe_allow_html=True)
    st.markdown('<p style="text-align:center;color:#666;">Q1 2026 Performance Across All Three Use Cases</p>', unsafe_allow_html=True)

    col1, col2, col3, col4 = st.columns(4)
    claims = run_query("SELECT COUNT(*) as total, SUM(billed_amount) as billed, SUM(CASE WHEN claim_status='DENIED' THEN billed_amount ELSE 0 END) as at_risk, ROUND(COUNT(CASE WHEN claim_status='DENIED' THEN 1 END)*100.0/COUNT(*),1) as denial_rate FROM LINCARE_DEMO.RAW_DATA.CLAIMS_SUBMISSIONS")

    if not claims.empty:
        with col1: metric_card("Total Claims", f"{claims['TOTAL'].iloc[0]:,.0f}", "Q1 2026", "📋")
        with col2: metric_card("Revenue Billed", f"${claims['BILLED'].iloc[0]:,.0f}", "Across 700 locations", "💰")
        with col3: metric_card("Revenue at Risk", f"${claims['AT_RISK'].iloc[0]:,.0f}", "From denied claims", "⚠️")
        with col4: metric_card("Denial Rate", f"{claims['DENIAL_RATE'].iloc[0]:.1f}%", "Target: <5%", "📉")

    st.markdown("---")
    col1, col2, col3 = st.columns(3)

    with col1:
        st.markdown("### 📋 Denials Snapshot")
        denials = run_query("SELECT root_cause, COUNT(*) as cnt, SUM(denied_amount) as amt FROM LINCARE_DEMO.RAW_DATA.CLAIMS_DENIALS GROUP BY root_cause ORDER BY cnt DESC")
        if not denials.empty:
            fig = px.pie(denials, values='CNT', names='ROOT_CAUSE', title="Denials by Root Cause", hole=0.4, color_discrete_sequence=px.colors.qualitative.Set2)
            fig.update_layout(margin=dict(t=40,b=0,l=0,r=0), height=300)
            st.plotly_chart(fig, use_container_width=True)

    with col2:
        st.markdown("### 📈 Sales Pipeline")
        refs = run_query("SELECT equipment_category, COUNT(*) as cnt, SUM(revenue) as rev FROM LINCARE_DEMO.RAW_DATA.PHYSICIAN_REFERRALS GROUP BY equipment_category ORDER BY rev DESC LIMIT 5")
        if not refs.empty:
            fig = px.bar(refs, x='EQUIPMENT_CATEGORY', y='REV', title="Referral Revenue by Category", color='REV', color_continuous_scale='Blues')
            fig.update_layout(margin=dict(t=40,b=0,l=0,r=0), height=300, showlegend=False)
            st.plotly_chart(fig, use_container_width=True)

    with col3:
        st.markdown("### 📞 Call Center Health")
        calls = run_query("SELECT phone_system, COUNT(*) as total, ROUND(COUNT(CASE WHEN abandoned THEN 1 END)*100.0/COUNT(*),1) as abandon_rate, ROUND(AVG(handle_time_seconds),0) as aht FROM LINCARE_DEMO.RAW_DATA.CALL_DETAIL_RECORDS GROUP BY phone_system")
        if not calls.empty:
            fig = px.bar(calls, x='PHONE_SYSTEM', y='ABANDON_RATE', title="Abandonment Rate by System", color='ABANDON_RATE', color_continuous_scale='Reds')
            fig.update_layout(margin=dict(t=40,b=0,l=0,r=0), height=300, showlegend=False)
            st.plotly_chart(fig, use_container_width=True)

# ============================================================================
# TAB 2: DENIALS COMMAND CENTER
# ============================================================================
elif tab_selection == "Denials Command Center":
    st.markdown('<h1 class="main-header">Denials Command Center</h1>', unsafe_allow_html=True)

    col1, col2, col3, col4, col5 = st.columns(5)
    kpis = run_query("""
        SELECT
            ROUND(COUNT(CASE WHEN claim_status='DENIED' THEN 1 END)*100.0/COUNT(*),2) as denial_rate,
            ROUND(COUNT(CASE WHEN claim_status='PAID' AND paid_amount>0 THEN 1 END)*100.0/COUNT(*),2) as clean_rate,
            ROUND(AVG(DATEDIFF(day, submission_date, adjudication_date)),1) as days_ar,
            SUM(CASE WHEN claim_status='DENIED' THEN billed_amount ELSE 0 END) as denied_rev,
            COUNT(CASE WHEN claim_status='DENIED' THEN 1 END) as denied_count
        FROM LINCARE_DEMO.RAW_DATA.CLAIMS_SUBMISSIONS
    """)
    if not kpis.empty:
        with col1: metric_card("Denial Rate", f"{kpis['DENIAL_RATE'].iloc[0]:.1f}%", "Target: <5%", "🚨")
        with col2: metric_card("Clean Claim Rate", f"{kpis['CLEAN_RATE'].iloc[0]:.1f}%", "Target: >95%", "✅")
        with col3: metric_card("Days in A/R", f"{kpis['DAYS_AR'].iloc[0]:.0f}", "Target: 30-35", "📅")
        with col4: metric_card("Revenue at Risk", f"${kpis['DENIED_REV'].iloc[0]:,.0f}", f"{kpis['DENIED_COUNT'].iloc[0]:,} claims", "💸")
        recovery = run_query("SELECT ROUND(SUM(recovered_amount)*100.0/NULLIF(SUM(CASE WHEN outcome IS NOT NULL THEN recovered_amount END + (SELECT SUM(denied_amount) FROM LINCARE_DEMO.RAW_DATA.CLAIMS_DENIALS)),0),1) as rate, SUM(recovered_amount) as recovered FROM LINCARE_DEMO.RAW_DATA.DENIAL_APPEALS")
        if not recovery.empty:
            with col5: metric_card("Recovered", f"${recovery['RECOVERED'].iloc[0]:,.0f}", "Via appeals", "🔄")

    col1, col2 = st.columns(2)
    with col1:
        trend = run_query("SELECT DATE_TRUNC('week', submission_date)::DATE as week, ROUND(COUNT(CASE WHEN claim_status='DENIED' THEN 1 END)*100.0/COUNT(*),2) as rate FROM LINCARE_DEMO.RAW_DATA.CLAIMS_SUBMISSIONS GROUP BY week ORDER BY week")
        if not trend.empty:
            fig = px.line(trend, x='WEEK', y='RATE', title="Weekly Denial Rate Trend", markers=True)
            fig.add_hline(y=5, line_dash="dash", line_color="green", annotation_text="Target: 5%")
            fig.update_layout(yaxis_title="Denial Rate %", xaxis_title="Week")
            st.plotly_chart(fig, use_container_width=True)

    with col2:
        payer = run_query("SELECT payer_name, COUNT(*) as total, COUNT(CASE WHEN claim_status='DENIED' THEN 1 END) as denied, ROUND(COUNT(CASE WHEN claim_status='DENIED' THEN 1 END)*100.0/COUNT(*),1) as rate FROM LINCARE_DEMO.RAW_DATA.CLAIMS_SUBMISSIONS GROUP BY payer_name ORDER BY rate DESC")
        if not payer.empty:
            fig = px.bar(payer, x='PAYER_NAME', y='RATE', title="Denial Rate by Payer", color='RATE', color_continuous_scale='RdYlGn_r', text='RATE')
            fig.update_layout(yaxis_title="Denial Rate %")
            st.plotly_chart(fig, use_container_width=True)

    col1, col2 = st.columns(2)
    with col1:
        root = run_query("SELECT root_cause, denial_code, denial_reason, COUNT(*) as cnt, SUM(denied_amount) as amt FROM LINCARE_DEMO.RAW_DATA.CLAIMS_DENIALS GROUP BY root_cause, denial_code, denial_reason ORDER BY cnt DESC LIMIT 10")
        if not root.empty:
            st.markdown("### Root Cause Analysis")
            st.dataframe(root, use_container_width=True)

    with col2:
        equip = run_query("SELECT equipment_category, COUNT(*) as denials, SUM(denied_amount) as amount FROM LINCARE_DEMO.RAW_DATA.CLAIMS_DENIALS GROUP BY equipment_category ORDER BY denials DESC")
        if not equip.empty:
            fig = px.treemap(equip, path=['EQUIPMENT_CATEGORY'], values='DENIALS', color='AMOUNT', title="Denials by Equipment Category")
            st.plotly_chart(fig, use_container_width=True)

# ============================================================================
# TAB 3: SALES INTELLIGENCE
# ============================================================================
elif tab_selection == "Sales Intelligence":
    st.markdown('<h1 class="main-header">Sales Intelligence</h1>', unsafe_allow_html=True)

    col1, col2, col3, col4 = st.columns(4)
    sales_kpis = run_query("""
        SELECT
            COUNT(*) as activities,
            COUNT(CASE WHEN referral_generated THEN 1 END) as referrals,
            ROUND(COUNT(CASE WHEN referral_generated THEN 1 END)*100.0/COUNT(*),1) as conv_rate,
            COUNT(DISTINCT rep_id) as active_reps
        FROM LINCARE_DEMO.RAW_DATA.SALES_REP_ACTIVITY
    """)
    ref_rev = run_query("SELECT SUM(revenue) as total_rev, COUNT(DISTINCT physician_npi) as physicians FROM LINCARE_DEMO.RAW_DATA.PHYSICIAN_REFERRALS")

    if not sales_kpis.empty:
        with col1: metric_card("Total Activities", f"{sales_kpis['ACTIVITIES'].iloc[0]:,}", "Q1 2026", "📊")
        with col2: metric_card("Referrals Generated", f"{sales_kpis['REFERRALS'].iloc[0]:,}", "Target: 12-18% rate", "🎯")
        with col3: metric_card("Conversion Rate", f"{sales_kpis['CONV_RATE'].iloc[0]:.1f}%", f"{sales_kpis['ACTIVE_REPS'].iloc[0]} active reps", "📈")
    if not ref_rev.empty:
        with col4: metric_card("Referral Revenue", f"${ref_rev['TOTAL_REV'].iloc[0]:,.0f}", f"{ref_rev['PHYSICIANS'].iloc[0]:,} physicians", "💰")

    col1, col2 = st.columns(2)
    with col1:
        reps = run_query("SELECT rep_name, territory, COUNT(CASE WHEN referral_generated THEN 1 END) as referrals, COUNT(*) as activities, ROUND(COUNT(CASE WHEN referral_generated THEN 1 END)*100.0/NULLIF(COUNT(*),0),1) as conv FROM LINCARE_DEMO.RAW_DATA.SALES_REP_ACTIVITY GROUP BY rep_name, territory ORDER BY referrals DESC LIMIT 15")
        if not reps.empty:
            fig = px.bar(reps, x='REP_NAME', y='REFERRALS', title="Top Reps by Referrals Generated", color='CONV', color_continuous_scale='Greens', text='REFERRALS')
            fig.update_xaxes(tickangle=45)
            st.plotly_chart(fig, use_container_width=True)

    with col2:
        market = run_query("SELECT state, SUM(total_claims) as market, SUM(CASE WHEN lincare_share THEN total_claims ELSE 0 END) as lincare, ROUND(SUM(CASE WHEN lincare_share THEN total_claims ELSE 0 END)*100.0/NULLIF(SUM(total_claims),0),1) as share FROM LINCARE_DEMO.RAW_DATA.CMS_RESPIRATORY_CLAIMS GROUP BY state ORDER BY share DESC LIMIT 15")
        if not market.empty:
            fig = px.bar(market, x='STATE', y='SHARE', title="Market Penetration by State (Top 15)", color='SHARE', color_continuous_scale='Blues', text='SHARE')
            fig.add_hline(y=35, line_dash="dash", line_color="green", annotation_text="Target: 35%")
            st.plotly_chart(fig, use_container_width=True)

    spec = run_query("SELECT physician_specialty, COUNT(*) as referrals, SUM(revenue) as revenue FROM LINCARE_DEMO.RAW_DATA.PHYSICIAN_REFERRALS GROUP BY physician_specialty ORDER BY referrals DESC")
    if not spec.empty:
        col1, col2 = st.columns(2)
        with col1:
            fig = px.pie(spec, values='REFERRALS', names='PHYSICIAN_SPECIALTY', title="Referrals by Physician Specialty", hole=0.4)
            st.plotly_chart(fig, use_container_width=True)
        with col2:
            fig = px.bar(spec, x='PHYSICIAN_SPECIALTY', y='REVENUE', title="Revenue by Specialty", color='REVENUE', color_continuous_scale='Greens')
            fig.update_xaxes(tickangle=45)
            st.plotly_chart(fig, use_container_width=True)

# ============================================================================
# TAB 4: CALL CENTER OPERATIONS
# ============================================================================
elif tab_selection == "Call Center Operations":
    st.markdown('<h1 class="main-header">Call Center Operations</h1>', unsafe_allow_html=True)
    st.markdown('<p style="text-align:center;color:#666;">Unified view across Avaya, Five9, and RingCentral</p>', unsafe_allow_html=True)

    col1, col2, col3, col4, col5 = st.columns(5)
    cc_kpis = run_query("""
        SELECT
            COUNT(*) as total_calls,
            ROUND(AVG(handle_time_seconds)/60.0,1) as avg_aht_min,
            ROUND(COUNT(CASE WHEN abandoned THEN 1 END)*100.0/COUNT(*),1) as abandon_rate,
            ROUND(COUNT(CASE WHEN first_call_resolution THEN 1 END)*100.0/NULLIF(COUNT(CASE WHEN NOT abandoned THEN 1 END),0),1) as fcr,
            ROUND(COUNT(CASE WHEN wait_time_seconds<=20 THEN 1 END)*100.0/NULLIF(COUNT(CASE WHEN direction='Inbound' THEN 1 END),0),1) as svc_level
        FROM LINCARE_DEMO.RAW_DATA.CALL_DETAIL_RECORDS
    """)
    if not cc_kpis.empty:
        with col1: metric_card("Total Calls", f"{cc_kpis['TOTAL_CALLS'].iloc[0]:,}", "Q1 2026", "📞")
        with col2: metric_card("Avg Handle Time", f"{cc_kpis['AVG_AHT_MIN'].iloc[0]:.1f} min", "Target varies", "⏱️")
        with col3: metric_card("Abandonment", f"{cc_kpis['ABANDON_RATE'].iloc[0]:.1f}%", "Target: <5%", "📵")
        with col4: metric_card("FCR Rate", f"{cc_kpis['FCR'].iloc[0]:.1f}%", "Target: >72%", "✅")
        with col5: metric_card("Service Level", f"{cc_kpis['SVC_LEVEL'].iloc[0]:.1f}%", "Target: 80% in 20s", "🎯")

    col1, col2 = st.columns(2)
    with col1:
        systems = run_query("SELECT phone_system, COUNT(*) as calls, ROUND(AVG(handle_time_seconds),0) as aht, ROUND(COUNT(CASE WHEN abandoned THEN 1 END)*100.0/COUNT(*),1) as abandon, ROUND(COUNT(CASE WHEN first_call_resolution THEN 1 END)*100.0/NULLIF(COUNT(CASE WHEN NOT abandoned THEN 1 END),0),1) as fcr, ROUND(AVG(wait_time_seconds),0) as asa FROM LINCARE_DEMO.RAW_DATA.CALL_DETAIL_RECORDS GROUP BY phone_system")
        if not systems.empty:
            st.markdown("### Phone System Comparison")
            st.dataframe(systems, use_container_width=True)

    with col2:
        types = run_query("SELECT call_type, COUNT(*) as calls, ROUND(AVG(handle_time_seconds)/60.0,1) as aht_min, ROUND(COUNT(CASE WHEN abandoned THEN 1 END)*100.0/COUNT(*),1) as abandon FROM LINCARE_DEMO.RAW_DATA.CALL_DETAIL_RECORDS WHERE direction='Inbound' GROUP BY call_type ORDER BY calls DESC")
        if not types.empty:
            fig = px.bar(types, x='CALL_TYPE', y='CALLS', title="Inbound Volume by Call Type", color='ABANDON', color_continuous_scale='RdYlGn_r', text='CALLS')
            st.plotly_chart(fig, use_container_width=True)

    col1, col2 = st.columns(2)
    with col1:
        weekly = run_query("SELECT DATE_TRUNC('week', call_date)::DATE as week, phone_system, COUNT(*) as calls FROM LINCARE_DEMO.RAW_DATA.CALL_DETAIL_RECORDS GROUP BY week, phone_system ORDER BY week")
        if not weekly.empty:
            fig = px.line(weekly, x='WEEK', y='CALLS', color='PHONE_SYSTEM', title="Weekly Call Volume by System", markers=True)
            st.plotly_chart(fig, use_container_width=True)

    with col2:
        sat = run_query("SELECT interaction_type, ROUND(AVG(overall_score),1) as score, ROUND(COUNT(CASE WHEN would_recommend THEN 1 END)*100.0/COUNT(*),0) as recommend FROM LINCARE_DEMO.RAW_DATA.PATIENT_SATISFACTION GROUP BY interaction_type ORDER BY score DESC")
        if not sat.empty:
            fig = px.bar(sat, x='INTERACTION_TYPE', y='SCORE', title="Patient Satisfaction by Interaction", color='RECOMMEND', text='SCORE', color_continuous_scale='Greens')
            st.plotly_chart(fig, use_container_width=True)

# ============================================================================
# TAB 5: AI ASSISTANT
# ============================================================================
elif tab_selection == "AI Assistant":
    st.markdown('<h1 class="main-header">Lincare AI Operations Assistant</h1>', unsafe_allow_html=True)
    st.markdown("""
    <p style="text-align:center;color:#666;margin-bottom:2rem;">
    Powered by Snowflake Intelligence Agent | Cortex Analyst + Cortex Search
    </p>""", unsafe_allow_html=True)

    st.info("💡 This assistant combines **structured data queries** (Cortex Analyst via Semantic View) with **policy document search** (Cortex Search). Ask about data OR policies!")

    col1, col2, col3 = st.columns(3)
    with col1:
        st.markdown("**📊 Data Questions**")
        st.markdown("- What is our denial rate by payer?")
        st.markdown("- Top 5 reps by referrals?")
        st.markdown("- Call abandonment by system?")
    with col2:
        st.markdown("**📋 Policy Questions**")
        st.markdown("- CMN requirements for oxygen?")
        st.markdown("- Appeal timeline for Medicare?")
        st.markdown("- Call center SLA targets?")
    with col3:
        st.markdown("**🔗 Combined Questions**")
        st.markdown("- Denial rate vs policy target?")
        st.markdown("- Why are CPAP claims denied?")
        st.markdown("- How to fix CO-16 denials?")

    st.markdown("---")
    st.markdown("### Chat with Lincare Operations Agent")
    st.markdown("Access the full agent experience at: **AI & ML > Snowflake Intelligence** in Snowsight")
    st.markdown("Agent: `SNOWFLAKE_INTELLIGENCE.AGENTS.LINCARE_OPERATIONS_AGENT`")

    user_question = st.text_input("Ask a question about Lincare operations:", placeholder="e.g., What is our denial rate for Medicare CPAP claims?")
    if user_question:
        st.markdown(f"**Your question:** {user_question}")
        st.info("For the full conversational experience with tool orchestration, use the Snowflake Intelligence UI. This embedded view demonstrates the concept.")

        if "denial" in user_question.lower():
            result = run_query("SELECT payer_name, ROUND(COUNT(CASE WHEN claim_status='DENIED' THEN 1 END)*100.0/COUNT(*),2) as denial_rate, COUNT(*) as total_claims FROM LINCARE_DEMO.RAW_DATA.CLAIMS_SUBMISSIONS GROUP BY payer_name ORDER BY denial_rate DESC")
            if not result.empty:
                st.dataframe(result, use_container_width=True)
                st.markdown("**Policy context:** Per CLM-001, the target denial rate is <5% (industry best-in-class). Current rate significantly exceeds target across all payers. Key actions: Verify CMN completeness, confirm PECOS enrollment, check modifier accuracy.")
        elif "referral" in user_question.lower() or "rep" in user_question.lower():
            result = run_query("SELECT rep_name, territory, COUNT(CASE WHEN referral_generated THEN 1 END) as referrals, ROUND(COUNT(CASE WHEN referral_generated THEN 1 END)*100.0/COUNT(*),1) as conversion_rate FROM LINCARE_DEMO.RAW_DATA.SALES_REP_ACTIVITY GROUP BY rep_name, territory ORDER BY referrals DESC LIMIT 10")
            if not result.empty:
                st.dataframe(result, use_container_width=True)
                st.markdown("**Policy context:** Per SLS-001, target conversion rate is 12-18%. Monthly activity minimums: 60 office visits, 80 phone contacts, 4 lunch meetings, 2 in-services.")
        elif "call" in user_question.lower() or "abandon" in user_question.lower():
            result = run_query("SELECT phone_system, COUNT(*) as total_calls, ROUND(COUNT(CASE WHEN abandoned THEN 1 END)*100.0/COUNT(*),2) as abandon_rate, ROUND(AVG(wait_time_seconds),0) as avg_wait, ROUND(COUNT(CASE WHEN first_call_resolution THEN 1 END)*100.0/NULLIF(COUNT(CASE WHEN NOT abandoned THEN 1 END),0),1) as fcr FROM LINCARE_DEMO.RAW_DATA.CALL_DETAIL_RECORDS GROUP BY phone_system")
            if not result.empty:
                st.dataframe(result, use_container_width=True)
                st.markdown("**Policy context:** Per CC-001, SLA target is 80/20 (80% answered within 20 seconds). Abandonment target: <5%. FCR target: >72%. Critical threshold at >10% abandonment triggers immediate staffing review.")
        else:
            st.markdown("Try asking about denials, referrals, sales reps, or call center metrics!")

# Footer
st.markdown("---")
st.caption("Lincare Operations Dashboard | Powered by Snowflake | Dynamic Tables + Semantic View + Cortex Search + Intelligence Agent")
