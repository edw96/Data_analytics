with AdsData as (
select 
	fabd.ad_date,
	fc.campaign_name,
	fabd.spend,
	fabd.impressions,
	fabd.reach,
	fabd.clicks,
	fabd.leads,
	fabd.value 
from facebook_ads_basic_daily fabd 
left join facebook_campaign fc on fabd.campaign_id=fc.campaign_id
left join facebook_adset fa on fabd.adset_id=fa.adset_id 
union all 
select 
	ad_date,
	campaign_name,
	spend,
	impressions,
	reach,
	clicks,
	leads,
	value
from google_ads_basic_daily
)
select 
	ad_date,
	campaign_name,
	sum(spend) as total_spend,
	sum(impressions) as total_impressions,
	sum(clicks) as total_clicks,
	sum(value) as total_value,
	((sum(value)-sum(spend))::float/sum(spend))*100 as ROMI
from AdsData
where spend > 0
group by 
	ad_date,
	campaign_name
having sum(spend) > 500000
order by romi desc;


