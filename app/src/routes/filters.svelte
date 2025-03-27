<script lang="ts">
	import { CirclePlus, Check } from '@lucide/svelte';
	import { cn } from '$lib/utils.js';
	import * as Popover from '$lib/components/ui/popover';
	import * as Command from '$lib/components/ui/command';
	import Button from '$lib/components/ui/button/button.svelte';
	import Badge from '$lib/components/ui/badge/badge.svelte';
	import Separator from '$lib/components/ui/separator/separator.svelte';

	type Props = {
		title: string;
		selectedValues: string[];
		options: string[];
	};

	let { title, options, selectedValues = $bindable<string[]>([]) }: Props = $props();
</script>

<Popover.Root>
	<Popover.Trigger>
		{#snippet child({ props })}
			<Button {...props} variant="outline" size="sm" class="h-8 border-dashed">
				<CirclePlus />
				{title}
				{#if selectedValues.length > 0}
					<Separator orientation="vertical" class="mx-2 h-4" />
					{#each selectedValues as selectedValue}
						{#each options as option}
							{#if option === selectedValue}
								<Badge class="rounded-sm px-1 font-normal">
									{option}
								</Badge>
							{/if}
						{/each}
					{/each}
				{/if}
			</Button>
		{/snippet}
	</Popover.Trigger>
	<Popover.Content class="w-[200px] p-0" align="start">
		<Command.Root>
			<Command.Input placeholder={title} />
			<Command.List>
				<Command.Empty>No results found.</Command.Empty>
				<Command.Group>
					{#each options as option}
						{@const isSelected = selectedValues.includes(option)}
						<Command.Item
							onSelect={() => {
								if (isSelected) {
									selectedValues = selectedValues.filter((value) => value !== option);
								} else {
									selectedValues = [...selectedValues, option];
								}
							}}
						>
							<div
								class={cn(
									'mr-2 flex size-4 items-center justify-center rounded-sm border border-primary',
									isSelected ? 'bg-primary text-primary-foreground' : 'opacity-50 [&_svg]:invisible'
								)}
							>
								<Check class="size-4" />
							</div>
							<span>{option}</span>
						</Command.Item>
					{/each}
				</Command.Group>
				{#if selectedValues.length > 0}
					<Command.Separator />
					<Command.Group>
						<Command.Item class="justify-center text-center" onSelect={() => (selectedValues = [])}>
							Clear filters
						</Command.Item>
					</Command.Group>
				{/if}
			</Command.List>
		</Command.Root>
	</Popover.Content>
</Popover.Root>
