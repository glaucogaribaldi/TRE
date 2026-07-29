# TRE

TRE è il nuovo agente personale OpenClaw di Giacomo, installato sul computer Ubuntu U50 e collegato alle VPS tramite Tailscale.

## Avvio rapido

Dopo avere creato il profilo Ubuntu definitivo e avere effettuato l'accesso al desktop, aprire il Terminale e incollare:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/glaucogaribaldi/TRE/main/bootstrap.sh)
```

Il bootstrap:

1. installa i componenti di base;
2. installa e collega Tailscale;
3. configura RDP/XRDP per Windows App, accessibile soltanto tramite Tailscale;
4. installa OpenClaw;
5. crea l'identità TRE;
6. crea un vault locale cifrato con `age`;
7. apre una GUI per inserire chiavi, account, token, IP e accessi VPS;
8. avvia l'onboarding ufficiale di OpenClaw.

## Prima di eseguire il comando

Preparare:

- password sudo del profilo Ubuntu;
- Tailscale auth key;
- Gemini API key;
- eventuale token Telegram;
- eventuale GitHub token dedicato;
- dati delle VPS;
- eventuali chiavi SSH;
- dati Coinbase solo quando necessari.

## Accesso remoto da Windows App

Al termine il terminale mostra l'IP Tailscale di U50.

In Windows App creare una nuova connessione PC:

```text
PC: IP_TAILSCALE:3389
Utente: nome utente Ubuntu
Password: password del profilo Ubuntu
```

La porta 3389 viene autorizzata sull'interfaccia `tailscale0` e negata sulle altre interfacce.

## Vault

Percorsi locali:

```text
/etc/tre/age.key
/var/lib/tre/vault/secrets.json.age
/var/log/tre/vault-audit.jsonl
```

Comandi:

```bash
sudo tre-vault set telegram.bot_token
sudo tre-vault set vps.nemotron.ip 100.64.0.10
sudo tre-vault set-file vps.nemotron.ssh_private_key ~/.ssh/id_ed25519
sudo tre-vault list
```

Il repository è pubblico, ma il vault e i segreti restano esclusivamente sul computer e sono esclusi da Git.

## Aggiornamento delle credenziali da TRE

Quando Giacomo chiede a TRE di memorizzare una password o una chiave, OpenClaw deve usare:

```bash
sudo tre-vault set nome.gerarchico
```

Per file sensibili:

```bash
sudo tre-vault set-file nome.gerarchico /percorso/del/file
```

La memoria Markdown conserva soltanto riferimenti logici, mai i valori.

## Stato attuale

Questa è la fase bootstrap. Memoria semantica, Model Router Gemini/Nemotron, Action Broker, PostgreSQL, Mem0 e Graphiti saranno integrati nelle fasi successive.
