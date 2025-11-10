SELECT 
    TO_CHAR(numrut_cli,'99g999g999')||'-'||dvrut_cli AS "Rut cliente",
    INITCAP (nombre_cli ||' '||appaterno_cli ||' '|| apmaterno_cli) AS "Nombre Completo Cliente",
    INITCAP(direccion_cli) AS "Dirección Cliente",
    TO_CHAR(ROUND(renta_cli),'$9G999G999') AS "Renta cliente", 
    SUBSTR (TO_CHAR(celular_cli), 1,2) ||'-'||
    SUBSTR (TO_CHAR(celular_cli), 3,3) ||'-'||
    SUBSTR (TO_CHAR(celular_cli), 6,4) AS "Celular Cliente",
    CASE
        WHEN renta_cli > 500000 THEN 'TRAMO 1'
        WHEN renta_cli BETWEEN 400000 AND 500000 THEN 'TRAMO 2'
        WHEN renta_cli BETWEEN 200000 AND 399999 THEN 'TRAMO 3'
        ELSE 'TRAMO 4'
    END AS "Trama Renta Cliente"
FROM cliente
WHERE renta_cli BETWEEN &RENTA_MINIMA AND &RENTA_MAXIMA
      AND celular_cli IS NOT NULL
ORDER BY INITCAP(nombre_cli || ' ' || appaterno_cli || ' ' || apmaterno_cli) ASC;



    
SELECT
    NVL(TO_CHAR(id_categoria_emp), 'Sin categoría asignada') AS CODIGO_CATEGORIA,
    NVL(
    CASE
        WHEN id_categoria_emp = 1 THEN 'Gerente'
        WHEN id_categoria_emp = 2 THEN 'Supervisor'
        WHEN id_categoria_emp = 3 THEN 'Ejecutivo de Arriendo'
        WHEN id_categoria_emp = 4 THEN 'Auxiliar'
    END, 'Sin categoría asignada') AS "DESCRIPCION_CATEGORIA", 
    COUNT (id_categoria_emp) AS "CANTIDAD_EMPLEADOS",
    CASE 
        WHEN id_sucursal = 10 THEN 'Sucursal Las Condes'
        WHEN id_sucursal = 20 THEN 'Sucursal Santiago Centro'
        WHEN id_sucursal = 30 THEN 'Sucursal Providencia'
        ELSE 'Sucursal Vitacura'
    END AS "SUCURSAL",
    TO_CHAR(ROUND(AVG(sueldo_emp),0),'$9G999G999') AS "SUELDO_PROMEDIO"
FROM empleado
GROUP BY id_categoria_emp,
         id_sucursal
HAVING ROUND(AVG(sueldo_emp),0) >= &SUELDO_PROMEDIO_MINIMO
ORDER BY ROUND(AVG(sueldo_emp),0) DESC;



SELECT 
    UPPER(id_tipo_propiedad) AS "CODIGO_TIPO",
    CASE 
        WHEN id_tipo_propiedad = 'A' THEN 'CASA'
        WHEN id_tipo_propiedad = 'B' THEN 'DEPARTAMENTO'
        WHEN id_tipo_propiedad = 'C' THEN 'LOCAL'
        WHEN id_tipo_propiedad = 'D' THEN 'PARCELA SIN CASA'
        WHEN id_tipo_propiedad = 'E' THEN 'PARCELA CON CASA'
        ELSE 'SIN CLASIFICAR'
    END AS "DESCRIPCION_TIPO",
    COUNT(nro_propiedad) AS "TOTAL_PROPIEDADES",
    TO_CHAR(ROUND(AVG(valor_arriendo), 0), '$9G999G999') AS "PROMEDIO_ARRIENDO",
    TO_CHAR(AVG(superficie), '9G999D99') AS "PROMEDIO_SUPERFICIE",
    TO_CHAR(ROUND(AVG(valor_arriendo/superficie), 0), '$9G999G999') AS "VALOR_ARRIENDO_M2",
    CASE 
        WHEN (AVG(valor_arriendo)/AVG(superficie)) < 5000 THEN 'Económico'
        WHEN (AVG(valor_arriendo)/AVG(superficie)) BETWEEN 5000 AND 10000 THEN 'Medio'
        ELSE 'Alto'
    END AS "CLASIFICACION"
FROM propiedad
GROUP BY id_tipo_propiedad
HAVING (AVG(valor_arriendo)/AVG(superficie)) > 1000
ORDER BY (AVG(valor_arriendo)/AVG(superficie)) DESC; 


