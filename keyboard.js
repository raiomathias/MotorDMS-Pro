(() => {
  'use strict';

  // Módulo independiente: no consulta Supabase ni bloquea la inicialización de cada página.
  if (window.__motorDmsKeyboardLoaded) return;
  window.__motorDmsKeyboardLoaded = true;

  const style = document.createElement('style');
  style.textContent = `
    .motor-kbd-hint{display:inline-block;margin-left:7px;padding:2px 5px;border:1px solid currentColor;border-radius:5px;font:600 9px/1.2 Inter,system-ui,sans-serif;opacity:.72;white-space:nowrap;vertical-align:middle;pointer-events:none}
    .nav .motor-kbd-hint{float:right}
    button:focus-visible,[role="button"]:focus-visible,a:focus-visible,input:focus-visible,select:focus-visible,textarea:focus-visible{outline:3px solid #1768e566!important;outline-offset:2px!important}
    #motor-kbd-trigger{position:fixed;right:16px;bottom:16px;z-index:9998;border:1px solid #d7e0ec;background:#fff;color:#526176;border-radius:999px;padding:8px 11px;font:600 11px/1.2 Inter,system-ui,sans-serif;box-shadow:0 4px 18px #20365418;cursor:pointer}
    #motor-kbd-overlay{position:fixed;inset:0;z-index:10000;background:#10182888;display:none;align-items:flex-start;justify-content:center;padding:9vh 16px 24px}
    #motor-kbd-overlay.open{display:flex}
    #motor-kbd-dialog{width:min(100%,620px);max-height:80vh;overflow:auto;background:#fff;color:#172438;border:1px solid #dce3ee;border-radius:16px;box-shadow:0 24px 80px #10182855;padding:20px}
    #motor-kbd-dialog h2{font-size:18px;margin:0 0 5px}
    #motor-kbd-dialog p{font-size:12px;color:#718096;margin:0 0 14px}
    #motor-kbd-search{width:100%;padding:11px 12px;border:1px solid #d8e0eb;border-radius:9px;margin-bottom:12px;font:inherit}
    #motor-kbd-list{display:grid;grid-template-columns:1fr 1fr;gap:6px}
    .motor-kbd-command{display:flex;justify-content:space-between;align-items:center;gap:10px;text-align:left;border:1px solid #edf0f5;background:#fff;border-radius:8px;padding:9px 10px;color:#344054;font:500 12px/1.35 Inter,system-ui,sans-serif;cursor:pointer;min-width:0}
    .motor-kbd-command:hover{background:#f3f7ff;border-color:#b9d0f5}
    .motor-kbd-command span{overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
    #motor-kbd-dialog kbd,#motor-kbd-trigger kbd{font:600 10px/1.2 Inter,system-ui,sans-serif;border:1px solid #d5deea;background:#f7f9fc;border-radius:5px;padding:3px 5px;color:#526176;white-space:nowrap}
    #motor-kbd-footer{display:flex;justify-content:space-between;align-items:center;gap:10px;margin-top:14px;color:#718096;font-size:11px}
    #motor-kbd-close{border:1px solid #dce3ee;background:#fff;border-radius:8px;padding:7px 10px;color:#344054;cursor:pointer}
    @media(max-width:560px){#motor-kbd-list{grid-template-columns:1fr}#motor-kbd-overlay{padding-top:5vh}#motor-kbd-dialog{max-height:88vh}}
  `;
  document.head.appendChild(style);

  const isVisible = el => !!el && el.isConnected && !el.disabled &&
    !el.closest('[hidden],.hidden,[aria-hidden="true"]') &&
    getComputedStyle(el).display !== 'none' &&
    getComputedStyle(el).visibility !== 'hidden' &&
    el.getClientRects().length > 0;

  const cleanLabel = el => {
    const clone = el.cloneNode(true);
    clone.querySelectorAll('.motor-kbd-hint').forEach(node => node.remove());
    return (clone.innerText || clone.textContent || el.getAttribute('aria-label') || el.title || 'Acción')
      .replace(/\s+/g, ' ').trim().slice(0, 90);
  };

  const assigned = new Set();
  function shortcutFor(el) {
    if (el.matches('.nav[data-view]')) {
      const navs = [...document.querySelectorAll('.nav[data-view]')];
      const index = navs.indexOf(el);
      return index >= 0 && index < 9 ? 'Alt+' + (index + 1) : null;
    }
    const id = (el.id || '').toLowerCase();
    if (id === 'newvehicle' || id === 'createuser') return 'Alt+N';
    if (id === 'registersale') return 'Alt+V';
    if (id === 'reload' || id === 'refreshreports') return 'Alt+R';
    if (id === 'openfilters') return 'Alt+Shift+F';
    if (id === 'adminpanel') return 'Alt+A';
    if (id === 'backbtn') return 'Alt+B';
    if (id === 'signout') return 'Alt+Q';
    if (el.type === 'submit') return 'Alt+S';
    return null;
  }

  function decorate(root) {
    const candidates = [];
    if (root && root.nodeType === 1 && root.matches('button,[role="button"]')) candidates.push(root);
    if (root && root.querySelectorAll) candidates.push(...root.querySelectorAll('button,[role="button"]'));
    candidates.forEach(el => {
      if (el.dataset.kbdDecorated || el.dataset.kbdIgnore !== undefined ||
          el.closest('#motor-kbd-overlay') || el.matches('.autocomplete-option,.vehicle-suggestion,.motor-kbd-command')) return;
      el.dataset.kbdDecorated = '1';
      const key = shortcutFor(el);
      if (!key || assigned.has(key)) return;
      assigned.add(key);
      el.dataset.kbd = key;
      el.setAttribute('aria-keyshortcuts', key);
      const hint = document.createElement('kbd');
      hint.className = 'motor-kbd-hint';
      hint.textContent = key.replace('Shift+', '⇧+');
      el.appendChild(hint);
    });
  }

  const overlay = document.createElement('div');
  overlay.id = 'motor-kbd-overlay';
  overlay.innerHTML = '<section id="motor-kbd-dialog" role="dialog" aria-modal="true" aria-labelledby="motor-kbd-title"><h2 id="motor-kbd-title">Atajos de teclado</h2><p>Usa los atajos para navegar y ejecutar acciones. Recorre los campos con Tab y Shift + Tab.</p><input id="motor-kbd-search" type="search" placeholder="Buscar acción…" autocomplete="off"><div id="motor-kbd-list"></div><div id="motor-kbd-footer"><span>Enter ejecuta · Esc cierra · Ctrl + K abre esta ventana</span><button id="motor-kbd-close" type="button">Cerrar <kbd>Esc</kbd></button></div></section>';
  document.body.appendChild(overlay);

  const trigger = document.createElement('button');
  trigger.id = 'motor-kbd-trigger';
  trigger.type = 'button';
  trigger.dataset.kbdIgnore = '';
  trigger.innerHTML = 'Atajos <kbd>?</kbd>';
  trigger.setAttribute('aria-label', 'Mostrar atajos de teclado');
  document.body.appendChild(trigger);

  const search = overlay.querySelector('#motor-kbd-search');
  const list = overlay.querySelector('#motor-kbd-list');

  function openHelp() {
    decorate(document.body);
    list.replaceChildren();
    [...document.querySelectorAll('[data-kbd]')].filter(isVisible).forEach(el => {
      const item = document.createElement('button');
      item.type = 'button';
      item.className = 'motor-kbd-command';
      item.dataset.label = cleanLabel(el).toLocaleLowerCase('es');
      const name = document.createElement('span');
      name.textContent = cleanLabel(el);
      const key = document.createElement('kbd');
      key.textContent = el.dataset.kbd;
      item.append(name, key);
      item.addEventListener('click', () => {
        closeHelp();
        if (isVisible(el)) el.click();
      });
      list.appendChild(item);
    });
    search.value = '';
    overlay.classList.add('open');
    search.focus();
  }
  function closeHelp() {
    overlay.classList.remove('open');
    trigger.focus();
  }
  trigger.addEventListener('click', openHelp);
  overlay.querySelector('#motor-kbd-close').addEventListener('click', closeHelp);
  overlay.addEventListener('mousedown', e => { if (e.target === overlay) closeHelp(); });
  search.addEventListener('input', () => {
    const q = search.value.toLocaleLowerCase('es').trim();
    list.querySelectorAll('.motor-kbd-command').forEach(el => { el.hidden = !!q && !el.dataset.label.includes(q); });
  });

  function clickFirst(selector) {
    const el = [...document.querySelectorAll(selector)].find(isVisible);
    if (el) { el.click(); return true; }
    return false;
  }
  function focusSearch() {
    const fields = [...document.querySelectorAll('input:not([type="hidden"]),textarea')].filter(isVisible);
    const el = fields.find(x => /search|buscar/i.test([x.type,x.id,x.name,x.placeholder].join(' '))) || fields[0];
    if (!el) return false;
    el.focus();
    if (typeof el.select === 'function') el.select();
    return true;
  }
  function run(key) {
    if (key === 'Alt+F') return focusSearch();
    if (key === 'Alt+N') return clickFirst('#newVehicle,#createUser');
    if (key === 'Alt+V') return clickFirst('#registerSale');
    if (key === 'Alt+R') return clickFirst('#reload,#refreshReports');
    if (key === 'Alt+Shift+F') return clickFirst('#openFilters');
    if (key === 'Alt+A') return clickFirst('#adminPanel');
    if (key === 'Alt+B') return clickFirst('#backBtn');
    if (key === 'Alt+Q') return clickFirst('#signOut');
    if (key === 'Alt+S') {
      const activeForm = document.activeElement && document.activeElement.closest('form');
      const form = activeForm && isVisible(activeForm) ? activeForm : [...document.querySelectorAll('form')].find(isVisible);
      if (form) { if (form.requestSubmit) form.requestSubmit(); else form.querySelector('[type="submit"]')?.click(); return true; }
      return false;
    }
    if (/^Alt+[1-9]$/.test(key)) {
      const navs = [...document.querySelectorAll('.nav[data-view]')].filter(isVisible);
      const el = navs[Number(key.slice(-1)) - 1];
      if (el) { el.click(); return true; }
    }
    return false;
  }

  document.addEventListener('keydown', e => {
    const tag = document.activeElement?.tagName || '';
    const typing = /^(INPUT|TEXTAREA|SELECT)$/.test(tag) || document.activeElement?.isContentEditable;
    if (e.key === 'Escape') {
      if (overlay.classList.contains('open')) { e.preventDefault(); closeHelp(); }
      else {
        const close = [...document.querySelectorAll('button')].find(el => isVisible(el) && (/close|cancel/i.test(el.id) || /^(cerrar|cancelar|✕)$/i.test(cleanLabel(el))));
        if (close && !e.defaultPrevented) { e.preventDefault(); close.click(); }
      }
      return;
    }
    if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'k') { e.preventDefault(); openHelp(); return; }
    if (e.key === '?' || (e.shiftKey && e.code === 'Slash')) { e.preventDefault(); openHelp(); return; }
    if (e.key === '/' && !typing && !e.ctrlKey && !e.metaKey && !e.altKey) { e.preventDefault(); focusSearch(); return; }
    if (e.altKey && !e.ctrlKey && !e.metaKey) {
      let key = e.key.toUpperCase();
      if (/^Digit[0-9]$/.test(e.code) || /^Key[A-Z]$/.test(e.code)) key = e.code.slice(-1);
      const combo = 'Alt+' + (e.shiftKey ? 'Shift+' : '') + key;
      if (run(combo)) e.preventDefault();
    }
  });

  decorate(document.body);
  // Solo procesa nodos nuevos; no observa atributos ni modifica repetidamente elementos existentes.
  const observer = new MutationObserver(records => {
    records.forEach(record => record.addedNodes.forEach(node => {
      if (node.nodeType === 1 && node.id !== 'motor-kbd-overlay' && node.id !== 'motor-kbd-trigger') decorate(node);
    }));
  });
  observer.observe(document.body, { childList: true, subtree: true });
})();