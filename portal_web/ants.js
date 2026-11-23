/**
 * =========================================================================
 * PCM WAYANAD - CRAWLING ANTS IDLE SIMULATION CANVAS
 * =========================================================================
 */

(() => {
  const canvas = document.getElementById('antsCanvas');
  if (!canvas) return;
  const ctx = canvas.getContext('2d');

  function resizeCanvas() {
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
  }
  window.addEventListener('resize', resizeCanvas);
  resizeCanvas();

  const secureRandom = () => {
    if (window.crypto && window.crypto.getRandomValues) {
      const buf = new Uint32Array(1);
      window.crypto.getRandomValues(buf);
      return buf[0] / (0xffffffff + 1);
    }
    return 0.5;
  };

  const ANT_COUNT = 18;
  const ants = [];
  let isUserActive = false;
  let idleTimer = null;

  class CrawlingAnt {
    constructor() {
      this.reset();
    }

    reset() {
      this.x = secureRandom() * canvas.width;
      this.y = secureRandom() * canvas.height;
      this.angle = secureRandom() * Math.PI * 2;
      this.speed = 0.6 + secureRandom() * 0.9;
      this.turnSpeed = 0.05;
      this.legPhase = secureRandom() * Math.PI * 2;
      this.opacity = 0.25 + secureRandom() * 0.45;
    }

    update() {
      if (isUserActive) {
        // When user is active, ants fade or scatter
        this.opacity = Math.max(0, this.opacity - 0.02);
        return;
      }

      // Restore opacity when idle
      this.opacity = Math.min(0.7, this.opacity + 0.02);

      // Organic wandering movement
      this.angle += (secureRandom() - 0.5) * this.turnSpeed * 4;
      this.x += Math.cos(this.angle) * this.speed;
      this.y += Math.sin(this.angle) * this.speed;
      this.legPhase += 0.25;

      // Screen boundary wrap
      if (this.x < -20) this.x = canvas.width + 10;
      if (this.x > canvas.width + 20) this.x = -10;
      if (this.y < -20) this.y = canvas.height + 10;
      if (this.y > canvas.height + 20) this.y = -10;
    }

    // JET BLACK ANTS WITH SUBTLE GLOW/OUTLINE
    draw(context) {
      if (this.opacity <= 0.02) return;

      context.save();
      context.translate(this.x, this.y);
      context.rotate(this.angle);
      context.globalAlpha = this.opacity;

      // ഉറുമ്പുകൾ കറുപ്പ് നിറമായതുകൊണ്ട് ഡാർക്ക് ബാക്ക്ഗ്രൗണ്ടിൽ വ്യക്തമായി കാണാൻ ചെറിയൊരു വെളിച്ചം (Glow)
      context.shadowColor = 'rgba(255, 255, 255, 0.4)';
      context.shadowBlur = 3;

      // കാലുകൾ - തനി കറുപ്പ് (Jet Black)
      context.strokeStyle = '#000000';
      context.lineWidth = 1.2;
      const legWiggle = Math.sin(this.legPhase) * 2.5;

      for (let i = -3; i <= 3; i += 3) {
        context.beginPath();
        context.moveTo(i, 0);
        context.lineTo(i - 2, -6 + legWiggle);
        context.stroke();

        context.beginPath();
        context.moveTo(i, 0);
        context.lineTo(i - 2, 6 - legWiggle);
        context.stroke();
      }

      // ഉറുമ്പിന്റെ ശരീരം - പ്യുവർ കറുപ്പ് നിറം
      context.fillStyle = '#000000';

      // പിൻഭാഗം (Abdomen)
      context.beginPath();
      context.ellipse(-4, 0, 3.8, 2.6, 0, 0, Math.PI * 2);
      context.fill();

      // നടുഭാഗം (Thorax)
      context.beginPath();
      context.ellipse(0, 0, 2.6, 1.8, 0, 0, Math.PI * 2);
      context.fill();

      // തല (Head)
      context.beginPath();
      context.ellipse(4, 0, 2.2, 1.8, 0, 0, Math.PI * 2);
      context.fill();

      // കൊമ്പുകൾ (Antennae)
      context.beginPath();
      context.moveTo(5, -1);
      context.lineTo(8, -3.5);
      context.moveTo(5, 1);
      context.lineTo(8, 3.5);
      context.stroke();

      context.restore();
    }
  }

  // Initialize ants
  for (let i = 0; i < ANT_COUNT; i++) {
    ants.push(new CrawlingAnt());
  }

  function handleUserActivity() {
    isUserActive = true;
    clearTimeout(idleTimer);
    idleTimer = setTimeout(() => {
      isUserActive = false;
    }, 3000); // 3 seconds idle triggers crawl
  }

  ['mousemove', 'touchstart', 'scroll', 'keydown', 'click'].forEach(evt => {
    window.addEventListener(evt, handleUserActivity, { passive: true });
  });

  function renderLoop() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ants.forEach(ant => {
      ant.update();
      ant.draw(ctx);
    });
    requestAnimationFrame(renderLoop);
  }

  // Start with brief delay
  handleUserActivity();
  requestAnimationFrame(renderLoop);
})();
