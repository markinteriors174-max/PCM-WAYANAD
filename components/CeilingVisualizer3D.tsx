import React, { useState, useEffect, useRef } from 'react';
import * as THREE from 'three';

export const CeilingVisualizer3D: React.FC = () => {
  const mountRef = useRef<HTMLDivElement | null>(null);
  const [lightsOn, setLightsOn] = useState(true);
  const [lightColor, setLightColor] = useState<'warm' | 'cyan' | 'purple'>('warm');
  
  const ambientLightRef = useRef<THREE.AmbientLight | null>(null);
  const spotlightsRef = useRef<THREE.SpotLight[]>([]);
  const coveLightRef = useRef<THREE.PointLight | null>(null);
  const coveGlowMeshesRef = useRef<THREE.Mesh[]>([]);

  const colorMap = {
    warm: { glow: 0xffaa44, spotlights: 0xfff3d6, point: 0xffd29c },
    cyan: { glow: 0x00f0ff, spotlights: 0xd6f7ff, point: 0x9cffff },
    purple: { glow: 0xbd00ff, spotlights: 0xf5d6ff, point: 0xeb9cff }
  };

  useEffect(() => {
    const container = mountRef.current;
    if (!container) return;

    const width = container.clientWidth || 350;
    const height = 240;

    const scene = new THREE.Scene();
    scene.background = new THREE.Color(0x0f172a); // Blends into slate-900

    const camera = new THREE.PerspectiveCamera(45, width / height, 0.1, 100);
    camera.position.set(0, 0, 7.5);

    const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
    renderer.setSize(width, height);
    renderer.setPixelRatio(Math.min(globalThis.devicePixelRatio, 2));
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    container.appendChild(renderer.domElement);

    // Group to pivot all geometries
    const roomGroup = new THREE.Group();
    scene.add(roomGroup);

    // Floor
    const floorGeo = new THREE.PlaneGeometry(6, 6);
    const floorMat = new THREE.MeshStandardMaterial({ 
      color: 0x242a38, 
      roughness: 0.7,
      metalness: 0.1
    });
    const floor = new THREE.Mesh(floorGeo, floorMat);
    floor.rotation.x = -Math.PI / 2;
    floor.position.y = -1.75;
    floor.receiveShadow = true;
    roomGroup.add(floor);

    // Walls
    const wallMat = new THREE.MeshStandardMaterial({ color: 0x1a2130, roughness: 0.8 });
    
    const backWallGeo = new THREE.PlaneGeometry(6, 3.5);
    const backWall = new THREE.Mesh(backWallGeo, wallMat);
    backWall.position.set(0, 0, -3);
    backWall.receiveShadow = true;
    roomGroup.add(backWall);

    const leftWallGeo = new THREE.PlaneGeometry(6, 3.5);
    const leftWall = new THREE.Mesh(leftWallGeo, wallMat);
    leftWall.rotation.y = Math.PI / 2;
    leftWall.position.set(-3, 0, 0);
    leftWall.receiveShadow = true;
    roomGroup.add(leftWall);

    const rightWallGeo = new THREE.PlaneGeometry(6, 3.5);
    const rightWall = new THREE.Mesh(rightWallGeo, wallMat);
    rightWall.rotation.y = -Math.PI / 2;
    rightWall.position.set(3, 0, 0);
    rightWall.receiveShadow = true;
    roomGroup.add(rightWall);

    // Flat Ceiling Plane (Upper recesses)
    const ceilingGeo = new THREE.PlaneGeometry(6, 6);
    const ceilingMat = new THREE.MeshStandardMaterial({ color: 0x0c0f17, roughness: 0.95 });
    const ceiling = new THREE.Mesh(ceilingGeo, ceilingMat);
    ceiling.rotation.x = Math.PI / 2;
    ceiling.position.y = 1.75;
    ceiling.receiveShadow = true;
    roomGroup.add(ceiling);

    // False Ceiling Borders (Lower Tray)
    const borderMat = new THREE.MeshStandardMaterial({ color: 0x151b26, roughness: 0.75 });
    
    // Left/Right Borders
    const borderL = new THREE.Mesh(new THREE.BoxGeometry(1, 0.25, 6), borderMat);
    borderL.position.set(-2.5, 1.625, 0);
    borderL.castShadow = true;
    borderL.receiveShadow = true;
    roomGroup.add(borderL);

    const borderR = new THREE.Mesh(new THREE.BoxGeometry(1, 0.25, 6), borderMat);
    borderR.position.set(2.5, 1.625, 0);
    borderR.castShadow = true;
    borderR.receiveShadow = true;
    roomGroup.add(borderR);

    // Front/Back Borders
    const borderF = new THREE.Mesh(new THREE.BoxGeometry(4, 0.25, 1), borderMat);
    borderF.position.set(0, 1.625, -2.5);
    borderF.castShadow = true;
    borderF.receiveShadow = true;
    roomGroup.add(borderF);

    const borderB = new THREE.Mesh(new THREE.BoxGeometry(4, 0.25, 1), borderMat);
    borderB.position.set(0, 1.625, 2.5);
    borderB.castShadow = true;
    borderB.receiveShadow = true;
    roomGroup.add(borderB);

    // Cove Light glowing strips
    const activeColor = colorMap[lightColor];
    const glowMat = new THREE.MeshBasicMaterial({ 
      color: activeColor.glow,
      transparent: true,
      opacity: 0.9
    });

    const glowL = new THREE.Mesh(new THREE.BoxGeometry(0.04, 0.04, 4), glowMat);
    glowL.position.set(-1.95, 1.7, 0);
    roomGroup.add(glowL);

    const glowR = new THREE.Mesh(new THREE.BoxGeometry(0.04, 0.04, 4), glowMat);
    glowR.position.set(1.95, 1.7, 0);
    roomGroup.add(glowR);

    const glowF = new THREE.Mesh(new THREE.BoxGeometry(4, 0.04, 0.04), glowMat);
    glowF.position.set(0, 1.7, -1.95);
    roomGroup.add(glowF);

    const glowB = new THREE.Mesh(new THREE.BoxGeometry(4, 0.04, 0.04), glowMat);
    glowB.position.set(0, 1.7, 1.95);
    roomGroup.add(glowB);

    coveGlowMeshesRef.current = [glowL, glowR, glowF, glowB];

    // Ambient Lighting
    const ambient = new THREE.AmbientLight(0xffffff, lightsOn ? 0.35 : 0.05);
    scene.add(ambient);
    ambientLightRef.current = ambient;

    // Center point light for cove lighting
    const coveLight = new THREE.PointLight(activeColor.point, lightsOn ? 1.5 : 0, 8);
    coveLight.position.set(0, 1.7, 0);
    coveLight.castShadow = true;
    roomGroup.add(coveLight);
    coveLightRef.current = coveLight;

    // Corner spotlights
    const spotCoords = [
      { x: -2.2, z: -2.2 },
      { x: 2.2, z: -2.2 },
      { x: -2.2, z: 2.2 },
      { x: 2.2, z: 2.2 }
    ];

    const spotlights: THREE.SpotLight[] = [];
    spotCoords.forEach((coord) => {
      // Spotlight fixture
      const fixtureGeo = new THREE.CylinderGeometry(0.08, 0.08, 0.08, 8);
      const fixtureMat = new THREE.MeshStandardMaterial({ color: 0x080b11, roughness: 0.5 });
      const fixture = new THREE.Mesh(fixtureGeo, fixtureMat);
      fixture.position.set(coord.x, 1.58, coord.z);
      roomGroup.add(fixture);

      // Light source
      const spotLight = new THREE.SpotLight(activeColor.spotlights, lightsOn ? 1.5 : 0, 6, Math.PI / 4, 0.5, 1);
      spotLight.position.set(coord.x, 1.55, coord.z);
      
      const target = new THREE.Object3D();
      target.position.set(coord.x, -1.75, coord.z);
      roomGroup.add(target);
      spotLight.target = target;
      
      spotLight.castShadow = true;
      spotLight.shadow.mapSize.width = 256;
      spotLight.shadow.mapSize.height = 256;
      spotLight.shadow.bias = -0.001;

      roomGroup.add(spotLight);
      spotlights.push(spotLight);
    });
    spotlightsRef.current = spotlights;

    // Set initial tilt
    roomGroup.rotation.x = 0.28;
    roomGroup.rotation.y = -0.45;

    // Mouse / Touch Drag mechanics
    let isDragging = false;
    let prevX = 0;
    let prevY = 0;
    let targetRotationY = -0.45;
    let targetRotationX = 0.28;
    let autoSpin = true;
    let spinTimer: any = null;

    const onMouseDown = (e: MouseEvent) => {
      isDragging = true;
      prevX = e.clientX;
      prevY = e.clientY;
      autoSpin = false;
      if (spinTimer) globalThis.clearTimeout(spinTimer);
    };

    const onMouseMove = (e: MouseEvent) => {
      if (!isDragging) return;
      const deltaX = e.clientX - prevX;
      const deltaY = e.clientY - prevY;
      
      targetRotationY += deltaX * 0.007;
      targetRotationX += deltaY * 0.007;
      
      targetRotationX = Math.max(-0.2, Math.min(0.8, targetRotationX));

      prevX = e.clientX;
      prevY = e.clientY;
    };

    const onMouseUp = () => {
      isDragging = false;
      spinTimer = globalThis.setTimeout(() => {
        autoSpin = true;
      }, 4000);
    };

    const onTouchStart = (e: TouchEvent) => {
      if (e.touches.length === 0) return;
      isDragging = true;
      prevX = e.touches[0].clientX;
      prevY = e.touches[0].clientY;
      autoSpin = false;
      if (spinTimer) globalThis.clearTimeout(spinTimer);
    };

    const onTouchMove = (e: TouchEvent) => {
      if (!isDragging || e.touches.length === 0) return;
      const deltaX = e.touches[0].clientX - prevX;
      const deltaY = e.touches[0].clientY - prevY;
      
      targetRotationY += deltaX * 0.007;
      targetRotationX += deltaY * 0.007;
      
      targetRotationX = Math.max(-0.2, Math.min(0.8, targetRotationX));

      prevX = e.touches[0].clientX;
      prevY = e.touches[0].clientY;
    };

    const canvasElement = renderer.domElement;
    canvasElement.addEventListener('mousedown', onMouseDown);
    globalThis.addEventListener('mousemove', onMouseMove);
    globalThis.addEventListener('mouseup', onMouseUp);
    canvasElement.addEventListener('touchstart', onTouchStart, { passive: true });
    canvasElement.addEventListener('touchmove', onTouchMove, { passive: true });
    canvasElement.addEventListener('touchend', onMouseUp);

    let animationFrameId = 0;
    const animate = () => {
      animationFrameId = requestAnimationFrame(animate);

      if (autoSpin) {
        targetRotationY += 0.002;
      }

      roomGroup.rotation.y += (targetRotationY - roomGroup.rotation.y) * 0.1;
      roomGroup.rotation.x += (targetRotationX - roomGroup.rotation.x) * 0.1;

      renderer.render(scene, camera);
    };
    animate();

    const resizeObserver = new ResizeObserver((entries) => {
      for (let entry of entries) {
        const w = entry.contentRect.width || width;
        renderer.setSize(w, height);
        camera.aspect = w / height;
        camera.updateProjectionMatrix();
      }
    });
    resizeObserver.observe(container);

    return () => {
      cancelAnimationFrame(animationFrameId);
      resizeObserver.disconnect();
      
      canvasElement.removeEventListener('mousedown', onMouseDown);
      globalThis.removeEventListener('mousemove', onMouseMove);
      globalThis.removeEventListener('mouseup', onMouseUp);
      canvasElement.removeEventListener('touchstart', onTouchStart);
      canvasElement.removeEventListener('touchmove', onTouchMove);
      canvasElement.removeEventListener('touchend', onMouseUp);
      
      if (spinTimer) globalThis.clearTimeout(spinTimer);

      scene.clear();
      renderer.dispose();
      renderer.domElement.remove();
    };
  }, []);

  // Update light components dynamically when React state changes
  useEffect(() => {
    const intensityFactor = lightsOn ? 1 : 0;
    
    if (ambientLightRef.current) {
      ambientLightRef.current.intensity = lightsOn ? 0.35 : 0.05;
    }

    const activeColor = colorMap[lightColor];

    if (coveLightRef.current) {
      coveLightRef.current.intensity = intensityFactor * 1.5;
      coveLightRef.current.color.setHex(activeColor.point);
    }

    spotlightsRef.current.forEach(spot => {
      spot.intensity = intensityFactor * 1.5;
      spot.color.setHex(activeColor.spotlights);
    });

    coveGlowMeshesRef.current.forEach(glow => {
      if (glow.material instanceof THREE.MeshBasicMaterial) {
        glow.material.color.setHex(activeColor.glow);
        glow.material.opacity = lightsOn ? 0.9 : 0.1;
      }
    });
  }, [lightsOn, lightColor]);

  return (
    <div className="backdrop-blur-md bg-white/10 border border-white/20 rounded-3xl p-5 text-white flex flex-col gap-4 shadow-xl">
      <div className="flex items-center justify-between border-b border-white/10 pb-3">
        <div>
          <h4 className="text-xs font-black uppercase tracking-wider text-blue-300">
            Interactive 3D Ceiling Room
          </h4>
          <p className="text-[10px] text-slate-400 font-semibold mt-0.5">
            Swipe inside canvas to rotate 360°
          </p>
        </div>
        <button
          onClick={() => setLightsOn(!lightsOn)}
          className={`px-3 py-1.5 rounded-xl text-[10px] font-black uppercase tracking-wider transition-all border ${
            lightsOn
              ? 'bg-yellow-500/20 text-yellow-300 border-yellow-500/30 shadow-lg shadow-yellow-500/10'
              : 'bg-slate-800 text-slate-400 border-slate-700'
          }`}
        >
          {lightsOn ? 'Lights: ON' : 'Lights: OFF'}
        </button>
      </div>

      <div 
        ref={mountRef} 
        className="w-full h-[240px] rounded-2xl overflow-hidden relative bg-slate-950 border border-white/5 shadow-inner cursor-grab active:cursor-grabbing"
      />

      <div className="flex justify-between items-center bg-white/5 border border-white/10 p-2.5 rounded-2xl">
        <span className="text-[10px] font-black uppercase text-slate-400 tracking-wider">
          Cove Light Color:
        </span>
        <div className="flex items-center gap-2">
          {(['warm', 'cyan', 'purple'] as const).map(color => {
            const classMap = {
              warm: 'bg-amber-400 border-amber-400 shadow-amber-400/20',
              cyan: 'bg-cyan-400 border-cyan-400 shadow-cyan-400/20',
              purple: 'bg-purple-400 border-purple-400 shadow-purple-400/20'
            };
            return (
              <button
                key={color}
                onClick={() => {
                  setLightColor(color);
                  setLightsOn(true);
                }}
                className={`w-6 h-6 rounded-full border-2 transition-transform duration-200 ${classMap[color]} ${
                  lightColor === color ? 'scale-115 ring-2 ring-white/50 shadow-lg' : 'opacity-60 scale-90'
                }`}
                title={color.toUpperCase()}
              />
            );
          })}
        </div>
      </div>
    </div>
  );
};
