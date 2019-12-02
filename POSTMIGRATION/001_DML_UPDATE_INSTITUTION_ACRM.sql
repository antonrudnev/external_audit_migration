--(2 rows affected)
--(2 rows affected)
--(1 row affected)
--(4 rows affected)
--(11 rows affected)

DECLARE @MODIFIED_BY NVARCHAR(50) = 'POSTMIGR_EXT_AUD_001';
DECLARE @MODIFIED DATETIME = GETDATE();

--reclassify 'CH-CGR', 'CR-CGR'
UPDATE INSTITUTION
SET FK_INSTITUTION_TYPE_ID = (SELECT CONVERGENCE_MASTER_DATA_ID FROM CONVERGENCE_MASTER_DATA
JOIN CONVERGENCE_MASTER_TYPE ON CONVERGENCE_MASTER_TYPE_ID = FK_CONVERGENCE_MASTER_TYPE_ID
WHERE CODE = 'EA' AND TYPE = 'INSTITUTION_TYPE')
	,ELGBLT = 'Eligible +'
	,INSTUT_TYP = 'EXTERNAL AUDITORS'
	,AUDITOR_TYPE = 'Supreme Audit Institutions'
	,MODIFIED = @MODIFIED
	,MODIFIED_BY = @MODIFIED_BY
WHERE ACRNM IN ('CH-CGR', 'CR-CGR');

--deactivate 'CH-CONTRALORIA', 'CR-CONTRALORIA'
UPDATE INSTITUTION
SET FK_VALIDATION_STAGE_ID = (SELECT CONVERGENCE_MASTER_DATA_ID FROM CONVERGENCE_MASTER_DATA
JOIN CONVERGENCE_MASTER_TYPE ON CONVERGENCE_MASTER_TYPE_ID = FK_CONVERGENCE_MASTER_TYPE_ID
WHERE CODE = 'INST_INACTIVE' AND TYPE = 'INSTITUTIONS_STATUS')
	,MODIFIED = @MODIFIED
	,MODIFIED_BY = @MODIFIED_BY
WHERE ACRNM IN ('CH-CONTRALORIA', 'CR-CONTRALORIA');

--redirect EXTERNAL_AUDIT from 'CH-CONTRALORIA', 'CR-CONTRALORIA' to 'CH-CGR', 'CR-CGR'
WITH UPDATED_CODES AS (
SELECT 'CH-CGR' AS NEW_CD, 'CH-CONTRALORIA' AS PREV_CD UNION ALL
SELECT 'CR-CGR' AS NEW_CD, 'CR-CONTRALORIA' AS PREV_CD)

UPDATE EXTERNAL_AUDIT
SET FK_AUDITOR_ID = NEW.INSTITUTION_ID
	,MODIFIED = @MODIFIED
	,MODIFIED_BY = @MODIFIED_BY
FROM EXTERNAL_AUDIT
JOIN INSTITUTION AS PREV ON PREV.INSTITUTION_ID = FK_AUDITOR_ID
JOIN UPDATED_CODES ON PREV_CD = PREV.ACRNM
JOIN INSTITUTION AS NEW ON NEW.ACRNM = NEW_CD;

----redirect INSTITUTION_RELATED from 'CH-CONTRALORIA', 'CR-CONTRALORIA' to 'CH-CGR', 'CR-CGR'
WITH UPDATED_CODES AS (
SELECT 'CH-CGR' AS NEW_CD, 'CH-CONTRALORIA' AS PREV_CD UNION ALL
SELECT 'CR-CGR' AS NEW_CD, 'CR-CONTRALORIA' AS PREV_CD)

UPDATE INSTITUTION_RELATED
SET FK_INSTITUTION_ID = NEW.INSTITUTION_ID
	,MODIFIED = @MODIFIED
	,MODIFIED_BY = @MODIFIED_BY
FROM INSTITUTION_RELATED
JOIN INSTITUTION AS PREV ON PREV.INSTITUTION_ID = FK_INSTITUTION_ID
JOIN UPDATED_CODES ON PREV_CD = PREV.ACRNM
JOIN INSTITUTION AS NEW ON NEW.ACRNM = NEW_CD;

--rename INSTITUTION acronyms
WITH UPDATED_CODES AS (
SELECT 'AR-TCBS' AS NEW_CD, 'AR-TCONTAS' AS PREV_CD UNION ALL
SELECT 'AR-TCME' AS NEW_CD, 'AR-TRIBUNAL MENDOZA' AS PREV_CD UNION ALL
SELECT 'BH-PWC' AS NEW_CD, 'BH-BAHAMAS' AS PREV_CD UNION ALL
SELECT 'BR-GT' AS NEW_CD, 'BR-GRANT' AS PREV_CD UNION ALL
SELECT 'BR-TCEMR' AS NEW_CD, 'BR-TCE MATO GROSSO S' AS PREV_CD UNION ALL
SELECT 'BR-TCEM' AS NEW_CD, 'BR-TC-MINAS GERAIS' AS PREV_CD UNION ALL
SELECT 'BR-TCSC' AS NEW_CD, 'BR-TRIB-CONTAS-SC' AS PREV_CD UNION ALL
SELECT 'DR-DPK' AS NEW_CD, 'DR-DFK-DE JESUS ALME' AS PREV_CD UNION ALL
SELECT 'DR-EY' AS NEW_CD, 'DR-ERNST-YOUNG' AS PREV_CD UNION ALL
SELECT 'GU-CGR' AS NEW_CD, 'GU-' AS PREV_CD UNION ALL
SELECT 'ME-KPMG' AS NEW_CD, 'ME-KPGM' AS PREV_CD)

UPDATE INSTITUTION 
SET ACRNM = UPDATED_CODES.NEW_CD
	,MODIFIED = @MODIFIED
	,MODIFIED_BY = @MODIFIED_BY
FROM UPDATED_CODES
JOIN INSTITUTION ON INSTITUTION.ACRNM = UPDATED_CODES.PREV_CD;
