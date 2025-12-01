--Ejercicio 1--
SELECT 
    ID ,
    MAX(Profesional) AS PROFESIONAL,
    SUM(asesoria_banca) AS "NRO ASESORIA BANCA",
    TO_CHAR(SUM(honorarios_banca), '$999,999,999') AS MONTO_TOTAL_BANCA,
    SUM(asesoria_retail) AS "NRO ASESORIA RETAIL",
    TO_CHAR(SUM(honorarios_retail), '$999,999,999') AS MONTO_TOTAL_RETAIL,
    SUM(asesoria_banca) + SUM(asesoria_retail) AS "TOTAL ASESORIAS",
    TO_CHAR(SUM(honorarios_banca) + SUM(honorarios_retail), '$999,999,999') AS "TOTAL HONORARIOS"
FROM (
    SELECT  
        pro.id_profesional AS ID,
        INITCAP(pro.appaterno || ' ' || pro.apmaterno || ' ' || pro.nombre) AS Profesional,
        COUNT(*) AS asesoria_banca,
        SUM(ase.honorario) AS honorarios_banca,
        0 AS asesoria_retail,
        0 AS honorarios_retail
    FROM profesional pro 
    JOIN asesoria ase ON pro.id_profesional = ase.id_profesional
    JOIN empresa emp ON ase.cod_empresa = emp.cod_empresa
    WHERE emp.cod_sector = 3
    GROUP BY pro.id_profesional, pro.appaterno, pro.apmaterno, pro.nombre
    UNION ALL 
    SELECT 
        pro.id_profesional AS ID,
        INITCAP(pro.appaterno || ' ' || pro.apmaterno || ' ' || pro.nombre) AS Profesional,
        0 AS asesoria_banca,
        0 AS honorarios_banca,
        COUNT(*) AS asesoria_retail,
        SUM(ase.honorario) AS honorarios_retail
    FROM profesional pro 
    JOIN asesoria ase ON pro.id_profesional = ase.id_profesional
    JOIN empresa emp ON ase.cod_empresa = emp.cod_empresa
    WHERE emp.cod_sector = 4
    GROUP BY pro.id_profesional, pro.appaterno, pro.apmaterno, pro.nombre
)
WHERE id IN (
    SELECT ase.id_profesional
    FROM asesoria ase
    JOIN empresa emp ON ase.cod_empresa = emp.cod_empresa
    WHERE emp.cod_sector = 3
    INTERSECT
    SELECT ase.id_profesional
    FROM asesoria ase
    JOIN empresa emp ON ase.cod_empresa = emp.cod_empresa
    WHERE emp.cod_sector = 4
)
GROUP BY id
ORDER BY id ASC;

--Ejercicio 2--

CREATE TABLE REPORTE_MES AS
SELECT pro.id_profesional AS ID_PROF,
       INITCAP(pro.appaterno ||' '|| pro.apmaterno ||' '|| pro.nombre) AS NOMBRE_COMPLETO,
       INITCAP(pn.nombre_profesion) AS NOMBRE_PROFESION,
       INITCAP(c.nom_comuna) AS NOM_COMUNA,
       COUNT(ase.cod_empresa) AS NRO_ASESORIAS,
       SUM(honorario) AS MONTO_TOTAL_HONORARIO,
       ROUND(AVG(honorario), 0) AS PROMEDIO_HONORARIO,
       MIN(honorario) AS HONORARIO_MINIMO,
       MAX(honorario) AS HONORARIO_MAXIMO
FROM  profesional pro JOIN profesion pn
                      ON  pro.cod_profesion = pn.cod_profesion
                      JOIN comuna c
                      ON pro.cod_comuna= c.cod_comuna
                      JOIN asesoria ase
                      ON pro.id_profesional=ase.id_profesional
WHERE EXTRACT(MONTH FROM ase.fin_asesoria) = 4
  AND EXTRACT(YEAR FROM ase.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) - 1
GROUP BY pro.id_profesional, pro.appaterno, pro.apmaterno, pro.nombre,
         pn.nombre_profesion, c.nom_comuna
ORDER BY pro.id_profesional ASC;

--Ejercicio 3--
--Creación de tabla para guardar los datos antes de ser actualizados--
CREATE TABLE HONORARIOS_ANTES_MODIFICACION AS
SELECT SUM(ase.honorario) AS HONORARIO,
       pro.id_profesional AS  ID_PROFESIONAL,
       pro.numrun_prof AS NUMRUN_PROF,
       pro.sueldo AS SUELDO
FROM profesional pro JOIN asesoria ase
                     ON pro.id_profesional = ase.id_profesional
WHERE EXTRACT (MONTH FROM ase.fin_asesoria)=3 
      AND EXTRACT(YEAR FROM ase.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE)-1
GROUP BY pro.id_profesional,pro.numrun_prof, pro.sueldo;

--Select para revisar los datos anteriores--
SELECT
    HONORARIO,
    ID_PROFESIONAL,
    NUMRUN_PROF,
    SUELDO
FROM honorarios_antes_modificacion
ORDER BY id_profesional;
    

UPDATE profesional pro
SET pro.sueldo = (
CASE WHEN (SELECT SUM(ase.honorario)
           FROM asesoria ase
           WHERE ase.id_profesional = pro.id_profesional
                  AND EXTRACT (MONTH FROM ase.fin_asesoria)= 3 
                  AND EXTRACT (YEAR FROM ase.fin_asesoria) = EXTRACT (YEAR FROM SYSDATE) -1
                 ) BETWEEN 1 AND 999999 
                  THEN ROUND(pro.sueldo * 1.10) 
     WHEN (SELECT SUM(ase.honorario)
           FROM asesoria ase
           WHERE ase.id_profesional = pro.id_profesional
                  AND EXTRACT (MONTH FROM ase.fin_asesoria)= 3 AND
                  EXTRACT (YEAR FROM ase.fin_asesoria) = EXTRACT (YEAR FROM SYSDATE) -1
                  )>=1000000 
                  THEN ROUND(pro.sueldo * 1.15)                  
     ELSE pro.sueldo    
     END
)
WHERE pro.id_profesional IN(SELECT id_profesional
                            FROM asesoria 
                            WHERE EXTRACT(MONTH FROM fin_asesoria)=3
                            AND EXTRACT(YEAR FROM fin_asesoria) = EXTRACT (YEAR FROM SYSDATE) -1
                            GROUP BY id_profesional);
                            
                                   
SELECT SUM(ase.honorario) AS HONORARIO,
       pro.id_profesional AS  ID_PROFESIONAL,
       pro.numrun_prof AS NUMRUN_PROF,
       pro.sueldo AS SUELDO
FROM profesional pro JOIN asesoria ase
                     ON pro.id_profesional = ase.id_profesional
WHERE EXTRACT (MONTH FROM ase.fin_asesoria)=3 
      AND EXTRACT(YEAR FROM ase.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE)-1
GROUP BY pro.id_profesional,pro.numrun_prof, pro.sueldo;


