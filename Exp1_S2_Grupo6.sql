
SELECT 
ADD_MONTHS(fecha, -12)   AS "Fecha emisión",
LPAD(rutcliente,10,0)    AS "Rut Cliente",
neto                     AS "Monto Neto",
iva                      AS "Monto Iva",
total                    AS "Total Factura",
CASE 
    WHEN total BETWEEN 0 AND 50000 THEN 'Bajo'
    WHEN total BETWEEN 50001 AND 100000 THEN 'Medio'
    ELSE 'Alto'
END                      AS "Categoria Monto",
CASE 
    WHEN codPago=1 THEN 'EFECTIVO'
    WHEN codPago=2 THEN 'TARJETA DEBITO'
    WHEN codPago=3 THEN 'TARJETA DE CREDITO'
    ELSE 'CHEQUE'
END                      AS "Forma de Pago"
FROM factura
ORDER BY fecha DESC, neto DESC;

SELECT 
LPAD(rutCliente,12,'*')                                       AS "Rut Cliente",
nombre AS "Cliente",
NVL(TO_CHAR(telefono),'Sin teléfono')                         AS "TELÉFONO",
NVL(TO_CHAR(codComuna),'Sin comuna')                          AS "COMUNA",
estado                                                        AS "ESTADO",
CASE 
    WHEN ((saldo/credito) < 0.5) THEN 'Bueno' || TO_CHAR(ROUND(credito-saldo),'9G999G999')
    WHEN ((saldo/credito)BETWEEN 0.5 AND 0.8) THEN 'Regular ' || TO_CHAR(ROUND(saldo), '9G999G999')
    ELSE 'Crítico'
END                                                           AS "Estado Crédito",
NVL(SUBSTR(mail,INSTR (mail, '@')+1),'Correo no registrado')  AS "Dominio Correo"
FROM cliente
WHERE estado = 'A' AND credito > 0 
ORDER BY nombre ASC;

SELECT 
descripcion                                                                     AS "Descipción de Producto",
NVL(TO_CHAR(valorCompraDolar,'$9G999G999D00'),'Sin registro')                   AS "Compra en USD",
NVL(TO_CHAR(ROUND(valorCompraDolar*&tipo_cambio),'$9G999G999'),'Sin Registro')  AS "USD convertido",
totalStock                                                                      AS "Stock",
CASE
    WHEN totalStock IS NULL THEN 'Sin datos'
    WHEN totalStock < &umbral_bajo THEN '¡ALERTA stock muy bajo'
    WHEN totalStock BETWEEN &umbral_bajo AND &umbral_alto THEN '¡Rebastecer pronto!'
    ELSE 'OK'
END                                                                             AS "Alerta Stock",
CASE
    WHEN totalStock > 80 THEN TO_CHAR(ROUND(vUnitario * 0.90),'9G999G999')
    Else 'N/A'
END                                                                             AS "Precio Oferta"
FROM producto
WHERE LOWER (descripcion) LIKE '%zapato%'  AND LOWER (procedencia) ='i'
ORDER BY codProducto DESC;
