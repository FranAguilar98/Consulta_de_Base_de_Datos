------USUARIO ADMIN - SYS - SYSTEM ----
---Código ejecutado por usuario SYS----  

CREATE USER PRY2205_USER1
IDENTIFIED BY OracleXe1234
DEFAULT TABLESPACE USERS
TEMPORARY TABLESPACE TEMP
QUOTA UNLIMITED ON USERS;

---Creación de rol 
CREATE ROLE PRY2205_ROL_D;
--Permite que PRY2205_USER1 pueda transferir estos permisos a otros usuarios
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, 
      CREATE SYNONYM, CREATE SEQUENCE, CREATE TRIGGER TO PRY2205_USER1
      WITH ADMIN OPTION;
      
--Asigna permisos al rol      
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, 
      CREATE SYNONYM TO PRY2205_ROL_D;
      
--Asigna rol al usuario      
GRANT PRY2205_ROL_D TO PRY2205_USER1;

--Permisos especiales 
GRANT CREATE PUBLIC SYNONYM TO PRY2205_USER1;
GRANT CREATE USER TO PRY2205_USER1;
GRANT CREATE ROLE TO PRY2205_USER1;

ALTER SESSION SET CONTAINER = XEPDB1; --Se uso esta herramienta porque sin ella los roles no funcionaban.



---USUARIO PRY2205_USER1----
--Creación y poblamiento de tablas
---Creación de sinónimos públicos y privados 

CREATE PUBLIC SYNONYM syn_prestamo FOR PRESTAMO;
CREATE PUBLIC SYNONYM syn_libro FOR LIBRO;
CREATE PUBLIC SYNONYM syn_ejemplar FOR EJEMPLAR;
CREATE PUBLIC SYNONYM syn_empleado FOR EMPLEADO;

CREATE SYNONYM syn_alumno FOR ALUMNO;
CREATE SYNONYM syn_carrera FOR CARRERA;
CREATE SYNONYM syn_rebaja_multa FOR REBAJA_MULTA;

--Creación de usuario PRY2205_USER2

CREATE USER PRY2205_USER2
IDENTIFIED BY OracleXe1234
DEFAULT TABLESPACE USERS
TEMPORARY TABLESPACE TEMP
QUOTA UNLIMITED ON USERS;

--Creación de rol
CREATE ROLE PRY2205_ROL_P;

--Asignar permisos al rol
GRANT CREATE SESSION, CREATE SEQUENCE, CREATE TRIGGER, 
      CREATE TABLE TO PRY2205_ROL_P;
      
--Asignar permisos al rol
GRANT PRY2205_ROL_P TO PRY2205_USER2;    

--Permiso para acceder a las tablas de PRY2205_USER1 
GRANT SELECT ON syn_prestamo TO PRY2205_USER2;
GRANT SELECT ON syn_libro TO PRY2205_USER2;
GRANT SELECT ON syn_ejemplar TO PRY2205_USER2;
GRANT SELECT ON syn_empleado TO PRY2205_USER2;


-----CÓDIGO CASO 3------
CREATE OR REPLACE VIEW VW_DETALLE_MULTAS AS
SELECT 
    pr.prestamoid AS ID_PRESTAMO,
    INITCAP(al.nombre ||' '|| al.apaterno) AS NOMBRE_ALUMNO,
    INITCAP(ca.descripcion) AS NOMBRE_CARRERA,
    li.libroid AS ID_LIBRO,
    TO_CHAR(li.precio, '$999G999') AS VALOR_LIBRO,
    pr.fecha_termino AS FECHA_TERMINO, 
    pr.fecha_entrega AS FECHA_ENTREGA,
    TRUNC(pr.fecha_entrega) - TRUNC(pr.fecha_termino) AS DIAS_ATRASO,
    TO_CHAR(ROUND((li.precio * 0.03) * (TRUNC(pr.fecha_entrega) - TRUNC(pr.fecha_termino)), 0),
        '$999G999') AS VALOR_MULTA,
    NVL(mu.porc_rebaja_multa, 0)/100 AS PORCENTAJE_REBAJA_MULTA,
    TO_CHAR( ROUND(
            ((li.precio * 0.03) * (TRUNC(pr.fecha_entrega) - TRUNC(pr.fecha_termino)))
            * (1 - NVL(mu.porc_rebaja_multa, 0) / 100),0),'$999G999') AS VALOR_REBAJADO

FROM syn_prestamo pr 
     JOIN syn_alumno al ON pr.alumnoid = al.alumnoid
     JOIN syn_carrera ca ON al.carreraid = ca.carreraid
     JOIN syn_ejemplar ej ON pr.ejemplarid = ej.ejemplarid AND pr.libroid = ej.libroid
     JOIN syn_libro li ON ej.libroid = li.libroid
     LEFT JOIN syn_rebaja_multa mu ON ca.carreraid = mu.carreraid

WHERE EXTRACT(YEAR FROM pr.fecha_termino) = EXTRACT(YEAR FROM SYSDATE) - 2
      AND pr.fecha_entrega > pr.fecha_termino
      
ORDER BY pr.fecha_entrega DESC;

CREATE INDEX idx_prestamo_alumnoid ON PRESTAMO (alumnoid); 
CREATE INDEX idx_alumno_carreraid ON ALUMNO (carreraid);



---USUARIO  PRY2205_USER2----

--CREACIÓN DE SECUENCIA
CREATE SEQUENCE  SEQ_CONTROL_STOCK
START WITH 1
MINVALUE 1
NOMAXVALUE
INCREMENT BY 1
NOCYCLE
NOCACHE;

--CÓDIGO DE CASO 2
CREATE TABLE CONTROL_STOCK_LIBROS AS 
SELECT SEQ_CONTROL_STOCK.NEXTVAL AS ID_CONTROL,
       LIBRO_ID,
       NOMBRE_LIBRO,
       TOTAL_EJEMPLARES,
       EN_PRESTAMO,
       DISPONIBLE,
       PORCENTAJE_PRESTAMO,
       STOCK_CRITICO
FROM (
    SELECT li.libroid AS LIBRO_ID,
           li.nombre_libro AS NOMBRE_LIBRO,
           COUNT(DISTINCT ej.ejemplarid) AS TOTAL_EJEMPLARES,
           COUNT(DISTINCT CASE 
            WHEN pr.prestamoid IS NOT NULL
                 AND pr.fecha_entrega IS NULL 
                 AND EXTRACT(YEAR FROM pr.fecha_inicio) = EXTRACT(YEAR FROM ADD_MONTHS(SYSDATE, -24))
                 AND pr.empleadoid IN (190, 180, 150)
            THEN ej.ejemplarid 
            END) AS EN_PRESTAMO,
           COUNT(DISTINCT ej.ejemplarid) - COUNT(DISTINCT CASE 
            WHEN pr.prestamoid IS NOT NULL
                 AND pr.fecha_entrega IS NULL 
                 AND EXTRACT(YEAR FROM pr.fecha_inicio) = EXTRACT(YEAR FROM ADD_MONTHS(SYSDATE, -24))
                 AND pr.empleadoid IN (190, 180, 150)
            THEN ej.ejemplarid 
            END) AS DISPONIBLE,
           ROUND(
            CASE 
            WHEN COUNT(DISTINCT ej.ejemplarid) = 0 THEN 0
            ELSE (COUNT(DISTINCT CASE 
                WHEN pr.prestamoid IS NOT NULL
                     AND pr.fecha_entrega IS NULL 
                     AND EXTRACT(YEAR FROM pr.fecha_inicio) = EXTRACT(YEAR FROM ADD_MONTHS(SYSDATE, -24))
                     AND pr.empleadoid IN (190, 180, 150)
                THEN ej.ejemplarid 
             END) * 100.0) / COUNT(DISTINCT ej.ejemplarid)
             END, 2) AS PORCENTAJE_PRESTAMO,
           CASE 
            WHEN (COUNT(DISTINCT ej.ejemplarid) - COUNT(DISTINCT CASE 
                WHEN pr.prestamoid IS NOT NULL
                     AND pr.fecha_entrega IS NULL 
                     AND EXTRACT(YEAR FROM pr.fecha_inicio) = EXTRACT(YEAR FROM ADD_MONTHS(SYSDATE, -24))
                     AND pr.empleadoid IN (190, 180, 150)
                THEN ej.ejemplarid 
            END)) > 2 THEN 'S'
            ELSE 'N'
            END AS STOCK_CRITICO
    FROM syn_libro li
         JOIN syn_ejemplar ej ON li.libroid = ej.libroid
         LEFT JOIN syn_prestamo pr ON ej.ejemplarid = pr.ejemplarid 
              AND ej.libroid = pr.libroid
    GROUP BY li.libroid, li.nombre_libro
    HAVING SUM(CASE 
                WHEN pr.prestamoid IS NOT NULL
                     AND EXTRACT(YEAR FROM pr.fecha_inicio) = EXTRACT(YEAR FROM ADD_MONTHS(SYSDATE, -24))
                     AND pr.empleadoid IN (190, 180, 150)
                THEN 1 
                ELSE 0 
               END) > 0
    ORDER BY li.libroid ASC
);    
    
    




    