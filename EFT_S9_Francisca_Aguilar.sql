ALTER SESSION SET CONTAINER = XEPDB1;
SHOW CON_NAME;
SHOW USER;
ALTER SESSION SET "_ORACLE_SCRIPT"=TRUE;
--CREACIÓN DE USUARIOS PRY2205_EFT, PRY2205_EFT_DES Y PRY2205_EFT_CON

CREATE USER PRY2205_EFT
IDENTIFIED BY OracleXe1234
DEFAULT TABLESPACE USERS 
TEMPORARY TABLESPACE TEMP
QUOTA 10M ON USERS;

CREATE USER PRY2205_EFT_DES
IDENTIFIED BY OracleXe1234
DEFAULT TABLESPACE USERS 
TEMPORARY TABLESPACE TEMP
QUOTA 10M ON USERS;

CREATE USER PRY2205_EFT_CON
IDENTIFIED BY OracleXe1234
DEFAULT TABLESPACE USERS 
TEMPORARY TABLESPACE TEMP
QUOTA 10M ON USERS;

-- OTORGAR PRIVILEGIOS DE SISTEMA 

--USUARIO PRY2205_EFT
GRANT CREATE TABLE, CREATE ANY INDEX, CREATE VIEW,
      CREATE SEQUENCE, CREATE SYNONYM, CREATE PUBLIC SYNONYM,
      CREATE SESSION, DROP PUBLIC SYNONYM TO PRY2205_EFT;
      
      
--USUARIO PRY2205_EFT_DES 
GRANT CREATE VIEW, CREATE PROFILE, CREATE USER, CREATE SESSION TO PRY2205_EFT_DES;

--USUARIO PRY2205_EFT_CON
GRANT CREATE SESSION TO PRY2205_EFT_CON;

--CREACIÓN DE ROLES
CREATE ROLE PRY2205_ROL_D;
CREATE ROLE PRY2205_ROL_C;

--ASIGNACIÓN DE PERMISOS AL ROL
GRANT CREATE SESSION TO PRY2205_ROL_D;
GRANT CREATE SESSION TO PRY2205_ROL_C;

--ASIGNACIÓN DE ROLES AL USUARIO
GRANT PRY2205_ROL_D TO PRY2205_EFT_DES;
GRANT PRY2205_ROL_C TO PRY2205_EFT_CON;


--USUARIO PRY2205_EFT 

--Poblamiento de tablas 
--CREACIÓN DE SINÓNIMOS PÚBLICOS
CREATE PUBLIC SYNONYM syn_profesional FOR PROFESIONAL;
CREATE PUBLIC SYNONYM syn_profesion FOR PROFESION;
CREATE PUBLIC SYNONYM syn_isapre FOR ISAPRE;
CREATE PUBLIC SYNONYM syn_tipo_contrato FOR TIPO_CONTRATO;
CREATE PUBLIC SYNONYM syn_rangos_sueldos FOR RANGOS_SUELDOS;
CREATE PUBLIC SYNONYM syn_cartola_profesionales FOR CARTOLA_PROFESIONALES;

--CREACIÓN SINÓNIMOS PRIVADOS
CREATE SYNONYM syn_empresa FOR EMPRESA;
CREATE SYNONYM syn_asesoria FOR ASESORIA;

--OTORGAR PRIVILEGIOS A PRY2205_EFT_DES

GRANT SELECT ON syn_profesional TO PRY2205_ROL_D;
GRANT SELECT ON syn_profesion TO PRY2205_ROL_D;
GRANT SELECT ON syn_isapre TO PRY2205_ROL_D;
GRANT SELECT ON syn_tipo_contrato  TO PRY2205_ROL_D;
GRANT SELECT ON syn_rangos_sueldos TO PRY2205_ROL_D;
GRANT SELECT, INSERT, UPDATE, DELETE ON syn_cartola_profesionales TO PRY2205_ROL_D;

--OTORGAR PRIVILEGIOS A PRY2205_EFT_CON
GRANT SELECT ON syn_profesional TO PRY2205_ROL_C;
GRANT SELECT ON syn_profesion TO PRY2205_ROL_C;
GRANT SELECT ON syn_isapre TO PRY2205_ROL_C;
GRANT SELECT ON syn_tipo_contrato  TO PRY2205_ROL_C;
GRANT SELECT ON syn_rangos_sueldos TO PRY2205_ROL_C;
GRANT SELECT ON syn_cartola_profesionales TO PRY2205_ROL_C;
--- CASO 3
CREATE OR REPLACE VIEW VW_EMPRESAS_ASESORADAS AS
SELECT 
    TO_CHAR(em.rut_empresa, '99G999G999') ||'-'|| em.dv_empresa AS RUT_EMPRESA,
    UPPER(em.nomEmpresa) AS NOMBRE_EMPRESA,
    iva_declarado AS IVA,
    TRUNC(MONTHS_BETWEEN(SYSDATE, em.fecha_iniciacion_actividades)/12) AS ANIOS_EXISTENCIA,
    COUNT (a.fin) AS TOTAL_ASESORIAS_ANUALES,
    ROUND((em.iva_declarado*(COUNT(a.fin)/12))/100,0) AS DEVOLUCION_IVA,
    CASE 
        WHEN TRUNC(COUNT(a.fin)/12) > 5 THEN 'CLIENTE PREMIUM'
        WHEN TRUNC(COUNT(a.fin)/12) BETWEEN 3 AND 5 THEN 'CLIENTE'
        WHEN TRUNC(COUNT (a.fin)/12) < 3 THEN 'CLIENTE POCO CONCURRIDO'
        ELSE 'SIN CLASIFICAR'
    END AS TIPO_CLIENTE,
    CASE 
        WHEN TRUNC(COUNT(a.fin)/12) > 5 THEN
            CASE 
              WHEN COUNT(a.fin)>=7 THEN '1 ASESORÍA GRATIS'
              ELSE '1 ASESORÍA 40% DE DESCUENTO'
            END
        WHEN TRUNC(COUNT(a.fin)/12) BETWEEN 3 AND 5 THEN
            CASE 
                WHEN COUNT(a.fin) = 5 THEN '1 ASESORÍA 30% DE DESCUENTO'
                ELSE '1 ASESORÍA 20% DE DESCUENTO'
            END
        WHEN TRUNC(COUNT(a.fin)/12) < 3 THEN 'CAPTAR CLIENTE'
        ELSE 'SIN PROMOCIÓN'
    END AS CORRESPONDE
FROM syn_empresa em JOIN syn_asesoria a 
    ON em.idempresa= a.idempresa
WHERE EXTRACT(YEAR FROM a.fin) = EXTRACT (YEAR FROM SYSDATE) - 1
GROUP BY em.idempresa, em.rut_empresa, em.dv_empresa, em.nomempresa, 
         em.fecha_iniciacion_actividades, em.iva_declarado
HAVING COUNT (*) > 0
ORDER BY nomempresa ASC;

--CREACIÓN SINÓNIMO PÚBLICO DE VISTA
CREATE PUBLIC SYNONYM syn_vw_empresas_asesoradas FOR VW_EMPRESAS_ASESORADAS;

--ENTREGA DE PRIVILEGIOS A LOS ROLES
GRANT SELECT ON vw_empresas_asesoradas TO PRY2205_ROL_D;
GRANT SELECT ON vw_empresas_asesoradas TO PRY2205_ROL_C;

--CREACIÓN DE ÍNDICES
CREATE INDEX idx_asesoria_fin ON ASESORIA (fin);


--USUARIO PRY2205_EFT_DES 

--CASO 2
SHOW USER;

COMMIT;

INSERT INTO syn_cartola_profesionales(
    RUT_PROFESIONAL, NOMBRE_PROFESIONAL, PROFESION, 
    ISAPRE, SUELDO_BASE, PORC_COMISION_PROFESIONAL,
    VALOR_TOTAL_COMISION, PORCENTATE_HONORARIO,
    BONO_MOVILIZACION, TOTAL_PAGAR)
SELECT 
    p.rutprof AS RUT_PROFESIONAL,
    INITCAP(p.nompro || ' ' ||p.apppro || ' ' || p.apmpro) AS NOMBRE_PROFESIONAL,
    INITCAP (prof.nomprofesion) AS PROFESION,
    i.nomisapre AS ISAPRE,
    p.sueldo AS SUELDO_BASE,
    NVL(ROUND(p.comision,2),0) AS PORC_COMISION_PROFESIONAL,
    CASE 
        WHEN p.comision is not null THEN ROUND(p.sueldo * p.comision)
        ELSE 0
    END AS VALOR_TOTAL_COMISION,
    ROUND(p.sueldo*(SELECT rs.honor_pct
     FROM syn_rangos_sueldos rs
     WHERE p.sueldo BETWEEN rs.s_min AND rs.S_MAX)/100)
     AS PORCENTAJE_HONORARIO,
     CASE tc.nomtcontrato
        WHEN 'Indefinido Jornada Completa' THEN 150000
        WHEN 'Indefinido Jornada Parcial' THEN 120000
        WHEN 'Plazo fijo' THEN 60000
        WHEN 'Honorarios' THEN 50000
        ELSE 0
     END AS BONO_MOVILIZACION,
     ROUND(p.SUELDO + 
        CASE 
            WHEN p.comision IS NOT NULL THEN p.sueldo * p.comision ELSE 0 END +
            (p.sueldo * (SELECT rs.honor_pct FROM syn_rangos_sueldos rs
                         WHERE p.sueldo BETWEEN rs.s_min AND rs.s_max)/100)+
        CASE tc.nomtcontrato
            WHEN 'Indefinido Jornada Completa' THEN 150000
            WHEN 'Indefinido Jornada Parcial' THEN 120000
            WHEN 'Plazo Fijo' THEN 60000
            WHEN 'Honorarios' THEN 50000
            ELSE 0
        END ) AS TOTAL_PAGAR
FROM syn_profesional p JOIN syn_profesion prof 
                       ON p.idprofesion = prof.idprofesion 
                       JOIN syn_isapre i 
                       ON p.idisapre = i.idisapre
                       JOIN syn_tipo_contrato tc
                       ON p.idtcontrato = tc.idtcontrato
ORDER BY prof.nomprofesion, p.sueldo DESC, NVL(p.comision, 0), p.rutprof;

--USUARIO PRY2205_EFT_CON

--INFORME CASO 2

SELECT
    rut_profesional,
    nombre_profesional,
    profesion,
    isapre,
    sueldo_base,
    porc_comision_profesional,
    valor_total_comision,
    porcentate_honorario,
    bono_movilizacion,
    total_pagar
FROM syn_cartola_profesionales
ORDER BY profesion ASC,
         sueldo_base DESC,
         total_pagar DESC,
         rut_profesional ASC;

--INFORME CASO 3

SELECT 
    rut_empresa,
    nombre_empresa,
    anios_existencia,
    iva,
    total_asesorias_anuales,
    devolucion_iva,
    tipo_cliente,
    corresponde
FROM syn_vw_empresas_asesoradas
ORDER BY nombre_empresa ASC;