<script lang="ts">
	import { AspectRatio } from '$lib/components/ui/aspect-ratio';
	import * as Drawer from '$lib/components/ui/drawer/index.js';
	import Badge from '$lib/components/ui/badge/badge.svelte';
	import Button from '$lib/components/ui/button/button.svelte';
	import { Copy, Download } from '@lucide/svelte';
	import { Info, ChevronRight, ChevronsUpDown } from '@lucide/svelte';
	import axios from 'axios';
	import { onMount } from 'svelte';
	import { toast } from 'svelte-sonner';
	import Filters from './filters.svelte';
	import Loading from './loading.svelte';

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

	const owner = 'anotherhadi';
	const repo = 'awesome-wallpapers';
	const path = 'wallpapers';
	const apiUrl = `https://api.github.com/repos/${owner}/${repo}/contents/${path}`;

	let wallpapers: Wallpaper[] = $state([]);

	let allTags: string[] = $state([]);
	let selectedTags: string[] = $state([]);

	const copyToClipboard = (text: string) => {
		navigator.clipboard
			.writeText(text)
			.then(() => toast.success('Copied to clipboard!'))
			.catch(() => toast.error('Failed to copy'));
	};

	onMount(() => {
		const fetchWallpapers = async () => {
			try {
				const response = await axios.get(apiUrl, {
					headers: { Accept: 'application/vnd.github.v3+json' }
				});

				if (Array.isArray(response.data)) {
					const promises = response.data.map(async (file) => {
						let [namePart, ...tagsArray] = file.name.split('.')[0].split('_');
						let tagsPart = tagsArray.join('_');
						let name = namePart.replace(/-/g, ' ').replace(/\b\w/, (l: string) => l.toUpperCase());
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
					});

					wallpapers = await Promise.all(promises);
				} else {
					console.error('Error');
				}
			} catch (error) {
				console.error('Error: ', error);
			}
		};

		fetchWallpapers();
	});
</script>

<div class="flex min-h-[100vh] flex-col gap-5 bg-background">
	<header class="flex h-96 w-full flex-col items-center justify-center gap-5 bg-primary/20">
		<Badge class="gap-2" href={'https://github.com/' + owner + '/' + repo} target="_blank"
			>Check the github repo <ChevronRight size={16} /></Badge
		>
		<h1 class="m-0">Awesome Wallpapers</h1>
		<p class="text-muted-foreground">Wallpapers collection from {owner}/{repo}</p>
	</header>

	<main class="mx-10">
		<div class="px-2 py-4">
			<Filters title="Tags" options={allTags} bind:selectedValues={selectedTags} />
		</div>
		{#if wallpapers.length === 0}
			<Loading />
		{:else}
			<div class="grid grid-cols-2 gap-5">
				{#each wallpapers as wallpaper}
					{#if selectedTags.length === 0 || selectedTags.some( (tag) => wallpaper.tags.includes(tag) )}
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
											class="absolute bottom-0 left-0 right-0 top-0 z-[10] flex items-center justify-center bg-primary/20"
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
															class="mb-4 mt-2 max-h-[650px] overflow-x-auto rounded-lg border bg-zinc-950 px-2 py-4 dark:bg-zinc-900">
image = pkgs.fetchurl &lbrace;
  url = "https://raw.githubusercontent.com/{owner}/{repo}/refs/heads/main/{path}/{wallpaper.filename}";
  sha256 = "{wallpaper.sha256}";
&rbrace;</pre>
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
				{/each}
			</div>
		{/if}
	</main>
</div>

