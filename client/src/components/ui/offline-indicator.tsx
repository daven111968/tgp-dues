import { useOffline } from '@/hooks/use-offline';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { WifiOff, Wifi } from 'lucide-react';

export function OfflineIndicator() {
  const isOffline = useOffline();

  if (!isOffline) return null;

  return (
    <Alert className="mb-4 border-orange-200 bg-orange-50 text-orange-800">
      <WifiOff className="h-4 w-4" />
      <AlertDescription>
        You're currently offline. Some features may not be available.
      </AlertDescription>
    </Alert>
  );
}

export function ConnectionStatus() {
  const isOffline = useOffline();

  return (
    <div className="flex items-center gap-2 text-sm">
      {isOffline ? (
        <>
          <WifiOff className="h-4 w-4 text-orange-500" />
          <span className="text-orange-600">Offline</span>
        </>
      ) : (
        <>
          <Wifi className="h-4 w-4 text-green-500" />
          <span className="text-green-600">Online</span>
        </>
      )}
    </div>
  );
}