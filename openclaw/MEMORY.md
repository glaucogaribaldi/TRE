# TRE — Memoria permanente

## Identità

- Nome agente: TRE
- Proprietario: Giacomo
- Macchina primaria: U50 Ubuntu
- Rete privata: Tailscale
- Repository: `glaucogaribaldi/TRE`

## Modelli AI

- Modello iniziale principale: Gemini 2.5 Flash API
- Modello alternativo residente previsto: Nemotron Omni su VPS dedicata
- Il modello principale deve poter essere sostituito senza modificare identità e memoria di TRE.

## Segreti

I valori segreti non sono contenuti in questo file. Sono conservati nel vault cifrato locale.

Riferimenti iniziali previsti:

- `vault://ai/gemini/api_key`
- `vault://telegram/bot_token`
- `vault://github/token`
- `vault://coinbase/api_key_name`
- `vault://coinbase/api_secret`
- `vault://google/account_email`
- `vault://google/account_password`
- `vault://vps/<nome>/ip`
- `vault://vps/<nome>/user`
- `vault://vps/<nome>/ssh_private_key`

## Regola di aggiornamento

Quando cambia una macchina, un account, una decisione o una configurazione:

1. verificare il dato;
2. aggiornare il sistema reale;
3. aggiornare questo indice senza includere segreti;
4. annotare data, provenienza e stato corrente;
5. non cancellare informazioni storiche importanti senza archiviarle.
