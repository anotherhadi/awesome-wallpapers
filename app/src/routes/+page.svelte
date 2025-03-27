<script lang="ts">
	import { onMount } from 'svelte';
	import Loading from './loading.svelte';
	import Filters from './filters.svelte';
	import Input from '$lib/components/ui/input/input.svelte';
	import { AspectRatio } from '$lib/components/ui/aspect-ratio';
	import Button from '$lib/components/ui/button/button.svelte';
	import { Copy, Download, Info } from '@lucide/svelte';
	import * as Drawer from '$lib/components/ui/drawer/index.js';
	import { toast } from 'svelte-sonner';
	import Badge from '$lib/components/ui/badge/badge.svelte';

	type Wallpaper = {
		name: string;
		filename: string;
		tags: string[];
		size: string;
		width: number;
		height: number;
		hovered: boolean;
	};

	let wallpapers: Wallpaper[] = [];
	let tags: string[] = [];
	let selectedTags: string[] = [];
	let search: string = '';
	let loading: boolean = false;
	let isLoadingMore: boolean = false; // Etat pour savoir si de nouveaux wallpapers sont en train de charger
	let allWallpapers: Wallpaper[] = [];
	let currentPage: number = 0;
	const wallpapersPerPage: number = 20;

	const owner = 'anotherhadi';
	const repo = 'awesome-wallpapers';
	const path = 'app/static/wallpapers';

	function parseFilename(filename: string) {
		let [namePart, ...tagsArray] = filename.split('.')[0].split('_');
		let tagsPart = tagsArray.join('_');
		let name = namePart.replace(/-/g, ' ').replace(/\b\w/, (l: string) => l.toUpperCase());
		let fileTags = tagsPart ? tagsPart.split('_') : [];

		fileTags.forEach((tag: string) => {
			if (!tags.includes(tag)) {
				tags.push(tag);
			}
		});

		return {
			name,
			filename,
			tags: fileTags
		};
	}

	const copyToClipboard = (text: string) => {
		navigator.clipboard
			.writeText(text)
			.then(() => toast.success('Copied to clipboard!'))
			.catch(() => toast.error('Failed to copy'));
	};

	async function fetchWallpapers() {
		const res = await fetch('/files.json');
		const fileData: { filename: string; size: string; width: number; height: number }[] =
			await res.json();

		// Map to Wallpaper objects
		allWallpapers = fileData.map((file) => {
			let { name, filename, tags: fileTags } = parseFilename(file.filename);

			return {
				name,
				filename,
				tags: fileTags,
				size: file.size,
				width: file.width,
				height: file.height,
				hovered: false
			};
		});

		// Initially load the first set of wallpapers
		loadMoreWallpapers();
	}

	function loadMoreWallpapers() {
		if (loading || isLoadingMore || currentPage * wallpapersPerPage >= allWallpapers.length) return;
		isLoadingMore = true;

		// Load next batch of wallpapers
		const nextWallpapers = allWallpapers.slice(
			currentPage * wallpapersPerPage,
			(currentPage + 1) * wallpapersPerPage
		);
		wallpapers = [...wallpapers, ...nextWallpapers];
		currentPage++;
		isLoadingMore = false;
	}

	// Handle scroll event
	function onScroll() {
		const scrollPosition = window.scrollY + window.innerHeight;
		const bottomPosition = document.documentElement.scrollHeight;

		if (scrollPosition >= bottomPosition - 100) {
			// Load more wallpapers when reaching the bottom
			loadMoreWallpapers();
		}
	}

	onMount(() => {
		fetchWallpapers();
		window.addEventListener('scroll', onScroll);

		return () => {
			window.removeEventListener('scroll', onScroll);
		};
	});
</script>

<div class="flex gap-5 px-2 py-4">
	<Input class="h-8" placeholder="Search..." bind:value={search} />
	<Filters title="Tags" options={tags} bind:selectedValues={selectedTags} />
</div>

{#if wallpapers.length === 0}
	<Loading />
{:else}
	<div class="grid grid-cols-1 gap-5 md:grid-cols-2 xl:grid-cols-3">
		{#each wallpapers as wallpaper}
			{#if selectedTags.length === 0 || selectedTags.some((tag) => wallpaper.tags.includes(tag))}
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
									src={`/wallpapers/${wallpaper.filename}`}
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
													{#if wallpaper.tags.length === 0}
														<span class="text-muted-foreground">No tags</span>
													{:else}
														{#each wallpaper.tags as tag}
															<Badge variant="outline">{tag}</Badge>
														{/each}
													{/if}
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
  sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
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
  sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
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
									href={`https://raw.githubusercontent.com/${owner}/${repo}/main/${path}/${wallpaper.filename}`}
									target="_blank"
								>
									<Download />
								</Button>
							</div>
						</div>
					</div>
				{/if}
			{/if}
		{/each}
	</div>
	{#if isLoadingMore}
		<div class="mt-4 flex justify-center">
			<Loading />
		</div>
	{/if}
{/if}
