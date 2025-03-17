with AdsData as (
select 
	fabd.ad_date,
	fabd.url_parameters,
	fabd.spend,
	fabd.impressions,
	fabd.reach,
	fabd.clicks,
	fabd.leads,
	fabd.value 
from facebook_ads_basic_daily fabd  
union all 
select 
	ad_date,
	url_parameters,
	spend,
	impressions,
	reach,
	clicks,
	leads,
	value
from google_ads_basic_daily
),
AdsData_2 as (
select 
	ad_date,
	date_trunc('month', ad_date)::date as ad_month,
	case 
		when lower(substring(url_parameters,'utm_campaign=([^/&]+)')) ='nan' then null
		else decode_url_part3(substring(url_parameters,'utm_campaign=([^/&]+)'))
	end as utm_campaign,
	coalesce(sum(spend),0) as total_spend,
	coalesce(sum(impressions),0) as total_impressions,
	coalesce(sum(reach),0) as total_reach,
	coalesce(sum(clicks),0)as total_clicks,
	coalesce(sum(leads),0) as total_leads,
	coalesce(sum(value),0) as total_value,
	case
		when sum(clicks) > 0 then coalesce(sum(spend)/sum(clicks),0)
		else 0
	end as CPC,
	case 
		when sum(impressions) > 0 then coalesce(sum(spend)::float/sum(impressions)*1000,0)
		else 0
	end as CPM,
	case
		when sum(impressions) > 0 then coalesce((sum(clicks)::float/sum(impressions))*100,0)
		else 0
	end as CTR,
	case 
		when sum(spend) > 0 then coalesce(((sum(value)::float-sum(spend))/sum(spend))*100,0)
		else 0
	end as ROMI
from adsdata
group by 1,2,3
),
AdsData_3 as (
select 
	ad_month,
	utm_campaign,
	total_spend,
	total_impressions,
	total_clicks,
	total_value,
	cpc,
	cpm,
	ctr,
	romi,
	lag(CPM) over (
		partition by utm_campaign 
		order by ad_month
		) as prev_CPM,
    lag(CTR) over (
    	partition by utm_campaign 
    	order by ad_month
    	) as prev_CTR,
    lag(ROMI) over (
    	partition by utm_campaign 
    	order by ad_month
    	) as prev_ROMI
from adsdata_2
order by utm_campaign, ad_month
)
select
	ad_month,
	utm_campaign,
	total_spend,
	total_impressions,
	total_clicks,
	total_value,
	cpc,
	cpm,
	ctr,
	romi,
	prev_CPM,
	prev_CTR,
	prev_ROMI,
	case 
        when prev_CPM is not null then ((CPM - prev_CPM) / prev_CPM) * 100
        else null
    end as current_CPM,
    case 
        when prev_CTR is not null then ((CTR - prev_CTR) / prev_CTR) * 100
        ELSE NULL
    end as current_CTR,
    case 
        when prev_ROMI is not null then ((ROMI - prev_ROMI) / prev_ROMI) * 100
        else null
    end as current_ROMI
from adsdata_3
where prev_CPM > 0 and prev_CTR > 0 and prev_ROMI > 0
order by 
	utm_campaign, 
	ad_month;