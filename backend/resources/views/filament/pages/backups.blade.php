<x-filament::page>
    <div class="space-y-6">
        <div class="flex justify-end">
            <x-filament::button wire:click="createBackup" color="success">
                Backup Now 🚀
            </x-filament::button>
        </div>

        <div class="overflow-x-auto border rounded-xl dark:border-gray-700">
            <table class="w-full text-sm text-left">
                <thead class="text-xs uppercase bg-gray-50 dark:bg-gray-800">
                    <tr>
                        <th class="px-6 py-3">File Name</th>
                        <th class="px-6 py-3">Size</th>
                        <th class="px-6 py-3">Date</th>
                        <th class="px-6 py-3 text-right">Actions</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($backups as $backup)
                    <tr class="border-b dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-800">
                        <td class="px-6 py-4 font-medium">{{ $backup['name'] }}</td>
                        <td class="px-6 py-4">{{ $backup['size'] }}</td>
                        <td class="px-6 py-4">{{ $backup['date'] }}</td>
                        <td class="px-6 py-4 text-right space-x-2">
                            <x-filament::button size="xs" icon="heroicon-m-arrow-down-tray" color="primary" wire:click="downloadBackup('{{ $backup['path'] }}')">
                                Download
                            </x-filament::button>
                            <x-filament::button size="xs" icon="heroicon-m-trash" color="danger" wire:click="deleteBackup('{{ $backup['path'] }}')">
                                Delete
                            </x-filament::button>
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="4" class="px-6 py-4 text-center text-gray-500">
                            Belum ada file backup. Klik tombol di atas untuk membuat backup.
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</x-filament::page>
