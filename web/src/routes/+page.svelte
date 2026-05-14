<script lang="ts">
	import { onMount } from 'svelte';
	import gsap from 'gsap';
	import { ScrollTrigger } from 'gsap/ScrollTrigger';
	import {
		Eye, Shield, Smartphone, Lock, Package, Cpu,
		ArrowRight, Check, X, Github, BookOpen,
		Zap, Server, Clock, Users
	} from 'lucide-svelte';

	gsap.registerPlugin(ScrollTrigger);

	let heroRef: HTMLElement;
	let featuresRef: HTMLElement;
	let codeRef: HTMLElement;
	let compareRef: HTMLElement;
	let statsRef: HTMLElement;
	let ctaRef: HTMLElement;

	const features = [
		{
			icon: Eye,
			title: '4 Liveness Actions',
			desc: 'Blink, smile, head turn left, head turn right — multi-challenge verification.',
			color: 'from-indigo-500 to-blue-500'
		},
		{
			icon: Shield,
			title: 'Session Security',
			desc: 'HMAC-SHA256 frame signing with nonce replay protection. Tamper-proof sessions.',
			color: 'from-emerald-500 to-teal-500'
		},
		{
			icon: Smartphone,
			title: 'Cross-Platform',
			desc: 'iOS with TrueDepth and Android with front camera support out of the box.',
			color: 'from-purple-500 to-pink-500'
		},
		{
			icon: Lock,
			title: 'Privacy-First',
			desc: '100% on-device processing. No server dependency. No data leaves the device.',
			color: 'from-amber-500 to-orange-500'
		},
		{
			icon: Package,
			title: 'Zero Dependencies',
			desc: 'Works offline with no external packages. Pure Flutter implementation.',
			color: 'from-cyan-500 to-blue-500'
		},
		{
			icon: Cpu,
			title: 'ML Kit Ready',
			desc: 'FaceDetectorInterface abstraction for pluggable face detection backends.',
			color: 'from-rose-500 to-red-500'
		}
	];

	const comparisons = [
		{ feature: 'Integration Time', vivd: '~10 min', inhouse: '3–6 months', competitor: '1–2 weeks' },
		{ feature: 'Liveness Actions', vivd: '4 actions', inhouse: 'Custom', competitor: '2–3 actions' },
		{ feature: 'On-Device', vivd: true, inhouse: true, competitor: false },
		{ feature: 'Offline Support', vivd: true, inhouse: true, competitor: false },
		{ feature: 'No API Key', vivd: true, inhouse: true, competitor: false },
		{ feature: 'Zero Dependencies', vivd: true, inhouse: false, competitor: false },
		{ feature: 'Session Signing', vivd: true, inhouse: 'Optional', competitor: false },
		{ feature: 'Face ID (20 faces)', vivd: true, inhouse: 'Custom', competitor: false },
		{ feature: 'Open Source', vivd: true, inhouse: true, competitor: false },
		{ feature: 'Price', vivd: 'Free', inhouse: '$50K+', competitor: '$$/mo' }
	];

	const stats = [
		{ value: '100%', label: 'On-Device', icon: Smartphone },
		{ value: '0', label: 'Dependencies', icon: Package },
		{ value: '4', label: 'Liveness Actions', icon: Eye },
		{ value: '20', label: 'Faces Stored', icon: Users }
	];

	const codeHero = `<span class="text-gray-500">dependencies:</span>\n  <span class="text-indigo-400">vivd</span><span class="text-gray-500">:</span> <span class="text-emerald-400">^0.1.0</span>`;

	const codeQuickstart = `<span class="text-purple-400">import</span> <span class="text-emerald-400">'package:vivd/vivd.dart'</span>;\n<span class="text-gray-500">// Start liveness detection</span>\n<span class="text-purple-400">final</span> result = <span class="text-purple-400">await</span> <span class="text-indigo-400">Vivd</span>.<span class="text-cyan-400">startLiveness</span>(\n  actions: [\n    <span class="text-indigo-400">VivdAction</span>.<span class="text-cyan-400">blink</span>,\n    <span class="text-indigo-400">VivdAction</span>.<span class="text-cyan-400">smile</span>,\n  ],\n);\n\n<span class="text-purple-400">if</span> (result.<span class="text-cyan-400">isLive</span>) {\n  <span class="text-indigo-400">print</span>(<span class="text-emerald-400">'Face verified!'</span>);\n  <span class="text-indigo-400">print</span>(<span class="text-emerald-400">'Score: \${result.score}'</span>);\n}`;

	const codePro = `<span class="text-purple-400">final</span> result = <span class="text-purple-400">await</span> <span class="text-indigo-400">VivdPro</span>.<span class="text-cyan-400">startLiveness</span>(\n  apiKey: <span class="text-emerald-400">'your-api-key'</span>,\n  actions: <span class="text-indigo-400">VivdAction</span>.<span class="text-cyan-400">all</span>,\n  enablePAD: <span class="text-amber-400">true</span>,\n);\n<span class="text-gray-500">// JWT-verified, server-signed result</span>`;

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

		return () => mm.revert();
	});
</script>

<!-- ===== HERO ===== -->
<section class="relative overflow-hidden pb-24 md:pb-32" bind:this={heroRef}>
	<!-- Background glow orbs -->
	<div class="absolute top-0 left-1/2 -translate-x-1/2 w-[800px] h-[500px] bg-gradient-to-b from-indigo-500/10 via-indigo-500/5 to-transparent rounded-full blur-3xl pointer-events-none"></div>
	<div class="absolute top-40 -left-40 w-72 h-72 bg-purple-500/5 rounded-full blur-3xl pointer-events-none"></div>
	<div class="absolute top-60 -right-40 w-72 h-72 bg-indigo-500/5 rounded-full blur-3xl pointer-events-none"></div>

	<div class="mx-auto max-w-6xl px-6 pt-24 md:pt-32 text-center relative">
		<!-- Badge -->
		<div data-hero-fade class="inline-flex items-center gap-2 px-4 py-1.5 rounded-full border border-indigo-500/20 bg-indigo-500/5 mb-8">
			<span class="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
			<span class="text-xs font-medium text-indigo-300">Open Source &bull; Apache 2.0 &bull; v0.1.0</span>
		</div>

		<!-- Headline -->
		<h1 data-hero-fade class="text-4xl sm:text-5xl md:text-7xl font-extrabold tracking-tight leading-[1.1] mb-6">
			<span class="text-white">Face Liveness</span><br />
			<span class="gradient-text">That Actually Works</span>
		</h1>

		<!-- Subtitle -->
		<p data-hero-fade class="mx-auto max-w-2xl text-base sm:text-lg text-gray-400 leading-relaxed mb-10">
			Drop-in Flutter SDK for on-device face verification. No server, no API key, no dependencies.
			Just <span class="text-gray-200 font-medium">blink, smile, and verify</span>.
		</p>

		<!-- CTAs -->
		<div data-hero-fade class="flex flex-col sm:flex-row items-center justify-center gap-4">
			<a
				href="#quickstart"
				class="group inline-flex items-center gap-2 px-7 py-3.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white font-semibold text-sm transition-all shadow-lg shadow-indigo-500/25 hover:shadow-indigo-500/40"
			>
				Get Started
				<ArrowRight size={16} class="transition-transform group-hover:translate-x-0.5" />
			</a>
			<a
				href="https://github.com/ajianaz/vivd"
				target="_blank"
				rel="noopener"
				class="inline-flex items-center gap-2 px-7 py-3.5 rounded-xl border border-white/10 hover:border-white/20 bg-white/[0.02] hover:bg-white/[0.05] text-gray-300 hover:text-white font-semibold text-sm transition-all"
			>
				<Github size={16} />
				View on GitHub
			</a>
		</div>

		<!-- Hero code preview -->
		<div data-hero-fade class="mt-16 mx-auto max-w-lg">
			<div class="code-block rounded-2xl p-1 glow-indigo">
				<div class="rounded-xl overflow-hidden">
					<!-- Terminal header -->
					<div class="flex items-center gap-2 px-4 py-3 border-b border-indigo-500/10">
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

<!-- ===== FEATURES ===== -->
<section id="features" class="py-24" bind:this={featuresRef}>
	<div class="mx-auto max-w-6xl px-6">
		<!-- Section header -->
		<div class="text-center mb-16">
			<span class="text-xs font-semibold text-indigo-400 uppercase tracking-widest">Features</span>
			<h2 class="mt-3 text-3xl sm:text-4xl font-bold text-white">Everything you need for face verification</h2>
			<p class="mt-4 text-gray-400 max-w-xl mx-auto">Built for Flutter developers who need reliable, privacy-preserving liveness detection.</p>
		</div>

		<!-- Feature grid -->
		<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
			{#each features as feature, i}
				<div
					data-feature-card
					class="glow-card group p-6 rounded-2xl border border-white/[0.06] bg-white/[0.02] transition-all duration-300"
				>
					<div class="w-10 h-10 rounded-xl bg-gradient-to-br {feature.color} flex items-center justify-center mb-4 shadow-lg">
						<feature.icon size={20} class="text-white" />
					</div>
					<h3 class="text-base font-semibold text-white mb-2">{feature.title}</h3>
					<p class="text-sm text-gray-400 leading-relaxed">{feature.desc}</p>
				</div>
			{/each}
		</div>
	</div>
</section>

<!-- ===== QUICK START ===== -->
<section id="quickstart" class="py-24" bind:this={codeRef}>
	<div class="mx-auto max-w-6xl px-6">
		<div class="text-center mb-16">
			<span class="text-xs font-semibold text-indigo-400 uppercase tracking-widest">Quick Start</span>
			<h2 class="mt-3 text-3xl sm:text-4xl font-bold text-white">Three steps to verify</h2>
		</div>

		<div class="grid lg:grid-cols-2 gap-10 items-center">
			<!-- Steps -->
			<div data-code-text class="space-y-8">
				<div class="flex gap-4">
					<div class="flex-shrink-0 w-8 h-8 rounded-lg bg-indigo-500/10 border border-indigo-500/20 flex items-center justify-center text-sm font-bold text-indigo-400">1</div>
					<div>
						<h3 class="text-base font-semibold text-white mb-1">Add the dependency</h3>
						<p class="text-sm text-gray-400">Add <code class="text-indigo-400 bg-indigo-500/10 px-1.5 py-0.5 rounded text-xs">vivd: ^0.1.0</code> to your pubspec.yaml.</p>
					</div>
				</div>

				<div class="flex gap-4">
					<div class="flex-shrink-0 w-8 h-8 rounded-lg bg-indigo-500/10 border border-indigo-500/20 flex items-center justify-center text-sm font-bold text-indigo-400">2</div>
					<div>
						<h3 class="text-base font-semibold text-white mb-1">Import and call</h3>
						<p class="text-sm text-gray-400">Import Vivd and call <code class="text-indigo-400 bg-indigo-500/10 px-1.5 py-0.5 rounded text-xs">startLiveness()</code> with your desired actions.</p>
					</div>
				</div>

				<div class="flex gap-4">
					<div class="flex-shrink-0 w-8 h-8 rounded-lg bg-indigo-500/10 border border-indigo-500/20 flex items-center justify-center text-sm font-bold text-indigo-400">3</div>
					<div>
						<h3 class="text-base font-semibold text-white mb-1">Check the result</h3>
						<p class="text-sm text-gray-400">Verify with <code class="text-indigo-400 bg-indigo-500/10 px-1.5 py-0.5 rounded text-xs">result.isLive</code> and get the confidence score.</p>
					</div>
				</div>

				<div class="pt-2">
					<a href="https://pub.dev/packages/vivd" target="_blank" rel="noopener" class="inline-flex items-center gap-2 text-sm font-medium text-indigo-400 hover:text-indigo-300 transition-colors">
						<BookOpen size={16} />
						Read full documentation
					</a>
				</div>
			</div>

			<!-- Code block -->
			<div data-code-block>
				<div class="code-block rounded-2xl p-1 glow-indigo">
					<div class="rounded-xl overflow-hidden">
						<div class="flex items-center gap-2 px-4 py-3 border-b border-indigo-500/10">
							<div class="flex gap-1.5">
								<div class="w-3 h-3 rounded-full bg-red-500/60"></div>
								<div class="w-3 h-3 rounded-full bg-yellow-500/60"></div>
								<div class="w-3 h-3 rounded-full bg-green-500/60"></div>
							</div>
							<span class="text-[11px] text-gray-500 ml-2">liveness_check.dart</span>
						</div>
						<pre class="px-4 py-4 text-[13px] leading-6 overflow-x-auto"><code>{@html codeQuickstart}</code></pre>
					</div>
				</div>
			</div>
		</div>
	</div>
</section>

<!-- ===== STATS ===== -->
<section class="py-24" bind:this={statsRef}>
	<div class="mx-auto max-w-6xl px-6">
		<div class="grid grid-cols-2 lg:grid-cols-4 gap-5">
			{#each stats as stat, i}
				<div data-stat class="text-center p-6 rounded-2xl border border-white/[0.06] bg-white/[0.02]">
					<div class="inline-flex items-center justify-center w-10 h-10 rounded-xl bg-indigo-500/10 mb-4">
						<stat.icon size={20} class="text-indigo-400" />
					</div>
					<div class="text-3xl sm:text-4xl font-extrabold text-white mb-1">{stat.value}</div>
					<div class="text-sm text-gray-400">{stat.label}</div>
				</div>
			{/each}
		</div>
	</div>
</section>

<!-- ===== COMPARISON ===== -->
<section id="compare" class="py-24" bind:this={compareRef}>
	<div class="mx-auto max-w-6xl px-6">
		<div class="text-center mb-16">
			<span class="text-xs font-semibold text-indigo-400 uppercase tracking-widest">Compare</span>
			<h2 class="mt-3 text-3xl sm:text-4xl font-bold text-white">Why Vivd?</h2>
			<p class="mt-4 text-gray-400 max-w-xl mx-auto">See how Vivd stacks up against building in-house or using closed-source alternatives.</p>
		</div>

		<div class="overflow-x-auto rounded-2xl border border-white/[0.06] bg-white/[0.02]">
			<table class="w-full text-sm">
				<thead>
					<tr class="border-b border-white/[0.06]">
						<th class="text-left px-6 py-4 text-gray-500 font-medium">Feature</th>
						<th class="text-center px-6 py-4">
							<span class="inline-flex items-center gap-1.5 font-semibold text-indigo-400">
								<span class="w-2 h-2 rounded-full bg-indigo-400"></span>
								Vivd
							</span>
						</th>
						<th class="text-center px-6 py-4 text-gray-500 font-medium">Build In-House</th>
						<th class="text-center px-6 py-4 text-gray-500 font-medium">Closed SDKs</th>
					</tr>
				</thead>
				<tbody>
					{#each comparisons as row}
						<tr class="compare-row border-b border-white/[0.03] transition-colors">
							<td class="px-6 py-3.5 text-gray-300">{row.feature}</td>
							<td class="px-6 py-3.5 text-center">
								{#if typeof row.vivd === 'boolean'}
									{#if row.vivd}
										<Check size={16} class="inline text-emerald-400" />
									{:else}
										<X size={16} class="inline text-red-400/60" />
									{/if}
								{:else}
									<span class="text-indigo-300 font-medium">{row.vivd}</span>
								{/if}
							</td>
							<td class="px-6 py-3.5 text-center">
								{#if typeof row.inhouse === 'boolean'}
									{#if row.inhouse}
										<Check size={16} class="inline text-emerald-400/60" />
									{:else}
										<X size={16} class="inline text-red-400/60" />
									{/if}
								{:else}
									<span class="text-gray-400">{row.inhouse}</span>
								{/if}
							</td>
							<td class="px-6 py-3.5 text-center">
								{#if typeof row.competitor === 'boolean'}
									{#if row.competitor}
										<Check size={16} class="inline text-emerald-400/60" />
									{:else}
										<X size={16} class="inline text-red-400/60" />
									{/if}
								{:else}
									<span class="text-gray-400">{row.competitor}</span>
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
<section id="pro" class="py-24">
	<div class="mx-auto max-w-6xl px-6">
		<div class="relative rounded-3xl border border-indigo-500/20 bg-gradient-to-br from-indigo-500/5 via-transparent to-purple-500/5 p-8 sm:p-12 overflow-hidden">
			<!-- Glow -->
			<div class="absolute top-0 right-0 w-80 h-80 bg-indigo-500/10 rounded-full blur-3xl -translate-y-1/2 translate-x-1/2 pointer-events-none"></div>

			<div class="relative">
				<span class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-indigo-500/10 border border-indigo-500/20 text-xs font-medium text-indigo-300 mb-6">
					<Server size={12} />
					Vivd Pro
				</span>

				<h2 class="text-3xl sm:text-4xl font-bold text-white mb-4">Need server-backed verification?</h2>
				<p class="text-gray-400 max-w-2xl mb-8 leading-relaxed">
					Vivd Pro adds ML-based Presentation Attack Detection (PAD), compliance features, face management, and
					JWT-signed server-verified results. Upgrade when you need enterprise-grade security.
				</p>

				<div class="flex flex-wrap gap-3 mb-8">
					{#each ['ML PAD Detection', 'JWT Verification', 'Face Management', 'Compliance Ready'] as tag}
						<span class="px-3 py-1 rounded-lg bg-white/[0.04] border border-white/[0.06] text-xs font-medium text-gray-300">
							{tag}
						</span>
					{/each}
				</div>

				<div class="code-block rounded-xl p-1 mb-8 max-w-lg">
					<div class="rounded-lg overflow-hidden">
						<div class="flex items-center gap-2 px-4 py-2 border-b border-indigo-500/10">
							<span class="text-[11px] text-gray-500">pro_example.dart</span>
						</div>
						<pre class="px-4 py-3 text-[12px] leading-5 overflow-x-auto"><code>{@html codePro}</code></pre>
					</div>
				</div>

				<div class="flex flex-wrap gap-4">
					<a href="https://pub.dev/packages/vivd_pro" target="_blank" rel="noopener" class="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white text-sm font-medium transition-colors">
						Learn about Pro
						<ArrowRight size={15} />
					</a>
					<span class="inline-flex items-center gap-1.5 px-4 py-2.5 text-sm text-gray-400">
						<Lock size={14} />
						BSL 1.1 License
					</span>
				</div>
			</div>
		</div>
	</div>
</section>

<!-- ===== CTA ===== -->
<section class="py-24" bind:this={ctaRef}>
	<div data-cta class="mx-auto max-w-4xl px-6 text-center">
		<h2 class="text-3xl sm:text-5xl font-extrabold text-white mb-6">Ready to verify?</h2>
		<p class="text-gray-400 text-lg mb-10 max-w-xl mx-auto">
			Start with the free core SDK. Add Pro when you need server-backed security.
		</p>
		<div class="flex flex-col sm:flex-row items-center justify-center gap-4">
			<a
				href="https://pub.dev/packages/vivd"
				target="_blank"
				rel="noopener"
				class="group inline-flex items-center gap-2 px-8 py-4 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white font-semibold transition-all shadow-xl shadow-indigo-500/25 hover:shadow-indigo-500/40"
			>
				<Package size={18} />
				Install from pub.dev
				<ArrowRight size={16} class="transition-transform group-hover:translate-x-0.5" />
			</a>
			<a
				href="https://github.com/ajianaz/vivd"
				target="_blank"
				rel="noopener"
				class="inline-flex items-center gap-2 px-8 py-4 rounded-xl border border-white/10 hover:border-white/20 bg-white/[0.02] hover:bg-white/[0.05] text-gray-300 hover:text-white font-semibold transition-all"
			>
				<Github size={18} />
				Star on GitHub
			</a>
		</div>

		<!-- Trust badges -->
		<div class="mt-16 flex flex-wrap items-center justify-center gap-x-8 gap-y-3">
			<div class="flex items-center gap-2 text-xs text-gray-500">
				<Shield size={14} class="text-emerald-500/60" />
				Apache 2.0 Licensed
			</div>
			<div class="flex items-center gap-2 text-xs text-gray-500">
				<Lock size={14} class="text-emerald-500/60" />
				Privacy-First
			</div>
			<div class="flex items-center gap-2 text-xs text-gray-500">
				<Clock size={14} class="text-emerald-500/60" />
				10 Minute Setup
			</div>
			<div class="flex items-center gap-2 text-xs text-gray-500">
				<Zap size={14} class="text-emerald-500/60" />
				Zero Dependencies
			</div>
		</div>
	</div>
</section>
