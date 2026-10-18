# Расчет продуктовых метрик и анализ A/B-теста (Яндекс Практикум, август 2026)

## Задача
Проект состоит из двух частей:
1. **Яндекс Книги:** Рассчитать ключевые продуктовые метрики (MAU, Retention Rate, LTV) с помощью SQL и проверить статистическую гипотезу о различиях в поведении пользователей из Москвы и Санкт-Петербурга.
2. **BitMotion Kit:** Оценить корректность проведения A/B-теста нового интерфейса и проанализировать его результаты (изменение конверсии в покупку).

## Инструменты
* **SQL:** агрегация данных, оконные функции (для Retention и LTV).
* **Python (Jupyter Notebook):** pandas, scipy, statsmodels, matplotlib.
* **Методы:** непараметрический U-тест Манна-Уитни, Z-тест для долей, расчет размера выборки (MDE).

## Примеры SQL-запросов (Яндекс Книги)
*Часть запросов была выполнена в тренажере платформы. Ниже приведены ключевые примеры логики.*

**1. Расчет Retention Rate (когорта 2 декабря):**
```sql
WITH cohort AS (
    SELECT puid, MIN(msk_business_dt_str::date) AS first_day
    FROM bookmate.audition
    WHERE msk_business_dt_str::date = '2024-12-02'
    GROUP BY puid
),
activity AS (
    SELECT a.puid, a.msk_business_dt_str::date - c.first_day AS day_since_install
    FROM bookmate.audition a
    JOIN cohort c ON a.puid = c.puid
)
SELECT 
    day_since_install,
    COUNT(DISTINCT puid) AS retained_users,
    ROUND(COUNT(DISTINCT puid)::numeric / MAX(COUNT(DISTINCT puid)) OVER ()::numeric, 2) AS retention_rate
FROM activity
GROUP BY day_since_install
ORDER BY day_since_install;

**2. Расчет LTV по городам::**
```sql
SELECT 
    g.usage_geo_id_name AS city,
    COUNT(DISTINCT a.puid) AS total_users,
    ROUND(COUNT(DISTINCT a.puid) * 399.0 / COUNT(DISTINCT a.puid), 2) AS ltv 
FROM bookmate.audition a
JOIN bookmate.geo g ON a.usage_geo_id = g.usage_geo_id
WHERE g.usage_geo_id_name IN ('Москва', 'Санкт-Петербург')
GROUP BY g.usage_geo_id_name;
