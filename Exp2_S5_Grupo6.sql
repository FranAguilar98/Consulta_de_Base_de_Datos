SELECT 
     TO_CHAR(cli.numRun, '99G999G999') ||'-'|| cli.dvRun AS "RUT Cliente",
     INITCAP(cli.pNombre ||' '|| cli.apPaterno) AS "Nombre Cliente",
     UPPER(po.nombre_prof_ofic) AS "Profesión Cliente",
     TO_DATE(fecha_inscripcion,'DD-MM-YYYY') AS "Fecha de Inscripcion",
     INITCAP(direccion) AS "Dirección Cliente"
FROM cliente cli JOIN profesion_oficio po
                 ON cli.cod_prof_ofic = po.cod_prof_ofic
                 JOIN tipo_cliente tcl
                 ON cli.cod_tipo_cliente = tcl.cod_tipo_cliente
WHERE UPPER(tcl.nombre_tipo_cliente)= 'TRABAJADORES DEPENDIENTES' 
      AND UPPER(po.nombre_prof_ofic) IN('CONTADOR','VENDEDOR')
      AND 
       EXTRACT(YEAR FROM cli.fecha_inscripcion) > 
                                                (SELECT ROUND(AVG(EXTRACT(YEAR FROM fecha_inscripcion)))
                                                 FROM cliente)
ORDER BY cli.numRun ASC;


CREATE TABLE CLIENTES_CUPOS_COMPRA AS
SELECT 
    TO_CHAR(cli.numRun, '99G999G999') ||'-'|| cli.dvRun AS RUT_CLIENTE,
    TRUNC(MONTHS_BETWEEN(SYSDATE, cli.fecha_nacimiento) / 12) AS EDAD_CLIENTE,
    TO_CHAR(tc.cupo_disp_compra,'$9G999G999') AS CUPO_DISPONIBLE_COMPRA,
    UPPER(ticl.nombre_tipo_cliente) AS TIPO_CLIENTE
FROM cliente cli JOIN tarjeta_cliente tc 
                 ON cli.numRun = tc.numRun
                 JOIN tipo_cliente ticl
                 ON cli.cod_tipo_cliente = ticl.cod_tipo_cliente
WHERE tc.cupo_disp_compra >= (SELECT MAX(tc2.cupo_disp_compra)
                                FROM tarjeta_cliente tc2
                                WHERE EXTRACT(YEAR FROM tc2.fecha_solic_tarjeta) = EXTRACT(YEAR FROM SYSDATE) - 1)
ORDER BY TRUNC(MONTHS_BETWEEN(SYSDATE, cli.fecha_nacimiento) / 12) ASC;

--Estimada profesora, junto con mi compañera de grupo queremos hacerle unas consultas sobre la tarea de esta semana, 
-- pues vera que en la primera consulta cuando se realizan la ejecución no nos da el resultado esperado y no  sabemos 
--la dirección de nuestro error. En la segunda sentencia tenemos un problema específico que es el tema de las edades
--pues varian en un año, funciona si le ponemos un ROUND, pero recuerdo que en clase nos manifesto que siempre deben truncarse las edades. 
--Perdón por usar este medio como método de conversación, lo utilizamos porque creeímos que es mas directo ver nuestro ejercicio de forma directa.
--Sin nada más que agregar, nos despedimos. Muchas gracias de antemano 
                 

