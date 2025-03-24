CREATE OR REPLACE FUNCTION decode_url_part(p varchar) RETURNS varchar AS $$
SELECT convert_from(CAST(E'\\x' || array_to_string(ARRAY(
    SELECT CASE WHEN length(r.m[1]) = 1 THEN encode(convert_to(r.m[1], 'SQL_ASCII'), 'hex') ELSE substring(r.m[1] from 2 for 2) END
    FROM regexp_matches($1, '%[0-9a-f][0-9a-f]|.', 'gi') AS r(m)
), '') AS bytea), 'UTF8');
$$ LANGUAGE SQL IMMUTABLE STRICT;


with AdsData as (
select 
	fabd.ad_date,
	fabd.url_parameters,
	fc.campaign_name,
	fa.adset_name,
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
	url_parameters,
	campaign_name,
	adset_name,
	spend,
	impressions,
	reach,
	clicks,
	leads,
	value
from google_ads_basic_daily
)
SELECT 
	ad_date,
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
group by 1,2;



