# TRE — Strumenti locali

## Vault cifrato

Comando disponibile:

```bash
sudo tre-vault help
```

Operazioni principali:

```bash
sudo tre-vault set servizio.nome
sudo tre-vault set-file servizio.chiave /percorso/file
sudo tre-vault get servizio.nome
sudo tre-vault list
sudo tre-vault delete servizio.nome
```

Quando Giacomo dice "salva questa password", "ricorda questa chiave" o una richiesta equivalente:

1. scegliere un nome gerarchico chiaro;
2. salvare il valore tramite `tre-vault`;
3. non ripetere il valore nella risposta;
4. aggiornare la memoria soltanto con il riferimento `vault://...`;
5. confermare il nome logico usato.

Esempi:

- `telegram.bot_token`
- `ai.gemini.api_key`
- `vps.nemotron.ip`
- `vps.nemotron.ssh_private_key`
- `coinbase.api_secret`

## Tailscale

```bash
tailscale status
tailscale ip -4
```

U50 deve essere raggiungibile via Tailscale. RDP è esposto sulla porta 3389 esclusivamente tramite l'interfaccia Tailscale.

## Repository

Repository principale:

```text
https://github.com/glaucogaribaldi/TRE
```

Non committare mai file cifrati locali, chiavi, password, token, database o dump del vault.
