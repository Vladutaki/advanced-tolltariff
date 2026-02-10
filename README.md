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

## Note

Aplicarea și testarea se fac local. Secțiunile legate de deploy/hosting au fost eliminate pentru a păstra doar funcționalitățile de bază.

<!-- Hosting/Deploy sections removed -->

<!-- Azure section removed -->

<!-- Power BI section removed -->

<!-- CI/CD and Railway sections removed -->

## Deploy pe Netlify

Acest proiect are frontend static în `frontend/` și API FastAPI (Python). Pentru Netlify vom publica doar frontend-ul, iar apelurile către API (`/htc/...`) se vor redirecționa către un backend găzduit separat.

Ce am adăugat:
- `netlify.toml` la rădăcina repo-ului: setează `publish = "frontend"`, maparea căii `/ui/*` către rădăcina site-ului și fallback SPA către `index.html`.
- `frontend/_redirects`: reguli Netlify pentru:
  - `/ui/*  ->  /:splat` (resursele referențiate ca `/ui/...` vor funcționa)
  - `/*     ->  /index.html` (fallback pentru aplicația single-page)
  - Șablon pentru proxy API: linie comentată pe care o poți edita cu URL-ul backend-ului tău.

Pași de deploy (UI):
1) Găzduiește API-ul (FastAPI) în altă parte (ex.: Render, Fly.io, Railway, VM). API-ul trebuie să expună rutele la `/htc/...`.
2) Editează fișierul [frontend/_redirects](frontend/_redirects) și înlocuiește exemplul pentru proxy:
   - Decomentează linia și setează URL-ul backend-ului tău:
   
   ```
   # /htc/*  https://your-backend.example.com/htc/:splat  200
   ->
   /htc/*  https://api.example.com/htc/:splat  200
   ```

3) Fă push pe GitHub (sau conectează direct repo-ul).
4) În Netlify: "Add new site" → "Import from Git" → selectează repo-ul → la "Publish directory" pune `frontend` (fără build command).
5) Deploy. Verifică că UI-ul se încarcă și că acțiunile care folosesc API funcționează.

Alternativ (CLI):

```bash
npm install -g netlify-cli
netlify init                 # creează site-ul și legătura cu repo
netlify deploy --prod --dir frontend
```

Note:
- Nu mutăm codul frontend; folosim redirectul `/ui/* -> /:splat` ca să păstrăm compatibilitatea cu referințele existente din UI.
- Netlify nu expandează variabile de mediu în `_redirects`; setează direct URL-ul backend.
- Dacă nu ai backend, UI-ul va afișa erori la apelurile către `/htc/...`. Configurează proxy-ul sau schimbă `fetch`-urile din `frontend/app.js` să folosească un `API_BASE_URL` dacă preferi asta.
