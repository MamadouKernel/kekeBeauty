'use strict';
if ('serviceWorker' in navigator && window.isSecureContext) {
  navigator.serviceWorker.register('/service-worker.js', { updateViaCache: 'none' })
    .then(registration => {
      const offerUpdate = () => {
        if (!registration.waiting || document.getElementById('pwa-update')) return;
        const button = document.createElement('button');
        button.id = 'pwa-update';
        button.textContent = 'Nouvelle version disponible : mettre à jour';
        button.style.cssText = 'position:fixed;bottom:80px;left:16px;right:16px;z-index:1001;padding:12px;background:#74388a;color:white;border:0;border-radius:8px';
        button.addEventListener('click', () => {
          if (!window.confirm('La page va être rechargée. Les données non envoyées seront perdues. Continuer ?')) return;
          navigator.serviceWorker.addEventListener('controllerchange', () => window.location.reload(), { once: true });
          registration.waiting?.postMessage('ACTIVATE_UPDATE');
        });
        document.body.append(button);
      };
      offerUpdate();
      registration.addEventListener('updatefound', () => {
        registration.installing?.addEventListener('statechange', offerUpdate);
      });
    }).catch(() => { /* Online functionality remains available without installation. */ });
}
