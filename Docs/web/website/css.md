FoCoCo | CSS Pack 
CSS: 
/* =========================== 
 0. BASE TOKENS & UTILITIES 
 =========================== */ 
:root { 
 --fococo-blue: #4285F4; 
 --fococo-green: #34A853; 
 --fococo-yellow: #FBBC05; 
 --fococo-bg: #000000; 
 --fococo-text: #FFFFFF; 
 --fococo-radius-xl: 999px; 
 --fococo-shadow-soft: 0 0 24px rgba(66, 133, 244, 0.45); 
} 
/* Reduced motion: kill all loops & transforms */ 
@media (prefers-reduced-motion: reduce) { 
 * { 
 animation-duration: 0.001ms !important; 
 animation-iteration-count: 1 !important; 
 transition: none !important; 
 } 
} 
/* Generic fade-in on scroll (JS should toggle .is-in-view) */ 
.section { 
 opacity: 0; 
 transform: translateY(16px); 
 transition: opacity 400ms ease-out, transform 400ms ease-out; 
} 
.section.is-in-view { 
 opacity: 1; 
 transform: translateY(0); 
} 
.section-title { 
 opacity: 0; 
 transform: translateY(12px); 
 transition: opacity 350ms ease-out, transform 350ms ease-out; 
} 
.section.is-in-view .section-title { 
 opacity: 1; 
 transform: translateY(0); 
} 
.section-body { 
 opacity: 0; 
 transform: translateY(8px); 
 transition: opacity 350ms ease-out 80ms, transform 350ms ease-out 80ms; 
} 
.section.is-in-view .section-body { 
 opacity: 1; 
 transform: translateY(0); 
} 
/* Images fade / slight zoom on reveal */ 
.section-image { 
 opacity: 0; 
 transform: scale(0.98); 
 transition: opacity 450ms ease-out, transform 450ms ease-out; 
} 
.section.is-in-view .section-image { 
 opacity: 1; 
 transform: scale(1); 
} 
****************************************************************************************************** 
1. HERO | ORB, ARCS, ORBIT LINE 
NOTE: Adjust width/height/position so the overlays sit perfectly on the Hero png. 
CSS: 
/* Hero layout wrapper */ 
.hero { 
 position: relative; 
 background-color: var(--fococo-bg); 
 color: var(--fococo-text); 
 overflow: hidden; 
} 
/* Orb “breathing” pulse */ 
.hero-orb { 
 position: absolute; 
 /* Imad: position this over the orb in the PNG */ 
 width: 220px; 
 height: 220px; 
 border-radius: 50%; 
 pointer-events: none; 
 animation: hero-orb-breathe 4s ease-in-out infinite; 
} 
@keyframes hero-orb-breathe { 
 0% { 
 transform: scale(1); 
 opacity: 1; 
 } 
 50% { 
 transform: scale(1.03); 
 opacity: 0.9; 
 } 
 100% { 
 transform: scale(1); 
 opacity: 1; 
 } 
} 
/* Orbit highlight traveling along line */ 
.hero-orbit-highlight { 
 position: absolute; 
 /* Imad: align this with the orbit line curve */ 
 width: 140px; 
 height: 140px; 
 border-radius: 50%; 
 border-top: 2px solid rgba(255, 255, 255, 0.3); 
 border-left: 2px solid transparent; 
 border-right: 2px solid transparent; 
 border-bottom: 2px solid transparent; 
 animation: hero-orbit-sweep 4s ease-out infinite; 
} 
@keyframes hero-orbit-sweep { 
 0% { 
 transform: rotate(-40deg); 
 opacity: 0; 
 } 
 15% { 
 opacity: 1; 
 } 
 60% { 
 transform: rotate(60deg); 
 opacity: 1; 
 } 
 100% { 
 transform: rotate(90deg); 
 opacity: 0; 
 } 
} 
/* Very soft arc glow pulsing together */ 
.hero-arcs-glow { 
 position: absolute; 
 inset: 0; 
 pointer-events: none; 
 mix-blend-mode: screen; 
 animation: hero-arcs-pulse 5.5s ease-in-out infinite; 
} 
@keyframes hero-arcs-pulse { 
 0%, 100% { 
 opacity: 0.45; 
 } 
 50% { 
 opacity: 0.65; 
 } 
} 
******************************************************************************************************* 
2. SECTION SPECIFIC IMAGE MOTION 
2.1 FoCoMap (center image, subtle nodes & signals) 
CSS: 
.focomap-wrapper { 
 position: relative; 
 display: inline-block; 
} 
.focomap-image { 
 display: block; 
 width: 100%; 
 height: auto; 
} 
/* Overlay for glowing nodes */ 
.focomap-overlay { 
 pointer-events: none; 
 position: absolute; 
 inset: 0; 
} 
/* Imad: place a few absolutely positioned .focomap-node divs inside .focomap-overlay */ 
.focomap-node { 
 position: absolute; 
 width: 8px; 
 height: 8px; 
 border-radius: 50%; 
 background: rgba(66, 133, 244, 0.9); 
 box-shadow: 0 0 12px rgba(66, 133, 244, 0.9); 
 animation: focomap-node-pulse 4s ease-in-out infinite; 
} 
@keyframes focomap-node-pulse { 
 0%, 100% { 
 opacity: 0.2; 
 transform: scale(0.8); 
 } 
 50% { 
 opacity: 1; 
 transform: scale(1); 
 } 
} 
/* “Signal” stroke sweeping occasionally */ 
.focomap-signal { 
 position: absolute; 
 width: 40%; 
 height: 2px; 
 background: linear-gradient( 
 to right, 
 rgba(66, 133, 244, 0), 
 rgba(66, 133, 244, 0.8), 
 rgba(66, 133, 244, 0) 
 ); 
 opacity: 0; 
 animation: focomap-signal-sweep 7s ease-out infinite; 
} 
@keyframes focomap-signal-sweep { 
 0% { 
 transform: translateX(-10%); 
 opacity: 0; 
 } 
 15% { 
 opacity: 1; 
 } 
 40% { 
 transform: translateX(70%); 
 opacity: 1; 
 } 
 60% { 
 opacity: 0; 
 } 
 100% { 
 transform: translateX(90%); 
 opacity: 0; 
 } 
} 
***************************************************************************************************** 
2.2 MindCoach (right image, soft glow) 
CSS: 
.mindcoach-image-wrapper { 
 position: relative; 
 display: inline-block; 
} 
.mindcoach-image { 
 display: block; 
 width: 100%; 
 height: auto; 
} 
/* Inner glow pulse */ 
.mindcoach-glow { 
 position: absolute; 
 inset: 8%; 
 border-radius: 24px; 
 box-shadow: 0 0 28px rgba(66, 133, 244, 0.45); 
 opacity: 0.4; 
 pointer-events: none; 
 animation: mindcoach-breathe 4.5s ease-in-out infinite; 
} 
@keyframes mindcoach-breathe { 
 0%, 100% { 
 opacity: 0.25; 
 } 
 50% { 
 opacity: 0.6; 
 } 
} 
/* Hover: slightly stronger glow */ 
.mindcoach-image-wrapper:hover .mindcoach-glow { 
 opacity: 0.7; 
} 
***************************************************************************************************** 
2.3 GolfSync (center image, gentle shimmer) 
CSS: 
.golfsync-image-wrapper { 
 position: relative; 
 display: inline-block; 
} 
.golfsync-image { 
 display: block; 
 width: 100%; 
 height: auto; 
} 
/* Shimmer line across arcs */ 
.golfsync-shimmer { 
 position: absolute; 
 inset: 0; 
 pointer-events: none; 
 background: linear-gradient( 
 120deg, 
 rgba(255, 255, 255, 0) 0%, 
 rgba(255, 255, 255, 0.15) 40%, 
 rgba(255, 255, 255, 0) 80% 
 ); 
 transform: translateX(-100%); 
 animation: golfsync-shimmer-move 5s ease-in-out infinite; 
} 
@keyframes golfsync-shimmer-move { 
 0% { 
 transform: translateX(-120%); 
 opacity: 0; 
 } 
 20% { 
 opacity: 1; 
 } 
 50% { 
 transform: translateX(20%); 
 opacity: 1; 
 } 
 80% { 
 opacity: 0; 
 } 
 100% { 
 transform: translateX(120%); 
 opacity: 0; 
 } 
} 
/* Hover brighten */ 
.golfsync-image-wrapper:hover .golfsync-image { 
 filter: brightness(1.05); 
} 
***************************************************************************************************** 
2.4 Trust (left image, calm breathing) 
CSS: 
.trust-image-wrapper { 
 position: relative; 
 display: inline-block; 
} 
.trust-image { 
 display: block; 
 width: 100%; 
 height: auto; 
} 
.trust-glow-bg { 
 position: absolute; 
 inset: 10%; 
 border-radius: 32px; 
 background: radial-gradient( 
 circle at center, 
 rgba(245, 197, 99, 0.35), 
 transparent 60% 
 ); 
 opacity: 0.35; 
 pointer-events: none; 
 animation: trust-glow-breathe 6s ease-in-out infinite; 
} 
@keyframes trust-glow-breathe { 
 0%, 100% { 
 opacity: 0.25; 
 } 
 50% { 
 opacity: 0.6; 
 } 
} 
***************************************************************************************************** 
2.5 3 Pillars (left image, hover highlight) 
CSS: 
.pillars-image-wrapper { 
 position: relative; 
 display: inline-block; 
} 
.pillars-image { 
 display: block; 
 width: 100%; 
 height: auto; 
} 
/* Simple gradient sweep to suggest flow */ 
.pillars-sweep { 
 position: absolute; 
 inset: 0; 
 pointer-events: none; 
 background: linear-gradient( 
 90deg, 
 rgba(66, 133, 244, 0) 0%, 
 rgba(66, 133, 244, 0.1) 40%, 
 rgba(52, 168, 83, 0.1) 60%, 
 rgba(251, 188, 5, 0) 100% 
 ); 
 opacity: 0; 
 animation: pillars-sweep-move 7s ease-in-out infinite; 
} 
@keyframes pillars-sweep-move { 
 0%, 40% { 
 opacity: 0; 
 transform: translateX(-10%); 
 } 
 50% { 
 opacity: 1; 
 transform: translateX(0%); 
 } 
 70%, 100% { 
 opacity: 0; 
 transform: translateX(10%); 
 } 
} 
/* Hover: subtle brightness bump */ 
.pillars-image-wrapper:hover .pillars-image { 
 filter: brightness(1.04); 
} 
***************************************************************************************************** 
3. BUTTONS, LINKS, ICONS 
CSS:
/* Primary CTA */ 
.btn-primary { 
 display: inline-flex; 
 align-items: center; 
 justify-content: center; 
 padding: 0.9rem 1.8rem; 
 border-radius: 999px; 
 border: none; 
 background: var(--fococo-blue); 
 color: var(--fococo-text); 
 font-weight: 600; 
 cursor: pointer; 
 box-shadow: 0 0 0 rgba(66, 133, 244, 0); 
 transition: 
 transform 160ms ease-out, 
 box-shadow 160ms ease-out, 
 background 160ms ease-out; 
} 
.btn-primary:hover { 
 transform: translateY(-1px) scale(1.03); 
 box-shadow: var(--fococo-shadow-soft); 
} 
.btn-primary:active { 
 transform: translateY(0) scale(0.98); 
 box-shadow: 0 0 0 rgba(0, 0, 0, 0); 
} 
/* Secondary CTA */ 
.btn-secondary { 
 display: inline-flex; 
 align-items: center; 
 justify-content: center; 
 padding: 0.9rem 1.8rem; 
 border-radius: 999px; 
 border: 1px solid rgba(255, 255, 255, 0.6); 
 background: transparent; 
 color: var(--fococo-text); 
 font-weight: 500; 
 cursor: pointer; 
 transition: 
 transform 150ms ease-out, 
 border-color 150ms ease-out, 
 background 150ms ease-out; 
} 
.btn-secondary:hover { 
 transform: translateY(-1px); 
 border-color: var(--fococo-blue); 
 background: rgba(255, 255, 255, 0.04); 
} 
.btn-secondary:active { 
 transform: translateY(0) scale(0.98); 
} 
/* Text links */ 
a.inline-link { 
 position: relative; 
 color: var(--fococo-text); 
 text-decoration: none; 
} 
a.inline-link::after { 
 content: ""; 
 position: absolute; 
 left: 50%; 
 right: 50%; 
 bottom: -2px; 
 height: 1px; 
 background: rgba(255, 255, 255, 0.65); 
 transition: left 160ms ease-out, right 160ms ease-out; 
} 
a.inline-link:hover::after { 
 left: 0; 
 right: 0; 
} 
/* Footer social icons */ 
.footer-social { 
 display: flex; 
 gap: 0.75rem; 
} 
.footer-social a { 
 display: inline-flex; 
 align-items: center; 
 justify-content: center; 
 width: 28px; 
 height: 28px; 
 border-radius: 999px; 
 color: rgba(255, 255, 255, 0.7); 
 transition: 
 color 150ms ease-out, 
 box-shadow 150ms ease-out, 
 transform 150ms ease-out; 
} 
.footer-social a:hover { 
 color: #ffffff; 
 box-shadow: 0 0 12px rgba(255, 255, 255, 0.35); 
 transform: translateY(-1px); 
} 
***************************************************************************************************** 
4. FAQ ACCORDION
NOTE: Assuming a simple structure: .faq-item, .faq-question, .faq-answer, .is-open toggled 
by JS. 
CSS: 
.faq-item { 
 border-bottom: 1px solid rgba(255, 255, 255, 0.09); 
 padding: 0.9rem 0; 
} 
.faq-question { 
 display: flex; 
 align-items: center; 
 justify-content: space-between; 
 cursor: pointer; 
 gap: 0.75rem; 
} 
.faq-question-text { 
 font-weight: 500; 
} 
.faq-chevron { 
 transition: transform 160ms ease-out; 
} 
.faq-item.is-open .faq-chevron { 
 transform: rotate(90deg); 
} 
.faq-answer { 
 max-height: 0; 
 opacity: 0; 
 overflow: hidden; 
 transform: translateY(-4px); 
 transition: 
 max-height 260ms ease-out, 
 opacity 220ms ease-out, 
 transform 220ms ease-out; 
} 
.faq-item.is-open .faq-answer { 
 opacity: 1; 
 transform: translateY(0); 
 max-height: 400px; /* enough for long answers */ 
} 
/* Slight highlight when open */ 
.faq-item.is-open { 
 background: linear-gradient( 
 to right, 
 rgba(66, 133, 244, 0.08), 
 rgba(0, 0, 0, 0) 
 ); 
}