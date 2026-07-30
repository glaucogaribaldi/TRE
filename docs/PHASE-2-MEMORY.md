# TRE — Fase 2: memoria persistente

## Obiettivo

Rendere la memoria di TRE indipendente dal modello AI e resistente a riavvii, cambi di provider e sostituzioni della macchina.

## Componenti

- PostgreSQL + pgvector: fatti strutturati, eventi, task, fonti e versioni.
- Redis: code, lock e working memory temporanea.
- Qdrant: ricerca semantica su conversazioni e documenti.
- Mem0: estrazione automatica delle memorie candidate.
- Graphiti: relazioni temporali tra persone, progetti, account, macchine e credenziali.
- MNEMOSYNE: agente separato che consolida, deduplica e verifica la memoria.

## Regole

1. I segreti non entrano nella memoria: si salva soltanto un riferimento `vault://...`.
2. Ogni fatto conserva fonte, data, confidenza, ambito e stato.
3. Le correzioni non cancellano la storia: sostituiscono il fatto precedente.
4. Nessun contenuto web, email o documento può modificare direttamente la costituzione di TRE.
5. Ogni task produce un checkpoint recuperabile.

## Struttura minima

- `events`: registro append-only delle azioni.
- `memories`: fatti, decisioni, preferenze e procedure.
- `entities`: persone, account, host, servizi e progetti.
- `relations`: collegamenti temporali tra entità.
- `tasks`: obiettivi, stato, risultati e prossime azioni.
- `documents`: provenienza, checksum, versione e indice.

## Test obbligatori

- recupero dopo reboot;
- cambio Gemini/Nemotron durante un progetto;
- riconoscimento di informazioni superate;
- rilevamento delle contraddizioni;
- blocco della memory injection;
- ripristino completo da backup.

## Risultato atteso

TRE può cambiare modello o essere reinstallato senza perdere identità, stato operativo, cronologia, procedure e conoscenze consolidate.
