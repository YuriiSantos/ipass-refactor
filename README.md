# Otimização do Relatório de Passagem de Plantão

## O Problema que Enfrentei

O relatório de passagem de plantão estava com sérios problemas de performance. A query original era uma verdadeira "monster query" com 46 campos diferentes, mais de 25 LEFT JOINs complexos e várias subconsultas usando ROW_NUMBER() repetidamente. Para piorar, não havia índices específicos nas tabelas que mais sofriam com consultas pesadas.

O resultado? Relatório lento, mais de um minuto para carregar.

## A Estratégia que Adotei

Decidi atacar o problema de duas formas: **melhorar o acesso aos dados** e **simplificar a arquitetura**.

### Primeiro: Criei Índices Estratégicos

Analisei onde estavam os gargalos e criei índices focados nas consultas mais custosas:

- **Escala_Nas**: DT_AVALIACAO DESC, DT_LIBERACAO, DT_INATIVACAO
- **Escala_News**: DT_AVALIACAO DESC, DT_LIBERACAO, DT_INATIVACAO
- **Atend_escala_Braden**: DT_AVALIACAO DESC, DT_INATIVACAO
- **Atendimento_precaucao**: DT_ATUALIZACAO DESC
- **Cur_ferida**: DT_INATIVACAO

### Segundo: Dividi a Query em Views Especializadas

Em vez de uma query gigante fazendo tudo, criei 5 views organizadas por assunto:

- **HMMD_PACIENTE_DADOS_BASICOS_V** - Informações básicas do paciente
- **HMMD_ESCALAS_V** - Todas as escalas (NAS, NEWS, Braden, etc.)
- **HMMD_ISOLAMENTO_PRECAUCOES_V** - Precauções e isolamentos
- **HMMD_MEDICAMENTOS_DISPOSITIVOS_V** - Medicamentos e dispositivos
- **HMMD_ALERTAS_COMPLEMENTOS_V** - Alertas, pânico e pendências

## Os Resultados que Obtive

### Performance Melhorou Bastante

- Consultas ficaram mais rápidas com os índices otimizados
- Oracle consegue fazer cache inteligente das views
- Menos JOINs complexos na query principal

### Manutenção Ficou Muito Mais Fácil

- Código organizado por responsabilidade
- Se der problema em escalas, sei exatamente onde mexer
- Posso reutilizar as views em outros relatórios

### Sistema Mais Preparado para o Futuro

- Oracle consegue paralelizar as consultas automaticamente
- Menos contenção de recursos
- Arquitetura preparada para crescer

## O Que Aprendi

A estratégia de **"dividir para conquistar"** funcionou muito bem. Em vez de tentar otimizar uma query monstruosa, quebrei ela em pedaços menores e mais gerenciáveis. Cada view tem uma responsabilidade específica, o que torna tudo mais fácil de entender e manter.

O resultado final foi um relatório que mantém todas as funcionalidades originais, mas roda muito mais rápido e é muito mais fácil de manter.

## IMPORTANTE

*PARA REALIZAR O BACKUP BASTA SUBSTITUIR A NOVA (QUERY PRINCIPAL + PARAMETRO) PELO BACKUP ANTIGO.
*NAO FOI MODIFICADA A ESTRUTURA DE VISUALIZACAO DO RELATORIO DENTRO DO TASY APENAS SUBSTITUCAO DE SQL.
\*BACKUP NO FINAL DO RELATÓRIO.
