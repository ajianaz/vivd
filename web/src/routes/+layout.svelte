<script lang="ts">
	import '../app.css';
	import { Menu, X, Github } from 'lucide-svelte';

	let { children } = $props();

	let mobileOpen = $state(false);

	const navLinks = [
		{ label: 'Features', href: '#features' },
		{ label: 'Quick Start', href: '#quickstart' },
		{ label: 'Compare', href: '#compare' },
		{ label: 'Pro', href: '#pro' }
	];
</script>

<div class="min-h-screen grid-bg radial-glow">
	<!-- Navbar -->
	<nav class="fixed top-0 left-0 right-0 z-50 border-b border-white/5 bg-[#06060e]/80 backdrop-blur-xl">
		<div class="mx-auto max-w-6xl px-6 h-16 flex items-center justify-between">
			<!-- Logo -->
			<a href="/" class="flex items-center gap-2.5 group">
				<div class="w-8 h-8 rounded-lg bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center text-white font-bold text-sm shadow-lg shadow-indigo-500/20">
					V
				</div>
				<span class="text-lg font-bold text-white tracking-tight">Vivd</span>
				<span class="text-[10px] font-medium px-1.5 py-0.5 rounded bg-indigo-500/10 text-indigo-400 border border-indigo-500/20">SDK</span>
			</a>

			<!-- Desktop Nav -->
			<div class="hidden md:flex items-center gap-8">
			{#each navLinks as link}
				<a href={link.href} class="nav-link text-sm text-gray-400 hover:text-white transition-colors">{link.label}</a>
			{/each}
			</div>

			<!-- Desktop CTA -->
			<div class="hidden md:flex items-center gap-3">
				<a href="https://github.com/ajianaz/vivd" target="_blank" rel="noopener" class="text-gray-400 hover:text-white transition-colors">
					<Github size={18} />
				</a>
				<a href="#quickstart" class="text-sm font-medium px-4 py-2 rounded-lg bg-indigo-600 hover:bg-indigo-500 text-white transition-colors">
					Get Started
				</a>
			</div>

			<!-- Mobile Toggle -->
			<button class="md:hidden text-gray-400 hover:text-white" onclick={() => mobileOpen = !mobileOpen}>
				{#if mobileOpen}
					<X size={22} />
				{:else}
					<Menu size={22} />
				{/if}
			</button>
		</div>

		<!-- Mobile Menu -->
		{#if mobileOpen}
			<div class="md:hidden border-t border-white/5 bg-[#06060e]/95 backdrop-blur-xl px-6 py-4 space-y-3">
				{#each navLinks as link}
					<a href={link.href} class="block text-sm text-gray-400 hover:text-white transition-colors py-1" onclick={() => mobileOpen = false}>{link.label}</a>
				{/each}
				<div class="pt-3 border-t border-white/5 flex gap-3">
					<a href="https://github.com/ajianaz/vivd" target="_blank" rel="noopener" class="text-gray-400 hover:text-white transition-colors">
						<Github size={18} />
					</a>
					<a href="#quickstart" class="text-sm font-medium px-4 py-2 rounded-lg bg-indigo-600 hover:bg-indigo-500 text-white transition-colors" onclick={() => mobileOpen = false}>
						Get Started
					</a>
				</div>
			</div>
		{/if}
	</nav>

	<!-- Main Content -->
	<main class="pt-16">
		{@render children()}
	</main>

	<!-- Footer -->
	<footer class="border-t border-white/5 mt-32">
		<div class="mx-auto max-w-6xl px-6 py-12">
			<div class="grid grid-cols-2 md:grid-cols-4 gap-8">
				<!-- Brand -->
				<div class="col-span-2 md:col-span-1">
					<div class="flex items-center gap-2 mb-4">
						<div class="w-7 h-7 rounded-lg bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center text-white font-bold text-xs">V</div>
						<span class="font-bold text-white">Vivd</span>
					</div>
					<p class="text-sm text-gray-500 leading-relaxed">Open source Flutter face liveness SDK. Privacy-first, on-device verification.</p>
				</div>

				<!-- Product -->
				<div>
					<h4 class="text-sm font-semibold text-gray-300 mb-3">Product</h4>
					<ul class="space-y-2">
						<li><a href="#features" class="text-sm text-gray-500 hover:text-gray-300 transition-colors">Features</a></li>
						<li><a href="#quickstart" class="text-sm text-gray-500 hover:text-gray-300 transition-colors">Quick Start</a></li>
						<li><a href="#compare" class="text-sm text-gray-500 hover:text-gray-300 transition-colors">Compare</a></li>
						<li><a href="#pro" class="text-sm text-gray-500 hover:text-gray-300 transition-colors">Pro</a></li>
					</ul>
				</div>

				<!-- Resources -->
				<div>
					<h4 class="text-sm font-semibold text-gray-300 mb-3">Resources</h4>
					<ul class="space-y-2">
						<li><a href="https://pub.dev/packages/vivd" target="_blank" rel="noopener" class="text-sm text-gray-500 hover:text-gray-300 transition-colors">pub.dev</a></li>
						<li><a href="https://github.com/ajianaz/vivd" target="_blank" rel="noopener" class="text-sm text-gray-500 hover:text-gray-300 transition-colors">GitHub</a></li>
						<li><a href="/CHANGELOG.md" class="text-sm text-gray-500 hover:text-gray-300 transition-colors">Changelog</a></li>
						<li><a href="/CONTRIBUTING.md" class="text-sm text-gray-500 hover:text-gray-300 transition-colors">Contributing</a></li>
					</ul>
				</div>

				<!-- Legal -->
				<div>
					<h4 class="text-sm font-semibold text-gray-300 mb-3">Legal</h4>
					<ul class="space-y-2">
						<li><span class="text-sm text-gray-500">Core: Apache 2.0</span></li>
						<li><span class="text-sm text-gray-500">Pro: BSL 1.1</span></li>
					</ul>
				</div>
			</div>

			<div class="mt-10 pt-6 border-t border-white/5 flex flex-col sm:flex-row items-center justify-between gap-4">
				<p class="text-xs text-gray-600">&copy; {new Date().getFullYear()} Vivd. Open source under Apache 2.0.</p>
				<div class="flex items-center gap-1 text-xs text-gray-600">
					Built with
					<span class="text-indigo-400 mx-0.5">♥</span>
					for Flutter developers
				</div>
			</div>
		</div>
	</footer>
</div>
