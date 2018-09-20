 SELECT
 d.SOLD_TO_CUST_NUM,
 d.SAP_SALES_ORD_NUM,
d.SAAS_DEAL_REGSTRN_GRP,
d.PART_NUM,
d.SALES_ORD_LINE_ITEM_NUM,
d.SAAS_TERMNTD_DATE,
d.FIRM_ORD_DATE,
d.ODS_ADD_DATE,
d.SAP_DEAL_REGSTRN_IND
    FROM
        SODS1.SAAS_INCUMBENCY_DTL d
    WHERE
    d.rsel_pwsw_id ='8rrrr' AND 
d.sold_to_cust_num = '0007103888' and
d.sap_sales_ord_num = '0077235816' and
d.part_num IN ('D003GZX') ;

SELECT s.SAAS_DEAL_REGSTRN_GRP,
s.RSEL_PWSW_ID, s.SOLD_TO_CUST_NUM, s.INCUMBENCY_START_DATE, s.INCUMBENCY_END_DATE, s.INCUMBENCY_GRACE_PRD_END_DATE
, s.INCUMBENCY_STAT_CODE
FROM SODS1.SAAS_DEAL_INCENT_ELGBLTY_SUM s
        WHERE-- (s.INCUMBENCY_END_DATE is  NOT NULL and s.INCUMBENCY_END_DATE <> '9999-12-31')
       -- s.SAAS_DEAL_REGSTRN_GRP in ('BSP013') 
        --s.RSEL_PWSW_ID  = '7481y'
       -- AND
       s.SOLD_TO_CUST_NUM IN ( '000710388');    
       
       
-------------------------
SELECT pd.SAAS_DEAL_REGSTRN_GRP  FROM rshr1.PROD_DIMNSN pd WHERE    pd.PART_NUM = 'D003GZX' ;--BSP161

--check the existing data

SELECT 1 FROM SODS1.SAAS_INCUMBENCY_DTL d WHERE
    d.rsel_pwsw_id = '8rrrr'
AND d.sold_to_cust_num = '0007103888'
AND d.sap_sales_ord_num ='0077235816'
AND d.sales_ord_line_item_num = 10
AND d.part_num = 'D003GZX'
AND COALESCE( d.sap_deal_regstrn_ind,'N/AP') = COALESCE( 'A','N/AP')
AND COALESCE(  d.firm_ord_date,'12/31/9999' ) = COALESCE('2018-06-09','12/31/9999')
AND COALESCE( d.saas_termntd_date, '12/31/9999') = COALESCE(null,'12/31/9999')
--AND d.ods_add_date = v_ods_add_date;


--INSERT INTO SODS1.SAAS_INCUMBENCY_DTL

s_inflight_incumbecy_date = '06/01/2018';
s_inflight_incumbecy_lookup_date = '06/01/2018' ;


---Checking the In-flight Data-----------
CURRENT DATE <= DATE('2018-06-01') AND DATE('2018-06-01') >= ('2017-12-12');

/*SELECT    DATE(qli.ADD_DATE) FROM
sods2.SALES_ORD_LINE_ITEM soli,
sods2.QUOTE_LINE_ITEM qli
WHERE
soli.SAP_SALES_ORD_NUM = '0077235816'
AND soli.LINE_ITEM_SEQ_NUM = 10
AND soli.QUOTE_NUM = qli.QUOTE_NUM
AND soli.QUOTE_LINE_ITEM_SEQ_NUM = qli.LINE_ITEM_SEQ_NUM ; ('2017-12-12')*/

SELECT
t.RSEL_PWSW_ID,  t.SOLD_TO_CUST_NUM,   t.SAAS_DEAL_REGSTRN_GRP,
MAX( t.INCUMBENCY_STAT_CODE ) AS INCUMBENCY_STAT_CODE,
MIN(t.FIRM_ORD_DATE) AS INCUMBENCY_START_DATE,
MAX( CASE WHEN t.SAAS_TERMNTD_DATE IS NULL THEN '12/31/9999' ELSE SAAS_TERMNTD_DATE END ) AS INCUMBENCY_END_DATE,
MAX( CASE WHEN t.SAAS_TERMNTD_DATE IS NULL THEN '12/31/9999' ELSE t.SAAS_TERMNTD_DATE + 90 DAYS END ) AS INCUMBENCY_GRACE_PRD_END_DATE
 FROM
 ( SELECT  dtl.RSEL_PWSW_ID, dtl.SOLD_TO_CUST_NUM,dtl.SAAS_DEAL_REGSTRN_GRP, dtl.INCUMBENCY_STAT_CODE, dtl.FIRM_ORD_DATE, dtl.START_DATE,dtl.SAAS_TERMNTD_DATE
 FROM SODS1.SAAS_INCUMBENCY_DTL dtl
WHERE dtl.RSEL_PWSW_ID = '8rrrr' AND dtl.SOLD_TO_CUST_NUM = '0007103888' AND SAAS_DEAL_REGSTRN_GRP = 'BSP161' ) t
 GROUP BY t.RSEL_PWSW_ID, t.SOLD_TO_CUST_NUM, t.SAAS_DEAL_REGSTRN_GRP ;
------------------------------------        
        

SELECT
        t.RSEL_PWSW_ID,
        t.SOLD_TO_CUST_NUM,
        t.SAAS_DEAL_REGSTRN_GRP,
        MAX (
            CASE
                WHEN t.LATEST_SAP_DEAL_REGSTRN_IND = 'A' THEN t.INCUMBENCY_STAT_CODE
                --Deal registration exists when quote was created and SQO sent to SAP
                --WHEN t.DEAL_REGSTRN_STAT_CODE = 'APPROVED' THEN t.FIRM_ORD_DATE ---sap_deal_reg_ind should handle this but incase of replication delay
                WHEN t.EXISTING_INCUMBENCY_START_DATE IS NOT NULL THEN t.INCUMBENCY_STAT_CODE
                --existing Incumbency(grandfather incumbency load , inflight quotes before go live,first one to place order)
                WHEN t.OTHER_INCUMBENCY_ALREADY_EXISTS IS NULL
                AND t.DEAL_REGSTRN_STAT_CODE IN (
                    'NOT_APPROVED',
                    'EXPIRED',
                    'APPROVED'
                ) THEN t.INCUMBENCY_STAT_CODE
                ELSE NULL
            END
        ) AS INCUMBENCY_STAT_CODE,
        ---no one have existing Incumbency & BP had Deal Reg but does not have to be approved status
 MIN (
            CASE
                WHEN t.LATEST_SAP_DEAL_REGSTRN_IND = 'A' THEN t.FIRST_FIRM_ORD_DATE
                --Deal registration exists when quote was created and SQO sent to SAP
                --WHEN t.DEAL_REGSTRN_STAT_CODE = 'APPROVED' THEN t.FIRM_ORD_DATE ---sap_deal_reg_ind should handle this but incase of replication delay
                WHEN t.EXISTING_INCUMBENCY_START_DATE IS NOT NULL THEN t.FIRST_FIRM_ORD_DATE
                --existing Incumbency(grandfather incumbency load , inflight quotes before go live,first one to place order)
                WHEN t.OTHER_INCUMBENCY_ALREADY_EXISTS IS NULL
                AND t.DEAL_REGSTRN_STAT_CODE IN (
                    'NOT_APPROVED',
                    'EXPIRED',
                    'APPROVED'
                ) THEN t.FIRST_FIRM_ORD_DATE
                ELSE NULL
            END
        ) AS INCUMBENCY_START_DATE,
        ---no one have existing Incumbency & BP had Deal Reg but does not have to be approved status
 MAX (
            CASE
                WHEN t.LATEST_SAP_DEAL_REGSTRN_IND = 'A' THEN (
                    CASE
                        WHEN t.SAAS_TERMNTD_DATE IS NULL THEN '12/31/9999'
                        ELSE SAAS_TERMNTD_DATE
                    END
                )
                --WHEN t.DEAL_REGSTRN_STAT_CODE = 'APPROVED' THEN (CASE WHEN t.SAAS_TERMNTD_DATE IS NULL THEN '12/31/9999' ELSE SAAS_TERMNTD_DATE END)
                WHEN t.EXISTING_INCUMBENCY_START_DATE IS NOT NULL THEN (
                    CASE
                        WHEN t.SAAS_TERMNTD_DATE IS NULL THEN '12/31/9999'
                        ELSE SAAS_TERMNTD_DATE
                    END
                )
                WHEN t.OTHER_INCUMBENCY_ALREADY_EXISTS IS NULL
                AND t.DEAL_REGSTRN_STAT_CODE IN (
                    'NOT_APPROVED',
                    'EXPIRED',
                    'APPROVED'
                ) THEN (
                    CASE
                        WHEN t.SAAS_TERMNTD_DATE IS NULL THEN '12/31/9999'
                        ELSE SAAS_TERMNTD_DATE
                    END
                )
                ELSE NULL
            END
        ) AS INCUMBENCY_END_DATE,
        MAX (
            CASE
                WHEN t.LATEST_SAP_DEAL_REGSTRN_IND = 'A' THEN (
                    CASE
                        WHEN t.SAAS_TERMNTD_DATE IS NULL THEN '12/31/9999'
                        ELSE t.SAAS_TERMNTD_DATE + 90 DAYS
                    END
                )
                --WHEN t.DEAL_REGSTRN_STAT_CODE = 'APPROVED' THEN (CASE WHEN t.SAAS_TERMNTD_DATE IS NULL THEN '12/31/9999' ELSE t.SAAS_TERMNTD_DATE + 90 DAYS END) 
                WHEN t.EXISTING_INCUMBENCY_START_DATE IS NOT NULL THEN (
                    CASE
                        WHEN t.SAAS_TERMNTD_DATE IS NULL THEN '12/31/9999'
                        ELSE t.SAAS_TERMNTD_DATE + 90 DAYS
                    END
                )
                WHEN t.OTHER_INCUMBENCY_ALREADY_EXISTS IS NULL
                AND t.DEAL_REGSTRN_STAT_CODE IN (
                    'NOT_APPROVED',
                    'EXPIRED',
                    'APPROVED'
                ) THEN (
                    CASE
                        WHEN t.SAAS_TERMNTD_DATE IS NULL THEN '12/31/9999'
                        ELSE t.SAAS_TERMNTD_DATE + 90 DAYS
                    END
                )
                ELSE NULL
            END
        ) AS INCUMBENCY_GRACE_PRD_END_DATE
    FROM
        (
            SELECT
                dtl.RSEL_PWSW_ID,
                dtl.SOLD_TO_CUST_NUM,
                dtl.SAAS_DEAL_REGSTRN_GRP,
                MAX( dtl.INCUMBENCY_STAT_CODE ) AS INCUMBENCY_STAT_CODE,
                MIN( dtl.START_DATE ) AS START_DATE ,
                MAX( dtl.END_DATE ) AS END_DATE,
                MAX( LATEST_TERMNTD_DATE ) AS SAAS_TERMNTD_DATE,
                dtl.PART_NUM,
               MAX( stemp.SOLD_TO_CUST_NUM ) AS OTHER_INCUMBENCY_ALREADY_EXISTS,
              MAX( dealtemp.DEAL_REGSTRN_STAT_CODE ) AS DEAL_REGSTRN_STAT_CODE,
               MAX( dealtemp.EXISTING_INCUMBENCY_START_DATE ) AS EXISTING_INCUMBENCY_START_DATE,
                MIN( LATEST_SAP_DEAL_REGSTRN_IND ) AS LATEST_SAP_DEAL_REGSTRN_IND,
                MIN( COALESCE( REGAIN_FIRST_FIRM_ORD_DATE, FIRST_FIRM_ORD_DATE )) AS FIRST_FIRM_ORD_DATE
            FROM
                SODS1.SAAS_INCUMBENCY_DTL dtl
                ----check if other Re-seller have existing incumbency--start
            LEFT JOIN (
                    SELECT
                        DISTINCT sm.SOLD_TO_CUST_NUM,
                        sm.SAAS_DEAL_REGSTRN_GRP
                    FROM
                        SODS1.SAAS_DEAL_INCENT_ELGBLTY_SUM sm
                    WHERE
                        sm.SOLD_TO_CUST_NUM = '0007103888'
                        AND sm.SAAS_DEAL_REGSTRN_GRP = 'BSP161'
                        AND sm.RSEL_PWSW_ID <> '8rrrr'
                        AND CURRENT_DATE BETWEEN sm.INCUMBENCY_START_DATE AND sm.INCUMBENCY_GRACE_PRD_END_DATE
                ) stemp ON
                dtl.SOLD_TO_CUST_NUM = stemp.SOLD_TO_CUST_NUM
                AND dtl.SAAS_DEAL_REGSTRN_GRP = stemp.SAAS_DEAL_REGSTRN_GRP
                ----check if other Re-seller have existing incumbency--end
                
                ----Check if the Re-seller ever registerd deal reg any satus & Incumbency existing--start
            LEFT JOIN (
                    SELECT
                        DISTINCT sm.RSEL_PWSW_ID,
                        sm.SOLD_TO_CUST_NUM,
                        sm.SAAS_DEAL_REGSTRN_GRP,
                        sm.DEAL_REGSTRN_STAT_CODE,
                        sm.INCUMBENCY_START_DATE AS EXISTING_INCUMBENCY_START_DATE
                    FROM
                        SODS1.SAAS_DEAL_INCENT_ELGBLTY_SUM sm
                    WHERE
                        sm.SOLD_TO_CUST_NUM = '0007103888'
                        AND sm.SAAS_DEAL_REGSTRN_GRP =  'BSP161'
                        AND sm.RSEL_PWSW_ID ='8rrrr'
                        AND ( COALESCE(  sm.DEAL_REGSTRN_STAT_CODE,'') <> '' OR CURRENT_DATE BETWEEN sm.INCUMBENCY_START_DATE AND sm.INCUMBENCY_GRACE_PRD_END_DATE)
                ) dealtemp ON
                
                dtl.SOLD_TO_CUST_NUM = dealtemp.SOLD_TO_CUST_NUM
                AND dtl.SAAS_DEAL_REGSTRN_GRP = dealtemp.SAAS_DEAL_REGSTRN_GRP
                AND dtl.RSEL_PWSW_ID = dealtemp.RSEL_PWSW_ID
                ----Check if the Re-seller ever registerd deal reg any satus & Incumbency existing--end
                
                
                ----get the latest SAP_DEAL_REGSTRN_IND flag info--start
            LEFT JOIN 
            
            (
                    SELECT
                        dt.RSEL_PWSW_ID,
                        dt.SOLD_TO_CUST_NUM,
                        dt.SAAS_DEAL_REGSTRN_GRP,
                        dt.SAP_DEAL_REGSTRN_IND AS LATEST_SAP_DEAL_REGSTRN_IND
                    FROM
                        SODS1.SAAS_INCUMBENCY_DTL dt
                    WHERE
                        dt.SOLD_TO_CUST_NUM = '0007103888'
                        AND dt.SAAS_DEAL_REGSTRN_GRP = 'BSP161'
                        AND dt.RSEL_PWSW_ID = '8rrrr'
                        --AND
                        --dt.ORIGNL_SRC_CODE = 'SAP'
                    ORDER BY
                        ODS_ADD_DATE DESC FETCH FIRST 1 ROWS ONLY
                ) flagtemp ON
                
                dtl.SOLD_TO_CUST_NUM = flagtemp.SOLD_TO_CUST_NUM
                AND dtl.SAAS_DEAL_REGSTRN_GRP = flagtemp.SAAS_DEAL_REGSTRN_GRP
                AND dtl.RSEL_PWSW_ID = flagtemp.RSEL_PWSW_ID
                ----get the latest SAP_DEAL_REGSTRN_IND flag info--end 
                
                ----get the first FIRM_ORD_DATE as they can be backdated on later part_num--start
            LEFT JOIN
            
( SELECT dt.RSEL_PWSW_ID,  dt.SOLD_TO_CUST_NUM,    dt.SAAS_DEAL_REGSTRN_GRP,  dt.FIRM_ORD_DATE AS FIRST_FIRM_ORD_DATE
  FROM SODS1.SAAS_INCUMBENCY_DTL dt
                    WHERE
                        dt.SOLD_TO_CUST_NUM = '0007103888'
                        AND dt.SAAS_DEAL_REGSTRN_GRP = 'BSP161'
                        AND dt.RSEL_PWSW_ID = '8rrrr'
                        --AND
                        --dt.ORIGNL_SRC_CODE = 'SAP'
                    ORDER BY
                        ODS_ADD_DATE ASC FETCH FIRST 1 ROWS ONLY
                ) firmtemp ON
                
                
                dtl.SOLD_TO_CUST_NUM = firmtemp.SOLD_TO_CUST_NUM
                AND dtl.SAAS_DEAL_REGSTRN_GRP = firmtemp.SAAS_DEAL_REGSTRN_GRP
                AND dtl.RSEL_PWSW_ID = firmtemp.RSEL_PWSW_ID
                
                ----get the first FIRM_ORD_DATE as they can be backdated on later part_num--end
                
                
                ----get the latest TERMINATION_DATE by part_num,ORDER NUM as key combination as they can be  reset to null --start
LEFT JOIN

(SELECT
RSEL_PWSW_ID, SOLD_TO_CUST_NUM,   SAAS_DEAL_REGSTRN_GRP,  PART_NUM, SAP_SALES_ORD_NUM,SALES_ORD_LINE_ITEM_NUM, SAAS_TERMNTD_DATE AS LATEST_TERMNTD_DATE
 FROM
  (SELECT dtl.RSEL_PWSW_ID,dtl.SOLD_TO_CUST_NUM, dtl.SAAS_DEAL_REGSTRN_GRP,
    dtl.PART_NUM,dtl.SAP_SALES_ORD_NUM,dtl.SALES_ORD_LINE_ITEM_NUM,   SAAS_TERMNTD_DATE, ROW_NUMBER() OVER (
    PARTITION BY dtl.RSEL_PWSW_ID,
    dtl.SOLD_TO_CUST_NUM,
   dtl.SAAS_DEAL_REGSTRN_GRP,
   dtl.PART_NUM,
   dtl.SAP_SALES_ORD_NUM,
   dtl.SALES_ORD_LINE_ITEM_NUM
ORDER BY (ODS_ADD_DATE) DESC ) AS ROW_NUMBER
 FROM
 sods1.SAAS_INCUMBENCY_DTL dtl WHERE
dtl.RSEL_PWSW_ID ='8rrrr'
AND dtl.SOLD_TO_CUST_NUM = '0007103888'
AND dtl.SAAS_DEAL_REGSTRN_GRP = 'BSP161' )
WHERE ROW_NUMBER = 1
                ) terminationtemp ON
                dtl.RSEL_PWSW_ID = terminationtemp.RSEL_PWSW_ID
                AND dtl.SOLD_TO_CUST_NUM = terminationtemp.SOLD_TO_CUST_NUM
                AND dtl.SAAS_DEAL_REGSTRN_GRP = terminationtemp.SAAS_DEAL_REGSTRN_GRP
                AND dtl.PART_NUM = terminationtemp.PART_NUM
                AND dtl.SAP_SALES_ORD_NUM = terminationtemp.SAP_SALES_ORD_NUM
                AND dtl.SALES_ORD_LINE_ITEM_NUM = terminationtemp.SALES_ORD_LINE_ITEM_NUM
                
 LEFT JOIN 
 
(SELECT dt.RSEL_PWSW_ID,dt.SOLD_TO_CUST_NUM,  dt.SAAS_DEAL_REGSTRN_GRP,  dt.FIRM_ORD_DATE AS REGAIN_FIRST_FIRM_ORD_DATE
FROM  SODS1.SAAS_INCUMBENCY_DTL dt, SODS1.SAAS_DEAL_INCENT_ELGBLTY_SUM sm
WHERE
dt.SOLD_TO_CUST_NUM = '0007103888'
AND dt.SAAS_DEAL_REGSTRN_GRP = 'BSP161'
AND dt.RSEL_PWSW_ID ='8rrrr'
AND dt.SOLD_TO_CUST_NUM = sm.SOLD_TO_CUST_NUM
AND dt.SAAS_DEAL_REGSTRN_GRP = sm.SAAS_DEAL_REGSTRN_GRP
AND dt.RSEL_PWSW_ID = sm.RSEL_PWSW_ID
AND dt.ODS_ADD_DATE > sm.DEAL_REGSTRN_START_DATE
AND dt.FIRM_ORD_DATE IS NOT NULL
ORDER BY dt.ODS_ADD_DATE ASC FETCH FIRST 1 ROWS ONLY ) 

regaintemp ON dtl.SOLD_TO_CUST_NUM = regaintemp.SOLD_TO_CUST_NUM
                AND dtl.SAAS_DEAL_REGSTRN_GRP = regaintemp.SAAS_DEAL_REGSTRN_GRP
                AND dtl.RSEL_PWSW_ID = regaintemp.RSEL_PWSW_ID
                ----get the first FIRM_ORD_DATE after RE-gaining incumbency--end
            WHERE
                dtl.SOLD_TO_CUST_NUM = v_sold_to_cust_num
                AND dtl.SAAS_DEAL_REGSTRN_GRP = v_saas_deal_regstrn_grp
                AND dtl.RSEL_PWSW_ID = p_rsel_pwsw_id
                --and dtl.ORIGNL_SRC_CODE = 'SAP'
            GROUP BY
                dtl.RSEL_PWSW_ID,
                dtl.SOLD_TO_CUST_NUM,
                dtl.SAAS_DEAL_REGSTRN_GRP,
                dtl.PART_NUM,
                dtl.SAP_SALES_ORD_NUM,
                dtl.SALES_ORD_LINE_ITEM_NUM
        ) t
    GROUP BY
        t.RSEL_PWSW_ID,
        t.SOLD_TO_CUST_NUM,
        t.SAAS_DEAL_REGSTRN_GRP
);

-------------------------------

