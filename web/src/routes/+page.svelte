<script lang="ts">
	import { onMount } from 'svelte';
	import gsap from 'gsap';
	import { ScrollTrigger } from 'gsap/ScrollTrigger';
	import {
		Eye, Shield, Smartphone, Lock, Package, Fingerprint,
		ScanFace, ArrowRight, Check, X, Github, BookOpen,
		Zap, Server, Clock, Users
	} from 'lucide-svelte';

	gsap.registerPlugin(ScrollTrigger);

	let heroRef: HTMLElement;
	let demoRef: HTMLElement;
	let featuresRef: HTMLElement;
	let codeRef: HTMLElement;
	let compareRef: HTMLElement;
	let statsRef: HTMLElement;
	let ctaRef: HTMLElement;

	const features = [
		{
			icon: Eye,
			title: '6 Liveness Actions',
			desc: 'Blink, smile, head turn left/right, look up/down — Fisher-Yates shuffled each session.',
			color: 'from-indigo-500 to-blue-500'
		},
		{
			icon: Shield,
			title: 'Session Security',
			desc: 'HMAC-SHA256 frame signing with nonce replay protection.',
			color: 'from-emerald-500 to-teal-500'
		},
		{
			icon: Smartphone,
			title: 'Cross-Platform',
			desc: 'iOS and Android. Front camera support out of the box.',
			color: 'from-purple-500 to-pink-500'
		},
		{
			icon: Lock,
			title: 'Privacy-First',
			desc: '100% on-device. No server. No data leaves the device.',
			color: 'from-amber-500 to-orange-500'
		},
		{
			icon: Package,
			title: 'Lightweight',
			desc: 'Minimal deps — camera, ML Kit, crypto only.',
			color: 'from-cyan-500 to-blue-500'
		},
		{
			icon: Fingerprint,
			title: 'Face ID',
			desc: 'Register & identify up to 20 faces. Adaptive template blending.',
			color: 'from-rose-500 to-red-500'
		}
	];

	const comparisons = [
		{ feature: 'Integration Time', vivd: '~10 min', inhouse: '3–6 months', competitor: '1–2 weeks' },
		{ feature: 'Liveness Actions', vivd: '6 actions', inhouse: 'Custom', competitor: '2–3 actions' },
		{ feature: 'On-Device', vivd: true, inhouse: true, competitor: false },
		{ feature: 'Offline Support', vivd: true, inhouse: true, competitor: false },
		{ feature: 'No API Key', vivd: true, inhouse: true, competitor: false },
		{ feature: 'Lightweight Deps', vivd: true, inhouse: false, competitor: false },
		{ feature: 'Session Signing', vivd: true, inhouse: 'Optional', competitor: false },
		{ feature: 'Face ID (20 faces)', vivd: true, inhouse: 'Custom', competitor: false },
		{ feature: 'Open Source', vivd: true, inhouse: true, competitor: false },
		{ feature: 'Price', vivd: 'Free', inhouse: '$50K+', competitor: '$$/mo' }
	];

	const stats = [
		{ value: '100%', label: 'On-Device', icon: Smartphone },
		{ value: '6', label: 'Actions', icon: Eye },
		{ value: '20', label: 'Faces', icon: Users },
		{ value: '59', label: 'Unit Tests', icon: Check }
	];

	const codeHero = `<span class="text-gray-500">dependencies:</span>\n  <span class="text-indigo-400">vivd</span><span class="text-gray-500">:</span> <span class="text-emerald-400">^0.0.1</span>`;

	const codeQuickstart = `<span class="text-purple-400">import</span> <span class="text-emerald-400">'package:vivd/vivd.dart'</span>;\n\n<span class="text-purple-400">final</span> vivd = <span class="text-indigo-400">Vivd</span>();\n<span class="text-purple-400">await</span> vivd.<span class="text-cyan-400">initialize</span>();\n\n<span class="text-gray-500">// Start liveness with camera frames</span>\n<span class="text-purple-400">final</span> result = <span class="text-purple-400">await</span> vivd.<span class="text-cyan-400">startLiveness</span>(\n  frameStream: <span class="text-indigo-400">cameraStream</span>,\n  actions: [\n    <span class="text-indigo-400">VivdAction</span>.<span class="text-cyan-400">blink</span>,\n    <span class="text-indigo-400">VivdAction</span>.<span class="text-cyan-400">smile</span>,\n    <span class="text-indigo-400">VivdAction</span>.<span class="text-cyan-400">headTurnLeft</span>,\n  ],\n);\n\n<span class="text-purple-400">if</span> (result.<span class="text-cyan-400">isLive</span>) {\n  <span class="text-indigo-400">print</span>(<span class="text-emerald-400">'Face verified!'</span>);\n  <span class="text-indigo-400">print</span>(<span class="text-emerald-400">'Score: \${result.score}'</span>);\n}\n\n<span class="text-purple-400">await</span> vivd.<span class="text-cyan-400">dispose</span>();`;

	const codeWidget = `<span class="text-purple-400">import</span> <span class="text-emerald-400">'package:vivd/vivd.dart'</span>;\n\n<span class="text-gray-500">// Drop-in widget — camera included</span>\n<span class="text-indigo-400">VivdLivenessDetector</span>(\n  onResult: (result) {\n    <span class="text-purple-400">if</span> (result.<span class="text-cyan-400">isLive</span>) {\n      <span class="text-indigo-400">print</span>(<span class="text-emerald-400">'Verified!'</span>);\n    }\n  },\n)`;

	const navSections = ['#features', '#quickstart', '#compare', '#pro'];

	onMount(() => {
		const mm = gsap.matchMedia();

		// Hero animations
		gsap.from('[data-hero-fade]', {
			y: 30,
			opacity: 0,
			duration: 0.8,
			stagger: 0.15,
			ease: 'power3.out',
			delay: 0.2
		});

		// Demo phone fade in
		gsap.from('[data-demo-phone]', {
			scrollTrigger: {
				trigger: demoRef,
				start: 'top 80%',
				toggleActions: 'play none none none'
			},
			y: 60,
			opacity: 0,
			duration: 1,
			ease: 'power3.out'
		});

		// Feature cards stagger
		mm.add('(min-width: 768px)', () => {
			gsap.from('[data-feature-card]', {
				scrollTrigger: {
					trigger: featuresRef,
					start: 'top 75%',
					toggleActions: 'play none none none'
				},
				y: 40,
				opacity: 0,
				duration: 0.6,
				stagger: 0.1,
				ease: 'power2.out'
			});
		});

		// Code block slide
		gsap.from('[data-code-block]', {
			scrollTrigger: {
				trigger: codeRef,
				start: 'top 70%',
				toggleActions: 'play none none none'
			},
			x: 40,
			opacity: 0,
			duration: 0.8,
			ease: 'power2.out'
		});

		gsap.from('[data-code-text]', {
			scrollTrigger: {
				trigger: codeRef,
				start: 'top 70%',
				toggleActions: 'play none none none'
			},
			x: -40,
			opacity: 0,
			duration: 0.8,
			ease: 'power2.out'
		});

		// Stats counter
		gsap.from('[data-stat]', {
			scrollTrigger: {
				trigger: statsRef,
				start: 'top 75%',
				toggleActions: 'play none none none'
			},
			y: 30,
			opacity: 0,
			duration: 0.5,
			stagger: 0.1,
			ease: 'power2.out'
		});

		// CTA section
		gsap.from('[data-cta]', {
			scrollTrigger: {
				trigger: ctaRef,
				start: 'top 70%',
				toggleActions: 'play none none none'
			},
			scale: 0.95,
			opacity: 0,
			duration: 0.8,
			ease: 'power2.out'
		});

		// Active nav link via IntersectionObserver
		const navLinks = document.querySelectorAll('.nav-link');
		const observer = new IntersectionObserver(
			(entries) => {
				entries.forEach((entry) => {
					if (entry.isIntersecting) {
						const id = '#' + entry.target.id;
						navLinks.forEach((link) => {
							link.classList.toggle('active', link.getAttribute('href') === id);
						});
					}
				});
			},
			{ rootMargin: '-20% 0px -60% 0px' }
		);
		navSections.forEach((sel) => {
			const el = document.querySelector(sel);
			if (el) observer.observe(el);
		});

		return () => {
			mm.revert();
			observer.disconnect();
		};
	});
</script>

<!-- ===== HERO ===== -->
<section class="relative overflow-hidden pb-16 md:pb-20 hero-mesh" bind:this={heroRef}>
	<!-- Background glow orbs -->
	<div class="absolute top-0 left-1/2 -translate-x-1/2 w-[800px] h-[500px] bg-gradient-to-b from-indigo-500/10 via-indigo-500/5 to-transparent rounded-full blur-3xl pointer-events-none"></div>
	<div class="absolute top-40 -left-40 w-72 h-72 bg-purple-500/5 rounded-full blur-3xl pointer-events-none"></div>
	<div class="absolute top-60 -right-40 w-72 h-72 bg-indigo-500/5 rounded-full blur-3xl pointer-events-none"></div>

	<div class="mx-auto max-w-4xl px-6 pt-20 md:pt-28 text-center relative">
		<!-- Badge -->
		<div data-hero-fade class="inline-flex items-center gap-2 px-4 py-1.5 rounded-full border border-indigo-500/20 bg-indigo-500/5 mb-6">
			<span class="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
			<span class="text-xs font-medium text-indigo-300">Open Source &bull; Apache 2.0 &bull; v0.0.1</span>
		</div>

		<!-- Headline -->
		<h1 data-hero-fade class="text-4xl sm:text-5xl md:text-6xl font-extrabold tracking-tight leading-[1.1] mb-5">
			<span class="text-white">Face Liveness</span>
			<span class="gradient-text">That Actually Works</span>
		</h1>

		<!-- Subtitle -->
		<p data-hero-fade class="mx-auto max-w-xl text-base sm:text-lg text-gray-400 leading-relaxed mb-8">
			Drop-in Flutter SDK for on-device face verification. No server, no API key, minimal dependencies.
			Just <span class="text-gray-200 font-medium">blink, smile, and verify</span>.
		</p>

		<!-- CTAs -->
		<div data-hero-fade class="flex flex-col sm:flex-row items-center justify-center gap-3">
			<a
				href="#quickstart"
				class="group inline-flex items-center gap-2 px-7 py-3 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white font-semibold text-sm transition-all shadow-lg shadow-indigo-500/25 hover:shadow-indigo-500/40"
			>
				Get Started
				<ArrowRight size={16} class="transition-transform group-hover:translate-x-0.5" />
			</a>
			<a
				href="https://github.com/ajianaz/vivd"
				target="_blank"
				rel="noopener"
				class="inline-flex items-center gap-2 px-7 py-3 rounded-xl border border-white/10 hover:border-white/20 bg-white/[0.02] hover:bg-white/[0.05] text-gray-300 hover:text-white font-semibold text-sm transition-all"
			>
				<Github size={16} />
				View on GitHub
			</a>
		</div>

		<!-- Hero code preview -->
		<div data-hero-fade class="mt-12 mx-auto max-w-xl">
			<div class="code-block rounded-2xl p-1 glow-indigo">
				<div class="rounded-xl overflow-hidden">
					<div class="flex items-center gap-2 px-4 py-2.5 border-b border-indigo-500/10">
						<div class="flex gap-1.5">
							<div class="w-3 h-3 rounded-full bg-red-500/60"></div>
							<div class="w-3 h-3 rounded-full bg-yellow-500/60"></div>
							<div class="w-3 h-3 rounded-full bg-green-500/60"></div>
						</div>
						<span class="text-[11px] text-gray-500 ml-2">pubspec.yaml</span>
					</div>
					<pre class="px-4 py-3 text-[13px] leading-6 overflow-x-auto"><code>{@html codeHero}</code></pre>
				</div>
			</div>
		</div>
	</div>
</section>

<!-- ===== DEMO ===== -->
<section class="py-10 md:py-16" bind:this={demoRef}>
	<div data-demo-phone class="mx-auto max-w-sm px-6 flex flex-col items-center">
		<!-- Phone mockup frame -->
		<div class="relative rounded-[2.5rem] border-[3px] border-gray-700/80 bg-gray-900 p-2 phone-glow">
			<!-- Notch -->
			<div class="absolute top-0 left-1/2 -translate-x-1/2 w-28 h-6 bg-gray-900 rounded-b-2xl z-10"></div>
			<!-- Screen -->
			<div class="rounded-[2rem] overflow-hidden">
				<img
					src="demo.gif"
					alt="Vivd liveness detection demo"
					class="w-full max-w-[320px] h-auto block"
					loading="lazy"
				/>
			</div>
		</div>
		<p class="mt-4 text-xs text-gray-500 text-center">Demo is watermarked for privacy protection</p>
	</div>
</section>

<!-- ===== FEATURES ===== -->
<section id="features" class="py-16 md:py-20" bind:this={featuresRef}>
	<div class="mx-auto max-w-5xl px-6">
		<!-- Section header -->
		<div class="text-center mb-12">
			<span class="text-xs font-semibold text-indigo-400 uppercase tracking-widest">Features</span>
			<h2 class="mt-2 text-2xl sm:text-3xl font-bold text-white">Everything you need for face verification</h2>
			<p class="mt-3 text-gray-400 max-w-lg mx-auto text-sm">Built for Flutter developers who need reliable, privacy-preserving liveness detection.</p>
		</div>

		<!-- Feature grid -->
		<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
			{#each features as feature, i}
				<div
					data-feature-card
					class="glow-card group p-5 rounded-2xl border border-white/[0.06] bg-white/[0.02] transition-all duration-300"
				>
					<div class="w-9 h-9 rounded-lg bg-gradient-to-br {feature.color} flex items-center justify-center mb-3 shadow-lg">
						<feature.icon size={18} class="text-white" />
					</div>
					<h3 class="text-sm font-semibold text-white mb-1.5">{feature.title}</h3>
					<p class="text-xs text-gray-400 leading-relaxed">{feature.desc}</p>
				</div>
			{/each}
		</div>
	</div>
</section>

<!-- ===== STATS ===== -->
<section class="py-12 md:py-16" bind:this={statsRef}>
	<div class="mx-auto max-w-4xl px-6">
		<div class="grid grid-cols-2 lg:grid-cols-4 gap-4">
			{#each stats as stat, i}
				<div data-stat class="text-center p-5 rounded-2xl border border-white/[0.06] bg-white/[0.02]">
					<div class="inline-flex items-center justify-center w-9 h-9 rounded-lg bg-indigo-500/10 mb-3">
						<stat.icon size={18} class="text-indigo-400" />
					</div>
					<div class="text-2xl sm:text-3xl font-extrabold text-white mb-0.5">{stat.value}</div>
					<div class="text-xs text-gray-400">{stat.label}</div>
				</div>
			{/each}
		</div>
	</div>
</section>

<!-- ===== QUICK START ===== -->
<section id="quickstart" class="py-16 md:py-20" bind:this={codeRef}>
	<div class="mx-auto max-w-5xl px-6">
		<div class="text-center mb-12">
			<span class="text-xs font-semibold text-indigo-400 uppercase tracking-widest">Quick Start</span>
			<h2 class="mt-2 text-2xl sm:text-3xl font-bold text-white">Get running in minutes</h2>
		</div>

		<div class="grid lg:grid-cols-2 gap-8 items-start">
			<!-- Steps -->
			<div data-code-text class="space-y-6">
				<div class="flex gap-3">
					<div class="flex-shrink-0 w-7 h-7 rounded-lg bg-indigo-500/10 border border-indigo-500/20 flex items-center justify-center text-xs font-bold text-indigo-400">1</div>
					<div>
						<h3 class="text-sm font-semibold text-white mb-1">Add the dependency</h3>
						<p class="text-xs text-gray-400">Add <code class="text-indigo-400 bg-indigo-500/10 px-1.5 py-0.5 rounded text-[11px]">vivd: ^0.0.1</code> to your pubspec.yaml.</p>
					</div>
				</div>

				<div class="flex gap-3">
					<div class="flex-shrink-0 w-7 h-7 rounded-lg bg-indigo-500/10 border border-indigo-500/20 flex items-center justify-center text-xs font-bold text-indigo-400">2</div>
					<div>
						<h3 class="text-sm font-semibold text-white mb-1">Initialize & start liveness</h3>
						<p class="text-xs text-gray-400">Create a <code class="text-indigo-400 bg-indigo-500/10 px-1.5 py-0.5 rounded text-[11px]">Vivd()</code> instance, call <code class="text-indigo-400 bg-indigo-500/10 px-1.5 py-0.5 rounded text-[11px]">initialize()</code>, then <code class="text-indigo-400 bg-indigo-500/10 px-1.5 py-0.5 rounded text-[11px]">startLiveness()</code> with camera frame stream.</p>
					</div>
				</div>

				<div class="flex gap-3">
					<div class="flex-shrink-0 w-7 h-7 rounded-lg bg-indigo-500/10 border border-indigo-500/20 flex items-center justify-center text-xs font-bold text-indigo-400">3</div>
					<div>
						<h3 class="text-sm font-semibold text-white mb-1">Check the result</h3>
						<p class="text-xs text-gray-400">Verify with <code class="text-indigo-400 bg-indigo-500/10 px-1.5 py-0.5 rounded text-[11px]">result.isLive</code> and the confidence score. Dispose when done.</p>
					</div>
				</div>

				<div class="flex gap-3">
					<div class="flex-shrink-0 w-7 h-7 rounded-lg bg-indigo-500/10 border border-indigo-500/20 flex items-center justify-center text-xs font-bold text-indigo-400">★</div>
					<div>
						<h3 class="text-sm font-semibold text-white mb-1">Or use the drop-in widget</h3>
						<p class="text-xs text-gray-400">Use <code class="text-indigo-400 bg-indigo-500/10 px-1.5 py-0.5 rounded text-[11px]">VivdLivenessDetector</code> widget — camera handling built-in. See the example app.</p>
					</div>
				</div>

				<div class="pt-1">
					<a href="https://github.com/ajianaz/vivd/tree/develop/examples/basic" target="_blank" rel="noopener" class="inline-flex items-center gap-2 text-xs font-medium text-indigo-400 hover:text-indigo-300 transition-colors">
						<BookOpen size={14} />
						View example app on GitHub
					</a>
				</div>
			</div>

			<!-- Code block -->
			<div data-code-block>
				<div class="code-block rounded-2xl p-1 glow-indigo">
					<div class="rounded-xl overflow-hidden">
						<div class="flex items-center gap-2 px-4 py-2.5 border-b border-indigo-500/10">
							<div class="flex gap-1.5">
								<div class="w-3 h-3 rounded-full bg-red-500/60"></div>
								<div class="w-3 h-3 rounded-full bg-yellow-500/60"></div>
								<div class="w-3 h-3 rounded-full bg-green-500/60"></div>
							</div>
							<span class="text-[11px] text-gray-500 ml-2">liveness_check.dart</span>
						</div>
						<pre class="px-4 py-3 text-[12px] leading-5 overflow-x-auto"><code>{@html codeQuickstart}</code></pre>
					</div>
				</div>

				<!-- Widget code -->
				<div class="mt-4">
					<div class="code-block rounded-2xl p-1">
						<div class="rounded-xl overflow-hidden">
							<div class="flex items-center gap-2 px-4 py-2.5 border-b border-indigo-500/10">
								<div class="flex gap-1.5">
									<div class="w-3 h-3 rounded-full bg-red-500/60"></div>
									<div class="w-3 h-3 rounded-full bg-yellow-500/60"></div>
									<div class="w-3 h-3 rounded-full bg-green-500/60"></div>
								</div>
								<span class="text-[11px] text-gray-500 ml-2">widget_example.dart</span>
							</div>
							<pre class="px-4 py-3 text-[12px] leading-5 overflow-x-auto"><code>{@html codeWidget}</code></pre>
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>
</section>

<!-- ===== COMPARISON ===== -->
<section id="compare" class="py-16 md:py-20" bind:this={compareRef}>
	<div class="mx-auto max-w-5xl px-6">
		<div class="text-center mb-12">
			<span class="text-xs font-semibold text-indigo-400 uppercase tracking-widest">Compare</span>
			<h2 class="mt-2 text-2xl sm:text-3xl font-bold text-white">Why Vivd?</h2>
			<p class="mt-3 text-gray-400 max-w-lg mx-auto text-sm">See how Vivd stacks up against building in-house or using closed-source alternatives.</p>
		</div>

		<div class="overflow-x-auto rounded-2xl border border-white/[0.06] bg-white/[0.02]">
			<table class="w-full text-sm">
				<thead>
					<tr class="border-b border-white/[0.06]">
						<th class="text-left px-5 py-3.5 text-gray-500 font-medium text-xs">Feature</th>
						<th class="text-center px-5 py-3.5">
							<span class="inline-flex items-center gap-1.5 font-semibold text-indigo-400 text-xs">
								<span class="w-2 h-2 rounded-full bg-indigo-400"></span>
								Vivd
							</span>
						</th>
						<th class="text-center px-5 py-3.5 text-gray-500 font-medium text-xs">Build In-House</th>
						<th class="text-center px-5 py-3.5 text-gray-500 font-medium text-xs">Closed SDKs</th>
					</tr>
				</thead>
				<tbody>
					{#each comparisons as row}
						<tr class="compare-row border-b border-white/[0.03] transition-colors">
							<td class="px-5 py-3 text-gray-300 text-xs">{row.feature}</td>
							<td class="px-5 py-3 text-center">
								{#if typeof row.vivd === 'boolean'}
									{#if row.vivd}
										<Check size={15} class="inline text-emerald-400" />
									{:else}
										<X size={15} class="inline text-red-400/60" />
									{/if}
								{:else}
									<span class="text-indigo-300 font-medium text-xs">{row.vivd}</span>
								{/if}
							</td>
							<td class="px-5 py-3 text-center">
								{#if typeof row.inhouse === 'boolean'}
									{#if row.inhouse}
										<Check size={15} class="inline text-emerald-400/60" />
									{:else}
										<X size={15} class="inline text-red-400/60" />
									{/if}
								{:else}
									<span class="text-gray-400 text-xs">{row.inhouse}</span>
								{/if}
							</td>
							<td class="px-5 py-3 text-center">
								{#if typeof row.competitor === 'boolean'}
									{#if row.competitor}
										<Check size={15} class="inline text-emerald-400/60" />
									{:else}
										<X size={15} class="inline text-red-400/60" />
									{/if}
								{:else}
									<span class="text-gray-400 text-xs">{row.competitor}</span>
								{/if}
							</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	</div>
</section>

<!-- ===== PRO ===== -->
<section id="pro" class="py-16 md:py-20">
	<div class="mx-auto max-w-5xl px-6">
		<div class="relative rounded-3xl border border-indigo-500/20 bg-gradient-to-br from-indigo-500/5 via-transparent to-purple-500/5 p-6 sm:p-10 overflow-hidden">
			<!-- Glow -->
			<div class="absolute top-0 right-0 w-80 h-80 bg-indigo-500/10 rounded-full blur-3xl -translate-y-1/2 translate-x-1/2 pointer-events-none"></div>

			<div class="relative">
				<span class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-indigo-500/10 border border-indigo-500/20 text-xs font-medium text-indigo-300 mb-5">
					<Server size={12} />
					Vivd Pro
					<span class="ml-1 px-1.5 py-0.5 rounded-full bg-amber-500/10 border border-amber-500/20 text-[10px] font-medium text-amber-300">Coming Soon</span>
				</span>

				<h2 class="text-2xl sm:text-3xl font-bold text-white mb-3">Need server-backed verification?</h2>
				<p class="text-gray-400 max-w-2xl mb-6 leading-relaxed text-sm">
					Vivd Pro adds ML-based Presentation Attack Detection (PAD), compliance features, face management, and
					JWT-signed server-verified results. Upgrade when you need enterprise-grade security.
				</p>

				<div class="flex flex-wrap gap-2 mb-6">
					{#each ['ML PAD Detection', 'JWT Verification', 'Face Management', 'Compliance Ready'] as tag}
						<span class="px-3 py-1 rounded-lg bg-white/[0.04] border border-white/[0.06] text-xs font-medium text-gray-300">
							{tag}
						</span>
					{/each}
				</div>

				<div class="flex flex-wrap gap-3">
					<a href="https://github.com/ajianaz/vivd" target="_blank" rel="noopener" class="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white text-sm font-medium transition-colors">
						Learn about Pro
						<ArrowRight size={15} />
					</a>
					<span class="inline-flex items-center gap-1.5 px-4 py-2.5 text-xs text-gray-400">
						<Lock size={14} />
						BSL 1.1 License
					</span>
				</div>
			</div>
		</div>
	</div>
</section>

<!-- ===== CTA ===== -->
<section class="py-16 md:py-20" bind:this={ctaRef}>
	<div data-cta class="mx-auto max-w-3xl px-6 text-center">
		<h2 class="text-2xl sm:text-4xl font-extrabold text-white mb-4">Ready to verify?</h2>
		<p class="text-gray-400 text-base mb-8 max-w-lg mx-auto">
			Start with the free core SDK. Add Pro when you need server-backed security.
		</p>
		<div class="flex flex-col sm:flex-row items-center justify-center gap-3">
			<a
				href="https://github.com/ajianaz/vivd"
				target="_blank"
				rel="noopener"
				class="cta-glow group inline-flex items-center gap-2 px-7 py-3.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white font-semibold text-sm transition-all shadow-xl shadow-indigo-500/25 hover:shadow-indigo-500/40"
			>
				<Github size={18} />
				Get Started
				<ArrowRight size={16} class="transition-transform group-hover:translate-x-0.5" />
			</a>
			<a
				href="https://github.com/ajianaz/vivd/stargazers"
				target="_blank"
				rel="noopener"
				class="inline-flex items-center gap-2 px-7 py-3.5 rounded-xl border border-white/10 hover:border-white/20 bg-white/[0.02] hover:bg-white/[0.05] text-gray-300 hover:text-white font-semibold text-sm transition-all"
			>
				<Zap size={18} />
				Star on GitHub
			</a>
		</div>

		<!-- Trust badges -->
		<div class="mt-12 flex flex-wrap items-center justify-center gap-x-6 gap-y-2">
			<div class="flex items-center gap-1.5 text-xs text-gray-500">
				<Shield size={13} class="text-emerald-500/60" />
				Apache 2.0 Licensed
			</div>
			<div class="flex items-center gap-1.5 text-xs text-gray-500">
				<Lock size={13} class="text-emerald-500/60" />
				Privacy-First
			</div>
			<div class="flex items-center gap-1.5 text-xs text-gray-500">
				<Clock size={13} class="text-emerald-500/60" />
				10 Minute Setup
			</div>
			<div class="flex items-center gap-1.5 text-xs text-gray-500">
				<Zap size={13} class="text-emerald-500/60" />
				Lightweight
			</div>
		</div>
	</div>
</section>
