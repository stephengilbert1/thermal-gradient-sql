-- 02_vertical_profile.sql

SELECT r.device_serial,
       r.position_index,
       s.height,
       s.submerged,
       AVG(r.temperature) AS mean_temp
FROM readings AS r
JOIN sensors AS s ON r.position_index = s.position_index
GROUP BY r.device_serial, r.position_index, s.height, s.submerged
ORDER BY r.device_serial, r.position_index;