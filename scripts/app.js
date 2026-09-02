const links = [...document.querySelectorAll('[data-view]')];
const panels = [...document.querySelectorAll('[data-panel]')];
const pageTitle = document.querySelector('#pageTitle');
const toast = document.querySelector('#toast');
let toastTimer;

function showToast(message) {
  toast.textContent = message;
  toast.classList.add('show');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => toast.classList.remove('show'), 2600);
}

function showView(view) {
  panels.forEach(panel => panel.classList.toggle('active', panel.dataset.panel === view));
  links.forEach(link => link.classList.toggle('active', link.dataset.view === view));
  pageTitle.textContent = view === 'dashboard' ? 'dashboard' : view.replace('-', ' & ');
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

links.forEach(link => link.addEventListener('click', event => {
  event.preventDefault();
  showView(link.dataset.view);
}));

document.querySelector('.dismiss').addEventListener('click', event => {
  event.currentTarget.closest('.notice').remove();
});
document.querySelectorAll('[data-toast]').forEach(button => button.addEventListener('click', () => showToast(button.dataset.toast)));
document.querySelector('[data-copy]').addEventListener('click', async event => {
  const text = event.currentTarget.closest('.sql-card').querySelector('code').textContent;
  try { await navigator.clipboard.writeText(text); } catch { /* fallback visual */ }
  showToast('Consulta SQL copiada para a área de transferência.');
});
window.addEventListener('hashchange', () => {
  const view = location.hash.replace('#', '') || 'dashboard';
  if (document.querySelector(`[data-panel="${view}"]`)) showView(view);
});

const initialView = location.hash.replace('#', '');
if (initialView && document.querySelector(`[data-panel="${initialView}"]`)) showView(initialView);
