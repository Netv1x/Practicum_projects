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

Ключевые результаты
Проверка гипотезы (Яндекс Книги): С помощью U-теста Манна-Уитни (выбран из-за ненормального распределения данных) установлено, что статистически значимых различий в средней активности пользователей СПб и Москвы нет (p-value > 0.05).

Корректность A/B-теста: В ходе проверки данных обнаружено 887 пересечений пользователей с конкурирующим тестом, что могло повлиять на результаты. Требуемая выборка составляла 3 763 пользователя на группу.

Результаты A/B-теста: Конверсия в покупку в тестовой группе B составила 35.3% против 32.8% в контрольной группе A (+2.5 п.п.). Различие статистически значимо (z-тест, p-value = 0.0029), однако фактический прирост не достиг целевого показателя в +3 п.п.

Файлы в репозитории
metrics_and_ab_test.ipynb — Jupyter Notebook с Python-кодом для проверки гипотез, статистических тестов и визуализаций.
