// The generated page's own script (club_project_generator). It runs from a
// file, not inline, so the page's Content-Security-Policy needs no
// 'unsafe-inline' for scripts (#315).

// Remove splash when Flutter renders (detect canvas or flt-glass-pane)
function removeSplash() {
  var loading = document.getElementById('loading');
  if (loading) {
    loading.style.opacity = '0';
    loading.style.transition = 'opacity 0.3s ease-out';
    setTimeout(function() { loading.remove(); }, 300);
  }
}

// Method 1: MutationObserver to detect Flutter content
var observer = new MutationObserver(function(mutations) {
  if (document.querySelector('flt-glass-pane') || document.querySelector('canvas')) {
    observer.disconnect();
    removeSplash();
  }
});
observer.observe(document.body, { childList: true, subtree: true });

// Method 2: Fallback timeout (10 seconds max)
setTimeout(removeSplash, 10000);

// When a phone's keyboard closes, put the page back in place (#160).
// Flutter re-measures the page only on a resize; if the keyboard closed
// while focus was moving between fields, a shortened height could stay
// and leave a blank band. Once the visible area grows back and nothing
// is being typed into, scroll to the top and ask for a re-measure.
(function () {
  var viewport = window.visualViewport;
  if (!viewport) return;
  var lastHeight = viewport.height;
  viewport.addEventListener('resize', function () {
    var grew = viewport.height > lastHeight;
    lastHeight = viewport.height;
    if (!grew) return;
    var active = document.activeElement;
    var editing = active && (active.tagName === 'INPUT' ||
      active.tagName === 'TEXTAREA' || active.isContentEditable);
    if (editing) return;
    setTimeout(function () {
      window.scrollTo(0, 0);
      window.dispatchEvent(new Event('resize'));
      viewport.dispatchEvent(new Event('resize'));
    }, 100);
  });
})();
