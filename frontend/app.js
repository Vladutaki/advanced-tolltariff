const api = {
  bestOrigin: ({ code, weight_kg, quantity, customs_value_nok, top_n, flatten }) => {
    const params = new URLSearchParams();
    if (weight_kg) params.set('weight_kg', weight_kg);
    if (quantity) params.set('quantity', quantity);
    if (customs_value_nok) params.set('customs_value_nok', customs_value_nok);
    if (top_n) params.set('top_n', top_n);
    if (flatten) params.set('flatten', 'true');
    return fetch(`/htc/${encodeURIComponent(code)}/best-origin?` + params.toString()).then(r => r.json());
  },
  agreements: (code) => fetch(`/htc/${encodeURIComponent(code)}/agreements`).then(r => r.json()),
  zeroDuty: (code) => fetch(`/htc/${encodeURIComponent(code)}/zero-duty`).then(r => r.json()),
  search: (q) => fetch(`/htc?q=${encodeURIComponent(q)}&limit=50`).then(r => r.json()),
};

function fmtCurrency(n) {
  if (n === null || n === undefined) return '-';
  return new Intl.NumberFormat('en-NO', { style: 'currency', currency: 'NOK', maximumFractionDigits: 2 }).format(n);
}

function renderCountries(container, countries) {
  const list = document.createElement('div');
  list.className = 'country-list';
  (countries || []).forEach(c => {
    const el = document.createElement('span');
    el.className = 'country';
    el.textContent = `${c.name} (${c.iso})`;
    list.appendChild(el);
  });
  container.appendChild(list);
}

function renderBestOrigin(output, data) {
  output.innerHTML = '';
  if (data.countries) {
    // flattened mode
    const item = document.createElement('div');
    item.className = 'item';
    const h3 = document.createElement('h3');
    h3.textContent = `Best Countries for ${data.code}`;
    item.appendChild(h3);
    renderCountries(item, data.countries);
    const meta = document.createElement('div');
    meta.className = 'meta';
    meta.textContent = 'From groups: ' + (data.from_groups || []).map(g => g.agreement_name || g.agreement || 'Ordinary').join(', ');
    item.appendChild(meta);
    output.appendChild(item);
    return;
  }
  const recs = data.recommendations || [];
  if (!recs.length) {
    const item = document.createElement('div');
    item.className = 'item';
    item.textContent = data.hint || 'No results. Provide inputs or ensure duty rates are imported.';
    output.appendChild(item);
    return;
  }
  recs.forEach(rec => {
    const item = document.createElement('div');
    item.className = 'item';
    const h3 = document.createElement('h3');
    h3.textContent = rec.agreement_name || rec.agreement || 'Ordinary (no agreement)';
    item.appendChild(h3);
    const meta = document.createElement('div');
    meta.className = 'meta';
    meta.innerHTML = `Cost: <span class="badge">${fmtCurrency(rec.cost_nok)}</span> Basis: <span class="badge">${rec.basis}</span> Rate: <span class="badge">${rec.rate_type} ${rec.rate_value}${rec.unit ? (' / ' + rec.unit) : ''}</span>`;
    item.appendChild(meta);
    renderCountries(item, rec.countries);
    output.appendChild(item);
  });
}

function renderAgreements(output, data) {
  output.innerHTML = '';
  const items = data.agreements || data.zero_duty || [];
  items.forEach(a => {
    const item = document.createElement('div');
    item.className = 'item';
    const h3 = document.createElement('h3');
    h3.textContent = a.agreement_name || a.agreement || 'Agreement';
    item.appendChild(h3);
    if (a.rates) {
      const rates = document.createElement('div');
      rates.className = 'meta';
      rates.textContent = (a.rates || []).map(r => `${r.type} ${r.value}${r.unit ? (' / ' + r.unit) : ''}`).join(' • ');
      item.appendChild(rates);
    }
    renderCountries(item, a.countries);
    output.appendChild(item);
  });
}

function renderSearch(output, items) {
  output.innerHTML = '';
  items.forEach(htc => {
    const item = document.createElement('div');
    item.className = 'item';
    const h3 = document.createElement('h3');
    h3.textContent = `${htc.code} — ${htc.name || ''}`;
    item.appendChild(h3);
    const meta = document.createElement('div');
    meta.className = 'meta';
    meta.textContent = htc.description || '';
    item.appendChild(meta);
    output.appendChild(item);
  });
}

window.addEventListener('DOMContentLoaded', () => {
  const bestForm = document.getElementById('bestForm');
  const bestOutput = document.getElementById('bestOutput');
  bestForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    const code = document.getElementById('htcCode').value.trim();
    const weight_kg = parseFloat(document.getElementById('weightKg').value);
    const quantity = parseInt(document.getElementById('quantity').value, 10);
    const customs_value_nok = parseFloat(document.getElementById('customsValue').value);
    const top_n = parseInt(document.getElementById('topN').value, 10);
    const flatten = document.getElementById('flatten').checked;
    const payload = {
      code,
      weight_kg: isNaN(weight_kg) ? undefined : weight_kg,
      quantity: isNaN(quantity) ? undefined : quantity,
      customs_value_nok: isNaN(customs_value_nok) ? undefined : customs_value_nok,
      top_n: isNaN(top_n) ? undefined : top_n,
      flatten,
    };
    bestOutput.innerHTML = '<div class="item">Loading…</div>';
    try {
      const data = await api.bestOrigin(payload);
      renderBestOrigin(bestOutput, data);
    } catch (err) {
      bestOutput.innerHTML = `<div class="item">Error: ${err}</div>`;
    }
  });

  const agreementsBtn = document.getElementById('agreementsBtn');
  const zeroBtn = document.getElementById('zeroBtn');
  const agreementsOutput = document.getElementById('agreementsOutput');
  agreementsBtn.addEventListener('click', async () => {
    const code = document.getElementById('agreementsCode').value.trim();
    agreementsOutput.innerHTML = '<div class="item">Loading…</div>';
    try {
      const data = await api.agreements(code);
      renderAgreements(agreementsOutput, data);
    } catch (err) {
      agreementsOutput.innerHTML = `<div class="item">Error: ${err}</div>`;
    }
  });
  zeroBtn.addEventListener('click', async () => {
    const code = document.getElementById('agreementsCode').value.trim();
    agreementsOutput.innerHTML = '<div class="item">Loading…</div>';
    try {
      const data = await api.zeroDuty(code);
      renderAgreements(agreementsOutput, data);
    } catch (err) {
      agreementsOutput.innerHTML = `<div class="item">Error: ${err}</div>`;
    }
  });

  const searchBtn = document.getElementById('searchBtn');
  const searchOutput = document.getElementById('searchOutput');
  searchBtn.addEventListener('click', async () => {
    const q = document.getElementById('searchQuery').value.trim();
    searchOutput.innerHTML = '<div class="item">Loading…</div>';
    try {
      const items = await api.search(q);
      renderSearch(searchOutput, items);
    } catch (err) {
      searchOutput.innerHTML = `<div class="item">Error: ${err}</div>`;
    }
  });
});
