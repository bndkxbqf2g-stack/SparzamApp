{{flutter_js}}
{{flutter_build_config}}

(async () => {
  // GitHub Pages is updated frequently during development. Do not let an older
  // Flutter service worker keep a stale JS/asset combination alive on Safari.
  if ('serviceWorker' in navigator) {
    try {
      const registrations = await navigator.serviceWorker.getRegistrations();
      await Promise.all(
        registrations
          .filter((registration) => {
            try {
              return new URL(registration.scope).pathname.startsWith('/SparzamApp/');
            } catch (_) {
              return false;
            }
          })
          .map((registration) => registration.unregister()),
      );
    } catch (error) {
      console.warn('Could not remove legacy Sparzam service worker', error);
    }
  }

  await _flutter.loader.load({
    config: {
      // Keep the web renderer self-contained. This avoids an external gstatic
      // dependency that can be blocked by Safari content/privacy settings.
      canvasKitBaseUrl: 'canvaskit/',
    },
    onEntrypointLoaded: async (engineInitializer) => {
      const appRunner = await engineInitializer.initializeEngine();
      document.getElementById('sparzam-loading')?.remove();
      await appRunner.runApp();
    },
  });
})();
