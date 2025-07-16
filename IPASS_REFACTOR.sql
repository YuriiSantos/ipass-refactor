/*  
 Notas sobre o relatório: 
 Total de atributos: 46
 
 Antigo: 49sec banco / 1:00 via web
 Novo: 2sec banco / 6 sec via web 
 
 Esses sao os passos que usei para otimizar a query antiga:
 
 Criação Index:
 
 Tabela: Escala_Nas: DT_AVALIACAO DESC, DT_LIBERACAO, DT_INATIVACAO
 Tabela: Escala_News: DT_AVALIACAO DESC, DT_LIBERACAO, DT_INATIVACAO
 Tabela: Atend_escala_Braden: DT_AVALIACAO DESC, DT_INATIVACAO
 Tabela: Atendimento_precaucao: DT_ATUALIZACAO DESC 
 Tabela: Cur_ferida: DT_INATIVACAO
 
 
 Criação VIEWS: 
 
 select * from HMMD_PACIENTE_DADOS_BASICOS_V;
 select * from HMMD_ESCALAS_V;
 select * from HMMD_ISOLAMENTO_PRECAUCOES_V;
 select * from HMMD_MEDICAMENTOS_DISPOSITIVOS_V;
 select * from HMMD_ALERTAS_COMPLEMENTOS_V;
 
 
 Atributos alvo:
 
 atendimento
 setor
 leito
 prontuario
 paciente
 dt_entrada
 previsao_alta
 idade
 filtro_idade
 tempo_leito
 dias_internacao
 diagnostico_ds
 peso
 cd_pessoa_fisica
 nas
 clinica
 braden
 bradenq
 scp
 news
 pews
 glasgow
 rass
 comfort_b
 jhon_hopkins
 humpty_dumpty
 nsras
 dini
 isolamento
 antibioticos
 sedacoes
 dispo_calibrado
 dietas_presc
 restri_hidrica
 feridas_relacionadas
 alergias
 panico
 pendencias_enf
 alerta
 sae
 status_vaga
 relacao_pf_adulto
 relacao_pf_infantil
 exames_pendentes
 metas
 meta_simplificada
 
 */

--- SEGUE NOVAS MODIFICAÇÕES


SELECT  *
FROM HMMD_PACIENTE_DADOS_BASICOS_V;

SELECT  *
FROM HMMD_ESCALAS_V;

SELECT  *
FROM HMMD_ISOLAMENTO_PRECAUCOES_V;

SELECT  *
FROM HMMD_MEDICAMENTOS_DISPOSITIVOS_V;

SELECT  *
FROM HMMD_ALERTAS_COMPLEMENTOS_V;

-- ESCALA_NAS 
CREATE INDEX IDX_ESCALA_NAS
ON ESCALA_NAS(DT_AVALIACAO DESC, DT_LIBERACAO, DT_INATIVACAO);

-- ESCALA_NEWS 
CREATE INDEX IDX_ESCALA_NEWS
ON ESCALA_NEWS(DT_AVALIACAO DESC, DT_LIBERACAO, DT_INATIVACAO);

-- ATEND_ESCALA_BRADEN 
CREATE INDEX IDX_ATEND_ESCALA_BRADEN
ON ATEND_ESCALA_BRADEN(DT_AVALIACAO DESC, DT_LIBERACAO, DT_INATIVACAO);

-- ATENDIMENTO_PRECAUCAO 
CREATE INDEX IDX_ATENDIMENTO_PRECAUCAO
ON ATENDIMENTO_PRECAUCAO(DT_ATUALIZACAO DESC, DT_LIBERACAO, DT_INATIVACAO);

-- CUR_FERIDA 
CREATE INDEX IDX_CUR_FERIDA
ON CUR_FERIDA(DT_LIBERACAO, DT_INATIVACAO);

-------------- VIEWS CRIADAS -------------- 

--VIEW HMMD_PACIENTE_DADOS_BASICOS_V 
CREATE VIEW HMMD_PACIENTE_DADOS_BASICOS_V AS
SELECT  DISTINCT t1.nr_atendimento                                AS atendimento
       ,t3.ds_setor_atendimento                                   AS setor
       ,t2.cd_unidade_basica                                      AS leito
       ,t2.nr_agrupamento                                         AS agrupamento_leito
       ,t4.nr_prontuario                                          AS prontuario
       ,upper( tiracento(nvl(t4.nm_social,t4.nm_pessoa_fisica)) ) AS paciente
       ,t1.dt_entrada                                             AS dt_entrada
       ,t1.dt_previsto_alta                                       AS previsao_alta
       ,obter_idade(t4.dt_nascimento,SYSDATE,'S')                 AS idade
       ,EXTRACT( YEAR
FROM SYSDATE ) - EXTRACT( YEAR
FROM T4.DT_NASCIMENTO ) AS FILTRO_IDADE, TRUNC(SYSDATE - t2.dt_entrada_unidade) || 'd ' || TRUNC(MOD((SYSDATE - t2.dt_entrada_unidade) * 24, 24)) || 'h ' || TO_CHAR( TRUNC( MOD((SYSDATE - t2.dt_entrada_unidade) * 24 * 60, 60) ), 'FM00' ) || 'm' AS tempo_leito, CEIL(SYSDATE - t1.dt_entrada) || ' Dias' AS dias_internacao, CASE WHEN OBTER_DESC_CID_DOENCA( SUBSTR( OBTER_CID_ATENDIMENTO(T1.NR_ATENDIMENTO, 'P'), 1, 10 ) ) IS NULL THEN 'SEM DIAGNOSTICO' ELSE UPPER( OBTER_DESC_CID_DOENCA( SUBSTR( OBTER_CID_ATENDIMENTO(T1.NR_ATENDIMENTO, 'P'), 1, 10 ) ) ) END AS diagnostico_ds, CASE WHEN OBTER_ULTIMO_SINAL_VITAL_PESO(T4.CD_PESSOA_FISICA) = ' Kg' THEN NULL ELSE OBTER_ULTIMO_SINAL_VITAL_PESO(T4.CD_PESSOA_FISICA) END AS peso, OBTER_CLINICA(T1.IE_CLINICA) AS clinica, t4.cd_pessoa_fisica
FROM atendimento_paciente t1
INNER JOIN unidade_atendimento t2
ON t1.nr_atendimento = t2.nr_atendimento
INNER JOIN setor_atendimento t3
ON t2.cd_setor_atendimento = t3.cd_setor_atendimento
INNER JOIN pessoa_fisica t4
ON t1.cd_pessoa_fisica = t4.cd_pessoa_fisica
WHERE t1.dt_alta IS NULL;

--VIEW HMMD_ESCALAS_V 
CREATE VIEW HMMD_ESCALAS_V AS
SELECT  t1.nr_atendimento
       ,t_nas.nas
       ,t_braden.braden
       ,t_scp.scp
       ,t_braden_q.bradenq
       ,t_news.news
       ,t_pews.pews
       ,t_glasgow.glasgow
       ,t_rass.rass
       ,t_comfort_b.comfort_b
       ,t_jhon_hopkins.jhon_hopkins
       ,t_humpty_dumpty.humpty_dumpty
       ,t_nsras.nsras
       ,t_dini.dini
FROM atendimento_paciente t1
LEFT JOIN
(
	SELECT  nr_atendimento
	       ,MAX(qt_pontuacao) KEEP( DENSE_RANK LAST ORDER BY  dt_avaliacao ) AS nas
	FROM escala_nas
	WHERE dt_liberacao IS NOT NULL
	AND dt_inativacao IS NULL
	GROUP BY  nr_atendimento
) t_nas
ON t1.nr_atendimento = t_nas.nr_atendimento
LEFT JOIN
(
	SELECT  nr_atendimento
	       ,INITCAP( SUBSTR( OBTER_RESULTADO_BRADEN( MAX(qt_ponto) KEEP ( DENSE_RANK LAST ORDER BY  dt_avaliacao ) ),1,255 ) ) AS braden
	FROM atend_escala_braden
	WHERE dt_liberacao IS NOT NULL
	AND dt_inativacao IS NULL
	GROUP BY  nr_atendimento
) t_braden
ON T1.nr_atendimento = t_braden.nr_atendimento
LEFT JOIN
(
	SELECT  nr_atendimento
	       ,INITCAP( SUBSTR( OBTER_DESCRICAO_PADRAO( 'GCA_GRADACAO','DS_GRADACAO',MAX(nr_seq_gradacao) KEEP ( DENSE_RANK LAST ORDER BY  dt_avaliacao ) ),1,100 ) ) AS scp
	FROM gca_atendimento
	WHERE dt_liberacao IS NOT NULL
	AND dt_inativacao IS NULL
	GROUP BY  nr_atendimento
) t_scp
ON T1.nr_atendimento = t_scp.nr_atendimento
LEFT JOIN
(
	SELECT  nr_atendimento
	       ,INITCAP( SUBSTR( OBTER_RESULTADO_BRADEN_Q( MAX(qt_ponto) KEEP ( DENSE_RANK LAST ORDER BY  dt_avaliacao ) ),1,255 ) ) AS bradenq
	FROM atend_escala_braden_q
	WHERE dt_liberacao IS NOT NULL
	AND dt_inativacao IS NULL
	GROUP BY  nr_atendimento
) t_braden_q
ON t1.nr_atendimento = t_braden_q.nr_atendimento
LEFT JOIN
(
	SELECT  nr_atendimento
	       ,MAX(qt_pontuacao) KEEP ( DENSE_RANK LAST ORDER BY  dt_avaliacao ) || ' - ' || TO_CHAR( MAX(dt_avaliacao) KEEP ( DENSE_RANK LAST ORDER BY dt_avaliacao ),'DD/MM/YYYY' ) AS news
	FROM escala_news
	WHERE dt_liberacao IS NOT NULL
	AND dt_inativacao IS NULL
	GROUP BY  nr_atendimento
) t_news
ON t1.nr_atendimento = t_news.nr_atendimento
LEFT JOIN
(
	SELECT  nr_atendimento
	       ,MAX(qt_pontuacao) KEEP ( DENSE_RANK LAST ORDER BY  dt_avaliacao ) || ' - ' || TO_CHAR( MAX(dt_avaliacao) KEEP ( DENSE_RANK LAST ORDER BY dt_avaliacao ),'DD/MM/YYYY' ) AS pews
	FROM escala_pews
	WHERE dt_liberacao IS NOT NULL
	AND dt_inativacao IS NULL
	GROUP BY  nr_atendimento
) t_pews
ON t1.nr_atendimento = t_pews.nr_atendimento
LEFT JOIN
(
	SELECT  nr_atendimento
	       ,MAX(qt_glasgow) KEEP ( DENSE_RANK LAST ORDER BY  dt_avaliacao ) AS glasgow
	FROM atend_escala_indice
	WHERE dt_liberacao IS NOT NULL
	AND dt_inativacao IS NULL
	GROUP BY  nr_atendimento
) t_glasgow
ON t1.nr_atendimento = t_glasgow.nr_atendimento
LEFT JOIN
(
	SELECT  nr_atendimento
	       ,MAX(ie_rass) KEEP ( DENSE_RANK LAST ORDER BY  dt_avaliacao,ROWID ) AS rass
	FROM escala_richmond
	WHERE dt_liberacao IS NOT NULL
	AND dt_inativacao IS NULL
	GROUP BY  nr_atendimento
) t_rass
ON t1.nr_atendimento = t_rass.nr_atendimento
LEFT JOIN
(
	SELECT  nr_atendimento
	       ,MAX(qt_pontuacao) KEEP ( DENSE_RANK LAST ORDER BY  dt_avaliacao ) AS comfort_b
	FROM escala_comfort_b
	WHERE dt_liberacao IS NOT NULL
	AND dt_inativacao IS NULL
	GROUP BY  nr_atendimento
) t_comfort_b
ON t1.nr_atendimento = t_comfort_b.nr_atendimento
LEFT JOIN
(
	SELECT  eif.nr_atendimento
	       ,MAX(sar.ds_resultado) KEEP ( DENSE_RANK LAST ORDER BY  eif.dt_avaliacao ) AS jhon_hopkins
	FROM escala_eif_ii eif
	INNER JOIN score_avaliacao_result sar
	ON eif.nr_sequencia = sar.nr_seq_avaliacao
	WHERE eif.nr_seq_escala = 63
	AND sar.nr_seq_item = 44016
	AND eif.dt_liberacao IS NOT NULL
	AND eif.dt_inativacao IS NULL
	GROUP BY  eif.nr_atendimento
) t_jhon_hopkins
ON t1.nr_atendimento = t_jhon_hopkins.nr_atendimento
LEFT JOIN
(
	SELECT  eif.nr_atendimento
	       ,INITCAP( MAX(sar.ds_resultado) KEEP ( DENSE_RANK LAST ORDER BY  eif.dt_avaliacao ) ) AS humpty_dumpty
	FROM escala_eif_ii eif
	INNER JOIN score_avaliacao_result sar
	ON eif.nr_sequencia = sar.nr_seq_avaliacao
	WHERE eif.nr_seq_escala = 61
	AND sar.nr_seq_item = 43992
	AND eif.dt_liberacao IS NOT NULL
	AND eif.dt_inativacao IS NULL
	GROUP BY  eif.nr_atendimento
) t_humpty_dumpty
ON t1.nr_atendimento = t_humpty_dumpty.nr_atendimento
LEFT JOIN
(
	SELECT  eif.nr_atendimento
	       ,UPPER( MAX(sar.ds_resultado) KEEP ( DENSE_RANK LAST ORDER BY  eif.dt_avaliacao ) ) AS nsras
	FROM escala_eif_ii eif
	INNER JOIN score_avaliacao_result sar
	ON eif.nr_sequencia = sar.nr_seq_avaliacao
	WHERE eif.nr_seq_escala = 62
	AND sar.nr_seq_item = 44280
	AND eif.dt_liberacao IS NOT NULL
	AND eif.dt_inativacao IS NULL
	GROUP BY  eif.nr_atendimento
) t_nsras
ON t1.nr_atendimento = t_nsras.nr_atendimento
LEFT JOIN
(
	SELECT  nr_atendimento
	       ,INITCAP( SUBSTR( OBTER_RESULT_DINI( 'S',MAX(qt_pontuacao) KEEP ( DENSE_RANK LAST ORDER BY  dt_avaliacao,ROWID ) ),1,100 ) ) AS dini
	FROM escala_dini
	WHERE dt_liberacao IS NOT NULL
	AND dt_inativacao IS NULL
	GROUP BY  nr_atendimento
) t_dini
ON t1.nr_atendimento = t_dini.nr_atendimento
WHERE t1.dt_alta IS NULL;

--VIEW HMMD_ISOLAMENTO_PRECAUCOES_V 
CREATE VIEW HMMD_ISOLAMENTO_PRECAUCOES_V AS
SELECT  ap.nr_atendimento
       ,t_isolamento.isolamento
FROM atendimento_paciente ap
LEFT JOIN
(
	SELECT  nr_atendimento
	       ,MAX( CASE WHEN nr_seq_precaucao = 5 THEN 'Precaução de Aerossóis ' WHEN nr_seq_precaucao = 6 THEN 'Precaução de Aerossóis e Contato' WHEN nr_seq_precaucao = 2 THEN 'Precaução de Contato' WHEN nr_seq_precaucao = 3 THEN 'Precaução de Contato Especial' WHEN nr_seq_precaucao = 4 THEN 'Precaução de Gotículas' WHEN nr_seq_precaucao = 7 THEN 'Precaução de Gotículas e Contato' ELSE '' END ) KEEP ( DENSE_RANK LAST ORDER BY  dt_atualizacao,ROWID ) AS isolamento
	FROM atendimento_precaucao
	WHERE dt_liberacao IS NOT NULL
	AND dt_inativacao IS NULL
	GROUP BY  nr_atendimento
) t_isolamento
ON ap.nr_atendimento = t_isolamento.nr_atendimento
WHERE ap.dt_alta IS NULL;

--VIEW HMMD_MEDICAMENTOS_DISPOSITIVOS_V 
CREATE VIEW HMMD_MEDICAMENTOS_DISPOSITIVOS_V AS
SELECT  ap.nr_atendimento
       ,UPPER( COALESCE(t_atb.antibioticos,'Sem ATB prescrito') )            AS antibioticos
       ,COALESCE(t_sedacoes.sedacoes,'SEM SEDATIVO')                         AS sedacoes
       ,COALESCE( t_dispositivos.dispositivos_calibrados,'SEM DISPOSITIVO' ) AS dispo_calibrado
       ,UPPER( COALESCE(t_dietas.dietas_presc,'Sem dieta prescrita') )       AS dietas_presc
       ,COALESCE( t_restricao.restri_hidrica,'Sem restrição hidrica' )       AS restri_hidrica
FROM atendimento_paciente ap
LEFT JOIN HMMD_ATB_PRESCR_DIA_V t_atb
ON ap.nr_atendimento = t_atb.nr_atendimento
LEFT JOIN
(
	SELECT  b.nr_atendimento
	       ,LISTAGG( DISTINCT OBTER_DESC_FICHA_TECNICA(d.nr_seq_ficha_tecnica),chr(10) ) WITHIN GROUP
	(
		ORDER BY OBTER_DESC_FICHA_TECNICA(d.nr_seq_ficha_tecnica)
	) AS sedacoes
	FROM cpoe_material b
	INNER JOIN mat_estrutura_cadastro C
	ON b.cd_material = C.cd_material
	INNER JOIN material d
	ON b.cd_material = d.cd_material
	WHERE C.nr_seq_estrutura = '57'
	AND ( b.dt_fim >= TRUNC(SYSDATE) OR b.dt_fim IS NULL )
	AND b.dt_suspensao IS NULL
	GROUP BY  b.nr_atendimento
) t_sedacoes
ON ap.nr_atendimento = t_sedacoes.nr_atendimento
LEFT JOIN
(
	SELECT  T1.NR_ATENDIMENTO
	       ,LISTAGG ( UPPER(t2.ds_disp_adep) || ' (' || UPPER(OBTER_CALIBRE (T1.NR_SEQ_CALIBRE)) || ') - ' || TO_CHAR (T1.DT_INSTALACAO,'DD/MM/YYYY') || ' - ' || ( CASE WHEN OBTER_STATUS_DISPOSITIVO (T1.NR_SEQUENCIA,1) = 'A' THEN 'EM ANDAMENTO ' WHEN OBTER_STATUS_DISPOSITIVO (T1.NR_SEQUENCIA,1) = 'V' THEN 'EXPIRADO ' ELSE 'SEM DISPOSITIVOS' END ) || CHR (10) ) WITHIN GROUP
	(
		ORDER BY T1.DT_INSTALACAO
	) AS DISPOSITIVOS_CALIBRADOS
	FROM ATEND_PAC_DISPOSITIVO T1
	INNER JOIN dispositivo t2
	ON t1.nr_seq_dispositivo = t2.nr_sequencia
	WHERE t1.dt_retirada IS NULL
	AND OBTER_STATUS_DISPOSITIVO(t1.nr_sequencia, 1) IN ('A', 'V')
	GROUP BY  t1.nr_atendimento
) t_dispositivos
ON ap.nr_atendimento = t_dispositivos.nr_atendimento
LEFT JOIN
(
	SELECT  nr_atendimento
	       ,LISTAGG(dietas_presc || ',' || CHR(10),'') WITHIN GROUP
	(
		ORDER BY dietas_presc
	) AS dietas_presc
	FROM HMBM_DIETA_PRESC_V2
	WHERE tipo IN ( 'Dietas Orais', 'Jejum', 'Enterais', 'Copo/Mamadeira', 'Frascos/Seringa' )
	GROUP BY  nr_atendimento
) t_dietas
ON ap.nr_atendimento = t_dietas.nr_atendimento
LEFT JOIN
(
	SELECT  nr_atendimento
	       ,MAX(OBTER_NOME_DIETA(cd_dieta)) KEEP ( DENSE_RANK LAST ORDER BY  dt_liberacao,ROWID ) AS restri_hidrica
	FROM cpoe_dieta
	WHERE cd_dieta IN (87, 23, 86)
	AND ( dt_fim >= TRUNC(SYSDATE) OR dt_fim IS NULL )
	AND dt_suspensao IS NULL
	AND dt_liberacao IS NOT NULL
	GROUP BY  nr_atendimento
) t_restricao
ON ap.nr_atendimento = t_restricao.nr_atendimento
WHERE ap.dt_alta IS NULL;

--VIEW HMMD_ALERTAS_COMPLEMENTOS_V 
CREATE VIEW HMMD_ALERTAS_COMPLEMENTOS_V AS
SELECT  ap.nr_atendimento
       ,ap.cd_pessoa_fisica
       ,UPPER( COALESCE(t_feridas.feridas_relacionadas,'SEM FERIDAS') ) AS feridas_relacionadas
       ,t_alergias.alergias
       ,t_panico.panico
       ,t_pendencias.pendencias_enf
       ,t_alertas.alerta
       ,TO_CHAR(t_sae.fim_da_validade,'DD/MM/YY HH24:MI')               AS sae
       ,COALESCE(t_vaga.status_vaga,'S/ vaga solicitada')               AS status_vaga
       ,t_relacao_pf.relacao_pf_adulto
       ,t_relacao_pf.relacao_pf_infantil
       ,t_exames.exames_pendentes
       ,t_metas.metas
       ,t_meta.meta_simplificada
FROM atendimento_paciente ap
LEFT JOIN
(
	SELECT  nr_atendimento
	       ,COALESCE( LISTAGG( UPPER( CASE WHEN localizacao_ferida IS NULL THEN ' Sem feridas' ELSE ' Ferida ' || rn || ': ' || localizacao_ferida || ' - ' || ds_classificacao END ),CHR(10) ) WITHIN GROUP
	(
		ORDER BY dt_liberacao
	), 'SEM FERIDAS' ) AS feridas_relacionadas
	FROM
	(
		SELECT  cf.nr_atendimento
		       ,cf.dt_liberacao
		       ,ROW_NUMBER() OVER ( PARTITION BY cf.nr_atendimento ORDER BY  cf.dt_liberacao ) AS rn
		       ,OBTER_LOCALIZACAO_FERIDA(cf.nr_seq_localizacao)                                AS localizacao_ferida
		       ,ccf.ds_classificacao
		FROM cur_ferida cf
		LEFT JOIN cur_classif_ferida ccf
		ON cf.nr_seq_classif_ferida = ccf.nr_sequencia
		WHERE cf.dt_liberacao IS NOT NULL
		AND cf.dt_inativacao IS NULL
		AND dt_alta_curativo IS NULL 
	)
	GROUP BY  nr_atendimento
) t_feridas
ON ap.nr_atendimento = t_feridas.nr_atendimento
LEFT JOIN
(
	SELECT  cd_pessoa_fisica
	       ,LISTAGG(descricao_alergia,', ') WITHIN GROUP
	(
		ORDER BY descricao_alergia
	) AS alergias
	FROM HMMD_PASSAGEM_PLANTAO_ALERGIA
	GROUP BY  cd_pessoa_fisica
) t_alergias
ON ap.cd_pessoa_fisica = t_alergias.cd_pessoa_fisica
LEFT JOIN
(
	SELECT  nr_atendimento
	       ,LISTAGG( 'Pânico ' || seq_panico || ': ' || ds_panico || '; ','' ) WITHIN GROUP
	(
		ORDER BY dt_atualizacao DESC
	) AS panico
	FROM
	(
		SELECT  DISTINCT nr_atendimento
		       ,dt_atualizacao
		       ,UPPER( SUBSTR( OBTER_DESC_RESULT_AVALIACAO(nr_sequencia,44352),1,600 ) ) || ' - ' || SUBSTR( OBTER_DESC_RESULT_AVALIACAO(nr_sequencia,44353),1,600 ) AS ds_panico
		       ,ROW_NUMBER() OVER ( PARTITION BY nr_atendimento ORDER BY  dt_atualizacao DESC ) AS seq_panico
		FROM med_avaliacao_paciente
		WHERE dt_liberacao IS NOT NULL
		AND dt_inativacao IS NULL
		AND nr_seq_tipo_avaliacao = 1021
		AND dt_atualizacao >= SYSDATE - 7 
	)
	GROUP BY  nr_atendimento
) t_panico
ON ap.nr_atendimento = t_panico.nr_atendimento
LEFT JOIN
(
	SELECT  nr_atendimento
	       ,LISTAGG( 'Pendencia ' || seq_anotacao || ': ' || ds_anotacao || '; ','' ) WITHIN GROUP
	(
		ORDER BY dt_atualizacao DESC
	) AS pendencias_enf
	FROM
	(
		SELECT  DISTINCT nr_atendimento
		       ,dt_atualizacao
		       ,UPPER(ds_anotacao)                                                              AS ds_anotacao
		       ,ROW_NUMBER() OVER ( PARTITION BY nr_atendimento ORDER BY  dt_atualizacao DESC ) AS seq_anotacao
		FROM atendimento_anot_enf
		WHERE ie_pendente = 'S'
		AND dt_liberacao IS NOT NULL 
	)
	GROUP BY  nr_atendimento
) t_pendencias
ON ap.nr_atendimento = t_pendencias.nr_atendimento
LEFT JOIN
(
	SELECT  nr_atendimento
	       ,MAX(ds_alerta) KEEP ( DENSE_RANK LAST ORDER BY  dt_atualizacao,ROWID ) AS alerta
	FROM atendimento_alerta
	WHERE dt_liberacao IS NOT NULL
	AND dt_inativacao IS NULL
	GROUP BY  nr_atendimento
) t_alertas
ON ap.nr_atendimento = t_alertas.nr_atendimento
LEFT JOIN
(
	SELECT  nr_atendimento
	       ,MAX(dt_validade_prescr) KEEP ( DENSE_RANK LAST ORDER BY  dt_prescricao,ROWID ) AS fim_da_validade
	FROM pe_prescricao
	WHERE dt_liberacao IS NOT NULL
	AND dt_inativacao IS NULL
	GROUP BY  nr_atendimento
) t_sae
ON ap.nr_atendimento = t_sae.nr_atendimento
LEFT JOIN
(
	SELECT  nr_atendimento
	       ,MAX( CASE WHEN SUBSTR(OBTER_DESC_STATUS_GV(ie_status,'D'),1,100) IN ('Finalizado','Acomodado') THEN 'Finalizada' ELSE SUBSTR(OBTER_DESC_STATUS_GV(ie_status,'D'),1,100) END || ' - Clínica: ' || SUBSTR(OBTER_VALOR_DOMINIO(1410,ie_tipo_vaga),1,100) ) KEEP ( DENSE_RANK LAST ORDER BY  dt_atualizacao,ROWID ) AS status_vaga
	FROM gestao_vaga
	GROUP BY  nr_atendimento
) t_vaga
ON ap.nr_atendimento = t_vaga.nr_atendimento
LEFT JOIN
(
	SELECT  nr_atendimento
	       ,MAX( CASE WHEN nr_seq_tipo_avaliacao = 945 THEN SUBSTR( OBTER_DESC_RESULT_AVALIACAO(nr_sequencia,44414),1,600 ) END ) KEEP ( DENSE_RANK LAST ORDER BY  CASE WHEN nr_seq_tipo_avaliacao = 945 THEN dt_atualizacao END,ROWID ) AS relacao_pf_adulto
	       ,MAX( CASE WHEN nr_seq_tipo_avaliacao = 947 THEN SUBSTR( OBTER_DESC_RESULT_AVALIACAO(nr_sequencia,44421),1,600 ) END ) KEEP ( DENSE_RANK LAST ORDER BY CASE WHEN nr_seq_tipo_avaliacao = 947 THEN dt_atualizacao END,ROWID ) AS relacao_pf_infantil
	FROM med_avaliacao_paciente
	WHERE dt_liberacao IS NOT NULL
	AND dt_inativacao IS NULL
	AND nr_seq_tipo_avaliacao IN (945, 947)
	GROUP BY  nr_atendimento
) t_relacao_pf
ON ap.nr_atendimento = t_relacao_pf.nr_atendimento
LEFT JOIN HMMD_QTDE_EXAMES_PENDENTES_V t_exames
ON ap.nr_atendimento = t_exames.nr_atendimento
LEFT JOIN
(
	SELECT  nr_atendimento
	       ,REPLACE( UPPER( LISTAGG(ds_recomendacao,'; ') WITHIN GROUP
	(
		ORDER BY dt_atualizacao DESC
	) ), CHR(10), ', ' ) AS metas
	FROM cpoe_recomendacao
	WHERE cd_recomendacao = 115
	AND ( dt_fim >= TRUNC(SYSDATE) OR dt_fim IS NULL )
	AND dt_suspensao IS NULL
	GROUP BY  nr_atendimento
) t_metas
ON ap.nr_atendimento = t_metas.nr_atendimento
LEFT JOIN
(
	SELECT  nr_atendimento
	       ,obter_result_avaliacao( nr_sequencia,CASE nr_seq_tipo_avaliacao WHEN 881 THEN 48315 WHEN 896 THEN 48316 END ) AS meta_simplificada
	FROM
	(
		SELECT  nr_atendimento
		       ,nr_sequencia
		       ,nr_seq_tipo_avaliacao
		       ,ROW_NUMBER() OVER ( PARTITION BY nr_atendimento ORDER BY  nr_seq_tipo_avaliacao DESC,dt_avaliacao DESC ) AS rn
		FROM med_avaliacao_paciente
		WHERE nr_seq_tipo_avaliacao IN (881, 896)
		AND ie_situacao = 'A' 
	)
	WHERE rn = 1 
) t_meta
ON ap.nr_atendimento = t_meta.nr_atendimento
WHERE ap.dt_alta IS NULL;

---------------------------- NOVO RELATORIO IPASS ADULTO ----------------------------

--Query principal adulto (Relatorio TASY) 
SELECT  base.atendimento
       ,CASE WHEN :setor = 'EMERGENCIA ADULTO' THEN 'EMERGENCIA ADULTO'
             WHEN :setor = 'UNIDADE DE TRANSIÇÃO AVANÇADA' THEN 'UNIDADE DE TRANSIÇÃO AVANÇADA'
             WHEN :setor = 'UNIDADE DE DECISÃO CLÍNICA' THEN 'UNIDADE DE DECISÃO CLÍNICA'  ELSE base.setor END AS setor
       ,base.leito
       ,base.agrupamento_leito
       ,base.prontuario
       ,base.paciente
       ,base.dt_entrada
       ,base.previsao_alta
       ,base.idade
       ,base.filtro_idade
       ,base.tempo_leito
       ,base.dias_internacao
       ,base.diagnostico_ds
       ,base.peso
       ,base.clinica
       ,base.cd_pessoa_fisica
       ,escalas.nas
       ,escalas.braden
       ,escalas.bradenq
       ,escalas.scp
       ,escalas.news
       ,escalas.pews
       ,escalas.glasgow
       ,escalas.rass
       ,escalas.comfort_b
       ,escalas.jhon_hopkins
       ,escalas.humpty_dumpty
       ,escalas.nsras
       ,escalas.dini
       ,isolamento.isolamento
       ,med_disp.antibioticos
       ,med_disp.sedacoes
       ,med_disp.dispo_calibrado
       ,med_disp.dietas_presc
       ,med_disp.restri_hidrica
       ,alertas.feridas_relacionadas
       ,alertas.alergias
       ,alertas.panico
       ,alertas.pendencias_enf
       ,alertas.alerta
       ,alertas.sae
       ,alertas.status_vaga
       ,alertas.relacao_pf_adulto
       ,alertas.relacao_pf_infantil
       ,alertas.exames_pendentes
       ,alertas.metas
       ,alertas.meta_simplificada
FROM HMMD_PACIENTE_DADOS_BASICOS_V base
LEFT JOIN HMMD_ESCALAS_V escalas
ON base.atendimento = escalas.nr_atendimento
LEFT JOIN HMMD_ISOLAMENTO_PRECAUCOES_V isolamento
ON base.atendimento = isolamento.nr_atendimento
LEFT JOIN HMMD_MEDICAMENTOS_DISPOSITIVOS_V med_disp
ON base.atendimento = med_disp.nr_atendimento
LEFT JOIN HMMD_ALERTAS_COMPLEMENTOS_V alertas
ON base.atendimento = alertas.nr_atendimento
WHERE ( :setor IS NULL OR base.agrupamento_leito = CASE WHEN :setor = 'EMERGENCIA ADULTO' THEN 10 WHEN :setor = 'UNIDADE DE TRANSIÇÃO AVANÇADA' THEN 20 WHEN :setor = 'UNIDADE DE DECISÃO CLÍNICA' THEN 30 ELSE NULL END OR ( :setor NOT IN ( 'EMERGENCIA ADULTO', 'UNIDADE DE TRANSIÇÃO AVANÇADA', 'UNIDADE DE DECISÃO CLÍNICA' ) AND base.setor = :setor ) )
ORDER BY 3;

--Parâmetro Setor 
 
WITH setores_existentes AS
(
	SELECT  DISTINCT UPPER(T3.DS_SETOR_ATENDIMENTO) AS CD
	       ,UPPER(T3.DS_SETOR_ATENDIMENTO)          AS DS
	FROM ATENDIMENTO_PACIENTE T1
	INNER JOIN TASY.ATEND_PACIENTE_UNIDADE T2
	ON T2.NR_ATENDIMENTO = T1.NR_ATENDIMENTO AND T2.NR_SEQ_INTERNO = (
	SELECT  MAX(TT1.NR_SEQ_INTERNO)
	FROM TASY.ATEND_PACIENTE_UNIDADE TT1
	WHERE TT1.NR_ATENDIMENTO = T1.NR_ATENDIMENTO
	AND DT_SAIDA_UNIDADE IS NULL )
	INNER JOIN SETOR_ATENDIMENTO T3
	ON T2.CD_SETOR_ATENDIMENTO = T3.CD_SETOR_ATENDIMENTO
	INNER JOIN PESSOA_FISICA T4
	ON T1.CD_PESSOA_FISICA = T4.CD_PESSOA_FISICA
	LEFT JOIN PESSOA_FISICA TT4
	ON T4.CD_PESSOA_MAE = TT4.CD_PESSOA_FISICA
	WHERE T1.DT_ALTA IS NULL
	AND T2.CD_SETOR_ATENDIMENTO NOT IN (53, 55, 66, 73, 115)
	AND T1.IE_TIPO_ATENDIMENTO = 1 
), setores_customizados AS
(
	SELECT  'UNIDADE DE DECISÃO CLÍNICA' AS CD
	       ,'UNIDADE DE DECISÃO CLÍNICA' AS DS
	FROM DUAL
)
SELECT  CD
       ,DS
FROM setores_existentes
UNION ALL
SELECT  CD
       ,DS
FROM setores_customizados
ORDER BY 1;


--------------------------------------------------------------------------------
---------------------------- NOVO RELATORIO IPASS KIDS ------------------------------ 

--Query principal kids (Relatorio TASY) 
SELECT  base.atendimento
       ,base.setor
       ,base.leito
       ,base.prontuario
       ,base.paciente
       ,base.dt_entrada
       ,base.previsao_alta
       ,base.idade
       ,base.filtro_idade
       ,base.tempo_leito
       ,base.dias_internacao
       ,base.diagnostico_ds
       ,base.peso
       ,base.clinica
       ,base.cd_pessoa_fisica
       ,escalas.nas
       ,escalas.braden
       ,escalas.bradenq
       ,escalas.scp
       ,escalas.news
       ,escalas.pews
       ,escalas.glasgow
       ,escalas.rass
       ,escalas.comfort_b
       ,escalas.jhon_hopkins
       ,escalas.humpty_dumpty
       ,escalas.nsras
       ,escalas.dini
       ,isolamento.isolamento
       ,med_disp.antibioticos
       ,med_disp.sedacoes
       ,med_disp.dispo_calibrado
       ,med_disp.dietas_presc
       ,med_disp.restri_hidrica
       ,alertas.feridas_relacionadas
       ,alertas.alergias
       ,alertas.panico
       ,alertas.pendencias_enf
       ,alertas.alerta
       ,alertas.sae
       ,alertas.status_vaga
       ,alertas.relacao_pf_adulto
       ,alertas.relacao_pf_infantil
       ,alertas.exames_pendentes
       ,alertas.metas
       ,alertas.meta_simplificada
FROM HMMD_PACIENTE_DADOS_BASICOS_V base
LEFT JOIN HMMD_ESCALAS_V escalas
ON base.atendimento = escalas.nr_atendimento
LEFT JOIN HMMD_ISOLAMENTO_PRECAUCOES_V isolamento
ON base.atendimento = isolamento.nr_atendimento
LEFT JOIN HMMD_MEDICAMENTOS_DISPOSITIVOS_V med_disp
ON base.atendimento = med_disp.nr_atendimento
LEFT JOIN HMMD_ALERTAS_COMPLEMENTOS_V alertas
ON base.atendimento = alertas.nr_atendimento
WHERE base.setor = :setor
ORDER BY 3;

--Parâmetro Setor kids
SELECT  DISTINCT UPPER(T3.DS_SETOR_ATENDIMENTO) AS CD
       ,UPPER(T3.DS_SETOR_ATENDIMENTO)          AS DS
FROM ATENDIMENTO_PACIENTE T1
LEFT JOIN UNIDADE_ATENDIMENTO T2
ON T1.NR_ATENDIMENTO = T2.NR_ATENDIMENTO
LEFT JOIN SETOR_ATENDIMENTO T3
ON T2.CD_SETOR_ATENDIMENTO = T3.CD_SETOR_ATENDIMENTO
WHERE T1.DT_ALTA IS NULL
AND T2.CD_SETOR_ATENDIMENTO NOT IN ( 33, 45, 47, 49, 64, 59, 139, 135, 112, 100, 71, 72, 74, 76, 90 )
AND T1.IE_TIPO_ATENDIMENTO = 1
ORDER BY 1;

--------------------------------------------------------------------------------
------------------------------BACKUP--------------------------------------------

 /* 
 OBS BACKUP: BASTA FAZER A SUBSTITUIÇÃO DAS QUERYS E PARAMETROS CASO SEJA NECESSARIO UM BACKUP. 
 A ESTRUTURA DO RELATORIO PARA VISUALIZACAO OS ITENS SE MANTEM OS MESMOS 
 -*/
 
-- BACKUP RELATORIOS IPASS ADULTO SQL ANTIGO
SELECT  DISTINCT ATENDIMENTO
       ,SETOR
       ,LEITO
       ,PRONTUARIO
       ,PACIENTE
       ,DT_ENTRADA
       ,TO_CHAR(PREVISAO_ALTA,'DD/MM/YYYY') AS PREVISAO_ALTA
       ,IDADE
       ,TEMPO_LEITO
       ,DIAS_INTERNACAO
       ,ISOLAMENTO
       ,DIAGNOSTICO_DS
       ,PESO
       ,CLINICA
       ,NAS
       ,BRADEN
       ,SCP
       ,NEWS
       ,SAE
       ,GLASGOW
       ,RASS
       ,COMFORT_B
       ,JHON_HOPKINS
       ,DISPO_CALIBRADO
       ,DIETAS_PRESC
       ,FERIDAS_RELACIONADAS
       ,RESTRI_HIDRICA
       ,ANTIBIOTICOS
       ,REPLACE(UPPER(ALERTA),' ')          AS ALERTA
       ,ALERGIAS
       ,PANICO
       ,SEDACOES
       ,REPLACE(UPPER(METAS),CHR(10),', ')  AS METAS
       ,RELACAO_PF_ADULTO
       ,EXAMES_PENDENTES
       ,PENDENCIAS_ENF
       ,FILTRO_IDADE
       ,STATUS_VAGA
       ,META_SIMPLIFICADA
FROM HMMD_PASSAGEM_PLANTAO_V T1
WHERE :SETOR = SETOR
ORDER BY 3;

-- ADULTO PARAMETRO -- 

SELECT  DISTINCT UPPER(T3.DS_SETOR_ATENDIMENTO) AS CD
       ,UPPER(T3.DS_SETOR_ATENDIMENTO)          AS DS
FROM ATENDIMENTO_PACIENTE T1
INNER JOIN TASY.ATEND_PACIENTE_UNIDADE T2
ON T2.NR_ATENDIMENTO = T1.NR_ATENDIMENTO AND T2.NR_SEQ_INTERNO = (
SELECT  MAX(TT1.NR_SEQ_INTERNO)
FROM TASY.ATEND_PACIENTE_UNIDADE TT1
WHERE TT1.NR_ATENDIMENTO = T1.NR_ATENDIMENTO -- AND TT1.CD_TIPO_ACOMODACAO = 3) 
 AND DT_SAIDA_UNIDADE IS NULL )
INNER JOIN SETOR_ATENDIMENTO T3
ON T2.CD_SETOR_ATENDIMENTO = T3.CD_SETOR_ATENDIMENTO
INNER JOIN PESSOA_FISICA T4
ON T1.CD_PESSOA_FISICA = T4.CD_PESSOA_FISICA
LEFT JOIN PESSOA_FISICA TT4
ON T4.CD_PESSOA_MAE = TT4.CD_PESSOA_FISICA
WHERE T1.DT_ALTA IS NULL
AND T2.CD_SETOR_ATENDIMENTO NOT IN (53, 55, 66, 73, 115)
AND T1.IE_TIPO_ATENDIMENTO = 1
ORDER BY 1;


-------------------------------------------------------------------------------- 
 /* BACKUP RELATORIOS IPASS KIDS SQL ANTIGO -*/

SELECT  DISTINCT ATENDIMENTO
       ,SETOR
       ,LEITO
       ,PRONTUARIO
       ,PACIENTE
       ,DT_ENTRADA
       ,PREVISAO_ALTA
       ,IDADE
       ,TEMPO_LEITO
       ,DIAS_INTERNACAO
       ,ISOLAMENTO
       ,DIAGNOSTICO_DS
       ,PESO
       ,CLINICA
       ,NAS
       ,SCP
       ,BRADENQ
       ,PEWS
       ,SAE
       ,DINI AS DINI
       ,COMFORT_B
       ,HUMPTY_DUMPTY
       ,NSRAS
       ,DISPO_CALIBRADO
       ,DIETAS_PRESC
       ,FERIDAS_RELACIONADAS
       ,RESTRI_HIDRICA
       ,ANTIBIOTICOS
       ,ALERTA
       ,ALERGIAS
       ,PANICO
       ,SEDACOES
       ,METAS
       ,RELACAO_PF_INFANTIL
       ,EXAMES_PENDENTES
       ,PENDENCIAS_ENF
       ,FILTRO_IDADE
       ,STATUS_VAGA
       ,META_SIMPLIFICADA
FROM HMMD_PASSAGEM_PLANTAO_V
WHERE :SETOR = SETOR
ORDER BY 3;

-- KIDS PARAMETRO -- 

SELECT  DISTINCT UPPER(T3.DS_SETOR_ATENDIMENTO) AS CD
       ,UPPER(T3.DS_SETOR_ATENDIMENTO)          AS DS
FROM ATENDIMENTO_PACIENTE T1
LEFT JOIN UNIDADE_ATENDIMENTO T2
ON T1.NR_ATENDIMENTO = T2.NR_ATENDIMENTO
LEFT JOIN SETOR_ATENDIMENTO T3
ON T2.CD_SETOR_ATENDIMENTO = T3.CD_SETOR_ATENDIMENTO
WHERE T1.DT_ALTA IS NULL
AND T2.CD_SETOR_ATENDIMENTO NOT IN ( 33, 45, 47, 49, 64, 59, 139, 135, 112, 100, 71, 72, 74, 76, 90 )
AND T1.IE_TIPO_ATENDIMENTO = 1
ORDER BY 1;
---------------------------------------------------------------------------------------------------
