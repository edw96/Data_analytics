select*from facebook_ads_basic_daily fabd;
select*from facebook_adset fa;
select*from facebook_campaign fc;
select*from google_ads_basic_daily gabd;

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
order by ad_date
)
select 
	spend,
	impressions,
	reach,
	clicks,
	leads,
	value
from adsdata

