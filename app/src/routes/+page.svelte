<script lang="ts">
	import { AspectRatio } from '$lib/components/ui/aspect-ratio';
	import * as Drawer from '$lib/components/ui/drawer/index.js';
	import Badge from '$lib/components/ui/badge/badge.svelte';
	import Button from '$lib/components/ui/button/button.svelte';
	import { Copy, Download, Moon, Sun } from '@lucide/svelte';
	import { Info, ChevronRight, ChevronsUpDown } from '@lucide/svelte';
	import axios from 'axios';
	import { onMount } from 'svelte';
	import { toast } from 'svelte-sonner';
	import Filters from './filters.svelte';
	import Loading from './loading.svelte';
	import Input from '$lib/components/ui/input/input.svelte';
	import { toggleMode } from 'mode-watcher';

	type Wallpaper = {
		name: string;
		filename: string;
		size: string;
		width: number;
		height: number;
		tags: string[];
		more: boolean;
		hovered: boolean;
		sha256: string;
	};

	const version = 'v0.1.0';
	const owner = 'anotherhadi';
	const repo = 'awesome-wallpapers';
	const path = 'wallpapers';
	const apiUrl = `https://api.github.com/repos/${owner}/${repo}/contents/${path}`;

	let search: string = $state('');
	let wallpapers: Wallpaper[] = $state([]);
	const batchSize = 10;

	let allTags: string[] = $state([]);
	let selectedTags: string[] = $state([]);

	const copyToClipboard = (text: string) => {
		navigator.clipboard
			.writeText(text)
			.then(() => toast.success('Copied to clipboard!'))
			.catch(() => toast.error('Failed to copy'));
	};

	const fetchWallpapers = async () => {
		try {
			const response = await axios.get(apiUrl, {
				headers: { Accept: 'application/vnd.github.v3+json' }
			});

			if (Array.isArray(response.data)) {
				const files = response.data;
				// Traitement par lots
				for (let i = 0; i < files.length; i += batchSize) {
					const batch = files.slice(i, i + batchSize);
					const batchResults = await Promise.all(
						batch.map(async (file) => {
							console.log(file);
							let [namePart, ...tagsArray] = file.name.split('.')[0].split('_');
							let tagsPart = tagsArray.join('_');
							let name = namePart
								.replace(/-/g, ' ')
								.replace(/\b\w/, (l: string) => l.toUpperCase());
							let tags = tagsPart ? tagsPart.split('_') : [];
							let size = (file.size / 1024 / 1024).toFixed(2);

							tags.forEach((tag: string) => {
								if (!allTags.includes(tag)) {
									allTags.push(tag);
								}
							});

							const img = new Image();
							img.src = `https://raw.githubusercontent.com/${owner}/${repo}/main/${path}/${file.name}`;

							return new Promise<Wallpaper>((resolve) => {
								img.onload = () => {
									resolve({
										name,
										filename: file.name,
										tags,
										size,
										width: img.width,
										height: img.height,
										more: false,
										hovered: false,
										sha256: 'sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='
									});
								};
							});
						})
					);
					wallpapers = [...wallpapers, ...batchResults];
					// Optionnel : attendre un peu avant de charger le batch suivant
					await new Promise((r) => setTimeout(r, 100));
				}
			} else {
				console.error('Error');
			}
		} catch (error) {
			console.error('Error: ', error);
		}
	};

	onMount(fetchWallpapers);
</script>

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
		<div class="flex gap-5 px-2 py-4">
			<Input class="h-8" placeholder="Search..." bind:value={search} />
			<Filters title="Tags" options={allTags} bind:selectedValues={selectedTags} />
		</div>
		{#if wallpapers.length === 0}
			<Loading />
		{:else}
			<div class="grid grid-cols-1 gap-5 md:grid-cols-2 xl:grid-cols-3">
				{#each wallpapers as wallpaper}
					{#if selectedTags.length === 0 || selectedTags.some( (tag) => wallpaper.tags.includes(tag) )}
						{#if wallpaper.name.toLowerCase().includes(search.toLowerCase())}
							<div class="rounded-t-md bg-muted/5">
								<div class="relative">
									<AspectRatio
										ratio={16 / 9}
										class="w-full rounded-md bg-muted"
										onmouseenter={() => (wallpaper.hovered = true)}
										onmouseleave={() => (wallpaper.hovered = false)}
									>
										{#if wallpaper.hovered}
											<div
												class="absolute bottom-0 left-0 right-0 top-0 z-[10] flex items-center justify-center bg-primary/50"
											>
												<Button
													href={`https://raw.githubusercontent.com/${owner}/${repo}/main/${path}/${wallpaper.filename}`}
													target="_blank">Download</Button
												>
											</div>
										{/if}
										<img
											src={`https://raw.githubusercontent.com/${owner}/${repo}/main/${path}/${wallpaper.filename}`}
											alt={wallpaper.name + ' wallpaper'}
											class="h-full w-full rounded-md object-cover"
										/>
									</AspectRatio>
								</div>
								<div class="flex w-full items-center justify-between p-2">
									{wallpaper.name}
									<div class="flex gap-2">
										<Drawer.Root>
											<Drawer.Trigger>
												<Button size="icon" variant="ghost" class="h-6 w-6">
													<Info />
												</Button>
											</Drawer.Trigger>
											<Drawer.Content>
												<div class="m-auto w-full max-w-3xl select-text">
													<Drawer.Header>
														<Drawer.Title>{wallpaper.name}</Drawer.Title>
													</Drawer.Header>
													<div class="p-4 pb-0">
														<p>
															<span class="text-muted-foreground">Filename:</span>
															{wallpaper.filename}
														</p>
														<p><span class="text-muted-foreground">Name:</span> {wallpaper.name}</p>
														<p>
															<span class="text-muted-foreground">Size:</span>
															{wallpaper.size} Mb
														</p>
														<p>
															<span class="text-muted-foreground">Resolution:</span>
															{wallpaper.width}x{wallpaper.height}
														</p>
														<p>
															<span class="text-muted-foreground">Tags:</span>
															{#each wallpaper.tags as tag}
																<Badge variant="outline">{tag}</Badge>
															{/each}
														</p>
														<p class="mt-2">
															<span class="text-muted-foreground">Nix fetchurl:</span>
														</p>

														<div class="relative">
															<Button
																size="icon"
																variant="ghost"
																class="absolute right-2 top-2 h-6 w-6"
																onclick={() => {
																	let content = `
image = pkgs.fetchurl {
  url = "https://raw.githubusercontent.com/${owner}/${repo}/refs/heads/main/${path}/${wallpaper.filename}";
  sha256 = "${wallpaper.sha256}";
};`;
																	copyToClipboard(content);
																}}
															>
																<Copy />
															</Button>

															<pre
																id={wallpaper.filename}
																class="mb-4 mt-2 max-h-[650px] overflow-x-auto rounded-lg border bg-zinc-950 px-2 py-4 text-white dark:bg-zinc-900">
image = pkgs.fetchurl &lbrace;
  url = "https://raw.githubusercontent.com/{owner}/{repo}/refs/heads/main/{path}/{wallpaper.filename}";
  sha256 = "{wallpaper.sha256}";
&rbrace;;</pre>
														</div>
													</div>
													<Drawer.Footer>
														<Drawer.Close>Close</Drawer.Close>
													</Drawer.Footer>
												</div>
											</Drawer.Content>
										</Drawer.Root>
										<Button
											size="icon"
											variant="ghost"
											class="h-6 w-6"
											onclick={() => (wallpaper.more = !wallpaper.more)}
										>
											<ChevronsUpDown />
										</Button>
										<Button
											size="icon"
											variant="ghost"
											class="h-6 w-6"
											href={`https://raw.githubusercontent.com/${owner}/${repo}/main/${path}/${wallpaper.filename}`}
											target="_blank"
										>
											<Download />
										</Button>
									</div>
								</div>
								{#if wallpaper.more}
									<div class="px-2 py-1">
										<p><span class="text-muted-foreground">Name:</span> {wallpaper.name}</p>
										<p><span class="text-muted-foreground">Size:</span> {wallpaper.size} Mb</p>
										<p>
											<span class="text-muted-foreground">Resolution:</span>
											{wallpaper.width}x{wallpaper.height}
										</p>
										<p>
											<span class="text-muted-foreground">Tags:</span>
											{#each wallpaper.tags as tag}
												<Badge variant="outline">{tag}</Badge>
											{/each}
										</p>
									</div>
								{/if}
							</div>
						{/if}
					{/if}
				{/each}
			</div>
		{/if}
	</main>
</div>
<div class="mt-5 flex h-32 w-full flex-col items-center justify-center gap-4 bg-primary/20">
	<img src="/favicon.png" alt="logo" class="w-5 rounded-md" />
	<p class="text-muted-foreground">@anotherhadi</p>
</div>
