
WITH clean_date AS -------Очищення даних таблиці cohort_users_raw
(-----------обрізка компонентів часу, заміна делімітерів
	SELECT *,
	SPLIT_PART(REGEXP_REPLACE(trim(signup_datetime), '[./]', '-', 'g'),' ',1) as signup_date_clean
	FROM public.cohort_users_raw as u
),
users_parsed AS
(SELECT user_id, promo_signup_flag,
	CASE --------------Формування коректної дати
	WHEN signup_date_clean ~ '^[0-9]{1,2}-[0-9]{1,2}-[0-9]{4}$'
      THEN TO_DATE(signup_date_clean, 'DD-MM-YYYY')
   	WHEN signup_date_clean ~ '^[0-9]{1,2}-[0-9]{1,2}-[0-9]{2}$'
      THEN TO_DATE(signup_date_clean, 'DD-MM-YY')
    ELSE NULL
  END AS signup_ts
FROM clean_date
),
-------Очищення даних таблиці cohort_events_raw
clean_date_ev AS 
(-----------обрізка компонентів часу, заміна делімітерів
	SELECT *,
	SPLIT_PART(REGEXP_REPLACE(trim(event_datetime), '[./]', '-', 'g'),' ',1) as event_date_clean
	FROM public.cohort_events_raw AS e
),
events_parsed as
(
SELECT user_id, event_type,
	CASE --------------Формування коректної дати
	WHEN event_date_clean ~ '^[0-9]{1,2}-[0-9]{1,2}-[0-9]{4}$'
      THEN TO_DATE(event_date_clean, 'DD-MM-YYYY')
   	WHEN event_date_clean ~ '^[0-9]{1,2}-[0-9]{1,2}-[0-9]{2}$'
      THEN TO_DATE(event_date_clean, 'DD-MM-YY')
    ELSE NULL
  END AS events_ts
FROM clean_date_ev
),
user_activity as
(------Вигначення когорт користувачів 
select 
	u.user_id,
	date_trunc('month', signup_ts)::date as cohort_month,
	u.promo_signup_flag,
	date_trunc('month', events_ts)::date as activity_month,
	EXTRACT(MONTH FROM age(events_ts, signup_ts))as month_offset
from users_parsed u
join events_parsed e on u.user_id=e.user_id
-----Фільтрування даних від нульвих та відсутніх значень
	where signup_ts is not null
	and events_ts is not null
	and event_type is not null
	and event_type<>'test_event'
)
select
	promo_signup_flag,
	cohort_month,
	month_offset,
	count(distinct user_id) as users_total
FROM user_activity
where activity_month between '2025-01-01' and '2025-06-01'
group by 
	promo_signup_flag,
	cohort_month,
	month_offset
order by
	promo_signup_flag,
	cohort_month,
	month_offset
	;