# Advanced Tolltariff (Norway) – Project Plan

Scop: Un serviciu care permite căutarea unui cod HS/HTC și afișează taxele vamale pentru Norvegia, incluzând excepții pe țări (FTA/alte reguli), cu rate în formatele %, per kg, per item.

## Tehnologii propuse
- Backend: FastAPI (Python 3.11+), Uvicorn
- ETL/Scraping: httpx + BeautifulSoup (și Playwright dacă paginile sunt dinamice)
- Modelare date: Pydantic v2, SQLAlchemy ORM
- Bază de date: SQLite (dev) → PostgreSQL (prod)
- CLI: Typer (comenzi de ingestie/actualizare)
- Testare: pytest, vcrpy (opțional pentru fixture-uri HTTP)
- Observabilitate: logging standard + tqdm pentru progres
- Programare ingestie: cron/APS (mai târziu)

## Model de date (inițial)
- `htc` (sau `hs_code`): id, code, name, description
- `rate` (reprezintă tarife/exceptări per țară de origine):
  - htc_id → FK
  - country_iso (ISO 3166-1 alpha-2)
  - rate_type (enum: percent, per_kg, per_item)
  - value (numeric/Decimal)
  - currency (ex. NOK pentru pre-kg/per-item)
  - unit (kg, item)
  - is_exemption (bool), agreement, conditions, valid_from, valid_to, source_url, priority

Notă: Sortarea „în ordine crescătoare” are sens per unitate. Vom grupa întâi pe `rate_type`/`unit`, apoi sortăm numeric în interiorul grupului.

## Pași
1) Confirmare sursă și permisiuni (URL și robots.txt / ToS)
2) Prototip scraper pentru 1 cod HS (extrage: nume, rată standard, tabel țări/exceptări)
3) Definire/parcurgere structură site și paginare
4) Persistență: mapare către modelul de date și salvare în DB
5) API: endpoint `GET /htc/{code}` + filtre pe țară și sortare
6) UI/Notebook: demo interactiv de căutare

## Comenzi rapide (după instalare deps)
```bash
# rulează API-ul (în dev, SQLite)
uvicorn tolltariff.api.main:app --reload

# rulare CLI (stubs)
python -m tolltariff.cli --help
```

## Mediu
- `DATABASE_URL` (implicit: sqlite:///data.db)
- `TOLLTARIFF_BASE_URL` (URL-ul de start pentru scraping)

## Legal și etică
- Respectarea robots.txt și Termenilor site-ului oficial. Dacă scraping-ul nu este permis, căutăm dataset/endpoint oficial.

## Rulare locală rapidă

```bash
python -m uvicorn tolltariff.api.main:app --reload --port 8001
```

UI-ul static este disponibil la http://localhost:8001/ui/

## Docker

Construiește și rulează un container care servește API + UI pe portul 8000. La primul start rulează bootstrap (descarcă + importă date) dacă `TOLLTARIFF_BOOTSTRAP=true`.

```bash
docker build -t tolltariff:local .
docker run --rm -p 8000:8000 \
  -e TOLLTARIFF_BOOTSTRAP=true \
  -e DATABASE_URL="sqlite:///data.db" \
  # Optional: direct URL to tollavgiftssats.json for duty rates import
  -e TOLLTARIFF_DUTY_URL="https://example.com/tollavgiftssats.json" \
  tolltariff:local
```

Deschide http://localhost:8000/ui/

Pentru producție recomandăm o bază de date persistentă (PostgreSQL):

```bash
docker run --rm -p 8000:8000 \
  -e DATABASE_URL="postgresql+psycopg://USER:PASSWORD@HOST:5432/DBNAME" \
  -e TOLLTARIFF_BOOTSTRAP=true \
  tolltariff:local
```

## Opțiuni ușoare de hosting

- Render (simplu, prietenos cu free-tier): conectezi repo-ul, folosești Docker, setezi `TOLLTARIFF_BOOTSTRAP=true`, adaugi persistent disk dacă rămâi pe SQLite.
- Railway / Fly.io: deploy cu Docker; adaugă un Postgres add-on pentru persistență.
- Azure Container Apps: împinge imaginea în Azure Container Registry, apoi creează un Container App cu `PORT=8000` și `DATABASE_URL` către Azure Database for PostgreSQL.
- Azure App Service (Web App for Containers): deploy imaginea Docker și setează aceleași variabile de mediu.

### Render (din repo, fără Docker local)

Acest repo include `render.yaml` pentru deploy rapid:

1) Fă push pe GitHub/GitLab.
2) În Render → New → Blueprint, alege repo-ul și confirmă.
3) Setează variabilele de mediu:
  - `PORT=8000`
  - `TOLLTARIFF_BOOTSTRAP=true`
  - `DATABASE_URL=sqlite:///data.db` (sau link către Render Postgres)
  - `TOLLTARIFF_DUTY_URL=<URL direct către tollavgiftssats.json>` (opțional, recomandat)
4) Asociază un Persistent Disk la serviciu (Render citește din `render.yaml`: disk `data` la `/app/data`).
5) Deschide URL-ul public și vizitează `/ui`.

## Azure quickstart (Container Apps)

```bash
az acr create -n <ACR_NAME> -g <RG> --sku Basic
az acr login -n <ACR_NAME>
docker tag tolltariff:local <ACR_NAME>.azurecr.io/tolltariff:latest
docker push <ACR_NAME>.azurecr.io/tolltariff:latest

az containerapp env create -g <RG> -n toll-env -l <REGION>
az containerapp create -g <RG> -n tolltariff \
  --environment toll-env \
  --image <ACR_NAME>.azurecr.io/tolltariff:latest \
  --ingress external --target-port 8000 \
  --env-vars PORT=8000 TOLLTARIFF_BOOTSTRAP=true TOLLTARIFF_DUTY_URL="<DIRECT_JSON_URL>" \
  --registry-server <ACR_NAME>.azurecr.io
```

Adaugă `DATABASE_URL` pentru a folosi un Postgres administrat (Azure Database for PostgreSQL Flexible Server) și dezactivează bootstrap dacă gestionezi datele separat.

## Integrare Power BI

Poți folosi endpoint-urile API ca sursă de tip Web:
- Best origin (țări flatten): `/htc/{code}/best-origin?quantity=1&flatten=true&top_n=3`
- Agreements (tabel): `/htc/{code}/agreements`
- Zero-duty (tabel): `/htc/{code}/zero-duty`
- Search/listare: `/htc?q=...&limit=...`

În Power BI Desktop:
- Get Data → Web → introdu URL-ul (asigură-te că API-ul este accesibil), apoi transformă JSON în tabele în Power Query.
- Pentru analize mai mari, expune un `DATABASE_URL` Postgres și conectează Power BI direct la baza de date, în loc de JSON.

## CI/CD cu GitHub Actions (GHCR)

Acest repo include un workflow care construiește și publică imaginea Docker în GHCR pe push pe `main`/`master` și pe tag-uri `v*.*.*`.

- Workflow: `.github/workflows/docker-publish.yml`
- Imagine: `ghcr.io/<owner>/<repo>:latest` (și SHA/tag)

După prima rulare, în GitHub → Settings → Packages vei vedea pachetul (containerul). Poți seta vizibilitatea pe public dacă dorești deploy fără autentificare la registru.

## Railway (din registru sau direct din repo)

Varianta A – din repo: creezi proiect nou în Railway și îl conectezi la repo; Railway detectează `Dockerfile`.

Varianta B – din GHCR:
1) Creează un serviciu nou → Deploy from Registry → `ghcr.io/<owner>/<repo>:latest`
2) Setează variabilele de mediu:
  - `PORT=8000`
  - `TOLLTARIFF_BOOTSTRAP=true`
  - `DATABASE_URL=sqlite:///data.db` (sau URL Postgres de pe Railway)
  - `TOLLTARIFF_DUTY_URL=<URL direct către tollavgiftssats.json>` (opțional)
3) Adaugă un volum/persistent storage pentru `/app/data` dacă folosești SQLite.
4) Deschide URL-ul serviciului și vizitează `/ui`.
