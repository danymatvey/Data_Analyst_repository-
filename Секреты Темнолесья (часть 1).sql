/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: Матвеев Даниил Алексеевич, группа da_123
 * Дата: 20.04.2025 г.
*/

-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков

-- 1.1. Доля платящих пользователей по всем данным:
-- Напишите ваш запрос здесь
SELECT 
COUNT (id) AS Всего_игроков,
sum (payer) AS Кол_во_платящих,
ROUND(AVG(payer),4) as Доля_платящих_от_всех
FROM fantasy.users;
-- 1.2. Доля платящих пользователей в разрезе расы персонажа:
-- Напишите ваш запрос здесь
SELECT 
 r.race  as Раса_персонажа,
 sum (payer) AS Кол_во_платящих,
 COUNT ( id) AS Всего_игроков,
 ROUND (AVG(payer),4) AS Доля_платящих_от_расы
 FROM fantasy.users AS u
 Left join fantasy.race AS r ON r.race_id=u.race_id
 GROUP BY DISTINCT  race
ORDER BY Кол_во_платящих
-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:
-- Напишите ваш запрос здесь
SELECT
count (amount) AS Общее_кол_во_покупок,
SUM (amount) AS Суммарная_стоимость_покупок,
MAX(amount)AS Максимальная_покупка,
MIN(amount)AS Минимальная_покупка,
AVG(amount)::NUMERIC (10,2) AS Средняя_покупка,
PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY amount) AS Медиана_покупки,
STDDEV(amount)::NUMERIC (10,2) AS Среднеквадратическое_отклонение
FROM fantasy.events;

-- 2.2: Аномальные нулевые покупки:
-- Напишите ваш запрос здесь
SELECT (SELECT
count(amount) AS Кол_во_нулевых_покупок
FROM fantasy.events
WHERE amount=0),
(SELECT
count(amount) AS Кол_во_нулевых_покупок
FROM fantasy.events
WHERE amount=0)/
count(amount)::REAL AS Доля_нулевых_покупок
FROM fantasy.events;
-- 2.3: Сравнительный анализ активности платящих и неплатящих игроков:
-- Напишите ваш запрос здесь
WITH player_stat as(
SELECT
      u.payer AS payer
      , e.id AS user_id
      , COUNT(e.transaction_id) AS total_orders
      , SUM(e.amount) AS total_amount
    FROM
      fantasy.events AS e
      LEFT JOIN fantasy.users AS u ON e.id = u.id
    WHERE e.amount > 0
    GROUP BY
      u.payer
      , e.id)
      SELECT 
      CASE WHEN payer=1 THEN 'Платящий' ELSE 'Неплатящий' END,
      count	(payer) AS Кол_во_игроков_по_категориям,
      AVG(total_orders) AS Среднее_кол_во_заказов_на_игрока,
      AVG(total_amount) AS Средняя_суммарная_стоимость_покупок_на_игрока
      FROM player_stat 
      GROUP BY payer;
-- 2.4: Популярные эпические предметы:
-- Напишите ваш запрос здесь
SELECT
i.game_items AS Вид_эпического_предмета,
COUNT(transaction_id) AS Общее_кол_во_продаж,
COUNT(transaction_id)/
(SELECT
count (amount)
FROM fantasy.events
WHERE amount>0)::REAL AS Доля_продажи,
AVG	(u.payer) AS Доля_платящих_по_предметам,
COUNT (DISTINCT e.id)/ (SELECT   
    COUNT (DISTINCT id)
    FROM fantasy.events e)::real AS Доля_игроков_купивших_предмет
FROM fantasy.events e 
JOIN fantasy.items AS i ON i.item_code =e.item_code 
JOIN fantasy.users AS u ON u.id=e.id
GROUP BY i.game_items
ORDER BY Общее_кол_во_продаж DESC;
-- Часть 2. Решение ad hoc-задач
-- Задача 1. Зависимость активности игроков от расы персонажа:
-- Напишите ваш запрос здесь
WITH total_users_race AS (
    SELECT
      r.race AS race
      , COUNT(u.id) AS count_users
    FROM
      fantasy.users AS u
      LEFT JOIN fantasy.race AS r ON u.race_id = r.race_id
    GROUP BY r.race),
player_stat as(
   SELECT
      r.race AS race,
      u.payer AS payer, 
      e.id,
      COUNT (DISTINCT u.id) AS total_players,
      COUNT(e.transaction_id) AS total_orders,
      SUM(e.amount) AS total_amount
    FROM
      fantasy.events AS e
      JOIN fantasy.users AS u ON e.id = u.id
      JOIN fantasy.race AS r ON r.race_id=u.race_id
    WHERE e.amount > 0
    GROUP BY
      u.payer,
      e.id,
      r.race)
  SELECT 
      ps.race,
      count_users AS Всего_зарегистрированных_игроков,
     COUNT (id) AS Всего_игроков_покупающих,
     COUNT (id)/count_users::real AS Доля_покупающих_из_общих,
     SUM(payer) AS Кол_во_платящих_из_покупающих,
     AVG (payer) AS Доля_платящих_из_покупающих,
     AVG(total_orders) AS Среднее_кол_во_покупок_на_игрока,
     AVG(total_amount)/ AVG(total_orders) AS Средняя_стоимость_покупки_на_игрока,
     AVG(total_amount) AS Средняя_суммарная_стоимость_покупок_на_игрока
      FROM player_stat AS ps
      JOIN total_users_race AS tur ON tur.race =ps.race 
      GROUP BY ps.race,count_users;


-- Задача 2: Частота покупок
-- Напишите ваш запрос здесь
не делал :)
