# TRE — Fase 3: router Gemini/Nemotron

## Obiettivo

Separare TRE dal singolo fornitore AI e permettere il cambio immediato tra Gemini e Nemotron senza perdere memoria o task.

## Architettura

OpenClaw chiama un endpoint stabile del Model Router. Il router inoltra la richiesta al provider scelto e registra modello, latenza, costo, errori e risultato.

Provider iniziali:

- Gemini 2.5 Flash: principale durante il bootstrap.
- Nemotron Omni su VPS GPU: alternativa locale/residente.

## Modalità

- `gemini`: Gemini principale, Nemotron fallback.
- `nemotron`: Nemotron principale, Gemini fallback.
- `auto`: selezione per privacy, lingua, strumenti, costo e salute.
- `local-only`: nessun dato inviato a provider esterni.
- `dual-check`: entrambi i modelli per verifiche critiche.

## Cambio modello

Comandi previsti:

```bash
uno model set gemini
uno model set nemotron
uno model set auto
uno model set local-only
```

Il nome definitivo del comando sarà `tre model ...`.

## Continuità

Prima del cambio:

1. salva checkpoint del task;
2. termina o congela le azioni in corso;
3. ricostruisce il contesto dalla memoria centrale;
4. verifica salute e capacità del nuovo modello;
5. riprende dal prossimo passo sicuro.

## VPS Nemotron

La VPS espone un endpoint OpenAI-compatible esclusivamente sulla rete Tailscale. Comprende:

- runtime NVIDIA;
- vLLM;
- Nemotron Omni quantizzato secondo la GPU disponibile;
- health check;
- watchdog;
- metriche;
- UNO/TRE node agent;
- nessuna porta pubblica del modello.

## Sicurezza

- Il modello non esegue direttamente shell root.
- Tutte le azioni passano dall'Action Broker.
- Coinbase resta un servizio isolato con risk engine deterministico.
- Nessun failover automatico a metà di operazioni finanziarie o distruttive.

## Risultato atteso

TRE continua a operare anche senza Gemini, senza perdere memoria e senza modificare la propria identità o configurazione operativa.
