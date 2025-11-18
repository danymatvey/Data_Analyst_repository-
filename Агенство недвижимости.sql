/* Проект первого модуля: анализ данных для агентства недвижимости
 * Часть 2. Решаем ad hoc задачи
 * 
 * Автор: Матвеев Даниил, da_123
 * Дата: 13 мая 2025 г.
*/

-- Пример фильтрации данных от аномальных значений
-- Определим аномальные значения (выбросы) по значению перцентилей:
WITH limits AS (
    SELECT
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats
),
-- Найдем id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    )
-- Выведем объявления без выбросов:
SELECT *
FROM real_estate.flats
WHERE id IN (SELECT * FROM filtered_id);


-- Задача 1: Время активности объявлений
-- Результат запроса должен ответить на такие вопросы:
-- 1. Какие сегменты рынка недвижимости Санкт-Петербурга и городов Ленинградской области 
--    имеют наиболее короткие или длинные сроки активности объявлений?
-- 2. Какие характеристики недвижимости, включая площадь недвижимости, среднюю стоимость квадратного метра, 
--    количество комнат и балконов и другие параметры, влияют на время активности объявлений? 
--    Как эти зависимости варьируют между регионами?
-- 3. Есть ли различия между недвижимостью Санкт-Петербурга и Ленинградской области по полученным результатам?

SELECT 
case when c.city='Санкт-Петербург' then 'Санкт-Петербург' else 'ЛенОбл' end as Регион,
case when a.days_exposition between 1 and 30 then '1до_месяца'
 when a.days_exposition between 31 and 90 then '2до_3_месяцев'
 when a.days_exposition between 91 and 180 then '3до_полугода'
 when a.days_exposition>='181' then '4более_полугода' end as Сегмент_активности,
AVG (last_price/total_area) as Средняя_стоимость_квм,
AVG(total_area) as Средняя_площадь,
PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY rooms  ) as Медиана_комнат,
PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY balcony ) as Медиана_балконов,
PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY floor ) as Медиана_этажей
FROM real_estate.flats f
join real_estate.city c on c.city_id = f.city_id 
JOIN real_estate.advertisement a on a.id = f.id
WHERE f.id IN (SELECT * FROM filtered_id) and days_exposition is not null and type_id ='F8EM'
group BY Регион, Сегмент_активности
order by Регион desc, Сегмент_активности ASC;

-- Задача 2: Сезонность объявлений
-- Результат запроса должен ответить на такие вопросы:
-- 1. В какие месяцы наблюдается наибольшая активность в публикации объявлений о продаже недвижимости? 
--    А в какие — по снятию? Это показывает динамику активности покупателей.
-- 2. Совпадают ли периоды активной публикации объявлений и периоды, 
--    когда происходит повышенная продажа недвижимости (по месяцам снятия объявлений)?
-- 3. Как сезонные колебания влияют на среднюю стоимость квадратного метра и среднюю площадь квартир? 
--    Что можно сказать о зависимости этих параметров от месяца?

--Анализ по публикациям
SELECT 
COUNT(f.id) as Кол_во_объявлений,
extract (month from first_day_exposition) as Месяц_публикации,
AVG (last_price/total_area) as  Средняя_стоимость_квм,
AVG(total_area) as Средняя_площадь
FROM real_estate.flats f 
JOIN real_estate.advertisement a on a.id = f.id
WHERE f.id IN (SELECT * FROM filtered_id) and type_id ='F8EM'
group by Месяц_публикации
order by Кол_во_объявлений DESC;
   --Анализ по снятиям
SELECT 
COUNT(f.id) as Кол_во_объявлений,
extract (month from (first_day_exposition::date  + days_exposition::INT)) as Месяц_снятия,
AVG (last_price/total_area) as  Средняя_стоимость_квм,
AVG(total_area) as Средняя_площадь
FROM real_estate.flats f 
JOIN real_estate.advertisement a on a.id = f.id
WHERE f.id IN (SELECT * FROM filtered_id) and days_exposition is not null and type_id ='F8EM'
group by Месяц_снятия
order by Кол_во_объявлений DESC;


-- Задача 3: Анализ рынка недвижимости Ленобласти
-- Результат запроса должен ответить на такие вопросы:
-- 1. В каких населённые пунктах Ленинградской области наиболее активно публикуют объявления о продаже недвижимости?
SELECT 
c.city,
COUNT(f.id) as Кол_во_объявлений
FROM real_estate.flats f
join real_estate.city c on c.city_id = f.city_id 
JOIN real_estate.advertisement a on a.id = f.id
WHERE f.id IN (SELECT * FROM filtered_id) and c.city !='Санкт-Петербург'
group BY  c.city 
order by Кол_во_объявлений desc
limit 15;
-- 2. В каких населённых пунктах Ленинградской области — самая высокая доля снятых с публикации объявлений? 
--    Это может указывать на высокую долю продажи недвижимости.
select
city,
COUNT(f.id) FILTER(WHERE days_exposition IS NOT NULL) as Кол_во_снятых_объявлений,
COUNT(f.id) FILTER(WHERE days_exposition IS NOT NULL) / COUNT(f.id)::real as Доля_снятых_объявлений
FROM real_estate.flats f
join real_estate.city c on c.city_id = f.city_id 
JOIN real_estate.advertisement a on a.id = f.id
WHERE f.id IN (SELECT * FROM filtered_id) and c.city !='Санкт-Петербург' 
group by city
order by Кол_во_снятых_объявлений DESC;
-- 3. Какова средняя стоимость одного квадратного метра и средняя площадь продаваемых квартир в различных населённых пунктах? 
--    Есть ли вариация значений по этим метрикам?
SELECT
c.city,
COUNT(f.id) as Кол_во_объявлений,
AVG (last_price/total_area) as  Средняя_стоимость_квм,
AVG(total_area) as Средняя_площадь
FROM real_estate.flats f
join real_estate.city c on c.city_id = f.city_id 
JOIN real_estate.advertisement a on a.id = f.id
WHERE f.id IN (SELECT * FROM filtered_id) and c.city !='Санкт-Петербург'and days_exposition is not null
group BY  c.city 
order by  Средняя_площадь desc
-- 4. Среди выделенных населённых пунктов какие пункты выделяются по продолжительности публикации объявлений? 
--    То есть где недвижимость продаётся быстрее, а где — медленнее.
 SELECT
    c.city,
COUNT(f.id) as Кол_во_объявлений,
avg (days_exposition )/30 as Среднее_время_объявления
FROM real_estate.flats f
join real_estate.city c on c.city_id = f.city_id 
JOIN real_estate.advertisement a on a.id = f.id
WHERE f.id IN (SELECT * FROM filtered_id) and c.city !='Санкт-Петербург' and days_exposition is not null
group BY  c.city
order by Кол_во_объявлений DESC;
