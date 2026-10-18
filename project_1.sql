/* Проект первого модуля: анализ данных для агентства недвижимости
 * Часть 2. Решаем ad hoc задачи
 * 
 * Автор: Бавин Максим
 * Дата: 13.04.2026
*/



-- Задача 1: Время активности объявлений
-- Определим аномальные значения (выбросы) по значению перцентилей:
WITH limits AS (
    SELECT
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_CONT(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats
),
filtered_id AS(
    SELECT id
    FROM real_estate.flats
    WHERE
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
),
prepared_data AS (
    SELECT 
        a.days_exposition,
        a.last_price,
        f.total_area,
        f.rooms,
        f.balcony,
        CASE 
            WHEN c.city = 'Санкт-Петербург' THEN 'СПБ'
            ELSE 'ЛенОбл'
        END AS region,
        CASE 
            WHEN a.days_exposition IS NULL THEN 'non category'
            WHEN a.days_exposition BETWEEN 1 AND 30 THEN '1-30 days'
            WHEN a.days_exposition BETWEEN 31 AND 90 THEN '31-90 days'
            WHEN a.days_exposition BETWEEN 91 AND 180 THEN '91-180 days'
            WHEN a.days_exposition >= 181 THEN '181+ days'
        END AS days_category,
        a.last_price / NULLIF(f.total_area, 0) AS sqm_price
    FROM real_estate.advertisement a
    JOIN real_estate.flats f ON a.id = f.id
    JOIN real_estate.city c ON f.city_id = c.city_id
    JOIN real_estate.type t ON f.type_id = t.type_id
    WHERE a.id IN (SELECT id FROM filtered_id)
      AND t.type = 'город'
      AND EXTRACT(YEAR FROM a.first_day_exposition) BETWEEN 2015 AND 2018
)
SELECT 
    region,
    days_category,
    COUNT(*) AS ads_count,
    ROUND(AVG(sqm_price)::numeric, 2) AS avg_sqm_price,
    ROUND(AVG(total_area)::numeric, 2) AS avg_total_area,
    ROUND(AVG(rooms)::numeric, 2) AS avg_rooms,
    ROUND(AVG(balcony)::numeric, 2) AS avg_balcony
FROM prepared_data
GROUP BY region, days_category
ORDER BY region, 
    CASE days_category
        WHEN '1-30 days' THEN 1
        WHEN '31-90 days' THEN 2
        WHEN '91-180 days' THEN 3
        WHEN '181+ days' THEN 4
        WHEN 'non category' THEN 5
    END;



-- Задача 2: Сезонность объявлений
-- Определим аномальные значения (выбросы) по значению перцентилей:
WITH limits AS (
    SELECT
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_CONT(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats
),
-- Найдём id объявлений, которые не содержат выбросы, также оставим пропущенные данные:
filtered_id AS(
    SELECT id
    FROM real_estate.flats
    WHERE
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    ),
-- Продолжите запрос здесь
-- Используйте id объявлений (СТЕ filtered_id), которые не содержат выбросы при анализе данных
prepared_data AS (
    SELECT 
        EXTRACT(MONTH FROM a.first_day_exposition) AS month_published,
        EXTRACT(MONTH FROM a.first_day_exposition + (a.days_exposition || ' days')::INTERVAL) AS month_removed,
        a.last_price / NULLIF(f.total_area, 0) AS sqm_price,
        f.total_area
    FROM real_estate.advertisement a
    JOIN real_estate.flats f ON a.id = f.id
    JOIN real_estate.city c ON f.city_id = c.city_id
    JOIN real_estate.type t ON f.type_id = t.type_id
    WHERE a.id IN (SELECT id FROM filtered_id)
      AND t.type = 'город'
      AND EXTRACT(YEAR FROM a.first_day_exposition) BETWEEN 2015 AND 2018
),
published_stats AS (
    SELECT 
        month_published AS month_num,
        COUNT(*) AS published_count,
        ROUND(AVG(sqm_price)::numeric, 2) AS published_avg_sqm_price,
        ROUND(AVG(total_area)::numeric, 2) AS published_avg_area
    FROM prepared_data
    GROUP BY month_published
),
removed_stats AS (
    SELECT 
        month_removed AS month_num,
        COUNT(*) AS removed_count,
        ROUND(AVG(sqm_price)::numeric, 2) AS removed_avg_sqm_price,
        ROUND(AVG(total_area)::numeric, 2) AS removed_avg_area
    FROM prepared_data
    WHERE month_removed IS NOT NULL
    GROUP BY month_removed
)
SELECT 
    COALESCE(p.month_num, r.month_num) AS month,
    COALESCE(p.published_count, 0) AS published_count,
    COALESCE(r.removed_count, 0) AS removed_count,
    p.published_avg_sqm_price,
    p.published_avg_area,
    r.removed_avg_sqm_price,
    r.removed_avg_area
FROM published_stats p
FULL JOIN removed_stats r ON p.month_num = r.month_num
ORDER BY month;