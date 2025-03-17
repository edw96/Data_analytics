select ad_date,
       campaign_id,
       sum(spend)/sum(clicks) as CPC,
       cast(sum(spend) as float)/sum(impressions)*1000 as CPM,
       cast(sum(clicks) as float)/sum(impressions)*100 as CTR,
       (cast((sum(value)-sum(spend)) as float)/sum(spend))*100 as ROMI
from facebook_ads_basic_daily
where clicks > 0 and impressions > 0 and spend > 0
group by ad_date,campaign_id
order by ad_date,campaign_id;




       