<script lang="ts">
	import '../app.css';
	import Badge from '$lib/components/ui/badge/badge.svelte';
	import Button from '$lib/components/ui/button/button.svelte';
	import { ChevronRight, Moon, Sun } from '@lucide/svelte';
	import { toggleMode } from 'mode-watcher';
	import { ModeWatcher } from 'mode-watcher';
	import { Toaster } from '$lib/components/ui/sonner/index.js';
	let { children } = $props();

	const version = 'v0.1.1';
	const owner = 'anotherhadi';
	const repo = 'awesome-wallpapers';
</script>

<ModeWatcher />
<Toaster />
<div class="relative flex min-h-[100vh] flex-col gap-5 bg-background">
	<p class="absolute right-2 top-2 m-2 text-muted-foreground">{version}</p>
	<Button onclick={toggleMode} variant="ghost" size="icon" class="absolute left-2 right-2 m-2">
		<Sun
			class="h-[1.2rem] w-[1.2rem] rotate-0 scale-100 transition-all dark:-rotate-90 dark:scale-0"
		/>
		<Moon
			class="absolute h-[1.2rem] w-[1.2rem] rotate-90 scale-0 transition-all dark:rotate-0 dark:scale-100"
		/>
		<span class="sr-only">Toggle theme</span>
	</Button>

	<header class="flex h-96 w-full flex-col items-center justify-center gap-5 bg-primary/20">
		<Badge class="gap-2" href={'https://github.com/' + owner + '/' + repo} target="_blank"
			>Check the github repo <ChevronRight size={16} /></Badge
		>
		<h1 class="m-0">Awesome Wallpapers</h1>
		<p class="text-muted-foreground">Open-source wallpapers collection from {owner}/{repo}</p>
	</header>

	<main class="px-10">
		{@render children()}
	</main>

	<div class="mt-32"></div>
	<div
		class="absolute bottom-0 flex h-32 w-full flex-col items-center justify-center gap-4 bg-primary/20"
	>
		<img src="/favicon.png" alt="logo" class="w-5 rounded-md" />
		<p class="text-muted-foreground">@anotherhadi</p>
	</div>
</div>
