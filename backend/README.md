# Compta — Backend

Backend API REST pour un logiciel de comptabilité générale, destiné à une
application Flutter multiplateforme (Android, iOS, Windows, macOS, Linux).

## Stack
FastAPI · PostgreSQL · SQLAlchemy 2.x (100% async, asyncpg) · Alembic (migrations async) · Argon2 (hash) · JWT

## Philosophie d'architecture

```
Router → Service → (Accounting Engine si comptable) → SQLAlchemy → PostgreSQL
```

Le cœur du logiciel est `app/accounting/engine.py` : **aucune écriture
comptable n'est créée en dehors de ce module**. Les opérations métier
(`Transaction`) sont traduites en écritures (`JournalEntry` +
`JournalEntryLine`) via des règles configurables (`AccountingRule`), jamais
codées en dur.

```
Transaction (saisie utilisateur)
        │
        ▼
Accounting Engine  ── applique une AccountingRule (type + moyen de paiement)
        │
        ▼
JournalEntry (DRAFT → VALIDATED, immuable après validation)
    ├── JournalEntryLine (débit)
    └── JournalEntryLine (crédit)
        Σdébit = Σcrédit (vérifié avant validation)
```

Une écriture validée n'est **jamais modifiée** : toute correction passe par
`reverse_entry()` (contrepassation), qui crée une nouvelle écriture inverse.

La numérotation (`2026-BQ-000001`) est générée de façon transactionnelle
(`SELECT ... FOR UPDATE` sur `journal_sequences`) pour rester séquentielle et
sans trou même avec plusieurs utilisateurs simultanés.

## Modules livrés (V1)

- Authentification (JWT access/refresh, Argon2)
- Multi-entreprise (isolation par `company_id`, un utilisateur = une entreprise, rôles admin/accountant/viewer)
- Plan comptable configurable (`/accounts`)
- Journaux (`/journals`)
- Périodes comptables (`/accounting-periods`) — création et **clôture d'exercice réelle** (`POST /accounting-periods/{id}/close`) : solde tous les comptes de produits/charges à zéro et reporte le résultat net dans le compte de capitaux propres désigné, via une véritable écriture comptable postée dans le journal MISC (pas un simple recalcul à l'affichage)
- Règles comptables configurables (`/accounting-rules`)
- Transactions → Écritures automatiques (`/transactions`)
- Clients / Fournisseurs (`/customers`, `/suppliers`)
- Comptes de trésorerie (`/cash-accounts`)
- Justificatifs facultatifs, stockage local (`/documents`)
- Rapports : balance (`/reports/trial-balance`), grand livre (`/reports/ledger`), bilan (`/reports/balance-sheet`), compte de résultat (`/reports/income-statement`)
- Journal d'audit (`app/services/audit_service.py`, appelé sur les actions sensibles)

**Non inclus (hors périmètre V1)** : paie, stock avancé, CRM, production, Redis, MinIO/S3 (stockage local `uploads/` pour l'instant).

## Installation

```bash
python3.12 -m venv .venv
source .venv/bin/activate        # .venv\Scripts\activate sous Windows
pip install -r requirements.txt
cp .env.example .env
```

## Lancement avec Docker (recommandé)

```bash
docker compose up -d
```
API sur http://localhost:8000 — documentation interactive sur http://localhost:8000/docs

## Lancement sans Docker

Nécessite un PostgreSQL local avec les identifiants du `.env`.
```bash
uvicorn app.main:app --reload
```

## Migrations (Alembic, 100% asynchrone)

Aucun driver synchrone requis — `alembic/env.py` migre directement via `asyncpg`.

**La migration initiale est déjà générée et incluse** (`alembic/versions/*_initial_schema.py`),
produite et testée contre un vrai PostgreSQL 16 : les 16 tables se créent
sans erreur (`alembic upgrade head`).

```bash
docker compose up -d postgres
alembic upgrade head
```

Pour régénérer après un changement de modèle :
```bash
alembic revision --autogenerate -m "description du changement"
alembic upgrade head
```

## Tests

```bash
pip install aiosqlite   # dépendance de test uniquement, pas de requirements.txt
pytest tests/test_accounting_engine.py -v   # moteur comptable, sur SQLite en mémoire, aucune dépendance externe
pytest tests/test_health.py -v              # nécessite Postgres démarré (docker compose up -d)
```

Les 4 tests du moteur comptable (écriture équilibrée, rejet d'une écriture
déséquilibrée, numérotation séquentielle, contrepassation) sont **déjà
validés** dans cette livraison.

## Premiers pas après démarrage

1. `POST /api/v1/auth/register` — crée l'entreprise + le premier utilisateur (rôle admin)
2. `POST /api/v1/auth/login` — récupère les tokens
3. Créer le plan comptable via `POST /api/v1/accounts` (au minimum : un compte de charge, un de banque, un de produit, un de capitaux propres)
4. Créer un journal via `POST /api/v1/journals` (ex: code `OD`, type `MISC`)
5. Créer une période via `POST /api/v1/accounting-periods`
6. Créer une `AccountingRule` via `POST /api/v1/accounting-rules` pour chaque (type de transaction, moyen de paiement)
7. `POST /api/v1/transactions` — déclenche le moteur comptable, génère et valide l'écriture
8. Consulter `/api/v1/reports/trial-balance`, `/ledger`, `/balance-sheet`, `/income-statement`
9. `POST /api/v1/accounting-periods/{id}/close` — clôture l'exercice, poste l'écriture de clôture, fige le résultat

**Ce parcours complet (étapes 1 à 9) a été exécuté en HTTP réel contre un
PostgreSQL 16, avec une dépense de 50 000 et une recette de 120 000** :
bilan équilibré avant clôture (`is_balanced: true`), résultat net de 70 000
correctement reporté en capitaux propres après clôture, bilan toujours
équilibré ensuite.

## Ce qui reste à construire (prochaines phases)
- RBAC granulaire par permission (`invoice.create`, etc. — actuellement basé sur 3 rôles)
- Révocation des refresh tokens (nécessitera Redis, volontairement différé — cf. décisions précédentes)
- Génération PDF des rapports
- Tableau de bord
- Réouverture contrôlée d'une période clôturée (actuellement définitive)
